//
//  ViewController.swift
//  swift_custom_camera
//
//  Created by Shaoting Zhou on 2017/8/11.
//  Copyright © 2017年 Shaoting Zhou. All rights reserved.
//

import UIKit
import AVFoundation

//屏幕宽高
struct kScreenWH {
    static let  width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
}

class ViewController: UIViewController,UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    var device:AVCaptureDevice!   //获取设备:如摄像头
    var input:AVCaptureDeviceInput!   //输入流
    var photoOutput:AVCaptureStillImageOutput! //输出流
    var  output:AVCaptureMetadataOutput! //当启动摄像头开始捕获输入
    var  session:AVCaptureSession!//会话,协调着intput到output的数据传输,input和output的桥梁
    var  previewLayer:AVCaptureVideoPreviewLayer! //图像预览层，实时显示捕获的图像
    
    var photoButton: UIButton?   //拍照按钮
    var imageView: UIImageView?   //拍照后的成像
    var image: UIImage?   //拍照后的成像
    var isJurisdiction: Bool?   //是否获取了拍照标示
    var flashBtn:UIButton?  //闪光灯按钮
    override func viewDidLoad() {
        super.viewDidLoad()

        isJurisdiction = canUserCamear()
        if isJurisdiction! {
            customCamera()  //自定义相机
            customUI()  //自定义相机按钮
        }
        else {
            return
        }
        
    }
    
    //MARK: 初始化自定义相机
    func customCamera(){
       guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else { return } //初始化摄像头设备
        guard let device = devices.filter({ return $0.position == .back }).first else{ return}
        self.device = device
        //输入流初始化
        self.input = try? AVCaptureDeviceInput(device: device)
        //照片输出流初始化
        self.photoOutput = AVCaptureStillImageOutput.init()
        //输出流初始化
        self.output = AVCaptureMetadataOutput.init()
        //生成会话
        self.session = AVCaptureSession.init()
        if(self.session.canSetSessionPreset("AVCaptureSessionPreset1280x720")){
            self.session.sessionPreset = "AVCaptureSessionPreset1280x720"
        }
        if(self.session.canAddInput(self.input)){
            self.session.addInput(self.input)
        }
        if(self.session.canAddOutput(self.photoOutput)){
            self.session.addOutput(self.photoOutput)
        }
        //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
        self.previewLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        self.previewLayer.frame  = CGRect.init(x: 0, y: 0, width: kScreenWH.width, height: kScreenWH.height)
        self.previewLayer.videoGravity = "AVLayerVideoGravityResizeAspectFill"
        self.view.layer.addSublayer(self.previewLayer)
        //启动
        self.session.startRunning()
        if ((try? device.lockForConfiguration()) != nil) {
            if device.isFlashModeSupported(.auto) {
                device.flashMode = .auto
            }
            //自动白平衡
            if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                device.whiteBalanceMode = .autoWhiteBalance
            }
            device.unlockForConfiguration()
        }
        
        //闪光灯
        do{ try device.lockForConfiguration() }catch{ }
        if device.hasFlash == false { return }
        device.flashMode = AVCaptureFlashMode.auto
        device.unlockForConfiguration()
        
    }
    
    // MARK: - 检查相机权限
    func canUserCamear() -> Bool {
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if authStatus == .denied {
            let alertView = UIAlertView(title: "请打开相机权限", message: "设置-隐私-相机", delegate: self, cancelButtonTitle: "确定", otherButtonTitles: "取消")
            alertView.tag = 100
            alertView.show()
            return false
        }
        else {
            return true
        }
        return true
    }
 //MARK: 添加自定义按钮等UI
    func customUI(){
       //前后摄像头切换
        let changeBtn = UIButton.init()
        changeBtn.frame = CGRect.init(x: kScreenWH.width - 50, y: 20, width: 40, height: 40)
        changeBtn.setImage(#imageLiteral(resourceName: "change"), for: .normal)
        changeBtn.addTarget(self, action: #selector(self.changeCamera), for: .touchUpInside)
        view.addSubview(changeBtn)
        
        //拍照按钮
        photoButton = UIButton(type: .custom)
        photoButton?.frame = CGRect(x: kScreenWH.width * 1 / 2.0 - 30, y: kScreenWH.height - 100, width: 60, height: 60)
        photoButton?.setImage(UIImage(named: "photograph"), for: .normal)
        photoButton?.setImage(UIImage(named: "photograph_Select"), for: .normal)
        photoButton?.addTarget(self, action: #selector(self.shutterCamera), for: .touchUpInside)
        view.addSubview(photoButton!)
        
      //闪光灯按钮
        flashBtn = UIButton.init()
        flashBtn?.frame = CGRect.init(x: 10, y: 20, width: 40, height: 40)
        flashBtn?.addTarget(self, action: #selector(self.flashAction), for: .touchUpInside)
        flashBtn?.setImage(#imageLiteral(resourceName: "flash-A"), for: .normal)
        view.addSubview(flashBtn!)
        
       //取消
        let cancelBtn = UIButton.init()
        cancelBtn.frame = CGRect.init(x: 10, y: kScreenWH.height - 100, width: 60, height: 60)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.addTarget(self, action: #selector(self.cancelActin), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
        //相册按钮
        let photoAlbumBtn  = UIButton.init()
        photoAlbumBtn.frame = CGRect.init(x: kScreenWH.width - 70, y: kScreenWH.height - 100, width: 60, height: 60)
        photoAlbumBtn.setImage(UIImage.init(named: "相册"), for: .normal)
        photoAlbumBtn.addTarget(self, action: #selector(self.photoAlbumAction), for: .touchUpInside)
        view.addSubview(photoAlbumBtn)
        
    }
    //MARK: 打开相册按钮
    func photoAlbumAction(){
        //判断设置是否支持图片库
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self
            //指定图片控制器类型
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //设置是否允许编辑
             picker.allowsEditing = false
            //弹出控制器，显示界面
            self.present(picker, animated: true, completion: {
                () -> Void in
            })
        }else{
            print("读取相册错误")
        }
    }
    //MARK:前后摄像头更改事件
    func changeCamera(){
        //获取之前的镜头
        guard var position = input?.device.position else { return }
        //获取当前应该显示的镜头
        position = position == .front ? .back : .front
        //创建新的device
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else { return }
        // 1.2.取出获取前置摄像头
        let d = devices.filter({ return $0.position == position }).first
        device = d
        //input
        guard let videoInput = try? AVCaptureDeviceInput(device: d) else { return }

        //切换
        session.beginConfiguration()
        session.removeInput(self.input!)
        session.addInput(videoInput)
        session.commitConfiguration()
        self.input = videoInput
        
    }
    //MARK:拍照按钮点击事件
    func shutterCamera(){
        let videoConnection: AVCaptureConnection? = photoOutput.connection(withMediaType: AVMediaTypeVideo)
        if videoConnection == nil {
            print("take photo failed!")
            return
        }
        photoOutput.captureStillImageAsynchronously(from: videoConnection ?? AVCaptureConnection(), completionHandler: {(_ imageDataSampleBuffer: CMSampleBuffer?, _ error: Error?) -> Void in
            if imageDataSampleBuffer == nil {
                return
            }
            let imageData: Data? = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)   //照片数据流
            self.image = UIImage(data: imageData!)
            self.session.stopRunning()
            self.imageView = UIImageView(frame: self.previewLayer.frame)
            self.view.insertSubview(self.imageView!, belowSubview: self.photoButton!)
            self.imageView?.layer.masksToBounds = true
            self.imageView?.image = self.image
            print("image size = \(NSStringFromCGSize((self.image?.size)!))")
        })
    }
    //MARK:选择图片成功后代理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            // 将图片显示给UIImageView
            self.session.stopRunning()
            self.imageView = UIImageView(frame: self.previewLayer.frame)
            self.view.insertSubview(self.imageView!, belowSubview: self.photoButton!)
            self.imageView?.layer.masksToBounds = true
            self.imageView?.image = image
        }else{
            print("pick image wrong")
        }
        // 收回图库选择界面
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: 闪光灯开关
    func flashAction(){
        try? device.lockForConfiguration()
        switch device.flashMode.rawValue {
        case 0:
            device!.flashMode = AVCaptureFlashMode.on
            flashBtn?.setImage(#imageLiteral(resourceName: "flash-on"), for: .normal)
            break
        case 1:
        device!.flashMode = AVCaptureFlashMode.auto
        flashBtn?.setImage(#imageLiteral(resourceName: "flash-A"), for: .normal)
            break
        default:
         device!.flashMode = AVCaptureFlashMode.off
            flashBtn?.setImage(#imageLiteral(resourceName: "flash-off"), for: .normal)
        }
        device.unlockForConfiguration()
        
    }
    //MARK:取消按钮
    func cancelActin(){
        self.imageView?.removeFromSuperview()
        self.session.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

