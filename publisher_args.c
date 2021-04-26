/*
 * This example shows how to publish messages from outside of the Mosquitto network loop.
 */

#include <mosquitto.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TEST_PORT 8088
#define MICROTOMILI 1000

static char **generate_topics(int test_num_topics)
{
	char **test_topic = malloc(sizeof(char *) * test_num_topics);
	char numset[] = "0123456789";
	char charset[] = "abcdefghijklmnopqrstuvwxyz";

	int num_pos = 0;
	int char_pos = 0;
	for (int i = 0; i < test_num_topics; i++) {
		// an alphabet + a number + \0
		test_topic[i] = malloc(sizeof(char) * 3);
		char *tmp = test_topic[i];
		*tmp++ = charset[char_pos];
		*tmp++ = numset[num_pos++];
		*tmp = '\0';
		// if num is at the end, 
		// loop num around, and increase char
		if(num_pos == 10){
			num_pos = 0;
			char_pos++;
		}
		printf("[ INFO ] generated %s\n", test_topic[i]);
	}
	return test_topic;	
}

/* Callback called when the client receives a CONNACK message from the broker. */
void on_connect(struct mosquitto *mosq, void *obj, int reason_code)
{
	/* Print out the connection result. mosquitto_connack_string() produces an
	 * appropriate string for MQTT v3.x clients, the equivalent for MQTT v5.0
	 * clients is mosquitto_reason_string().
	 */
	printf("on_connect: %s\n", mosquitto_connack_string(reason_code));
	if(reason_code != 0){
		/* If the connection fails for any reason, we don't want to keep on
		 * retrying in this example, so disconnect. Without this, the client
		 * will attempt to reconnect. */
		mosquitto_disconnect(mosq);
	}

	/* You may wish to set a flag here to indicate to your application that the
	 * client is now connected. */
}


/* Callback called when the client knows to the best of its abilities that a
 * PUBLISH has been successfully sent. For QoS 0 this means the message has
 * been completely written to the operating system. For QoS 1 this means we
 * have received a PUBACK from the broker. For QoS 2 this means we have
 * received a PUBCOMP from the broker. */
void on_publish(struct mosquitto *mosq, void *obj, int mid)
{
	printf("Message with mid %d has been published.\n", mid);
}


int get_temperature(void)
{
	/* Prevent a storm of messages - this pretend sensor works at 1Hz */
	int temp = random()%100;
	printf("send %d\n",temp);
	return temp;
}

/* This function pretends to read some data from a sensor and publish it.*/
void publish_sensor_data(struct mosquitto *mosq, char *test_topic)
{
	char payload[20];
	int temp;
	int rc;

	/* Get our pretend data */
	temp = get_temperature();
	/* Print it to a string for easy human reading - payload format is highly
	 * application dependent. */
	snprintf(payload, sizeof(payload), "%d", temp);

	/* Publish the message
	 * mosq - our client instance
	 * *mid = NULL - we don't want to know what the message id for this message is
	 * topic = "example/temperature" - the topic on which this message will be published
	 * payloadlen = strlen(payload) - the length of our payload in bytes
	 * payload - the actual payload
	 * qos = 2 - publish with QoS 2 for this example
	 * retain = false - do not use the retained message feature for this message
	 */
	rc = mosquitto_publish(mosq, NULL, test_topic,
			strlen(payload), payload, 2, false);
	if(rc != MOSQ_ERR_SUCCESS){
		fprintf(stderr, "Error publishing: %s\n", mosquitto_strerror(rc));
	}
}


int main(int argc, char *argv[])
{
	struct mosquitto *mosq;
	int rc;
	int test_port, test_num_topics, num_msg, msg_mili_sleep;
	char test_ip[20], **test_topic, *topic, buf[20];

	if (argc < 6) {	
		fprintf(stderr, "./publisher_args <broker_ip> <broker_port> "
				"<num_msg_per_topic> <msg_sleep_msec> "
				"<num_topic> <topic1> ...\n");
		return -1;
	}else{
		sscanf(argv[1], "%s", test_ip);
		test_port = atoi(argv[2]);
		num_msg = atoi(argv[3]);
		msg_mili_sleep = atoi(argv[4]);
		test_num_topics = atoi(argv[5]);
		if (argc - 6 == 0 && test_num_topics > 0) {
			// generate topics
			test_topic = generate_topics(test_num_topics);
			goto generated_topics;
		}
		if (argc - 6 < test_num_topics || msg_mili_sleep <= 0) {
			fprintf(stderr, "./pubsliher_args <broker_ip> <broker_port> "
					"<num_msg_per_topic> <msg_sleep_msec> "
					"<num_topic> <topic1> ...\n");
			return -1;
		}
	}
	test_topic = malloc(sizeof(char *) * test_num_topics);
	for (int i = 0; i < test_num_topics; i++) {
		sscanf(argv[6 + i], "%s", buf);
		test_topic[i] = malloc(sizeof(char) * strlen(buf));
		strncpy(test_topic[i], buf, strlen(buf));
		printf("[ INFO ] pub obtained topic=%s\n", test_topic[i]);
	}

generated_topics:
	/* Required before calling other mosquitto functions */
	mosquitto_lib_init();

	/* Create a new client instance.
	 * id = NULL -> ask the broker to generate a client id for us
	 * clean session = true -> the broker should remove old sessions when we connect
	 * obj = NULL -> we aren't passing any of our private data for callbacks
	 */
	for (int kid = 0; kid < test_num_topics; kid++) {
		int pid = fork();
		if (pid < 0) {
			exit(-1);
		}else if (pid > 0) {
			/* no op, perhaps add wait */
		}else{
			/* child exits when done. Child never forks. */
			topic = test_topic[kid];
			mosq = mosquitto_new(NULL, true, NULL);
			if(mosq == NULL){
				fprintf(stderr, "Error: Out of memory.\n");
				return 1;
			}

			/* Configure callbacks. This should be done before connecting ideally. */
			mosquitto_connect_callback_set(mosq, on_connect);
			mosquitto_publish_callback_set(mosq, on_publish);

			/* Connect to test.mosquitto.org on port 1883, with a keepalive of 60 seconds.
			 * This call makes the socket connection only, it does not complete the MQTT
			 * CONNECT/CONNACK flow, you should use mosquitto_loop_start() or
			 * mosquitto_loop_forever() for processing net traffic. */
			rc = mosquitto_connect(mosq, test_ip, test_port, 60);
			if(rc != MOSQ_ERR_SUCCESS){
				mosquitto_destroy(mosq);
				fprintf(stderr, "Error: %s\n", mosquitto_strerror(rc));
				return 1;
			}

			/* Run the network loop in a background thread, this call returns quickly. */
			rc = mosquitto_loop_start(mosq);
			if(rc != MOSQ_ERR_SUCCESS){
				mosquitto_destroy(mosq);
				fprintf(stderr, "Error: %s\n", mosquitto_strerror(rc));
				return 1;
			}

			/* At this point the client is connected to the network socket, but may not
			 * have completed CONNECT/CONNACK.
			 * It is fairly safe to start queuing messages at this point, but if you
			 * want to be really sure you should wait until after a successful call to
			 * the connect callback.
			 * In this case we know it is 1 second before we start publishing.
			 */
			printf("[ INFO ]Publishing at topic: %s\n", topic);
			int i=0;
			while(i++ < num_msg){
				publish_sensor_data(mosq, topic);
				usleep(msg_mili_sleep * MICROTOMILI); 
			}

			mosquitto_lib_cleanup();

			exit(0);
		}
	}
	return 0;
}
