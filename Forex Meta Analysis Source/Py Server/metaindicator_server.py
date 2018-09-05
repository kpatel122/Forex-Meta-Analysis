from flask import Flask, render_template, request
from sentiment import Symbols,HTMLGenerator

app = Flask(__name__)

counter = 1
vals = "not set"

symb = Symbols()


def GetSummaryTableHtml():
    html =("<thead>"
            "<tr>"
            "<th>Name</th>"
            "<th>Type</th>"
            "<th>5 Minutes</th>"
            "<th>15 Minutes</th>"
            "<th>1H</th>"
            "</tr>"
            "</thead>")
    return html

@app.route('/gettablevalues')
def GetTableValues():

    header = HTMLGenerator.GetSummaryTableHeader()
    body = HTMLGenerator.GetSummaryTableBody()
    indicator_head = HTMLGenerator.GetTableIndicatorHead("EURUSD","M5")
    indicator_body = HTMLGenerator.GetTableIndicatorBody("EURUSD","M5")



    return  header+body+indicator_head+indicator_body #header + html


@app.route('/getvalues')
def values():
    return vals

@app.route('/data',methods=["POST"])
def data():
    global vals
    dict = request.form.to_dict()
    vals = ""
    symb.Read(dict)
    HTMLGenerator.Set(symb.symbol_list)
  
    return 'ok'

if __name__ == '__main__':
    app.run(port=80)
