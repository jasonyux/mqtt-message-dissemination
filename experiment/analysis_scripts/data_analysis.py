import numpy as np
import xarray as xr

# import cartopy.crs as ccrs
# import cartopy.feature as cfeature
from scipy import stats
import csv
import sys

from matplotlib import pyplot as plt

from datetime import datetime

months = [datetime(2019, imon, 1) for imon in np.arange(1, 12 + 1)]
month_str = [date_obj.strftime("%b") for date_obj in months]
m_str = [w[0] for w in month_str]

# Get color order
prop_cycle = plt.rcParams["axes.prop_cycle"]

colors = prop_cycle.by_key()["color"]
cc = prop_cycle.by_key()["color"]

brokers = [
    "",
    "172.19.0.2",
    "172.19.0.3",
    "172.19.0.4",
    "172.19.0.5",
    "172.19.0.6",
    "172.19.0.7",
    "172.19.0.8",
]
clients = ["172.19.0.9", "172.19.0.10"]

num_brokers = 7
csv_files = []
csv_dir = "./"
output_dir = "./"
plot_base_name = ""


def save_plot(file_name):
    global output_dir
    plt.savefig(output_dir + file_name + ".png", dpi=300)
    return


def my_init(csv_dir):
    csv_files = []
    # configures csv_files
    for i in range(num_brokers):
        file = csv_dir + "b{}.csv".format(i + 1)
        print(file)
        csv_files.append(file)
    return csv_files


def parse_single_csv(filename):
    fields = []
    rows = []

    with open(filename, "r") as csvfile:
        # creating a csv reader object
        csvreader = csv.reader(csvfile)

        # extracting field names through first row
        fields = next(csvreader)

        for row in csvreader:
            rows.append(
                {
                    "time": float(row[0]),
                    "len": int(row[1]),
                    "src": row[2],
                    "dst": row[3],
                }
            )
        print("[{}] Total no. of rows: {}".format(filename, csvreader.line_num))

    # printing the field names

    #  printing first 5 rows
    # print('\nFirst 5 rows are:\n')
    # print(' | '.join(field.ljust(20) for field in fields))
    # for row in rows[:5]:
    # parsing each column of a row
    # print(' | '.join(str(col).ljust(20) for col in row.values()))
    return (fields, rows)


# returns a list of [ (field, data), (field, data) ]  for each csv in @csv_files
def parse_num_csv(csv_files):
    result = []
    for file in csv_files:
        print("parsing " + file)
        result.append(parse_single_csv(file))
    return result


def print_csv(field, data, all_data=1):
    print(" | ".join(field.ljust(20) for field in fields))
    if all_data:
        for row in data:
            print(" | ".join(str(col).ljust(20) for col in row.values()))
        return
    if all_data > len(data):
        all_data = len(data)

    for row in data[:all_data]:
        print(" | ".join(str(col).ljust(20) for col in row.values()))
    return


def print_data(data, all_data=1):
    if all_data:
        all_data = len(data)
    if all_data > len(data):
        all_data = len(data)

    for row in data[:all_data]:
        print(" | ".join(str(col).ljust(20) for col in row.values()))
    return


# returns true if @src matches ANY of the @filters
def check_in_multiple(src, filters):
    if filters is None or len(filters) == 0:
        print("[ DEBUG ] not filters passed in")
        return False

    if(isinstance(src, str) and not src.strip()):
        return True

    for filter in filters:
        if src == filter:
            # print("[ DEBUG ] {} matches {}".format(src, filter))
            return True
    return False


# filters data by excluding rows that matches @src_ip and @dst_ip
def my_filter(data, src_ip_filter, dst_ip_filter):
    filtered = []
    if data is None or len(data) == 0:
        print("[ ERROR ] no data given")
        return
    for row in data:
        condition_1 = check_in_multiple(row["src"], src_ip_filter)
        condition_2 = not check_in_multiple(row["dst"], dst_ip_filter)
        if condition_1 and condition_2:
            filtered.append(row)
    return filtered


def round_time(data):
    if data is None or len(data) == 0:
        print("[ ERROR ] no data given")
        return None
    result = []
    for row in data:
        clone = row.copy()
        clone["time"] = int(clone["time"])
        result.append(clone)

    # print_data(result)
    return result


# for all data with same data[@key], do agg_func(@data[@value])
# this assumes the data is ALREADY SORTED in data[@key]
def aggregate_dup(data, key="time", value="len", agg_func=None):
    if data is None or len(data) == 0:
        print("[ ERROR ] no data given")
        return None
    if not agg_func:
        agg_func = sum

    result = []
    temp = []
    curr_time = data[0][key]
    temp.append(data[0][value])

    for row in data[1:]:
        if row[key] == curr_time:
            temp.append(row[value])
        else:
            # now we are at a new time, first compute the previous aggregates
            result.append({"time": curr_time, "len": agg_func(temp)})
            # print("[ DEBUG ] summed to "+str({ 'rounded_time':curr_time, 'len': sum(temp) }))

            # reset the temp and update the new curr time pointer
            temp = []
            curr_time = row[key]
            temp.append(row[value])

    # computes the last
    result.append({"time": curr_time, "len": agg_func(temp)})
    # print("[ DEBUG ] summed to "+str({ 'rounded_time':curr_time, 'len': agg_func(temp) }))
    return result


# works if @data is already sorted in key
def zero_fill(data, key="time", up_to=125):
    result = []
    prev = data[0][key]

    if(prev > 0):
        # we need to pad backward in time
        missing = prev
        for i in range(missing):
                temp = data[0].copy()
                temp = dict.fromkeys(temp, 0)
                temp[key] = i
                result.append(temp)

    result.append(data[0])
    for curr in data[1:]:
        missing = curr[key] - prev - 1
        if missing > 0:
            # not continous, zero fill
            for i in range(missing):
                temp = curr.copy()
                temp = dict.fromkeys(temp, 0)
                temp[key] = prev + i + 1
                result.append(temp)
        # nothing is missing
        result.append(curr)
        prev = curr[key]

    # zero fills for alignment
    if prev < up_to:
        missing = up_to - prev
        for i in range(missing):
            temp = data[0].copy()
            temp = dict.fromkeys(temp, 0)
            temp[key] = prev + i + 1
            result.append(temp)
    return result


def cumulative_value(data, value="len"):
    if data is None or len(data) == 0:
        print("[ ERROR ] no data given")
        return None
    result = []
    result.append(data[0])
    prev = data[0]
    for row in data[1:]:
        temp = row.copy()
        temp[value] += prev[value]
        result.append(temp)

        prev = temp

    return result


def split_into_x_y(data, key="time", value="len"):
    if data is None or len(data) == 0:
        print("[ ERROR ] no data given")
        return None
    x = []
    y = []
    for row in data:
        x.append(row[key])
        y.append(row[value])
    return (x, y)


def process_single(fields, rows, broker_num):
    src_filter = [brokers[broker_num]]
    print(brokers[broker_num])
    dst_filter = clients
    # process data
    result = my_filter(rows, src_filter, dst_filter)
    result = round_time(result)
    result = aggregate_dup(result)
    result = zero_fill(result)
    result_cumu = cumulative_value(result)
    # converts to plottable format
    rate_x, rate_y = split_into_x_y(result)
    cumu_x, cumu_y = split_into_x_y(result_cumu)
    return (rate_x, rate_y, cumu_x, cumu_y)


# returns a list of [ (rate_x, rate_y, cumu_x, cumu_y) ]  for each data of type (field, data) in @all_data
def process_all(all_data, num_brokers):
    result = []
    for i in range(num_brokers):
        fld, data = all_data[i]
        result.append(process_single(fld, data, i + 1))
    return result


def plot_single_rate(rate_x, rate_y, p_label="b1"):
    plt.plot(rate_x, rate_y, label=p_label)
    return


def plot_single_cumu(cumu_x, cumu_y):
    plt.stackplot(cumu_x, cumu_y)
    return


def plot_all_rate(all_data):
    global plot_base_name
    count = 1
    for data in all_data:
        (rate_x, rate_y, cumu_x, cumu_y) = data
        plot_single_rate(rate_x, rate_y, p_label="b{}".format(count))
        count += 1

    print(plot_base_name)
    plt.xlabel("time (second)")
    plt.ylabel("Bytes Sent (byte)")
    plt.title("{} Rate Plot".format(plot_base_name))
    plt.legend()
    return


def plot_all_cumu(all_data):
    global plot_base_name
    plt.clf()
    count = 1
    labels = []
    y_values = []
    for data in all_data:
        label = "b{}".format(count)
        labels.append(label)
        (rate_x, rate_y, cumu_x, cumu_y) = data
        y_values.append(cumu_y)
        count += 1

    plt.stackplot(cumu_x, y_values, labels=labels)

    plt.xlabel("time (second)")
    plt.ylabel("Cumulative Bytes Sent (byte)")
    plt.title("{} Cumulative Rate Plot".format(plot_base_name))
    plt.legend()
    return


def main():
    global plot_base_name, output_dir, csv_dir
    args = sys.argv
    argc = len(args)
    if argc != 4:
        print("Usage ./data_analysis <csv_folder_input_path> <image_output_path> <plot_base_name>")
        return
    csv_dir = args[1]
    output_dir = args[2]
    plot_base_name = args[3]
    print("[ INFO ]! input directory={} output={}".format(csv_dir, output_dir))
    csv_files = my_init(csv_dir)
    all_data = parse_num_csv(csv_files)
    all_plot_data = process_all(all_data, num_brokers)
    plot_all_rate(all_plot_data)
    save_plot("rate_plot")
    plot_all_cumu(all_plot_data)
    save_plot("cumu_plot")


if __name__ == "__main__":
    main()
