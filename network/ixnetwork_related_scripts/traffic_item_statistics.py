#!/usr/bin/env python3


"""
Generates Item Traffic Statistics from IxNetwork's CSV file.
Writen by Aleksandr Bazhenov, October 2019.

This Source Code Form is subject to the terms of the BSD 3-Clause License
 If a copy of a source(s) was not distributed with this file, You can obtain one at:
 https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE

Usage:
    python3 graph/traffic_item_statistics.py -i "$PWD/stats_example/Traffic Item Statistics.csv" \
        -o "$PWD/" -t test_name -m 'Traffic Item Name'
"""


import argparse
from os.path import basename, isfile, join

import pandas as pd
import plotly
import plotly.graph_objs as go

# use 'True' for instant open if you run on the desktop PC
AUTO_OPEN_GRAPH = False


if __name__ == "__main__":
    args_parser = argparse.ArgumentParser()
    args_parser.add_argument(
        "-i", "--input_file", required=True, help="Path to .csv file"
    )
    args_parser.add_argument(
        "-o", "--output_dir", required=True, help="Output folder path"
    )
    args_parser.add_argument("-t", "--test_name", required=True, help="Test name")
    args_parser.add_argument(
        "-m", "--item_name", required=True, help="Traffic Item name"
    )
    settings = args_parser.parse_args()

    if (
        isfile(settings.inputfile)
        and basename(settings.inputfile) == "Traffic Item Statistics.csv"
    ):
        df = pd.read_csv(settings.inputfile)
        trace1 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df[settings.itemname + ":Loss %"],
            name="Loss (%)",
            mode="lines",
            line=dict(color="rgb(0, 51, 204)"),
        )
        trace2 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df["%s:Rx Frame Rate" % settings.itemname],
            name="Rx Rate (pps)",
            yaxis="y2",
            mode="lines",
            line=dict(color="rgb(255, 128, 0)"),
        )
        trace3 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df["%s:Rx Rate (Mbps)" % settings.itemname],
            name="Rx Rate (Mbps)",
            yaxis="y3",
            mode="markers",
            marker=dict(color="rgb(255, 128, 0)"),
        )
        trace4 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df["%s:Frames Delta" % settings.itemname],
            name="Delta",
            yaxis="y4",
            marker=dict(color="rgb(0, 153, 51)"),
        )
        trace5 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df["%s:Store-Forward Avg Latency (ns)" % settings.itemname] * 1e6,
            name="Latency (ms)",
            yaxis="y5",
            mode="markers",
            opacity=0.7,
            marker=dict(color="rgb(191, 0, 255)"),
        )

        data = [trace1, trace2, trace3, trace4, trace5]

        layout = go.Layout(
            title="<b>%s </b>%s: Loss, Rx Frame Rate, Frames Delta and Store-Forward Avg Latency"
            % (settings.testname, settings.itemname),
            width=1900,
            height=930,
            xaxis=dict(domain=[0.07, 0.96]),
            yaxis=dict(
                title="Loss (%)",
                titlefont=dict(color="#0033cc"),
                tickfont=dict(color="#0033cc"),
                position=0.07,
            ),
            yaxis2=dict(
                title="Rx Frames Rate (pps)",
                titlefont=dict(color="#ff8000"),
                tickfont=dict(color="#ff8000"),
                anchor="free",
                overlaying="y",
                side="left",
                position=0.00,
            ),
            yaxis3=dict(
                title="Rx Rate (Mbps)",
                titlefont=dict(color="#ff8000"),
                tickfont=dict(color="#ff8000"),
                anchor="free",
                overlaying="y",
                side="left",
                position=0.035,
            ),
            yaxis4=dict(
                title="Frames Delta",
                titlefont=dict(color="#00802b"),
                tickfont=dict(color="#00802b"),
                anchor="free",
                overlaying="y",
                side="right",
                position=0.96,
            ),
            yaxis5=dict(
                title="S/F Avg Latency (ms)",
                titlefont=dict(color="#cc33ff"),
                tickfont=dict(color="#cc33ff"),
                anchor="free",
                overlaying="y",
                side="right",
                position=0.995,
            ),
        )
        fig = go.Figure(data=data, layout=layout)

        plotly.offline.plot(
            fig,
            filename=join(settings.outputdir, "%s Statistics.html" % settings.itemname),
            auto_open=AUTO_OPEN_GRAPH,
        )

    else:
        print(
            "Error, wrong input data: defined path is not a file or not 'Traffic Item Statistics.csv'"
        )
