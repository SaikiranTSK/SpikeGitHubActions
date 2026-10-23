import argparse
import csv
from decimal import Decimal
import json
import sys
import time
import os
import asyncio
from pathlib import Path
from tokenize import Double
from unicodedata import decimal
import xml.etree.ElementTree as ElementTree
import xml.dom.minidom as Minidom
from collections import deque
from elasticsearch import Elasticsearch, helpers
import urllib3
urllib3.disable_warnings()
import re


#===========================================================Variable section start===========================================================================================
systeminfo_param = {           
            "Stm": "",
            "BayName": "",
            "Pdc": "",
            "SystemType": "",
            "Family": "",
            "FrontalStandType": "",
            "LateralStandType": "",
            "FrontalDetector": "",
            "LateralDetector": "",
            "TableType": "",
            "VideoType": "",
            "MonoplaneOrBiplane":""
            }
measurment_params = {           
            "TestName": "",
            "Name": "",
            "FeatureName": "",
            "FeatureOutcome": "",
            "NumberOfMeasurements": "",
            "NumberOfWarnings": "",
            "AverageMeasurementValue": "",
            "MinmumMeasurementValue": "",
            "MaximumMeasurementValue": "",
            "WarningLimitValue":"",
            "FailureLimitValue":"",
            "FailureAverageLimitValue":"",
            "MinimumNumberOfMeasurement":"",
            "ValueLimit":"",
            "MeasurementValue":"",
            "MeasurementOutcome":"",
            "DateAndTime": ""
            }
nightbatchlocation={
            "Path":""
            }
elkuploadingdata = []
#===========================================================Variable section End===========================================================================================
elastic_search_engine = Elasticsearch(
    [{"scheme": "http", 'host': 'nlybstqvp4vw726', 'port': 9200},
    ],
    request_timeout=60,
    max_retries=10,
    retry_on_timeout=True,
    verify_certs=False
)


def get_field_items():
    for data in elkuploadingdata:
        yield data
    

def send_data_to_es(index):
    deque(
        helpers.parallel_bulk(
            elastic_search_engine, get_field_items(), index=index
        ),
        maxlen=0,
    )
    elastic_search_engine.indices.refresh()

def read_and_send_data(indexname,location):
    if(Path(location).exists()):
        for root, dirs, files in os.walk(location):
            if root.__contains__("TestOutput"):
                measurement_file_location = root + "\measurements.xml"
                systeminfo_file_location = root + "\system-info.xml"
                if(Path(measurement_file_location).exists() and Path(systeminfo_file_location).exists()):
                    measurment_params["TestName"] = re.sub("Testing","",re.sub("FromMSI","",root.split('\\')[len(root.split('\\')) - 2].split("_")[0]))
                    #test_date = root.split('\\')[2].split("_")[1]+root.split('\\')[2].split("_")[2]
                                    
                    measurement_file = ElementTree.parse(measurement_file_location).getroot()
                    system_info_reader(systeminfo_param, systeminfo_file_location)
                    nightbatchlocation["Path"]= root
                    
                    for type_tag in measurement_file.findall('MeasurementGroup'):
                        measurment_params["Name"] = re.sub("\(.*?\)","",type_tag.find('Name').text)
                        measurment_params["FeatureName"] = type_tag.find('FeatureName').text
                        measurment_params["FeatureOutcome"] = type_tag.find('Outcome').text
                        measurment_params["NumberOfMeasurements"] = type_tag.find('NumberOfMeasurements').text
                        measurment_params["NumberOfWarnings"] = type_tag.find('NumberOfWarnings').text
                        measurment_params["AverageMeasurementValue"] = type_tag.find('AverageMeasurementValue').text
                        measurment_params["MinmumMeasurementValue"] = type_tag.find('MinimumMeasurementValue').text
                        measurment_params["MaximumMeasurementValue"] = type_tag.find('MaximumMeasurementValue').text
                        measurment_params["WarningLimitValue"] = type_tag.find('WarningAboveValue').text
                        measurment_params["FailureLimitValue"] = type_tag.find('FailureAboveValue').text
                        measurment_params["FailureAverageLimitValue"] = type_tag.find('FailureIfAverageAboveThisValue').text
                        measurment_params["MinimumNumberOfMeasurement"] = type_tag.find('MinimumNumberOfMeasurements').text
                        measurment_params["ValueLimit"] = (float( measurment_params["AverageMeasurementValue"])/float(measurment_params["FailureAverageLimitValue"]))*100
                        
                        for measurement in type_tag.findall('Measurements/Measurement'):
                            measurment_params["MeasurementValue"] = measurement.find('Value').text
                            measurment_params["MeasurementOutcome"] = measurement.find('Outcome').text
                            measurment_params["DateAndTime"] = measurement.find('DateTime').text
                            elkuploadingdata.append(measurment_params|systeminfo_param|nightbatchlocation)
                    
                    send_data_to_es(indexname)
                else:
                    raise Exception("Failed to upload the data to ELK. Possible reason is one depenent files are missing the given datalocation") 
    else: raise Exception("Give location doesn't exsist, please check and try with correct location")              
                        

def system_info_reader(systeminfo_param, systeminfo_file_location):

     f = open(systeminfo_file_location,encoding='utf-8-sig')
     source = f.read()
     docs = Minidom.parseString(source.strip())
     systemType = docs.getElementsByTagName("SystemType")
     if(systemType.length !=0):
         if(systemType[0].firstChild.data!=''): systeminfo_param["SystemType"] = str(systemType[0].firstChild.data)
         else: systeminfo_param["SystemType"] = "None"
     else: systeminfo_param["SystemType"] = "None"
     ProductFamily = docs.getElementsByTagName("ProductFamily")
     if(ProductFamily.length !=0):
         if(ProductFamily[0].firstChild.data!=''):systeminfo_param["Family"] = str(ProductFamily[0].firstChild.data)
         else: systeminfo_param["Family"] = "None"
     else: systeminfo_param["Family"] = "None"
     FrontalStandType = docs.getElementsByTagName("FrontalStandType")
     if(FrontalStandType.length !=0):
         if(FrontalStandType[0].firstChild.data!=''):systeminfo_param["FrontalStandType"]= str(FrontalStandType[0].firstChild.data)
         else: systeminfo_param["FrontalStandType"] = "None"
     else: systeminfo_param["FrontalStandType"] = "None"
     LateralStandType = docs.getElementsByTagName("LateralStandType")
     if(LateralStandType.length != 0):
         if(LateralStandType[0].firstChild.data!=''):systeminfo_param["LateralStandType"] = str(LateralStandType[0].firstChild.data)
         else: systeminfo_param["LateralStandType"] = "None"
     else: systeminfo_param["LateralStandType"] = "None"
     DetectorNameFrontal= docs.getElementsByTagName("DetectorNameFrontal")
     if(DetectorNameFrontal.length !=0):
         if(DetectorNameFrontal[0].firstChild.data!=''):systeminfo_param["FrontalDetector"] =str(DetectorNameFrontal[0].firstChild.data)
         else: systeminfo_param["FrontalDetector"] = "None"
     else: systeminfo_param["FrontalDetector"] = "None"
     DetectorNameLateral= docs.getElementsByTagName("DetectorNameLateral")
     if(DetectorNameLateral.length != 0):
         if(DetectorNameLateral[0].firstChild.data!=''):systeminfo_param["LateralDetector"]= str(DetectorNameLateral[0].firstChild.data)
         else: systeminfo_param["LateralDetector"] = "None"
     else: systeminfo_param["LateralDetector"] = "None"
     TableType = docs.getElementsByTagName("TableType")
     if(TableType.length !=0):
         if(TableType[0].firstChild.data!=''):systeminfo_param["TableType"] = str(TableType[0].firstChild.data)
         else: systeminfo_param["TableType"] = "None"
     else: systeminfo_param["TableType"] = "None"
     VideoType = docs.getElementsByTagName("VideoType")
     if(VideoType.length !=0):
         if(VideoType[0].firstChild.data!=''):systeminfo_param["VideoType"] = str(VideoType[0].firstChild.data)
         else: systeminfo_param["VideoType"] = "None"
     else: systeminfo_param["VideoType"] = "None"
     Stm = docs.getElementsByTagName("STM")
     if(Stm.length !=0):
         if(Stm[0].firstChild.data!=''):systeminfo_param["Stm"] = str(Stm[0].firstChild.data)
         else: systeminfo_param["Stm"] = "None"
     else: systeminfo_param["Stm"] = "None"
     PdcVersion = docs.getElementsByTagName("PDCVersion")
     if(PdcVersion.length !=0):
         if(PdcVersion[0].firstChild.data!=''):systeminfo_param["Pdc"] = str(PdcVersion[0].firstChild.data)
         else: systeminfo_param["Pdc"] = "None"
     else: systeminfo_param["Pdc"] = "None"
     SystemName = docs.getElementsByTagName("SystemName")
     if(SystemName.length !=0):
         if(SystemName[0].firstChild.data!=''):systeminfo_param["BayName"] = str(SystemName[0].firstChild.data)
         else: systeminfo_param["BayName"] = "None"
     else: systeminfo_param["BayName"] = "None"
     MonoOrBi = docs.getElementsByTagName("MonoplaneOrBiplane")
     if(MonoOrBi.length !=0):
         strvalue = MonoOrBi[0].firstChild.data
         if(strvalue!=''):systeminfo_param["MonoplaneOrBiplane"] = strvalue[0] + strvalue[1:].lower()
         else: systeminfo_param["MonoplaneOrBiplane"] = "None"
     else: systeminfo_param["MonoplaneOrBiplane"] = "None"



def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Parse the test results of a Jenkins job and send it to "
                    "Elasticsearch.",        
    )
    parser.add_argument("--datalocation", required=True, type=str)
    parser.add_argument("--indexname", required=True, type=str)
    return parser.parse_args()


def main():
    args = parse_arguments()
    if((args.datalocation).endswith("\\")):
        raise Exception("please provide proper end location. Give location value should not end with \\")        
    read_and_send_data(args.indexname,args.datalocation)
    
if __name__ == "__main__":
    sys.exit(main())

