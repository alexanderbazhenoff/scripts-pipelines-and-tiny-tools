#!/usr/bin/env python3


"""
Generates Item Traffic Statistics from IxNetwork's CSV file.
Writen by Aleksandr Bazhenov, October 2019.

Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Usage:
    python3 graph/traffic_item_statistics.py \
        -i "$PWD/stats_example/Traffic Item Statistics.csv" \
        -o "$PWD/" -t test_name -m 'Traffic Item Name'
"""


import argparse
from os.path import basename, isfile, join

# pylint: disable=E0401
# pyright: reportMissingImports=false
import pandas as pd
import plotly
import plotly.graph_objs as go

# use 'True' for instant open if you run on the desktop PC
AUTO_OPEN_GRAPH = False
LAYOUT_TITLE = "Loss, Rx Frame Rate, Frames Delta and Store-Forward Avg Latency"


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
            line={"color": "rgb(0, 51, 204)"},
        )
        trace2 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df[f"{settings.itemname}:Rx Frame Rate"],
            name="Rx Rate (pps)",
            yaxis="y2",
            mode="lines",
            line={"color": "rgb(255, 128, 0)"},
        )
        trace3 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df[f"{settings.itemname}:Rx Rate (Mbps)"],
            name="Rx Rate (Mbps)",
            yaxis="y3",
            mode="markers",
            marker={"color": "rgb(255, 128, 0)"},
        )
        trace4 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df[f"{settings.itemname}:Frames Delta"],
            name="Delta",
            yaxis="y4",
            marker={"color": "rgb(0, 153, 51)"},
        )
        trace5 = go.Scatter(
            x=df["~ElapsedTime"],
            y=df[f"{settings.itemname}:Store-Forward Avg Latency (ns)"] * 1e6,
            name="Latency (ms)",
            yaxis="y5",
            mode="markers",
            opacity=0.7,
            marker={"color": "rgb(191, 0, 255)"},
        )

        data = [trace1, trace2, trace3, trace4, trace5]

        layout = go.Layout(
            title=f"<b>{settings.testname} </b>{settings.itemname}: {LAYOUT_TITLE}",
            width=1900,
            height=930,
            xaxis={"domain": [0.07, 0.96]},
            yaxis={
                "title": "Loss (%)",
                "titlefont": {"color": "#0033cc"},
                "tickfont": {"color": "#0033cc"},
                "position": 0.07,
            },
            yaxis2={
                "title": "Rx Frames Rate (pps)",
                "titlefont": {"color": "#ff8000"},
                "tickfont": {"color": "#ff8000"},
                "anchor": "free",
                "overlaying": "y",
                "side": "left",
                "position": 0.00,
            },
            yaxis3={
                "title": "Rx Rate (Mbps)",
                "titlefont": {"color": "#ff8000"},
                "tickfont": {"color": "#ff8000"},
                "anchor": "free",
                "overlaying": "y",
                "side": "left",
                "position": 0.035,
            },
            yaxis4={
                "title": "Frames Delta",
                "titlefont": {"color": "#00802b"},
                "tickfont": {"color": "#00802b"},
                "anchor": "free",
                "overlaying": "y",
                "side": "right",
                "position": 0.96,
            },
            yaxis5={
                "title": "S/F Avg Latency (ms)",
                "titlefont": {"color": "#cc33ff"},
                "tickfont": {"color": "#cc33ff"},
                "anchor": "free",
                "overlaying": "y",
                "side": "right",
                "position": 0.995,
            },
        )
        fig = go.Figure(data=data, layout=layout)

        plotly.offline.plot(
            fig,
            filename=join(settings.outputdir, f"{settings.itemname} Statistics.html"),
            auto_open=AUTO_OPEN_GRAPH,
        )

    else:
        print(
            "Error, wrong input: defined path is not a file or not 'Traffic Item Statistics.csv'"
        )
