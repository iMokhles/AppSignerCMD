//
//  CommandFunction.swift
//  iOS App Signer
//
//  Created by iMokhles on 20/03/16.
//  Copyright © 2016 Daniel Radtke. All rights reserved.
//

import Foundation

class CommandFunction: NSObject {
    
    // cmd variables
    var ipaFilePath: String?
    var certName: String?
    var profileFilePath: String?
    var newBundleID: String?
    var newAppName: String?
    var outputFile: String?
    
    //MARK: Constants
    let defaults = NSUserDefaults()
    let fileManager = NSFileManager.defaultManager()
    let bundleID = "com.imokhles.appresignerCMD"//NSBundle.mainBundle().bundleIdentifier
    let arPath = "/usr/bin/ar"
    let mktempPath = "/usr/bin/mktemp"
    let tarPath = "/usr/bin/tar"
    let unzipPath = "/usr/bin/unzip"
    let zipPath = "/usr/bin/zip"
    let defaultsPath = "/usr/bin/defaults"
    let codesignPath = "/usr/bin/codesign"
    let securityPath = "/usr/bin/security"
    
    func testSigning(certificate: String, tempFolder: String )->Bool? {
        let codesignTempFile = tempFolder.stringByAppendingPathComponent("test-sign")
        
        // Copy our binary to the temp folder to use for testing.
        let path = NSProcessInfo.processInfo().arguments[0]
        if (try? fileManager.copyItemAtPath(path, toPath: codesignTempFile)) != nil {
            codeSign(codesignTempFile, certificate: certificate, entitlements: nil, before: nil, after: nil)
            
            let verificationTask = NSTask().execute(codesignPath, workingDirectory: nil, arguments: ["-v",codesignTempFile])
            try? fileManager.removeItemAtPath(codesignTempFile)
            if verificationTask.status == 0 {
                return true
            } else {
                return false
            }
        } else {

        }
        return nil
    }
    
    func createTempDirectory() -> String? {
        
        let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("XXXXXX")
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(tempDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        
        return tempDirURL.absoluteString
    }
    
    func makeTempFolder()->String?{
        let tempTask = NSTask().execute(mktempPath, workingDirectory: nil, arguments: ["-d","-t",bundleID])
        if tempTask.status != 0 {
            print(" error :(")
            return nil
        }
        return tempTask.output.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func cleanup(tempFolder: String){
        do {
            try fileManager.removeItemAtPath(tempFolder)
        } catch let error as NSError {

        }
    }
    
    func unzip(inputFile: String, outputPath: String)->AppSignerTaskOutput {
        return NSTask().execute(unzipPath, workingDirectory: nil, arguments: ["-q",inputFile,"-d",outputPath])
    }
    func zip(inputPath: String, outputFile: String)->AppSignerTaskOutput {
        return NSTask().execute(zipPath, workingDirectory: inputPath, arguments: ["-qry", outputFile, "."])
    }
    
    func getPlistKey(plist: String, keyName: String)->String? {
        let currTask = NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["read", plist, keyName])
        if currTask.status == 0 {
            return String(currTask.output.characters.dropLast())
        } else {
            return nil
        }
    }
    
    func setPlistKey(plist: String, keyName: String, value: String)->AppSignerTaskOutput {
        return NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["write", plist, keyName, value])
    }
    
    func recursiveDirectorySearch(path: String, extensions: [String], found: ((file: String) -> Void)){
        
        if let files = try? fileManager.contentsOfDirectoryAtPath(path) {
            var isDirectory: ObjCBool = true
            
            for file in files {
                let currentFile = path.stringByAppendingPathComponent(file)
                fileManager.fileExistsAtPath(currentFile, isDirectory: &isDirectory)
                if isDirectory {
                    recursiveDirectorySearch(currentFile, extensions: extensions, found: found)
                }
                if extensions.contains(file.pathExtension) {
                    found(file: currentFile)
                }
                
            }
        }
    }
    
    //MARK: Codesigning
    func codeSign(file: String, certificate: String, entitlements: String?,before:((file: String, certificate: String, entitlements: String?)->Void)?, after: ((file: String, certificate: String, entitlements: String?, codesignTask: AppSignerTaskOutput)->Void)?)->AppSignerTaskOutput{
        
        let useEntitlements: Bool = ({
            if entitlements == nil {
                return false
            } else {
                if fileManager.fileExistsAtPath(entitlements!) {
                    return true
                } else {
                    return false
                }
            }
        })()
        
        if let beforeFunc = before {
            beforeFunc(file: file, certificate: certificate, entitlements: entitlements)
        }
        var arguments = ["-vvv","-fs",certificate,"--no-strict"]
        if useEntitlements {
            arguments.append("--entitlements=\(entitlements!)")
        }
        arguments.append(file)
        let codesignTask = NSTask().execute(codesignPath, workingDirectory: nil, arguments: arguments)
        if let afterFunc = after {
            afterFunc(file: file, certificate: certificate, entitlements: entitlements, codesignTask: codesignTask)
        }
        return codesignTask
    }
    
    func signingThread(){
        
        
        //MARK: Set up variables
        
        //var ipaFilePath: String?
        //var certName: String?
        //var profileFilePath: String?
        //var newBundleID: String?
        //var newAppName: String?
        //var outputFile: String?
        
        print("File path is \(ipaFilePath!)")
        print("Profile path is \(profileFilePath!)")
        print("Cert path is \(certName!)")
        print("Out path is \(outputFile!)")
        
        print("Preparing 1");
        var warnings = 0
        print("Preparing 1A");
        let inputFile = ipaFilePath//InputFileText.stringValue
        print("Preparing 1B");
        var provisioningFile = profileFilePath//self.profileFilename
        print("Preparing 1C");
        let signingCertificate = certName//self.CodesigningCertsPopup.selectedItem?.title
        print("Preparing 1D");
        let newApplicationID = newBundleID!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        print("Preparing 1E");
        let newDisplayName = newAppName!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        print("Preparing 1F");
        let inputStartsWithHTTP = inputFile!.lowercaseString.substringToIndex(inputFile!.startIndex.advancedBy(4)) == "http"
        print("Preparing 1G");
        var eggCount: Int = 0
        var continueSigning: Bool? = nil
        
        //MARK: Sanity checks
        
        // Check if input file exists
        var inputIsDirectory: ObjCBool = false
        if !inputStartsWithHTTP && !fileManager.fileExistsAtPath(inputFile!, isDirectory: &inputIsDirectory){
            
        }
        
        print("Preparing 2");
        //MARK: Create working temp folder
        var tempFolder: String! = nil
        print("Preparing 2A");
        if let tmpFolder = createTempDirectory() {
            print("Preparing 2B");
            tempFolder = tmpFolder
        } else {
            print("Preparing 2B Error");
        }
        print("Preparing 2C");
        let workingDirectory = tempFolder.stringByAppendingPathComponent("out")
        print("Preparing 2D");
        let eggDirectory = tempFolder.stringByAppendingPathComponent("eggs")
        print("Preparing 2E");
        let payloadDirectory = workingDirectory.stringByAppendingPathComponent("Payload/")
        print("Preparing 2F");
        let entitlementsPlist = tempFolder.stringByAppendingPathComponent("entitlements.plist")
        print("Preparing 2G");
        
        print("Preparing 3");
        //MARK: Codesign Test
        
        dispatch_async(dispatch_get_main_queue(), {
            if let codesignResult = self.testSigning(signingCertificate!, tempFolder: tempFolder) {
                if codesignResult == false {
//                    let alert = NSAlert()
//                    alert.messageText = "Codesigning error"
//                    alert.addButtonWithTitle("Yes")
//                    alert.addButtonWithTitle("No")
//                    alert.informativeText = "You appear to have a error with your codesigning certificate, do you want me to try and fix the problem?"
//                    let response = alert.runModal()
//                    if response == NSAlertFirstButtonReturn {
//                        self.fixSigning(tempFolder)
//                        if self.testSigning(signingCertificate!, tempFolder: tempFolder) == false {
//                            let errorAlert = NSAlert()
//                            errorAlert.messageText = "Unable to Fix"
//                            errorAlert.addButtonWithTitle("OK")
//                            errorAlert.informativeText = "I was unable to automatically resolve your codesigning issue ☹\n\nIf you have previously trusted your certificate using Keychain, please set the Trust setting back to the system default."
//                            errorAlert.runModal()
//                            continueSigning = false
//                            return
//                        }
//                    } else {
//                        continueSigning = false
//                        return
//                    }
                }
            }
            continueSigning = true
        })
        
        print("Preparing 4");
//        while true {
//            if continueSigning != nil {
//                if continueSigning! == false {
//                    continueSigning = nil
//                    cleanup(tempFolder); return
//                }
//                break
//            }
//            usleep(100)
//        }
        
        //MARK: Create Egg Temp Directory
        do {
            try fileManager.createDirectoryAtPath(eggDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            cleanup(tempFolder); return
        }
        
        print("Preparing 5 \(inputFile!.pathExtension.lowercaseString)");
        //MARK: Process input file
        switch(inputFile!.pathExtension.lowercaseString){
        case "deb":
            //MARK: --Unpack deb
            let debPath = tempFolder.stringByAppendingPathComponent("deb")
            do {
                
                try fileManager.createDirectoryAtPath(debPath, withIntermediateDirectories: true, attributes: nil)
                try fileManager.createDirectoryAtPath(workingDirectory, withIntermediateDirectories: true, attributes: nil)
                let debTask = NSTask().execute(arPath, workingDirectory: debPath, arguments: ["-x", inputFile!])
                if debTask.status != 0 {
                    cleanup(tempFolder); return
                }
                
                var tarUnpacked = false
                for tarFormat in ["tar","tar.gz","tar.bz2","tar.lzma","tar.xz"]{
                    let dataPath = debPath.stringByAppendingPathComponent("data.\(tarFormat)")
                    if fileManager.fileExistsAtPath(dataPath){
                        
                        let tarTask = NSTask().execute(tarPath, workingDirectory: debPath, arguments: ["-xf",dataPath])
                        if tarTask.status == 0 {
                            tarUnpacked = true
                        }
                        break
                    }
                }
                if !tarUnpacked {
                    cleanup(tempFolder); return
                }
                try fileManager.moveItemAtPath(debPath.stringByAppendingPathComponent("Applications"), toPath: payloadDirectory)
                
            } catch {
                cleanup(tempFolder); return
            }
            break
            
        case "ipa":
            //MARK: --Unzip ipa
            print("unziping 6");
            do {
                try fileManager.createDirectoryAtPath(workingDirectory, withIntermediateDirectories: true, attributes: nil)
                
                let unzipTask = self.unzip(inputFile!, outputPath: workingDirectory)
                if unzipTask.status != 0 {
                    cleanup(tempFolder); return
                }
            } catch {
                cleanup(tempFolder); return
            }
            break
            
        case "app":
            //MARK: --Copy app bundle
            if !inputIsDirectory {
                cleanup(tempFolder); return
            }
            do {
                try fileManager.createDirectoryAtPath(payloadDirectory, withIntermediateDirectories: true, attributes: nil)
                try fileManager.copyItemAtPath(inputFile!, toPath: payloadDirectory.stringByAppendingPathComponent(inputFile!.lastPathComponent))
            } catch {
                cleanup(tempFolder); return
            }
            break
            
        case "xcarchive":
            //MARK: --Copy app bundle from xcarchive
            if !inputIsDirectory {
                cleanup(tempFolder); return
            }
            do {
                try fileManager.createDirectoryAtPath(workingDirectory, withIntermediateDirectories: true, attributes: nil)
                try fileManager.copyItemAtPath(inputFile!.stringByAppendingPathComponent("Products/Applications/"), toPath: payloadDirectory)
            } catch {
                cleanup(tempFolder); return
            }
            break
            
        default:
            cleanup(tempFolder); return
        }
        
        print("checking payload 7");
        if !fileManager.fileExistsAtPath(payloadDirectory){
            cleanup(tempFolder); return
        }
        
        // Loop through app bundles in payload directory
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(payloadDirectory)
            var isDirectory: ObjCBool = true
            
            for file in files {
                
                fileManager.fileExistsAtPath(payloadDirectory.stringByAppendingPathComponent(file), isDirectory: &isDirectory)
                if !isDirectory { continue }
                
                print("prepare app bundle path 8");
                //MARK: Bundle variables setup
                let appBundlePath = payloadDirectory.stringByAppendingPathComponent(file)
                print("prepare app bundle info plist 8A");
                let appBundleInfoPlist = appBundlePath.stringByAppendingPathComponent("Info.plist")
                print("prepare app bundle provisioning profile 8B");
                let appBundleProvisioningFilePath = appBundlePath.stringByAppendingPathComponent("embedded.mobileprovision")
                print("prepare app bundle provisioning profile 8C");
                let useAppBundleProfile = (provisioningFile == nil && fileManager.fileExistsAtPath(appBundleProvisioningFilePath))
                print("detel CFBundleResourceSpecification from info plist 8D");
                //MARK: Delete CFBundleResourceSpecification from Info.plist
                NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["delete",appBundleInfoPlist,"CFBundleResourceSpecification"])
//                Log.write(NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["delete",appBundleInfoPlist,"CFBundleResourceSpecification"]).output)
                print("Copy Provisioning Profile 8E");
                
                //MARK: Copy Provisioning Profile
                if provisioningFile != nil {
                    if fileManager.fileExistsAtPath(appBundleProvisioningFilePath) {
                        print("Provisioning Profile existe 8G");
                        do {
                            try fileManager.removeItemAtPath(appBundleProvisioningFilePath)
                            print("removing old Provisioning profile 8H");
                        } catch let error as NSError {
                            print("Erro 8I");
                            Log.write(error.localizedDescription)
                            cleanup(tempFolder); return
                        }
                    }
                    do {
                        try fileManager.copyItemAtPath(provisioningFile!, toPath: appBundleProvisioningFilePath)
                        print("Copy Provisioning Profile 8J ( Finish )");
                    } catch let error as NSError {
                        Log.write(error.localizedDescription)
                        cleanup(tempFolder); return
                    }
                }
                
                print("Generate entitlements.plist 9");
                
                //MARK: Generate entitlements.plist
                if provisioningFile != nil || useAppBundleProfile {
                    print("get provisioning profile 9A");
                    if let profile = ProvisioningProfile(filename: useAppBundleProfile ? appBundleProvisioningFilePath : provisioningFile!){
                        if let entitlements = profile.getEntitlementsPlist(tempFolder) {
                            print("get entitlements plist 9B");
//                            Log.write("–––––––––––––––––––––––\n\(entitlements)")
//                            Log.write("–––––––––––––––––––––––")
                            do {
                                print("save entitlements plist 9C");
                                try entitlements.writeToFile(entitlementsPlist, atomically: false, encoding: NSUTF8StringEncoding)
                            } catch let error as NSError {
                                print("Function 9C Error: \(error.localizedDescription)");
                            }
                        } else {
                            warnings++
                        }
                        if profile.appID != "*" && (newApplicationID != "" && newApplicationID != profile.appID) {
                            cleanup(tempFolder); return
                        }
                    } else {
                        warnings++
                    }
                    
                }
                
                print("Change Application ID 10");
                //MARK: Change Application ID
                if newApplicationID != "" {
                    
                    if let oldAppID = getPlistKey(appBundleInfoPlist, keyName: "CFBundleIdentifier") {
                        func changeAppexID(appexFile: String){
                            let appexPlist = appexFile.stringByAppendingPathComponent("Info.plist")
                            if let appexBundleID = getPlistKey(appexPlist, keyName: "CFBundleIdentifier"){
                                let newAppexID = "\(newApplicationID)\(appexBundleID.substringFromIndex(oldAppID.endIndex))"
                                setPlistKey(appexPlist, keyName: "CFBundleIdentifier", value: newAppexID)
                            }
                            if NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["read", appexPlist,"WKCompanionAppBundleIdentifier"]).status == 0 {
                                setPlistKey(appexPlist, keyName: "WKCompanionAppBundleIdentifier", value: newApplicationID)
                            }
                            recursiveDirectorySearch(appexFile, extensions: ["app"], found: changeAppexID)
                        }
                        recursiveDirectorySearch(appBundlePath, extensions: ["appex"], found: changeAppexID)
                    }
                    
                    let IDChangeTask = setPlistKey(appBundleInfoPlist, keyName: "CFBundleIdentifier", value: newApplicationID)
                    if IDChangeTask.status != 0 {
                        Log.write(IDChangeTask.output)
                        cleanup(tempFolder); return
                    }
                    
                    
                }
                
                print("Change Display Name 11");
                //MARK: Change Display Name
                if newDisplayName != "" {
                    let displayNameChangeTask = NSTask().execute(defaultsPath, workingDirectory: nil, arguments: ["write",appBundleInfoPlist,"CFBundleDisplayName", newDisplayName])
                    if displayNameChangeTask.status != 0 {
                        Log.write(displayNameChangeTask.output)
                        cleanup(tempFolder); return
                    }
                }
                
                print("generate signed files 12");
                func generateFileSignFunc(payloadDirectory:String, entitlementsPath: String, signingCertificate: String)->((file:String)->Void){
                    
                    
                    let useEntitlements: Bool = ({
                        if fileManager.fileExistsAtPath(entitlementsPath) {
                            return true
                        }
                        return false
                    })()
                    
                    func shortName(file: String, payloadDirectory: String)->String{
                        return file.substringFromIndex(payloadDirectory.endIndex)
                    }
                    
                    func beforeFunc(file: String, certificate: String, entitlements: String?){
                    }
                    
                    func afterFunc(file: String, certificate: String, entitlements: String?, codesignOutput: AppSignerTaskOutput){
                        if codesignOutput.status != 0 {
                            Log.write(codesignOutput.output)
                            warnings++
                        }
                    }
                    
                    func output(file:String){
                        codeSign(file, certificate: signingCertificate, entitlements: entitlementsPath, before: beforeFunc, after: afterFunc)
                    }
                    return output
                }
                
                print("Codesigning subfiles 13");
                //MARK: Codesigning - General
                let signableExtensions = ["dylib","so","0","vis","pvr","framework","appex","app"]
                
                //MARK: Codesigning - Eggs
                let eggSigningFunction = generateFileSignFunc(eggDirectory, entitlementsPath: entitlementsPlist, signingCertificate: signingCertificate!)
                func signEgg(eggFile: String){
                    eggCount++
                    
                    let currentEggPath = eggDirectory.stringByAppendingPathComponent("egg\(eggCount)")
                    let shortName = eggFile.substringFromIndex(payloadDirectory.endIndex)
                    if self.unzip(eggFile, outputPath: currentEggPath).status != 0 {
                        Log.write("Error extracting \(shortName)")
                        return
                    }
                    recursiveDirectorySearch(currentEggPath, extensions: ["egg"], found: signEgg)
                    recursiveDirectorySearch(currentEggPath, extensions: signableExtensions, found: eggSigningFunction)
                    self.zip(currentEggPath, outputFile: eggFile)
                }
                
                print("Codesigning app 14");
                recursiveDirectorySearch(appBundlePath, extensions: ["egg"], found: signEgg)
                
                //MARK: Codesigning - App
                let signingFunction = generateFileSignFunc(payloadDirectory, entitlementsPath: entitlementsPlist, signingCertificate: signingCertificate!)
                
                recursiveDirectorySearch(appBundlePath, extensions: signableExtensions, found: signingFunction)
                signingFunction(file: appBundlePath)
                
                //MARK: Codesigning - Verification
                let verificationTask = NSTask().execute(codesignPath, workingDirectory: nil, arguments: ["-v",appBundlePath])
                if verificationTask.status != 0 {
//                    let alert = NSAlert()
//                    alert.addButtonWithTitle("OK")
//                    alert.messageText = "Error verifying code signature!"
//                    alert.informativeText = verificationTask.output
//                    alert.alertStyle = .CriticalAlertStyle
//                    alert.runModal()
//                    setStatus("Error verifying code signature")
                    Log.write(verificationTask.output)
                    cleanup(tempFolder); return
                }
            }
        } catch let error as NSError {
            Log.write(error.localizedDescription)
            cleanup(tempFolder); return
        }
        
        print("Packaging... 15");
        //MARK: Packaging
        //Check if output already exists and delete if so
        if fileManager.fileExistsAtPath(outputFile!) {
            do {
                try fileManager.removeItemAtPath(outputFile!)
            } catch let error as NSError {
                Log.write(error.localizedDescription)
                cleanup(tempFolder); return
            }
        }
        let zipTask = self.zip(workingDirectory, outputFile: outputFile!)
        if zipTask.status != 0 {

        }
        print("Cleanup... 16");
        //MARK: Cleanup
        cleanup(tempFolder)
        print("Finish... 17");
    }
}