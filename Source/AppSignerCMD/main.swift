//
//  main.swift
//  AppSignerCMD
//
//  Created by iMokhles on 20/03/16.
//  Copyright © 2016 Daniel Radtke. All rights reserved.
//

import Foundation

let cli = CommandLine()

let filePath = StringOption(shortFlag: "f", longFlag: "file", required: true,
    helpMessage: "Path to the input ipa file.")

let signCertName = StringOption(shortFlag: "s", longFlag: "certName", required: true,
    helpMessage: "exmple: iPhone Developer: xxxx")

let proProfile = StringOption(shortFlag: "p", longFlag: "provisioningProfile", required: true,
    helpMessage: "Path to the mobileprovision file.")

let newBundleID = StringOption(shortFlag: "i", longFlag: "appID", required: false,
    helpMessage: "exmple: com.imokhles.xxxx")

let newAppName = StringOption(shortFlag: "n", longFlag: "appName", required: false,
    helpMessage: "exmple: iMDownloader")

let outFilePath = StringOption(shortFlag: "o", longFlag: "outfile", required: true,
    helpMessage: "Path to the output ipa file.")

let help = BoolOption(shortFlag: "h", longFlag: "help",
    helpMessage: "Prints a help message.")

let verbosity = CounterOption(shortFlag: "v", longFlag: "verbose",
    helpMessage: "Print verbose messages. Specify multiple times to increase verbosity.")

cli.addOptions(filePath, signCertName, proProfile, newBundleID, newAppName, outFilePath, help, verbosity)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

//print("File path is \(filePath.value!)")
//print("File path is \(signCertName.value!)")
//print("File path is \(proProfile.value!)")
//print("File path is \(newBundleID.value!)")
//print("File path is \(newAppName.value!)")
//print("File path is \(outFilePath.value!)")

var mainView = CommandFunction()

mainView.ipaFilePath = filePath.value!
mainView.certName = signCertName.value!
mainView.profileFilePath = proProfile.value!
mainView.newBundleID = newBundleID.value
mainView.newAppName = newAppName.value
mainView.outputFile = outFilePath.value!

mainView.signingThread()
