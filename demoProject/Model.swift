//
//  Model.swift
//  demoProject
//
//  Created by HKBeast on 27/11/24.
//


struct JSONDataModel{
    let userID:Int
    let id :Int
    let title:String
    let body:String
}

package com.msl.openglpresenter.OpenGL.Models;

import static com.msl.openglpresenter.db.DBConstants.NO_DATA;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.util.Log;
import android.util.SizeF;

import com.msl.openglpresenter.CrashlyticsTracker;
import com.msl.openglpresenter.OpenGL.View.AnimationInfo;

import com.msl.openglpresenter.OpenGL.View.GLThreadNativeListener;
import com.msl.openglpresenter.OpenGL.View.LayerModel;
import com.msl.openglpresenter.OpenGL.View.OpenGLViewMode;
import com.msl.openglpresenter.OpenGL.View.ParentChangeInfo;
import com.msl.openglpresenter.OpenGL.View.TimelineModel;
import com.msl.openglpresenter.OpenGL.View.Utils;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;

public class SceneManager implements ModelListener, TextModelListener {
    WeakReference<Context> contextWeakReference;
    long rendererObjectPointer = -1;
    WeakReference<SceneManagerListener> sceneManagerListenerWeakReference;
    long frameNumber = 0;
    Bitmap templateThumbnail;




//    SceneManagerListener sceneManagerListener;


    int surfaceWidth;
    int surfaceHeight;
    int offsetX;
    int offsetY;
    int pageWidth = 1;
    int pageHeight = 1;
//    float ratioWidth;
//    float ratioHeight;
    int designId;

    ArrayList<float[]> savedChildDimensions = new ArrayList<>();
    ArrayList<float[]> savedChildDimensionsAsPerRoot = new ArrayList<>();
    private WeakReference<GLThreadNativeListener> glThreadNativeListenerWeakReference;
    private float progress = 0f;
    private boolean debug = false;

    public boolean isDataChanged() {
        return didDataChanged;
    }

    private  boolean didDataChanged = true;
    private  boolean refreshThumbnails = true;
    private  final Object lock = new Object();



    private float thumbNailRenderingTime = 0.0f;


   // private ArrayList<Scene> scenes = new ArrayList<>();
    Scene scene;
    int rendererBGColorRed = 0;
    int rendererBGColorGreen = 0;
    int rendererBGColorBlue = 0;
    boolean didChangeRendererBackground = true;

    // Keep a Hash Map of ids and Models
    private Map<Integer, Model> modelHashMap = new HashMap<>();
    private Map<Integer, Model> pageHashMap = new HashMap<>();

    LinkedList<Long> times = new LinkedList<Long>(){{
        add(System.nanoTime());
    }};
    private final int MAX_SIZE = 1;
    private final double NANOS = 1000000000.0;

//region Constructor
    public SceneManager(Context context, float ratioW, float ratioH) {
        if(context == null){
            throw new RuntimeException("Context Cannot Be Null");
        }
        contextWeakReference = new WeakReference<>(context);
        scene = new Scene("Main");
        setDataChanged(true);
        setRatio(ratioW, ratioH, true);
//        ratioWidth = 1;//ratioW;
//        ratioHeight = ratioH/;
    }
//endregion

    // region Actions
    public ArrayList<ModelDimensionsChangedInfo> onRatioChange(float newRatioWidth, float newRatioHeight, float previousRatioWidth, float previousRatioHeight, boolean useCurrentValues){
        boolean didSucceed = false;
        ArrayList<ModelDimensionsChangedInfo> modelChangeInfos = setRatio(newRatioWidth, newRatioHeight, useCurrentValues);
        refreshThumbnails = true;
        setDataChanged(true);
        return modelChangeInfos;
    }
    private ArrayList<ModelDimensionsChangedInfo> setRatio(float ratioW, float ratioH, boolean useCurrentValues){
        float normalizedRatioW = 1;
        float noramlizedRatioH = 1;
        ArrayList<ModelDimensionsChangedInfo> modelChangeInfos = new ArrayList<>();
        if(ratioW>ratioH){
            normalizedRatioW = 1;
            noramlizedRatioH = ratioH/ratioW;

//            scene.ratioWidth = 1;
//            scene.ratioHeight = ratioH/ratioW;
        } else {
            noramlizedRatioH = 1;
            normalizedRatioW = ratioW/ratioH;
//            scene.ratioHeight = 1;
//            scene.ratioWidth = ratioW/ratioH;
        }
        // If
        if(normalizedRatioW == scene.ratioWidth && noramlizedRatioH == scene.ratioHeight){
            // No Changes
            return modelChangeInfos;
        }
        float previousRatioWidth = scene.ratioWidth;
        float previousRatioHeight = scene.ratioHeight;

        // Change ratio
        scene.ratioWidth = normalizedRatioW;
        scene.ratioHeight = noramlizedRatioH;
        // We are going to Loop Through the first level
        for(int i = 0 ; i < scene.models.size(); i++){
            // for each page
            // Loop through the models
            for(int j = 0 ; j < scene.models.get(i).childlist.size() ; j++){


                ModelDimensionsChangedInfo modelDimensionsChangedInfo = new ModelDimensionsChangedInfo();
                modelDimensionsChangedInfo.viewId = scene.models.get(i).childlist.get(j).modelId;
                modelDimensionsChangedInfo.startCx = scene.models.get(i).childlist.get(j).x +scene.models.get(i).childlist.get(j).width/2 ;
                modelDimensionsChangedInfo.startCy = scene.models.get(i).childlist.get(j).y +scene.models.get(i).childlist.get(j).height/2 ;
                modelDimensionsChangedInfo.startWidth = scene.models.get(i).childlist.get(j).width;
                modelDimensionsChangedInfo.startHeight = scene.models.get(i).childlist.get(j).height;
                modelDimensionsChangedInfo.startRotation = scene.models.get(i).childlist.get(j).angle;
                modelDimensionsChangedInfo.startPrevAvailableWidth = scene.models.get(i).childlist.get(j).previousAvailableWidth;
                modelDimensionsChangedInfo.startPrevAvailableHeight = scene.models.get(i).childlist.get(j).previousAvailableHeight;
                double[] modelNewDim = Utils.calculateComponentPostion(scene.models.get(i).childlist.get(j).x * previousRatioWidth ,
                        scene.models.get(i).childlist.get(j).y * previousRatioHeight,
                        modelDimensionsChangedInfo.startWidth * previousRatioWidth,
                        modelDimensionsChangedInfo.startHeight * previousRatioHeight, modelDimensionsChangedInfo.startPrevAvailableWidth * previousRatioWidth,
                        modelDimensionsChangedInfo.startPrevAvailableHeight * previousRatioHeight,modelDimensionsChangedInfo.startRotation
                        ,previousRatioWidth, previousRatioHeight, scene.ratioWidth,scene.ratioHeight);
                if(useCurrentValues) {
                    // Store Previous Width Height
                    scene.models.get(i).childlist.get(j).previousAvailableWidth = scene.models.get(i).childlist.get(j).width ;
                    scene.models.get(i).childlist.get(j).previousAvailableHeight = scene.models.get(i).childlist.get(j).height ;
                }
                // Make the
                //
//                if(scene.models.get(i).childlist.get(j).previousAvailableWidth == 0
//                        || scene.models.get(i).childlist.get(j).previousAvailableHeight == 0){
//                    scene.models.get(i).childlist.get(j).previousAvailableWidth = scene.models.get(i).childlist.get(j).width;
//                    scene.models.get(i).childlist.get(j).previousAvailableHeight = scene.models.get(i).childlist.get(j).height;
//                }

                // This Models as Per Root
//                float widthAsPerRoot = previousRatioWidth * scene.models.get(i).width *
//                        scene.models.get(i).childlist.get(j).width;
//                float heightAsPerRoot = previousRatioHeight * scene.models.get(i).height *
//                        scene.models.get(i).childlist.get(j).height;
//
//                float widthAsPerRootNew = scene.ratioWidth * scene.models.get(i).width *
//                        scene.models.get(i).childlist.get(j).previousAvailableWidth ;
//                float heightAsPerRootNew =  scene.ratioHeight * scene.models.get(i).height *
//                        scene.models.get(i).childlist.get(j).previousAvailableHeight ;
//                if(useCurrentValues) {
//                    widthAsPerRootNew = scene.ratioWidth * scene.models.get(i).width *
//                            scene.models.get(i).childlist.get(j).width ;
//                    heightAsPerRootNew =  scene.ratioHeight * scene.models.get(i).height *
//                            scene.models.get(i).childlist.get(j).height ;
//                    // Change Previous to current
//                    scene.models.get(i).childlist.get(j).previousAvailableWidth = scene.models.get(i).childlist.get(j).width ;
//                    scene.models.get(i).childlist.get(j).previousAvailableHeight = scene.models.get(i).childlist.get(j).height ;
//                }
//                // Maintain Ratio
//                float newWidthAsPerRootMaintainingRatio = widthAsPerRootNew;
//                float newHeightAsPerRootMaintainingRatio = newWidthAsPerRootMaintainingRatio * heightAsPerRoot/widthAsPerRoot;
//                if(newHeightAsPerRootMaintainingRatio > heightAsPerRootNew) {
//                    newHeightAsPerRootMaintainingRatio = heightAsPerRootNew;
//                    newWidthAsPerRootMaintainingRatio = newHeightAsPerRootMaintainingRatio * widthAsPerRoot/heightAsPerRoot;
//                }
//
//
//                // Change the Model as per Parent
//                float newWidth = newWidthAsPerRootMaintainingRatio/(scene.ratioWidth * scene.models.get(i).width);
//                float newHeight = newHeightAsPerRootMaintainingRatio/(scene.ratioHeight * scene.models.get(i).height);
//                float x = scene.models.get(i).childlist.get(j).x + (scene.models.get(i).childlist.get(j).width - newWidth)/2;
//                float y = scene.models.get(i).childlist.get(j).y + (scene.models.get(i).childlist.get(j).height - newHeight)/2;
                float newWidth = (float) (modelNewDim[2]/ scene.ratioWidth);
                float newHeight = (float) (modelNewDim[3]/ scene.ratioHeight);
                float x = (float) (modelNewDim[0]/ scene.ratioWidth);
                float y = (float) (modelNewDim[1]/ scene.ratioHeight);

                scene.models.get(i).childlist.get(j).width = newWidth;
                scene.models.get(i).childlist.get(j).height = newHeight;
                scene.models.get(i).childlist.get(j).x = x;
                scene.models.get(i).childlist.get(j).y = y;


                modelDimensionsChangedInfo.endCx = scene.models.get(i).childlist.get(j).x +scene.models.get(i).childlist.get(j).width/2 ;
                modelDimensionsChangedInfo.endCy = scene.models.get(i).childlist.get(j).y +scene.models.get(i).childlist.get(j).height/2 ;
                modelDimensionsChangedInfo.endWidth = scene.models.get(i).childlist.get(j).width;
                modelDimensionsChangedInfo.endHeight = scene.models.get(i).childlist.get(j).height;
                modelDimensionsChangedInfo.endRotation = scene.models.get(i).childlist.get(j).angle;
                modelDimensionsChangedInfo.endPrevAvailableWidth = scene.models.get(i).childlist.get(j).previousAvailableWidth;
                modelDimensionsChangedInfo.endPrevAvailableHeight = scene.models.get(i).childlist.get(j).previousAvailableHeight;

                if (scene.models.get(i).childlist.get(j).getModelType() != ModelType.WATERMARK) { //no need to add watermark mode in this list
                    modelChangeInfos.add(modelDimensionsChangedInfo);
                }
            }
        }

//        if(previousRatioWidth == -1 || previousRatioHeight == -1) {
//            // this means we are not changing the Ratio - just setting it
//        } else{

//
//        // Change all Models dimensions according to the new ratio
//        for (Map.Entry<Integer, Model > model : modelHashMap.entrySet()) {
//
//            if(model.getValue().modelObjectPointer != -1) {
//                if(model.getValue() instanceof TextModel){
//                    ((TextModel) model.getValue()).contentChangeFlag = true;
//                    ((TextModel) model.getValue()).contentTextFlag = true;
//                }
//            }
//        }
//
//        setDataChanged(true);


        return modelChangeInfos;
    }
    public boolean resetAllTexts(){
        synchronized (lock) {
            // Change all Models dimensions according to the new ratio
            for (Map.Entry<Integer, Model> model : modelHashMap.entrySet()) {

                if (model.getValue().modelObjectPointer != -1) {
                    if (model.getValue() instanceof TextModel) {
                        ((TextModel) model.getValue()).contentChangeFlag = true;
                        ((TextModel) model.getValue()).contentTextFlag = true;
                    }
                }
            }

            setDataChanged(true);
        }
        return true;
    }
    public boolean removeScene(){
        if(scene.sceneObjectPointer!=-1){
                 NativeBrigde.removeScene(rendererObjectPointer, scene.sceneObjectPointer);
                 scene.setSceneObjectPointer(-1);
             }
             if(rendererObjectPointer!=-1) {
                 NativeBrigde.deinit(rendererObjectPointer);
                 rendererObjectPointer = -1;
             }
        return true;
    }

    public boolean removeAllObjectsFromScene(){
        // What if something is already locking this // IF so then it needs to be released immed
         synchronized (lock) {
             // We need to remove all models from the scene
             pageHashMap.clear();
             modelHashMap.clear();
             scene.models.clear();
             if(scene.sceneObjectPointer!=-1) {
                 boolean didSucceed = NativeBrigde.resetScene(rendererObjectPointer, scene.sceneObjectPointer);
             }
//             for (Map.Entry<Integer, Model > model : pageHashMap.entrySet()) {
//                 if(model.getValue().modelObjectPointer != -1) {
//                     boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.getValue().modelObjectPointer);
//                     model.getValue().modelObjectPointer = -1;
//                 }
//             }
//             for (Map.Entry<Integer, Model > model : modelHashMap.entrySet()) {
//                 if(model.getValue().modelObjectPointer != -1) {
//                     boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.getValue().modelObjectPointer);
//                     model.getValue().modelObjectPointer = -1;
//                 }
//             }
//
////             if(scene.sceneObjectPointer!=-1){
////                 NativeBrigde.removeScene(rendererObjectPointer, scene.sceneObjectPointer);
////                 scene.setSceneObjectPointer(-1);
////             }
//             pageHashMap.clear();
//             modelHashMap.clear();
//             scene.models.clear();
//             if(rendererObjectPointer!=-1) {
//                 NativeBrigde.deinit(rendererObjectPointer);
//                 rendererObjectPointer = -1;
//             }

             }
        return true;


    }
    public void setSceneManagerListener(SceneManagerListener sceneManagerListener) {
        //this.sceneManagerListener = sceneManagerListener;
        sceneManagerListenerWeakReference = new WeakReference<>(sceneManagerListener);
    }
    public void setGLNativeListener(GLThreadNativeListener glNativeListener) {
        //this.sceneManagerListener = sceneManagerListener;
        glThreadNativeListenerWeakReference = new WeakReference<>(glNativeListener);
    }
    public void removeScene(String sceneName){
        if(scene!=null){
            // Remove Models
            for(Model model: scene.models){
                // We only flag it to be removed
                model.removeFlag = true;

            }
            scene.removeFlag = true;
            setDataChanged(true);
        }
    }
    public boolean removeModelFromScene(int modelId){
        boolean didSucceed = false;
        if(scene!=null){
            // Remove Models
            Model model = getModel(modelId);
            if(model!=null){
                model.removeFlag = true;
                refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
            }
//            for(Model model: scene.models){
//                //if(model)
//                if( model.modelId == modelId) {
//                    model.removeFlag = true;
//                    setDataChanged(true);
//                    didSucceed = true;
//                }
//            }
        }
        return didSucceed;

    }

    public boolean removeWatermarkModelFromScene(){
        boolean didSucceed = false;
        if(scene!=null){
            // Remove Models
            for(Model model: scene.models){
                // We only flag it to be removed
                int modelChildListSize = model.childlist.size();
                if (modelChildListSize > 0 && model.childlist.get(modelChildListSize-1).getModelType() == ModelType.WATERMARK) {
                    model.childlist.get(modelChildListSize-1).removeFlag = true;
                }
            }
            refreshThumbnails = true;
            setDataChanged(true);

            didSucceed = true;
        }
        return didSucceed;

    }

    public boolean scrollPage( float deltaX){
        // We need to Update each of the Page
        if(debug) Log.i("GLESRecycler", "Scroll Page Called with delta" + deltaX);
        synchronized (lock) {
            boolean didSucceed = false;
            if (deltaX < 1 / 1000000) {
                return didSucceed;
            }
            float pageX = 0.0f - deltaX;
            // float pageX = 0.0f + (1-ratioWidth)/2 - deltaX;
//        for (Map.Entry page : pageHashMap.entrySet()) {
//        //    System.out.println("Key: "+me.getKey() + " & Value: " + me.getValue());
//          ((Model )page.getValue()).x = pageX;
//          pageX = pageX + 1.0f;
//
//        }
            for (Model model : scene.models) {

                if (!model.removeFlag) {
                    model.x = pageX;
                    pageX = pageX + 1.0f;
                }
                if(debug) Log.i("MoveModel", " Model Id" + model.modelId + " x set to " + model.x);
            }

            setDataChanged(true);
            didSucceed = true;
            return didSucceed;
        }
    }
    public boolean unScrollPages(){
        boolean didSucceed = false;
        if(debug) Log.i("GLESRecycler", "unScroll Page Called " );
        float pageX = 0.0f;
        for(Model model: scene.models){
            if( !model.removeFlag ) {
                model.x = pageX;
            }
        }
        setDataChanged(true);
        didSucceed = true;
        return didSucceed;
    }


    public boolean movePage( int pageId, float x, float y, float width, float height, float angle){
        boolean didSucceed = false;
        Model model = getPage(pageId);
        if(model!=null){
            model.x = x;
            model.y = y;
            model.width = width;
            model.height = height;
            model.angle = angle;

            setDataChanged(true);
            didSucceed = true;
        }
        return didSucceed;
    }

    public boolean setLockStatus(int modelId, boolean isLocked){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                model.setLocked(isLocked);
                didSucceed = true;
            }

            return didSucceed;
        }
    }
    public boolean setBackgroundColor(int modelId, int red, int green, int blue, int alpha){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundColor(red,green,blue,alpha);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }


    public boolean setBackgroundImage(int modelId, Bitmap bitmap , int blurPercentage, String pathOrAsset, String imageType, boolean isEncrypted , float cropX, float cropY, float cropW, float cropH
            , int imageWidth, int imageHeight){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundImage(bitmap, blurPercentage, pathOrAsset, imageType, isEncrypted, cropX, cropY, cropW, cropH);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundTileImage(int modelId, Bitmap bitmap , int blurPercentage, float tileMultiple){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundTileImage(bitmap, blurPercentage, tileMultiple);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundGradientLinear(  int modelId, int color1Red, int color1Green, int color1Blue,
                                                 int color2Red, int color2Green, int color2Blue, int gradientAngle, int blurPercent){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundGradientLinear(color1Red,color1Green, color1Blue, color2Red,color2Green,color2Blue,gradientAngle,blurPercent);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundGradientLinearAngle(int modelId, int gradientAngleInDegrees) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundGradientLinearAngle( gradientAngleInDegrees);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundGradientRadialRadius(int modelId, float gradientRadius) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundGradientRadialRadius( gradientRadius);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundGradientRadial(  int modelId, int color1Red, int color1Green, int color1Blue,
                                                 int color2Red, int color2Green, int color2Blue, float gradientRadius, int blurPercent){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundGradientRadial(color1Red,color1Green, color1Blue, color2Red,color2Green,color2Blue,gradientRadius,blurPercent);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundTileImageMultipler(int modelId , float tileMultiple){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundTileImageMultiplier(tileMultiple);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setOverlayImage(int modelId, Bitmap bitmap , int opacity){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setOverlayImage(bitmap, opacity);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setOverlayImageOpacity(int modelId, int opacity){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setOverlayImageOpacity(opacity);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean removeOverlayImage(int modelId){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).removeOverlay();
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }
    public boolean setBackgroundImageBlur(int modelId, int blurPercentage){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if(model instanceof ParentModel){
                    ((ParentModel)model).setBackgroundImageBlur(blurPercentage);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }

    public boolean setParentModelBitmap(int modelId, Bitmap bitmap){

        Model model = getModel(modelId);
        if(model!=null){
            model.setModelThumbnailBitmap(bitmap);
        }else{
            model = getPage(modelId);
            if(model!=null){
                model.setModelThumbnailBitmap(bitmap);
            }
        }

        return true;
    }
    public boolean setAnimation(int modelId, AnimationType animationType, int animationTemplateId, float animationDuration){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Get animation Details
             //   AnimationDetails animationDetails = DesignDbHelper.getInstance(contextWeakReference.get()).getAnimationDetailsForAnimationTemplateId(animationName);
//                model.setModelAnimation(animationType,animationName,animationDuration, animationDetails);
                model.setModelAnimation(contextWeakReference.get(), animationType,  animationTemplateId , animationDuration);
//                if (animationType == AnimationType.IN) {
//                    model.animationInName = animationName;
//                    model.animationInDuration = animationDuration;
//                } else if (animationType == AnimationType.OUT) {
//                    model.animationOutName = animationName;
//                    model.animationOutDuration = animationDuration;
//                } else if (animationType == AnimationType.LOOP) {
//                    model.animationLoopName = animationName;
//                    model.animationLoopDuration = animationDuration;
//                }

                setDataChanged(true);
                didSucceed = true;
            } else {

            }

            return didSucceed;
        }
    }

    public boolean setImageHue(int modelId, int hueAngle){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null  ) {
                // this means something is wrong
                return false;
            }

            if (model != null && model instanceof ImageModel) {
                didSucceed = ((ImageModel) model).setImageHue(hueAngle);
                if(didSucceed) {
                    refreshThumbnails = true;
                    setDataChanged(true);
                }
            }
            return didSucceed;
        }
    }
    public boolean setImageColorFilter(int modelId, int red, int green, int blue){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null  ) {
                // this means something is wrong
                return false;
            }

            if (model != null && model instanceof ImageModel) {
                didSucceed = ((ImageModel) model).setImageColorFilter(red, green, blue);
                if(didSucceed) {
                    refreshThumbnails = true;
                    setDataChanged(true);
                }
            }
            return didSucceed;
        }
    }
    public boolean removeImageColorFilter(int modelId){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null  ) {
                // this means something is wrong
                return false;
            }

            if (model != null && model instanceof ImageModel) {
                didSucceed = ((ImageModel) model).removeColorFilter();
                if(didSucceed) {
                    refreshThumbnails = true;
                    setDataChanged(true);
                }
            }
            return didSucceed;
        }
    }
    public boolean replaceImage(int modelId,String pathOrAsset, String imageType, boolean isEncrypted , Bitmap bitmap, float cropX, float cropY, float cropW, float cropH, int cropStyle, int fullImageWidth, int fullImageHeight){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if(model == null || model.getParent() == null){
                // this means something is wrong
                return false;
            }


            if(model != null && model instanceof ImageModel){
                ((ImageModel)model).changeContent(pathOrAsset, imageType, isEncrypted,bitmap,cropX,cropY,cropW,cropH, cropStyle);
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }

            // We need to check if the image ratio has changed
            int imageWidth = -1;
            int imageHeight = -1;
            if(bitmap!=null){
                imageWidth = (int) (bitmap.getWidth() * cropW);
                imageHeight = (int) (bitmap.getHeight() * cropH);
            } else {
                imageWidth = (int) (cropW * fullImageWidth );
                imageHeight = (int) (cropH  * fullImageHeight);
            }


            float cX = model.getX() + model.getWidth()/2;
            float cY = model.getY() + model.getHeight()/2;
            float orignalWidth = model.getWidth();
            float originalHeight = model.getHeight();
            float originalX = model.getX();
            float originalY = model.getY();

            int parentId = model.getParent().getModelId();
            float[] parentDimensions =  getModelDimensionsAsPerRoot(parentId);
            float parentWidth = parentDimensions[2];// * mRatioWidth;
            float parentHeight = parentDimensions[3] ;//* mRatioHeight;
            float parentAngle = parentDimensions[4];

            float modelWidth = orignalWidth * parentWidth;

            float modelHeight = modelWidth * imageHeight/imageWidth;
            if(modelHeight > originalHeight * parentHeight){
                modelHeight = originalHeight * parentHeight;
                modelWidth  = modelHeight * imageWidth / imageHeight;
            }
            float newWidth = modelWidth/parentWidth;
            float newHeight = modelHeight/parentHeight;
            float x = cX - newWidth/2;
            float y = cY - newHeight/2;

            // if width and height is changed
            float previousAvailableWidth = model.previousAvailableWidth;
            float previousAvailalbeHeight = model.previousAvailableHeight;
            if(newWidth!=orignalWidth || newHeight != originalHeight){
               previousAvailableWidth = newWidth;
               previousAvailalbeHeight = newHeight;
            }
            moveModel(modelId,x,y,newWidth,newHeight,model.getAngle(),previousAvailableWidth,previousAvailalbeHeight,true);
            // Inform Listeners
            if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null ){
                sceneManagerListenerWeakReference.get().onModelDimensionsChanged(modelId, originalX,
                        originalY, orignalWidth,originalHeight,model.getAngle()
                        ,model.previousAvailableWidth,model.previousAvailableHeight,x, y, newWidth, newHeight,model.getAngle(), previousAvailableWidth, previousAvailalbeHeight);
            }

            return didSucceed;
        }
    }


    public boolean addParent(int modelId, int parentModelId, int pageId,   float x ,float y , float width, float height,
                             float angle ,float previousAvailableWidth, float previousAvailableHeight, int opacity, int flipHorizontal, int flipVertical, boolean isLocked,   float startTime, float duration , int atPosition){
        synchronized (lock) {
            if(scene!=null) {
                // get the Page Model
                Model pageModel = getPage(pageId);
                if(pageModel == null){
                    return false;
                }
                Model parentModel = getModel(parentModelId);

                if(parentModel == null) {
                    parentModel = pageModel;
                }
                ParentModel parent = new ParentModel(this, modelId, parentModel,   x, y, width, height, angle,
                        previousAvailableWidth, previousAvailableHeight, opacity, flipHorizontal, flipVertical, isLocked,  startTime, duration, atPosition);
                modelHashMap.put(modelId,parent);
                // scene.addModel(parent);
                setDataChanged(true);
                return true;
            }
            return false;
        }
    }
    public boolean changeModelPosition(int modelId, int fromPosition, int toPosition){

        boolean didSucceed = false;
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model != null) {
                if (model.parent != null) {
                    Model parent = model.parent;
                    int delta = fromPosition < toPosition ? 1 : -1;
                    for (int i = fromPosition; i != toPosition; i += delta) {
                        parent.childlist.set(i, parent.childlist.get(i + delta));
                    }
                    parent.childlist.set(toPosition, model);
                    parent.didChildResequenced = true;
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }
            }
        }
        return didSucceed;
    }

    public boolean changePageSequence (int fromPosition, int toPos){
        // We need a lock
        // We need to change the x and StartTimings for each element
        synchronized (lock) {
            try {
                // Get The start X
                float startX = 0;
                for (int i = 0; i < scene.models.size(); i++) {
                    if (!scene.models.get(i).isRemoveFlag()) {
                        startX = scene.models.get(i).x;
                        break;
                    }
                }


                // get the previous page startTime and startX


                Model fromValue = scene.models.get(fromPosition);

                int delta = fromPosition < toPos ? 1 : -1;
                for (int i = fromPosition; i != toPos; i += delta) {
                    scene.models.set(i, scene.models.get(i + delta));

                }
                scene.models.set(toPos, fromValue);
                resetXValuesAndTimesForPages(startX);
                reAdjustTimings();

                //setProperXValuesAndTimesForPages(startPosition,endPosition, startX, startTime);
                scene.pageSequenceChanged = true;
                setDataChanged(true);
            }catch (Exception e){
                e.printStackTrace();
                CrashlyticsTracker.report(e, "Exception(IndexOutOfBound)");
                return false;
            }
        }

        return true;
    }
/*
    public boolean changeParentOfModelV1(int modelId, int parentId, int atNewIndex){

        synchronized (lock) {
            boolean didSucceed = false;
            // Check if Both are valid
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
                if (model == null) {
                    return didSucceed;
                }
            }
            Model parentModel = getModel(parentId);
            if (parentModel == null) {
                parentModel = getPage(parentId);
                if (parentModel == null) {
                    return didSucceed;
                }
            }

            float[] modelRootDimensions = getModelDimensionsAsPerRootV2(modelId);  // This is with Rotation Angle Cumulative

            float[] parentRootDimensions = getModelDimensionsAsPerRootV2(parentId); // This is with Rotation Angle Cumulative
            // getParentDimensionsAfterAddingChildV2(parentRootDimensions, modelRootDimensions);
            //1. Check if Parent has any childs
            if(parentModel.parent == null){
                // This is a Root Model
                float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                changeModelParent(modelId, parentId, atNewIndex);
                moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
                didSucceed = true;

            } else {
                if (parentModel.childlist.size() == 0) {
                    // Get Rotated Coordinates of Model

                    float[] parentDimWeWant = getRotatedRect(modelRootDimensions);
                    float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentDimWeWant, modelRootDimensions);
                    float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
                    moveModel(parentId, parentNewDimension[0], parentNewDimension[1], parentNewDimension[2], parentNewDimension[3], parentNewDimension[4]);
                    float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                    changeModelParent(modelId, parentId, atNewIndex);
                    moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
                    if(model.flipHorizontal != childNewDimension[5]){
                        changeFlipHorizontal(modelId);
                    }
                    if(model.flipVertical != childNewDimension[6]){
                        changeFlipVertical(modelId);
                    }
                    didSucceed = true;

                } else {

                    ArrayList<float[]> childDimensions = new ArrayList<>();
                    for (int i = 0; i < parentModel.childlist.size(); i++) {
                        // Resize each model as per the new Parent Dimensions
                        float[] childDimension = getModelDimensionsAsPerRootV2(parentModel.childlist.get(i).modelId);
                        childDimensions.add(childDimension);
//                float[] reverse = getModelDimensionsAsPerParentV2(parentId,childDimension);
                        //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
                        int j = 1;
                    }
                    float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentRootDimensions, modelRootDimensions);
                    float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
                    moveModel(parentId, parentNewDimension[0], parentNewDimension[1], parentNewDimension[2], parentNewDimension[3], parentNewDimension[4]);
                    //changeFlipHorizontal(parentId);


                    //   moveModel(parentId,150.375F/surfaceWidth , 340.25F/surfaceHeight ,453.5F/surfaceWidth ,1361F/surfaceHeight ,parentNewDimension[4]);
                    // Re Adjust everything back
                    for (int i = 0; i < parentModel.childlist.size(); i++) {
                        // Resize each model as per the new Parent Dimensions
                        float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, childDimensions.get(i));
                        if(debug) Log.i("MoveModel" , " Requesting Moving Existing Child Model " +  parentModel.childlist.get(i).modelId);
                        moveModel(parentModel.childlist.get(i).modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
                    }
                    // Add the New Model
                    float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                    if(debug) Log.i("MoveModel" , " Request to Change models Parent " +  modelId + " to " + parentId);
                    changeModelParent(modelId, parentId, atNewIndex);
                    if(debug) Log.i("MoveModel" , " Requesting Moving New Child Model " + modelId);
                    moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
                    if(model.flipHorizontal != childNewDimension[5]){
                        changeFlipHorizontal(modelId);
                    }
                    if(model.flipVertical != childNewDimension[6]){
                        changeFlipVertical(modelId);
                    }
                    setDataChanged(true);
                    didSucceed = true;
                }

            }



            // get Model as per root Dimension

            return didSucceed;
        }
    }
*/
    public ArrayList<ParentChangeInfo> changeParentOfModel(int modelId, int parentId, int atNewIndex){

        synchronized (lock) {
            boolean didSucceed = false;
            // Check if Both are valid
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
                if (model == null) {
                    return null;
                }
            }
            Model parentModel = getModel(parentId);
            if (parentModel == null) {
                parentModel = getPage(parentId);
                if (parentModel == null) {
                    return null;
                }
            }

            float[] modelRootDimensions = getModelDimensionsAsPerRootV2(modelId);  // This is with Rotation Angle Cumulative


            ArrayList<ParentChangeInfo> parentChangeInfos = new ArrayList<>();


            float[] parentRootDimensions = getModelDimensionsAsPerRootV2(parentId); // This is with Rotation Angle Cumulative
            // getParentDimensionsAfterAddingChildV2(parentRootDimensions, modelRootDimensions);

                //1. Check if Parent has any childs
                if (parentModel.parent == null) {

                    ParentChangeInfo modelDimensInfo = new ParentChangeInfo();
                    ParentChangeInfo parentDimensInfo = new ParentChangeInfo();

                    loadData(modelId, modelDimensInfo, true);
                    loadData(parentId, parentDimensInfo, true);

                    // This is a Root Model
                    float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                    changeModelParent(modelId, parentId, atNewIndex);
                    moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4],childNewDimension[2], childNewDimension[3],true);
                    changeModelStartTimeAndDuration(modelId, childNewDimension[7], childNewDimension[8]);

                    loadData(modelId, modelDimensInfo, false);
                    loadData(parentId, parentDimensInfo, false);

                    parentChangeInfos.add(modelDimensInfo);
                    parentChangeInfos.add(parentDimensInfo);

                    didSucceed = true;

                } else {

                    ParentChangeInfo[] parentChangeInfoArray = new ParentChangeInfo[parentModel.childlist.size() + 2];

                    for (int i = 0; i < parentChangeInfoArray.length - 2; i++) {
                        parentChangeInfoArray[i] = new ParentChangeInfo();

                        loadData(parentModel.childlist.get(i).getModelId(), parentChangeInfoArray[i], true);
                    }

                    parentChangeInfoArray[parentChangeInfoArray.length - 2] = new ParentChangeInfo();
                    parentChangeInfoArray[parentChangeInfoArray.length - 1] = new ParentChangeInfo();
                    loadData(modelId, parentChangeInfoArray[parentChangeInfoArray.length - 2], true);
                    loadData(parentId, parentChangeInfoArray[parentChangeInfoArray.length - 1], true);

                    didSucceed = accommodateNewChild(parentModel.parent.modelId, parentId, modelRootDimensions, parentChangeInfos);

                    if (didSucceed) {
                        if (parentModel.childlist.size() == 0) {
                            // Get Rotated Coordinates of Model
                            float[] parentDimWeWant = getRotatedRect(modelRootDimensions);
                            float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentDimWeWant, modelRootDimensions);
                            float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
                            moveModel(parentId, parentNewDimension[0], parentNewDimension[1], parentNewDimension[2], parentNewDimension[3], parentNewDimension[4],parentNewDimension[2], parentNewDimension[3],true);
                            changeModelStartTimeAndDuration(parentId, parentNewDimension[7], parentNewDimension[8]);

                            float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                            changeModelParent(modelId, parentId, atNewIndex);

                            moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
                            changeModelStartTimeAndDuration(modelId, childNewDimension[7], childNewDimension[8]);

                            if (model.flipHorizontal != childNewDimension[5]) {
                                changeFlipHorizontal(modelId);
                            }
                            if (model.flipVertical != childNewDimension[6]) {
                                changeFlipVertical(modelId);
                            }
                            didSucceed = true;

                        } else {

                            ArrayList<float[]> childDimensions = new ArrayList<>();
                            for (int i = 0; i < parentModel.childlist.size(); i++) {
                                // Resize each model as per the new Parent Dimensions
                                float[] childDimension = getModelDimensionsAsPerRootV2(parentModel.childlist.get(i).modelId);
                                childDimensions.add(childDimension);
//                float[] reverse = getModelDimensionsAsPerParentV2(parentId,childDimension);
                                //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
                                int j = 1;
                            }
                            float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentRootDimensions, modelRootDimensions);
                            float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
                            moveModel(parentId, parentNewDimension[0], parentNewDimension[1], parentNewDimension[2], parentNewDimension[3], parentNewDimension[4], parentNewDimension[2], parentNewDimension[3],true);
                            changeModelStartTimeAndDuration(parentId, parentNewDimension[7], parentNewDimension[8]);
                            //changeFlipHorizontal(parentId);


                            //   moveModel(parentId,150.375F/surfaceWidth , 340.25F/surfaceHeight ,453.5F/surfaceWidth ,1361F/surfaceHeight ,parentNewDimension[4]);
                            // Re Adjust everything back
                            for (int i = 0; i < parentModel.childlist.size(); i++) {
                                // Resize each model as per the new Parent Dimensions
                                float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, childDimensions.get(i));
                                if(debug) Log.i("MoveModel" , " Requesting Moving Existing Child Model " +  parentModel.childlist.get(i).modelId);
                                moveModel(parentModel.childlist.get(i).modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
                                changeModelStartTimeAndDuration(parentModel.childlist.get(i).modelId, childNewDimension[7], childNewDimension[8]);
                            }
                            // Add the New Model
                            float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, modelRootDimensions);
                            if(debug) Log.i("MoveModel", " Request to Change models Parent " + modelId + " to " + parentId);
                            changeModelParent(modelId, parentId, atNewIndex);
                            if(debug) Log.i("MoveModel", " Requesting Moving New Child Model " + modelId);
                            moveModel(modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
                            changeModelStartTimeAndDuration(modelId, childNewDimension[7], childNewDimension[8]);
                            if (model.flipHorizontal != childNewDimension[5]) {
                                changeFlipHorizontal(modelId);
                            }
                            if (model.flipVertical != childNewDimension[6]) {
                                changeFlipVertical(modelId);
                            }
                            setDataChanged(true);
                            didSucceed = true;
                        }

                        for (ParentChangeInfo parentChangeInfo : parentChangeInfoArray) {
                            loadData(parentChangeInfo.modelId, parentChangeInfo, false);
                            parentChangeInfos.add(parentChangeInfo);
                        }
                    }
                }


            // get Model as per root Dimension
            if (didSucceed) {
                return parentChangeInfos;
            } else {
                return null;
            }
        }
    }

    private boolean accommodateNewChild(int modelId, int childId, float[] childRootDimensions, ArrayList<ParentChangeInfo> parentChangeInfos){
        boolean didSucceed = false;

        Model parentModel = getModel(modelId);
        if (parentModel == null) {
            parentModel = getPage(modelId);
            if (parentModel == null) {
                return didSucceed;
            }
        }
        ParentChangeInfo parentDimensInfo = new ParentChangeInfo();

        if (parentModel.parent != null){
            loadData(modelId, parentDimensInfo, true);

            didSucceed = accommodateNewChild(parentModel.parent.getModelId(), modelId, childRootDimensions, parentChangeInfos);

            if (parentModel.getChildlist().size() == 0){
                return didSucceed;
            }
        } else {
            didSucceed = true;
            return didSucceed;
        }

        int startIndex =parentChangeInfos.size();

        ArrayList<float[]> childDimensions = new ArrayList<>();

        for (int i = 0; i < parentModel.childlist.size(); i++) {

            int childModelId = parentModel.childlist.get(i).modelId;

            if (childModelId != childId) {
                ParentChangeInfo info = new ParentChangeInfo();
                parentChangeInfos.add(info);
                loadData(childModelId, info, true);
            }

            // Resize each parentModel as per the new Parent Dimensions
            float[] childDimension = getModelDimensionsAsPerRootV2(childModelId);
            childDimensions.add(childDimension);
        }

        int parentId = parentModel.getModelId();
        float[] parentRootDimensions = getModelDimensionsAsPerRootV2(parentId); // This is with Rotation Angle Cumulative

        float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentRootDimensions, childRootDimensions);
        float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
        moveModel(parentId, parentNewDimension[0], parentNewDimension[1], parentNewDimension[2], parentNewDimension[3], parentNewDimension[4], parentNewDimension[2], parentNewDimension[3],true);
        changeModelStartTimeAndDuration(parentId, parentNewDimension[7], parentNewDimension[8]);

        for (int i = 0, j=0; i < parentModel.childlist.size(); i++) {
            int childModelId = parentModel.childlist.get(i).modelId;

            // Resize each parentModel as per the new Parent Dimensions
            float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, childDimensions.get(i));
            if(debug) Log.i("MoveModel" , " Requesting Moving Existing Child Model " +  childModelId);
            moveModel(childModelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
            changeModelStartTimeAndDuration(childModelId, childNewDimension[7], childNewDimension[8]);

            if (childModelId != childId) {
                loadData(childModelId, parentChangeInfos.get(startIndex + j++), false);
            }
        }

        loadData(parentId, parentDimensInfo, false);

        parentChangeInfos.add(parentDimensInfo);

        return didSucceed;
    }

    private void loadData(int modelId, ParentChangeInfo parentChangeInfo, boolean fillOldData){
        float[] modelDimens = getModelDimensions(modelId);

        int parentModelId = getParentIdOfModel(modelId);
        int modelIndex = getModelIndex(modelId);

        parentChangeInfo.modelId = modelId;

        if (fillOldData) {
            parentChangeInfo.oldParentId = parentModelId;
            parentChangeInfo.oldCenterX = modelDimens[0] + modelDimens[2] / 2;
            parentChangeInfo.oldCenterY = modelDimens[1] + modelDimens[3] / 2;
            parentChangeInfo.oldWidth = modelDimens[2];
            parentChangeInfo.oldHeight = modelDimens[3];
            parentChangeInfo.oldAngle = modelDimens[4];
            parentChangeInfo.oldStartTime = modelDimens[5];
            parentChangeInfo.oldDuration = modelDimens[6];
            parentChangeInfo.oldModelIndex = modelIndex;
            parentChangeInfo.oldPreviousAvailableWidth = modelDimens[7];
            parentChangeInfo.oldPreviousAvailableHeight = modelDimens[8];

        } else {
            parentChangeInfo.newParentId = parentModelId;
            parentChangeInfo.newCenterX = modelDimens[0] + modelDimens[2] / 2;
            parentChangeInfo.newCenterY = modelDimens[1] + modelDimens[3] / 2;
            parentChangeInfo.newWidth = modelDimens[2];
            parentChangeInfo.newHeight = modelDimens[3];
            parentChangeInfo.newAngle = modelDimens[4];
            parentChangeInfo.newStartTime = modelDimens[5];
            parentChangeInfo.newDuration = modelDimens[6];
            parentChangeInfo.newModelIndex = modelIndex;
            parentChangeInfo.newPreviousAvailableWidth = modelDimens[7];
            parentChangeInfo.newPreviousAvailableHeight = modelDimens[8];
        }
    }

    public void setViewPortOfPage(int x, int y, int width, int height){
        synchronized (lock) {
            if(offsetX!=x || offsetY!=y || pageWidth!=width || pageHeight!=height){
                offsetX = x;
                offsetY = y;
                pageWidth = width;
                pageHeight = height;
                setDataChanged(true);
                if(debug) Log.i("RKPAGE", "setViewPortOfPage" + pageWidth + " height" + pageHeight + "SceneManager template is" + getDesignId() );
            }

        }
    }

    public void setViewPortOfPage(int width, int height){
        float mGLESViewWidth = width;
        float mGLESViewHeight = (float) (width * scene.ratioHeight/scene.ratioWidth);
        if(mGLESViewHeight > height){
            // Calculate based on Height
            mGLESViewHeight = height;
            mGLESViewWidth = (float) height * scene.ratioWidth/scene.ratioHeight;
        }
        int left =(int) (width - mGLESViewWidth)/2;

        int top = (int) (height - mGLESViewHeight)/2;

        offsetX = left;
        offsetY = top;
        setViewPortOfPage(offsetX, offsetY, (int)mGLESViewWidth,(int) mGLESViewHeight);
    }
    public boolean refreshTextureView(){
        setDataChanged(true);
        return true;
    }
//    public boolean moveModelSpecificallyByUser(int modelId, float x, float y, float width, float height, float angle, boolean shouldRefreshThumbs ){
//        // This is called whenever we change and have to reflect the Thumb Refresh
//        if(debug) Log.i("RKTHUMB", "Move Model called ");
//        boolean didSucceed = false;
//        Model model = getModel(modelId);
//
//        if(model!=null){
//            // check if width and height have changed
//            float previousAvailableWidth = model.previousAvailableWidth;
//            float previousAvailableHeight = model.previousAvailableHeight;
//            if(model.width!=width || model.height!= height){
//                previousAvailableWidth = width;
//                previousAvailableHeight = height;
//            }
//                didSucceed = moveModel(model,x,y,width,height,angle,previousAvailableWidth, previousAvailableHeight,shouldRefreshThumbs);
//
//        }
//        return didSucceed;
//    }

    private boolean moveModel(Model model, float x, float y, float width, float height, float angle ,
                             float previousAvailableWidth, float previousAvailableHeight, boolean shouldRefreshThumbBitmap){
        if(debug) Log.i("RKTHUMB", "Move Model called with shouldRefreshThumbBitmap" + shouldRefreshThumbBitmap);
        boolean didSucceed = false;

        if(model!=null){
            model.x = x;
            model.y = y;
            // Check if this is a Text Model and if it is visible .. If so then turn on replace content flag
            if(model.getModelType() == ModelType.TEXT){
                if(model.isVisible && (model.width != width || model.height!=height)){
                    ((TextModel) model).contentChangeFlag = true;
                }
            }

            model.width = width;
            model.height = height;
            // Reset the Width and Height
            model.previousAvailableWidth =  previousAvailableWidth;
            model.previousAvailableHeight = previousAvailableHeight;
            model.angle = angle;
            refreshThumbnails = shouldRefreshThumbBitmap;
            setDataChanged(true);
            didSucceed = true;

        }
        return didSucceed;
    }
    public boolean moveModel(int modelId, float x, float y, float width, float height, float angle ,
                             float previousAvailableWidth, float previousAvailableHeight, boolean shouldRefreshThumbBitmap){
        if(debug) Log.i("RKTHUMB", "Move Model called with shouldRefreshThumbBitmap" + shouldRefreshThumbBitmap);
        boolean didSucceed = false;
        Model model = getModel(modelId);
        return moveModel(model,x,y,width,height,angle,previousAvailableWidth,previousAvailableHeight,shouldRefreshThumbBitmap);
    }
    public boolean setRefreshThumbs(){
        synchronized (lock) {
            refreshThumbnails = true;
        }
        return true;
    }
    public boolean refreshTextViewsInHierarchy(int modelId) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model != null) {
                if (model.getModelType() == ModelType.TEXT) {
                    ((TextModel) model).contentChangeFlag = true;
                }
                refreshTextViewsInHierarchy(model);
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    private boolean refreshTextViewsInHierarchy(Model model){
        for(int i= 0; i< model.childlist.size(); i++){
            if(model.childlist.get(i) instanceof TextModel){
                ((TextModel)model.childlist.get(i)).contentChangeFlag = true;
            }
            refreshTextViewsInHierarchy(model.childlist.get(i));
        }
        return true;
    }

    public boolean saveChildDimensionsAtBeginingOfParentRatioChange(int parentId){
        savedChildDimensions.clear();
        savedChildDimensionsAsPerRoot.clear();
        Model parentModel = getModel(parentId);
        if(parentModel == null){
            throw new RuntimeException("How is the Parent not in hashmap");
        }
        for (int i = 0; i < parentModel.childlist.size(); i++) {
            // Resize each model as per the new Parent Dimensions
            float[] childDimension = getModelDimensionsAsPerRootV2(parentModel.childlist.get(i).modelId);
            savedChildDimensionsAsPerRoot.add(childDimension);
            float[] childDimAsPerImmediateParent = new float[7];
            childDimAsPerImmediateParent[0] = parentModel.childlist.get(i).x + parentModel.childlist.get(i).width/2f;
            childDimAsPerImmediateParent[1] = parentModel.childlist.get(i).y  + parentModel.childlist.get(i).height/2f;
            childDimAsPerImmediateParent[2] = parentModel.childlist.get(i).width;
            childDimAsPerImmediateParent[3] = parentModel.childlist.get(i).height;
            childDimAsPerImmediateParent[4] = parentModel.childlist.get(i).angle;
            // Prev Available Width and Heigt
            childDimAsPerImmediateParent[5] = parentModel.childlist.get(i).previousAvailableWidth;
            childDimAsPerImmediateParent[6] = parentModel.childlist.get(i).previousAvailableHeight;

            savedChildDimensions.add(childDimAsPerImmediateParent);
//                float[] reverse = getModelDimensionsAsPerParentV2(parentId,childDimension);
            //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
            int j = 1;
        }
        return true;
    }

    public ModelDimensionsChangedInfo[] changeRatioOfParentWithoutMovingChilds(int parentId, float x, float y, float width, float height, float angle, boolean didEndAction){
        Model parentModel = getModel(parentId);
        if(parentModel == null){
            throw new RuntimeException("How is the Parent not in hashmap");
        }
        ArrayList<float[]> childDimensions = new ArrayList<>();
        for (int i = 0; i < parentModel.childlist.size(); i++) {
            // Resize each model as per the new Parent Dimensions
            float[] childDimension = getModelDimensionsAsPerRootV2(parentModel.childlist.get(i).modelId);
            childDimensions.add(childDimension);
//                float[] reverse = getModelDimensionsAsPerParentV2(parentId,childDimension);
            //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
            int j = 1;
        }
        //float[] parentNewDimensionRoot = getParentDimensionsAfterAddingChild(parentRootDimensions, modelRootDimensions);
       // float[] parentNewDimension = getModelDimensionsAsPerParentV2(parentModel.parent.getModelId(), parentNewDimensionRoot);
        moveModel(parentId, x, y, width, height, angle,width,height,true);
        //   moveModel(parentId,150.375F/surfaceWidth , 340.25F/surfaceHeight ,453.5F/surfaceWidth ,1361F/surfaceHeight ,parentNewDimension[4]);
        // Re Adjust everything back

        ModelDimensionsChangedInfo[] modelDimensionsChangedInfos = new ModelDimensionsChangedInfo[parentModel.childlist.size()];

        for (int i = 0; i < parentModel.childlist.size(); i++) {
            float[] childDimensionOriginal =  savedChildDimensions.get(i);
            // Resize each model as per the new Parent Dimensions
            float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, childDimensions.get(i));

            if(debug) Log.i("MoveModel" , " Requesting Moving Existing Child Model " +  parentModel.childlist.get(i).modelId);
            moveModel(parentModel.childlist.get(i).modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
            // Inform for UI

//            if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null && didEndAction){
//                sceneManagerListenerWeakReference.get().onModelDimensionsChanged(parentModel.childlist.get(i).modelId, childDimensionOriginal[0],
//                        childDimensionOriginal[1], childDimensionOriginal[2],childDimensionOriginal[3],childDimensionOriginal[4]
//                        ,childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
//            }

            ModelDimensionsChangedInfo dimensionsChangedInfo = new ModelDimensionsChangedInfo();
            dimensionsChangedInfo.viewId = parentModel.childlist.get(i).modelId;
            dimensionsChangedInfo.startCx = childDimensionOriginal[0];
            dimensionsChangedInfo.startCy = childDimensionOriginal[1];
            dimensionsChangedInfo.startWidth = childDimensionOriginal[2];
            dimensionsChangedInfo.startHeight = childDimensionOriginal[3];
            dimensionsChangedInfo.startRotation = childDimensionOriginal[4];
            dimensionsChangedInfo.startPrevAvailableWidth = childDimensionOriginal[5];
            dimensionsChangedInfo.startPrevAvailableHeight = childDimensionOriginal[6];
            dimensionsChangedInfo.endCx = childNewDimension[0] + childNewDimension[2]/2f;
            dimensionsChangedInfo.endCy = childNewDimension[1] + childNewDimension[3]/2f;
            dimensionsChangedInfo.endWidth = childNewDimension[2];
            dimensionsChangedInfo.endHeight = childNewDimension[3];
            dimensionsChangedInfo.endRotation = childNewDimension[4];
            dimensionsChangedInfo.endPrevAvailableWidth = childNewDimension[2]; // Same as New One
            dimensionsChangedInfo.endPrevAvailableHeight = childNewDimension[3]; // Same as new One

            modelDimensionsChangedInfos[i] = dimensionsChangedInfo;
        }
        return modelDimensionsChangedInfos;
    }

    public ModelDimensionsChangedInfo[] changeRatioOfParentNonEditing(int parentId, float x, float y, float width, float height, float angle, boolean didEndAction){
        // We need to make sure if there are any image Models their Width and Height Ratio will be changed

        Model parentModel = getModel(parentId);
        if(parentModel == null){
            throw new RuntimeException("How is the Parent not in hashmap");
        }

        moveModel(parentId, x, y, width, height, angle, width, height,true);

        // Re Adjust Childs Width and Height Ratio if they are Image Model
        ModelDimensionsChangedInfo[] modelDimensionsChangedInfos = new ModelDimensionsChangedInfo[parentModel.childlist.size()];

        for (int i = 0; i < parentModel.childlist.size(); i++) {
            if(parentModel.childlist.get(i).modelType == ModelType.IMAGE ||parentModel.childlist.get(i).modelType == ModelType.TEXT){
                // Because Parent Ratio is Changed The Child Ratio will also change
                float[] childDimensionPerRootOriginal =  savedChildDimensionsAsPerRoot.get(i);
                float[] childDimensionOriginal =  savedChildDimensions.get(i);
                // New Dimensions As Per Root
                float[] childDimensionNewDimension = getModelDimensionsAsPerRootV2(parentModel.childlist.get(i).modelId);
                float originalX = childDimensionPerRootOriginal[0];
                float originalY = childDimensionPerRootOriginal[1];
                float originalWidth = childDimensionPerRootOriginal[2];
                float originalHeight = childDimensionPerRootOriginal[3];
                float originalAngle = childDimensionPerRootOriginal[4];

                float afterChangeX = childDimensionNewDimension[0];
                float afterChangeY = childDimensionNewDimension[1];
                float afterChangeWidth = childDimensionNewDimension[2];
                float afterChangeHeight = childDimensionNewDimension[3];
                float afterChangeAngle = childDimensionNewDimension[4];

                // Now check if we are maintaining Ratio
                float newWidth = afterChangeWidth;
                float newHeight = newWidth * originalHeight/originalWidth;
                if(newHeight > afterChangeHeight){
                    newHeight = afterChangeHeight;
                    newWidth = newHeight * originalWidth/originalHeight;
                }
                float cX = originalX + originalWidth/2;
                float cY = originalY + originalHeight/2;
                float newX = cX - newWidth/2;
                float newY = cY - newHeight/2;

                float[] newDimensions = new float[5];
                newDimensions[0] = newX;
                newDimensions[1] = newY;
                newDimensions[2] = newWidth;
                newDimensions[3] = newHeight;
                newDimensions[4] = afterChangeAngle;

                float[] childNewDimension = getModelDimensionsAsPerParentV2(parentId, newDimensions);

                if(debug) Log.i("MoveModel" , " Requesting Moving Existing Child Model " +  parentModel.childlist.get(i).modelId);
                moveModel(parentModel.childlist.get(i).modelId, childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4], childNewDimension[2], childNewDimension[3],true);
                // Inform for UI
//                if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null && didEndAction){
//                    sceneManagerListenerWeakReference.get().onModelDimensionsChanged(parentModel.childlist.get(i).modelId, childDimensionOriginal[0],
//                            childDimensionOriginal[1], childDimensionOriginal[2],childDimensionOriginal[3],childDimensionOriginal[4]
//                            ,childNewDimension[0], childNewDimension[1], childNewDimension[2], childNewDimension[3], childNewDimension[4]);
//                }

                ModelDimensionsChangedInfo dimensionsChangedInfo = new ModelDimensionsChangedInfo();
                dimensionsChangedInfo.viewId = parentModel.childlist.get(i).modelId;
                dimensionsChangedInfo.startCx = childDimensionOriginal[0];
                dimensionsChangedInfo.startCy = childDimensionOriginal[1];
                dimensionsChangedInfo.startWidth = childDimensionOriginal[2];
                dimensionsChangedInfo.startHeight = childDimensionOriginal[3];
                dimensionsChangedInfo.startRotation = childDimensionOriginal[4];
                dimensionsChangedInfo.startPrevAvailableWidth = childDimensionOriginal[5];
                dimensionsChangedInfo.startPrevAvailableHeight = childDimensionOriginal[6];
                dimensionsChangedInfo.endCx = childNewDimension[0];
                dimensionsChangedInfo.endCy = childNewDimension[1];
                dimensionsChangedInfo.endWidth = childNewDimension[2];
                dimensionsChangedInfo.endHeight = childNewDimension[3];
                dimensionsChangedInfo.endRotation = childNewDimension[4];
                dimensionsChangedInfo.endPrevAvailableWidth = childNewDimension[2];
                dimensionsChangedInfo.endPrevAvailableHeight = childNewDimension[3];

                modelDimensionsChangedInfos[i] = dimensionsChangedInfo;
            }

        }

        return modelDimensionsChangedInfos;
    }

//    //
//    private boolean setDataChangedForAllChilds(Model model){
//        ArrayList<Model> childList = model.childlist;
//        if(childList.size()>0){
//        for(Model childModels: childList){
//            childModels.didParentChangeFlag = true;
//            childModels
//            setDataChangedForAllChilds()
//
//
//        }
//         return true;
//        } else{
//            return true;
//        }
//
//    }
    public boolean addImage(ModelType modelType, int modelId, int parentModelId, int pageId, String imagePath,  String imageType, boolean isEncrypted, Bitmap bitmap,
                            float cropX, float cropY, float cropWidth, float cropHeight, int cropStyle,
                            float x ,float y , float width, float height, float angle, float previousAvailableWidth, float previousAvailableHeight, int opacity, int flipHorizontal, int flipVertical,
                            boolean isLocked, float startTime, float duration, int atPosition){
        synchronized (lock) {
            if(scene!=null) {
                // Get the Page
                Model pageModel = getPage(pageId);
                if(pageModel == null){
                    return false;
                }
                Model parentModel = getModel(parentModelId);
                if(parentModel == null) {
                    parentModel = pageModel;
                }
                ImageModel image = new ImageModel(modelType, this, modelId, parentModel, imagePath, imageType, isEncrypted,
                        bitmap, x, y, width, height, angle,
                        cropX, cropY, cropWidth, cropHeight, cropStyle, previousAvailableWidth, previousAvailableHeight, opacity, flipHorizontal, flipVertical,isLocked,  startTime, duration, atPosition);
                modelHashMap.put(modelId,image);
                refreshThumbnails = true;
                setDataChanged(true);
                return true;
            }
            return false;
        }
    }
    public boolean addText(int modelId, int parentModelId, int pageId, String text, Typeface font,
                           int textColor, float lineSpacing, float letterSpacing, TextModel.TextAlignment textAlignment,
                           float shadowRadius, float shadowdx, float shadowdy, int shadowColor, int shadowOpacity , float internalWidthMargin, float internalHeightMargin,
                           float x , float y , float width, float height, float angle,
                           float previousAvailableWidth, float previousAvailableHeight, int opacity,
                           int flipHorizontal, int flipVertical, boolean isLocked,
                           float startTime, float duration , int atPosition , boolean shouldCacheBitmap){
        synchronized (lock) {
            if(scene!=null) {
                // Get the Page
                Model pageModel = getPage(pageId);
                if(pageModel == null){
                    return false;
                }
                Model parentModel = getModel(parentModelId);
                if(parentModel == null) {
                    parentModel = pageModel;
                }
                TextModel textModel = new TextModel(this, this, modelId, parentModel, text, font, textColor, lineSpacing, letterSpacing, textAlignment,
                        shadowRadius,shadowdx,shadowdy,shadowColor,shadowOpacity, internalWidthMargin, internalHeightMargin, x, y , width, height, angle,
                        previousAvailableWidth, previousAvailableHeight, opacity , flipHorizontal, flipVertical, isLocked, startTime, duration,atPosition , shouldCacheBitmap);
                modelHashMap.put(modelId,textModel);
                refreshThumbnails = true;
                setDataChanged(true);
                return true;
            }
            return false;
        }
    }
    public boolean addPage(int pageId,   float x ,float y , float width, float height, float angle,   float duration, int atPosition, boolean isForRendering ){
        synchronized (lock) {
            if(scene!=null) {
                // Check if Page already exists
                if(getPage(pageId)!=null){
                    if(debug) Log.i("SceneManager", "Page " + pageId + " already exists");
                    return false;
                }
                // Position X
                float pageX = 0;
                if(isForRendering){
                    pageX =  pageHashMap.size();
                }
                //float nextX =
                float startTime = getTotalTimeForScene();
//                ParentModel page = new ParentModel(this, pageId, null,   nextX, y, width, height, angle,
                ParentModel page = new ParentModel(this, pageId, null,   pageX, y, width, height, angle, width, height,
                        255, 0, 0 , false, startTime, duration,atPosition);
                pageHashMap.put(pageId,page);
                scene.addModel(page);
                refreshThumbnails = true;
                setDataChanged(true);
                return true;
            }
            return false;
        }
    }

    public boolean changePageDuration(int pageId, float duration){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getPage(pageId);
            if (model != null) {
                model.duration = duration;
                model.timeChangeFlag = true;

                //set time in watermark model of this page if watermark exists
                int pageChildListsize = model.childlist.size();
                if (pageChildListsize > 0 && model.childlist.get(pageChildListsize - 1).getModelType() == ModelType.WATERMARK){
                    model.childlist.get(pageChildListsize - 1).duration = duration;
                    model.childlist.get(pageChildListsize - 1).timeChangeFlag = true;
                }

                setDataChanged(true);
                didSucceed = true;
            }
            reAdjustTimings();
            return didSucceed;
        }

    }
    public boolean changeModelStartTimeAndDuration(int modelId, float startTime, float duration){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model != null) {
                model.duration = duration;
                model.startTime = startTime;
                model.timeChangeFlag = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }

    }

    public boolean removePage(int pageId){
        synchronized (lock) {
            if(scene!=null) {
                // Check if Page already exists
                if(getPage(pageId)==null){
                    if(debug) Log.i("SceneManager", "Page " + pageId + " doesnt exists");
                    return false;
                }
                // Which is the Item that is 0 that is showing

                // Remove Page Model from Scene
                int position = 0;
                for(Model model: scene.models){

                    //if(model is not removed)
                    if(!model.removeFlag){
                        if(model.modelId == pageId){
                            if(position == 0 && model.x < 0){
                                model.removeFlag = true;
                                pageHashMap.remove(pageId);

                                setDataChanged(true);
                                break;

                            }
                            else if(position > 0 && model.x < 0){
                                // pull all previous ones by 1
                                pullModelsByOne(position,false);
                                model.removeFlag = true;
                                pageHashMap.remove(pageId);
                                setDataChanged(true);
                                break;
                            }
                            else if(position > 0 && model.x > 0){
                                pullModelsByOne(position,true);
                                model.removeFlag = true;
                                pageHashMap.remove(pageId);
                                setDataChanged(true);
                                break;
                            }
                            else if(position > 0 && model.x ==0 ){
                                pullModelsByOne(position,false);
                                model.removeFlag = true;
                                pageHashMap.remove(pageId);
                                setDataChanged(true);
                                break;
                            }
                            else if(position == 0 && model.x ==0 ){
                                // The first one is Current
                                pullModelsByOne(position,true);
                                model.removeFlag = true;
                                pageHashMap.remove(pageId);
                                setDataChanged(true);
                                break;
                            }

                            else {

                                if(debug) Log.i("SceneManager","Delete cannot handle this Dont Know");
                                throw new RuntimeException("Delete Page cannot be handled");

                            }
                        }

                        position = position + 1;
                    }

                }
                reAdjustTimings();
                return true;
            }
            return false;
        }
    }
    public boolean hideText(int viewId) {
        synchronized (lock) {
            Model model = getModel(viewId);
                if (model == null) {
                    return false;
                }
                model.isVisible = false;
            model.didSetVisiblityChanged = true;
            refreshThumbnails = true;
            setDataChanged(true);
        }
        return true;
    }

    public boolean showText(int viewId) {
        synchronized (lock) {
            Model model = getModel(viewId);
            if (model == null) {
                return false;
            }
            if(model instanceof TextModel) {
                model.isVisible = true;
                model.didSetVisiblityChanged = true;
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
            }
        }
        return true;
    }

    // endregion
    //region Getters


    public float[] getModelDimensions(int modelId) {
        Model model = getModel(modelId);
        if(model==null){
            model = getPage(modelId);
        }
        float[] modelDimensions = new float[9];
        modelDimensions[0] = model.getX();
        modelDimensions[1] = model.getY();
        modelDimensions[2] = model.getWidth();
        modelDimensions[3] = model.getHeight();
        modelDimensions[4] = model.getAngle();
        modelDimensions[5] = model.getStartTime();
        modelDimensions[6] = model.getDuration();
        modelDimensions[7] = model.getPreviousAvailableWidth();
        modelDimensions[8] = model.getPreviousAvailableHeight();
        return modelDimensions;

    }

    public float[] getModelDimensionsAsPerRoot(int modelId){


            float x = 0;
            float y = 0;
            float width =  1;//pageWidth; //surfaceWidth;
            float height = 1;//pageHeight;// surfaceHeight;
            float angle = 0;

            float[] out = new float[5];
            Model model = getModel(modelId);
            if(model!=null && model.parent!=null){
                float[] parentInfo = getModelDimensionsAsPerRootV2(model.parent.modelId);
                width = model.width * parentInfo[2];
                height = model.height * parentInfo[3];
                x = model.x * parentInfo[2] + parentInfo[0];
                y = model.y * parentInfo[3] + parentInfo[1];
                // If Parent has an Angle then the X and Y needs to be rotated
                float cXParent = parentInfo[0] + parentInfo[2]/2;
                float cYParent = parentInfo[1] + parentInfo[3]/2;

                float cXChild = x + width/2;
                float cYChild = y + height/2;

                PointF rotatedCenterPoint = getRotatedPoint(new PointF(cXChild,cYChild),new PointF(cXParent, cYParent),parentInfo[4]);

                angle = model.angle + parentInfo[4];
                out[0] = rotatedCenterPoint.x - width/2;
                out[1] = rotatedCenterPoint.y - height/2;
                out[2] = width;
                out[3] = height;
                out[4] = angle;


            } else{

                out[0] = x;
                out[1] = y;
                out[2] = scene.ratioWidth;
                out[3] = scene.ratioHeight;
                out[4] = angle;

            }

            return out;

    }
    public AnimationInfo getAnimation (int modelId){
        // Check if this is a Page
        Model model = getPage(modelId);
        if(model == null ){
            // check if this is a Model
            model = getModel(modelId);
            if(model ==null){
                return null;
            }
        }
        AnimationInfo animationInfo = new AnimationInfo();
        animationInfo.animationInTemplateId =  model.animationInTemplateId;
        animationInfo.animationOutTemplateId = model.animationOutTemplateId;
        animationInfo.animationLoopTemplateId = model.animationLoopTemplateId;
        animationInfo.animationInDuration = model.animationInDuration;
        animationInfo.animationOutDuration = model.animationOutDuration;
        animationInfo.animationLoopDuration = model.animationLoopDuration;
        animationInfo.modelBitmap = model.modelThumbnailBitmap;
        return animationInfo;

    }

    public Model getModel( int id){
        return modelHashMap.get(id);
    }
    public int getParentIdOfModel(int modelId){
        int parentId = -1;
        Model model = getModel(modelId);
        if(model!=null){
            parentId =  model.parent.modelId;
        }
        return parentId;
    }
    public int getPageOfModel(int modelId){
        int pageId = -1;
        // Check Hash Map
        Model model =  getModel(modelId);
        // Check Parent
        if(model == null){
//            throw new RuntimeException("model id " + modelId + " not found");
            CrashlyticsTracker.report(new RuntimeException("model id " + modelId + " not found"), "model id " + modelId + " not found");
            return pageId;
        }
        if(model.parent == null){
            //throw  new RuntimeException("You are trying to get a Page");
            CrashlyticsTracker.report(new RuntimeException("You are trying to get a Page. ModelId : "+modelId), "You are trying to get a Page. ModelId : "+modelId);
            return pageId;
        }
        while (model.parent!=null){
            if(model.parent == null){
                // this is the Page
                pageId = model.parent.getModelId();
            } else {
                pageId = model.parent.getModelId();
                model = model.parent;

            }
        }

        return pageId;
    }

    public Model getPage( int id){
        return pageHashMap.get(id);
    }
    private void setDataChanged(boolean value){
        synchronized (lock){
            if(debug) Log.i("MoveModel" , " Data Changed " + value );
            didDataChanged = value;
        }
    }
    // Getters for Managing the Views
    public int getNumberOfPages(){
        int numberOfPages = 0;
        for (int i = 0; i < scene.models.size(); i++){
            if(!scene.models.get(i).isRemoveFlag()){
                numberOfPages = numberOfPages + 1;
            }
        }
        return numberOfPages;
    }
    public ArrayList<Model> getChildModelsForModel(int modelId){
        // get Page Model

        Model model = getModel(modelId);
        if(model == null){
            model = getPage(modelId);
            if(model == null){
                return null;
            }
        }
        return model.childlist;
//
    }
    public int getPageIdAtPosition(int position){
        synchronized (lock) {
            if (position >= scene.models.size() || position < 0) {
                return -1;
            } else {
                int positionCounter = 0;
                for (Model model : scene.models) {
                    if (!model.removeFlag) {
                        if (positionCounter == position) {
                            return model.modelId;
                        }
                        positionCounter = positionCounter + 1;
                    }

                }
            }
            return -1;
        }
    }
    public float getTimeForPagePosition(int position){
        synchronized (lock) {
            if (position >= scene.models.size() || position < 0) {
                return -1;
            } else {
                int positionCounter = 0;
                for (Model model : scene.models) {
                    if (!model.removeFlag) {
                        if (positionCounter == position) {
                            return model.startTime;
                        }
                        positionCounter = positionCounter + 1;
                    }

                }

//
            }
            return -1;
        }
    }
    public float getDurationForPageId(int pageId){



        for(Model model: scene.models){

            if( !model.removeFlag ) {
                if(model.modelId==pageId){
                    return model.duration;
                }
            }
        }
        return -1;
    }
    public float getDurationForModel(int modelId){
        Model model = getModel(modelId);
        if (model == null) {
            // Check if this is a page
            model = getPage(modelId);
            if (model == null) {
                 return -1;
            }
        }
        return model.duration;
    }
    public float getTimeForPageId(int pageId){

        float startTime = 0;

        for(Model model: scene.models){

            if( !model.removeFlag ) {
                if(model.modelId==pageId){
                    return startTime;
                } else {
                    startTime = startTime + model.duration;
                }
            }
        }
        return -1;
    }
    public int getPagePositionForTime(float time){
        // float timeCounter = 0;
        for (int i = 0; i < scene.models.size(); i++){
            if(!scene.models.get(i).isRemoveFlag()){
                if(time >= scene.models.get(i).startTime && time < scene.models.get(i).startTime +  scene.models.get(i).duration){
                    return i;
                }
            }
        }
        return -1;
    }
    public int getPagePosition(int pageId){
        // float timeCounter = 0;
        int position = 0;
        for (int i = 0; i < scene.models.size(); i++){
            if(!scene.models.get(i).removeFlag){
                if(scene.models.get(i).modelId == pageId){
                    return position;
                }
                position = position + 1;
            }

        }
        return -1;
    }
    public float getTotalTimeForScene(){
        float startTime = 0;
        for(Model model: scene.models){

            if( !model.removeFlag ) {
                startTime = startTime + model.duration;
            }
        }
        return startTime;
    }
    //endregion

    // ************ADDING SCENES AND MODELS******

    public int getSurfaceWidth() {
        return surfaceWidth;
    }

    public int getSurfaceHeight() {
        return surfaceHeight;
    }

//    public void addScene(String sceneName){
//       Scene scene = new Scene(sceneName);
//       scenes.add(scene);
//       setDataChanged(true);
//    }
//    public boolean createPage( Scene scene , int pageId,  float x , float y , float width, float height, float angle){
//        boolean didSucceed  = false;
//        // Create a New ImageModel with NULL Parent
//        ParentModel parentModel = new ParentModel(pageId,null,x,y,width,height,angle);
//    }

    //***** Parent Child



//    public void addFPS(  String objName, int x, int y){
//        if(scene!=null) {
//            FPSModel fpsModel = new FPSModel(1, objName, x, y);
//            scene.addModel(fpsModel);
//            setDataChanged(true);
//        }
//    }

//    public float[] getValuesAsPerRoot(int modelId){
//
//        return getModelDimensionsAsPerRoot(modelId);
//    }
//    private float[] getModelDimensionsAsPerParent(int parentId, float[] modelDimensionsAsPerRoot){
//        float [] parentDimensionsAsPerRoot = getModelDimensionsAsPerRoot(parentId);
//
//        float[] modelRootDimensionsWithPivot = getDimensionsAfterRotationWithPivot(modelDimensionsAsPerRoot, new PointF(parentDimensionsAsPerRoot[0] + parentDimensionsAsPerRoot[2]/2, parentDimensionsAsPerRoot[1] + parentDimensionsAsPerRoot[3]/2), -parentDimensionsAsPerRoot[4]);
////        float x = ( modelDimensionsAsPerRoot[0] -parentDimensionsAsPerRoot[0])/parentDimensionsAsPerRoot[2]; // divide by parentWidth
////        float y = ( modelDimensionsAsPerRoot[1] - parentDimensionsAsPerRoot[1] )/parentDimensionsAsPerRoot[3]; // divide by parentHeight
////        float width = modelDimensionsAsPerRoot[2]/parentDimensionsAsPerRoot[2]; // divide by parentWidth
////        float height = modelDimensionsAsPerRoot[3]/parentDimensionsAsPerRoot[3]; // divide by parentHeight
////        float angle = modelDimensionsAsPerRoot[4] - parentDimensionsAsPerRoot[4];
//        float x = ( modelRootDimensionsWithPivot[0] -parentDimensionsAsPerRoot[0])/parentDimensionsAsPerRoot[2]; // divide by parentWidth
//        float y = ( modelRootDimensionsWithPivot[1] - parentDimensionsAsPerRoot[1] )/parentDimensionsAsPerRoot[3]; // divide by parentHeight
//        float width = modelRootDimensionsWithPivot[2]/parentDimensionsAsPerRoot[2]; // divide by parentWidth
//        float height = modelRootDimensionsWithPivot[3]/parentDimensionsAsPerRoot[3]; // divide by parentHeight
//        //float angle = modelRootDimensionsWithPivot[4] - parentDimensionsAsPerRoot[4];
//        float angle = modelDimensionsAsPerRoot[4] - parentDimensionsAsPerRoot[4];
//        float [] out = new float[5];//
//        out[0] = x;
//        out[1] = y;
//        out[2] = width;
//        out[3] = height;
//        out[4] = angle;
//
//        return out;
//    }
//
//    private float[] getModelDimensionsAsPerRoot(int modelId){
//        float x = 0;
//        float y = 0;
//        float width = 1;
//        float height =1;
//        float angle = 0;
//
//        float[] out = new float[5];
//        Model model = getModel(modelId);
//        if(model!=null && model.parent!=null){
//            float[] parentInfo = getModelDimensionsAsPerRoot(model.parent.modelId);
//            width = model.width * parentInfo[2];
//            height = model.height * parentInfo[3];
//            x = model.x * parentInfo[2] + parentInfo[0];
//            y = model.y * parentInfo[3] + parentInfo[1];
//            angle = model.angle + parentInfo[4];
//            // We need to get the real Rect
////            Matrix m = new Matrix();
////// point is the point about which to rotate.
////            m.setRotate(angle, x + width/2, y+width/2);
////            RectF r = new RectF(x,y,x+width/2,y+width/2);
////            m.mapRect(r);
//
//
//            out[0] = x;
//            out[1] = y;
//            out[2] = width;
//            out[3] = height;
//            out[4] = angle;
////
////            float[] rectangleCorners = {
////                    x, y, //left, top
////                    x+width, y, //right, top
////                    x+width, y+height, //right, bottom
////                    x, y+height//left, bottom
////            };
////
////            Matrix m = new Matrix();
////// point is the point about which to rotate.
////            m.setRotate(angle, x+width/2, y+width/2);
////            m.mapPoints(rectangleCorners);
////            if(debug) Log.i("Mapped" , " Points ");
////            // We are going to find the new rec
////
////
////
////
////            float newLeft = Math.min(Math.min(rectangleCorners[0], rectangleCorners[2]),Math.min(rectangleCorners[4],rectangleCorners[6]));
////            float newRight = Math.max(Math.max(rectangleCorners[0], rectangleCorners[2]),Math.max(rectangleCorners[4],rectangleCorners[6]));
////            float newTop = Math.min(Math.min(rectangleCorners[1], rectangleCorners[3]),Math.min(rectangleCorners[5],rectangleCorners[7]));
////            float newBottom = Math.max(Math.max(rectangleCorners[1], rectangleCorners[3]),Math.max(rectangleCorners[5],rectangleCorners[7]));
////
////            out[0] = newLeft;
////            out[1] = newTop;
////            out[2] = (newRight - newLeft);
////            out[3] = (newBottom - newTop);
////            out[4] = angle;
//
//
//
//        } else{
//            out[0] = x;
//            out[1] = y;
//            out[2] = width;
//            out[3] = height;
//            out[4] = angle;
//
//        }
//
//        return out;
//    }
//    private float[] getParentDimensionsAfterAddingChildV2(float[] parentInfo, float [] modelDimensionsAsPerRoot){
//        // we are going to get the Actual Points of Parent After Rotation
//        PointF parentCenterPoint = new PointF(parentInfo[0]+parentInfo[2]/2,parentInfo[1]+parentInfo[3]/2);
//        PointF parentActualRotatedLeftTop = getRotatedPoint(new PointF(parentInfo[0],parentInfo[1]),parentCenterPoint,parentInfo[4]);
//        PointF parentActualRotatedLeftBottom = getRotatedPoint(new PointF(parentInfo[0],parentInfo[1]+parentInfo[3] ),parentCenterPoint,parentInfo[4]);
//        PointF parentActualRotatedRightTop = getRotatedPoint(new PointF(parentInfo[0]+parentInfo[2],parentInfo[1]),parentCenterPoint,parentInfo[4]);
//        PointF parentActualRotatedRightBottom = getRotatedPoint(new PointF(parentInfo[0]+parentInfo[2],parentInfo[1]+parentInfo[3]),parentCenterPoint,parentInfo[4]);
//
//        // We are going to get the Actual Points of Child After Rotation
//
//        PointF pivotPoint = new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2]/2,modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]/2);
//        PointF rotatedLeftTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
//        PointF rotatedLeftBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3] ),pivotPoint,modelDimensionsAsPerRoot[4]);
//        PointF rotatedRightTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
//        PointF rotatedRightBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]),pivotPoint,modelDimensionsAsPerRoot[4]);
//
//
//        // We rotate Parent back
//        PointF parentLeftTop = getRotatedPoint(parentActualRotatedLeftTop,parentCenterPoint,-parentInfo[4]);
//        PointF parentLeftBottom = getRotatedPoint(parentActualRotatedLeftBottom,parentCenterPoint,-parentInfo[4]);
//        PointF parentRightTop = getRotatedPoint(parentActualRotatedRightTop,parentCenterPoint,-parentInfo[4]);
//        PointF parentRightBottom = getRotatedPoint(parentActualRotatedRightBottom,parentCenterPoint,-parentInfo[4]);
//
//        // We Rotate Child Back but with Parents Rotation
//        PointF childLeftTop = getRotatedPoint(rotatedLeftTop,parentCenterPoint,-parentInfo[4]);
//        PointF childLeftBottom = getRotatedPoint(rotatedLeftBottom,parentCenterPoint,-parentInfo[4]);
//        PointF childRightTop = getRotatedPoint(rotatedRightTop,parentCenterPoint,-parentInfo[4]);
//        PointF childRightBottom = getRotatedPoint(rotatedRightBottom,parentCenterPoint,-parentInfo[4]);
//
//        // Now we are going to Rotate the Parent Back & Child Back by negative Parent
//
//        // First PIVOT and then Rotate
//        pivotPoint = parentCenterPoint;
//        PointF pivotChildLeftTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]),pivotPoint,-parentInfo[4]);
//        PointF pivotChildLeftBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3] ),pivotPoint,-parentInfo[4]);
//        PointF pivotChildRightTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]),pivotPoint,-parentInfo[4]);
//        PointF pivotChildRightBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]),pivotPoint,-parentInfo[4]);
//
//
//        float newLeft = Math.min(Math.min(pivotChildLeftTop.x, pivotChildLeftBottom.x),Math.min(pivotChildRightBottom.x,pivotChildRightTop.x));
//        float newRight = Math.max(Math.max(pivotChildLeftTop.x, pivotChildLeftBottom.x),Math.max(pivotChildRightBottom.x,pivotChildRightTop.x));
//        float newTop = Math.min(Math.min(pivotChildLeftTop.y, pivotChildLeftBottom.y),Math.min(pivotChildRightBottom.y,pivotChildRightTop.y));
//        float newBottom = Math.max(Math.max(pivotChildLeftTop.y, pivotChildLeftBottom.y),Math.max(pivotChildRightBottom.y,pivotChildRightTop.y));
//
//
//        PointF childNewCenterAfterPivot = new PointF((newRight-newLeft)/2,(newBottom-newTop)/2 );
//        PointF childLeftTop1 = getRotatedPoint(pivotChildLeftTop,childNewCenterAfterPivot,modelDimensionsAsPerRoot[4]);
//        PointF childLeftBottom1 = getRotatedPoint(pivotChildLeftBottom,childNewCenterAfterPivot,modelDimensionsAsPerRoot[4]);
//        PointF childRightTop1 = getRotatedPoint(pivotChildRightTop,childNewCenterAfterPivot,modelDimensionsAsPerRoot[4]);
//        PointF childRightBottom1 = getRotatedPoint(pivotChildRightBottom,childNewCenterAfterPivot,modelDimensionsAsPerRoot[4]);
//
//        float[] out = new float[5];
//        return out;
//
//
//
//    }


    // region Private Functions & Calculations
    private boolean resetXValuesAndTimesForPages(float startX){
        boolean didSucceed = false;

        float startTime = 0.0f;

        for(Model model: scene.models){

            if( !model.removeFlag ) {
                model.x = startX;
                startX = startX + 1.0f;
//                model.startTime = startTime;
//                startTime = startTime + model.duration;
//                model.timeChangeFlag = true;

            }
        }


        didSucceed = true;
        return didSucceed;

    }


    private boolean reAdjustTimings(){

        float startTime = 0;
        for(int i = 0; i < scene.models.size(); i++){
            Model model = scene.models.get(i);
            if( !model.removeFlag ) {
                if(model.startTime != startTime) {
                    model.timeChangeFlag = true;
                    model.startTime = startTime;
                    setDataChanged(true);
                    // Tell listener if time changed
                    if(sceneManagerListenerWeakReference!=null&&sceneManagerListenerWeakReference.get()!=null){
                        sceneManagerListenerWeakReference.get().onPageTimingChanged(model.modelId,model.startTime);
                    }
                }
                startTime = startTime + model.duration;

            }
        }
        return true;
    }

    private boolean pullModelsByOne(int reAdjustPosition , boolean greaterThanZero){

        int position = 0;
        for(int i = 0; i < scene.models.size(); i++){
            Model model = scene.models.get(i);
            if( !model.removeFlag ) {
                if(!greaterThanZero){
                    if(position < reAdjustPosition){
                        model.x = model.x+1.0f;
                        setDataChanged(true);
                    }
                } else{
                    if(position > reAdjustPosition){
                        model.x = model.x - 1.0f;
                        setDataChanged(true);
                    }
                }
                position = position + 1;
            }
        }
        return true;
    }
    private boolean changeModelParent(int modelId, int parentId , int atNewIndex){
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model != null) {
                // Check if the parent is available
                Model parentModel = getModel(parentId);
                if (parentModel == null) {
                    parentModel = getPage(parentId);
                }
                if (parentModel != null) {
                    model.setParent(parentModel, atNewIndex);
                    model.didParentChangeFlag = true;
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }
            }
            return didSucceed;
        }
    }

    private float[] getRotatedRect(float[] modelDimensionsAsPerRoot){
        PointF pivotPoint = new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2]/2,modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]/2);
        PointF rotatedLeftTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedLeftBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3] ),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedRightTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedRightBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]),pivotPoint,modelDimensionsAsPerRoot[4]);
        float newLeft = Math.min(Math.min(rotatedLeftTop.x, rotatedLeftBottom.x),Math.min(rotatedRightBottom.x,rotatedRightTop.x));
        float newRight = Math.max(Math.max(rotatedLeftTop.x, rotatedLeftBottom.x),Math.max(rotatedRightBottom.x,rotatedRightTop.x));
        float newTop = Math.min(Math.min(rotatedLeftTop.y, rotatedLeftBottom.y),Math.min(rotatedRightBottom.y,rotatedRightTop.y));
        float newBottom = Math.max(Math.max(rotatedLeftTop.y, rotatedLeftBottom.y),Math.max(rotatedRightBottom.y,rotatedRightTop.y));

        float[] out = new float[9];
        out[0] = newLeft;
        out[1] = newTop;
        out[2] = newRight - newLeft;
        out[3] = newBottom - newTop;
        out[4] = 0 ;
        out[5] = modelDimensionsAsPerRoot[5] ;
        out[6] = modelDimensionsAsPerRoot[6] ;

        out[7] = modelDimensionsAsPerRoot[7];
        out[8] = modelDimensionsAsPerRoot[8];

        return out;

    }
    private float[] getParentDimensionsAfterAddingChild(float[] parentInfo, float[] modelDimensionsAsPerRoot  ){
        // This is exactly like the getModelDimensionsAsPerParentV2 except there we modify the ParentSize to fit the New Child and send back the Parent new size
        // The Model Dimension needs to be wrt to Parent
        // if Parent has Rotation then we would need to rotate the Center Point

        // Rotate the Child as per its rotation
        PointF pivotPoint = new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2]/2,modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]/2);
        PointF rotatedLeftTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedLeftBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3] ),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedRightTop = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]),pivotPoint,modelDimensionsAsPerRoot[4]);
        PointF rotatedRightBottom = getRotatedPoint(new PointF(modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2],modelDimensionsAsPerRoot[1]+modelDimensionsAsPerRoot[3]),pivotPoint,modelDimensionsAsPerRoot[4]);

        // Now Rotate each point as per the Pivot of Parent

        pivotPoint = new PointF(parentInfo[0] + parentInfo[2]/2, parentInfo[1] + parentInfo[3]/2);

        PointF pivotedLeftTop = getRotatedPoint(rotatedLeftTop,pivotPoint,-parentInfo[4]);
        PointF pivotedLeftBottom = getRotatedPoint(rotatedLeftBottom,pivotPoint,-parentInfo[4]);
        PointF pivotedRightTop = getRotatedPoint( rotatedRightTop,pivotPoint,-parentInfo[4]);
        PointF pivotedRightBottom = getRotatedPoint(rotatedRightBottom,pivotPoint,-parentInfo[4]);

        float newLeft = Math.min(Math.min(pivotedLeftTop.x, pivotedLeftBottom.x),Math.min(pivotedRightBottom.x,pivotedRightTop.x));
        float newRight = Math.max(Math.max(pivotedLeftTop.x, pivotedLeftBottom.x),Math.max(pivotedRightBottom.x,pivotedRightTop.x));
        float newTop = Math.min(Math.min(pivotedLeftTop.y, pivotedLeftBottom.y),Math.min(pivotedRightBottom.y,pivotedRightTop.y));
        float newBottom = Math.max(Math.max(pivotedLeftTop.y, pivotedLeftBottom.y),Math.max(pivotedRightBottom.y,pivotedRightTop.y));

        // We need to see if Parent Needs any modification
        float combinedParentLeft = Math.min(newLeft, parentInfo[0]);
        float combinedParentTop = Math.min(newTop, parentInfo[1]);
        float combinedParentRight = Math.max(newRight, parentInfo[0] + parentInfo[2]);
        float combinedParentBottom = Math.max(newBottom, parentInfo[1] + parentInfo[3]);

        float newCenterX = (combinedParentLeft + combinedParentRight)/2;
        float newCenterY = (combinedParentTop + combinedParentBottom)/2;

        // We need to rotate the Center back

        PointF newCenter = getRotatedPoint(new PointF(newCenterX,newCenterY),pivotPoint,parentInfo[4]);



        float newWidth = (combinedParentRight - combinedParentLeft);
        float newHeight = (combinedParentBottom - combinedParentTop );

        float newX = newCenter.x - newWidth/2;
        float newY = newCenter.y - newHeight/2;




        float[] out = new float[9];
//        out[0] = combinedParentLeft;
//        out[1] = combinedParentTop;
//        out[2] = combinedParentRight - combinedParentLeft;
//        out[3] = combinedParentBottom - combinedParentTop;
        out[0] = newX;
        out[1] = newY;
        out[2] = newWidth;
        out[3] = newHeight;
        out[4] = parentInfo[4]; // angle we keep the same
        out[5] = parentInfo[5];
        out[6] = parentInfo[6];

        out[7] = Math.min(parentInfo[7], modelDimensionsAsPerRoot[7]);

        out[8] = Math.max( (parentInfo[7]+parentInfo[8]), (modelDimensionsAsPerRoot[7]+modelDimensionsAsPerRoot[8])) - out[7];

        return out;



//
//        float cXChild = modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2]/2;
//        float cYChild = modelDimensionsAsPerRoot[1] + modelDimensionsAsPerRoot[3]/2;
//
//        float cXParent = parentInfo[0] + parentInfo[2]/2;
//        float cYParent = parentInfo[1] + parentInfo[3]/2;
//
//        // We turn the Child Dimensions in the Opposite Direction // So we are matching how the Child will look after turning
//        PointF newCXChild = getRotatedPoint(new PointF(cXChild,cYChild), new PointF(cXParent,cYParent),-parentInfo[4]);
//
//        float newX = newCXChild.x - modelDimensionsAsPerRoot[2]/2;
//        float newY = newCXChild.y - modelDimensionsAsPerRoot[3]/2;
//        float angle = modelDimensionsAsPerRoot[4] - parentInfo[4];
//        float width = modelDimensionsAsPerRoot[2];
//        float height = modelDimensionsAsPerRoot[3];
//
//        // Now apply rotation to get the New Points
//
//        PointF pivotPoint = new PointF(newX+width/2,newY+height/2);
//        PointF rotatedLeftTop = getRotatedPoint(new PointF(newX,newY),pivotPoint,angle);
//        PointF rotatedLeftBottom = getRotatedPoint(new PointF(newX,newY+height),pivotPoint,angle);
//        PointF rotatedRightTop = getRotatedPoint(new PointF(newX+width,newY),pivotPoint,angle);
//        PointF rotatedRightBottom = getRotatedPoint(new PointF(newX+width,newY+height),pivotPoint,angle);


//        float newLeft = Math.min(Math.min(rotatedLeftTop.x, rotatedLeftBottom.x),Math.min(rotatedRightBottom.x,rotatedRightTop.x));
//        float newRight = Math.max(Math.max(rotatedLeftTop.x, rotatedLeftBottom.x),Math.max(rotatedRightBottom.x,rotatedRightTop.x));
//        float newTop = Math.min(Math.min(rotatedLeftTop.y, rotatedLeftBottom.y),Math.min(rotatedRightBottom.y,rotatedRightTop.y));
//        float newBottom = Math.max(Math.max(rotatedLeftTop.y, rotatedLeftBottom.y),Math.max(rotatedRightBottom.y,rotatedRightTop.y));
//
//        // We need to see if Parent Needs any modification
//        float combinedParentLeft = Math.min(newLeft, parentInfo[0]);
//        float combinedParentTop = Math.min(newTop, parentInfo[1]);
//        float combinedParentRight = Math.max(newRight, parentInfo[0] + parentInfo[2]);
//        float combinedParentBottom = Math.max(newBottom, parentInfo[1] + parentInfo[3]);
//
//        float[] out = new float[5];
//        out[0] = combinedParentLeft;
//        out[1] = combinedParentTop;
//        out[2] = combinedParentRight - combinedParentLeft;
//        out[3] = combinedParentBottom - combinedParentTop;
//        out[4] = parentInfo[4]; // angle we keep the same
//        return out;


    }
    private float[] getModelDimensionsAsPerParentV2(int parentId, float[] modelDimensionsAsPerRoot){
        // We calulate Everything as per ROOT
        // Then we will divide the Numbers by Parent Width and Parent Height to get as per immed parent
        float [] parentInfo = getModelDimensionsAsPerRootV2(parentId);
        float flipHorizontal = 0;
        float flipVertical = 0;

        // If Parent is Not Flipped and Child is Flipped
        //Horizontal
        if(parentInfo[5] == 0 && modelDimensionsAsPerRoot[5] == 0){
            flipHorizontal = 0;
        }else if(parentInfo[5] == 0 && modelDimensionsAsPerRoot[5] == 1){
            // then Child needs to be in flipped state
            flipHorizontal = 1;
        }
        // If Parent is already Flipped and Child is Flipped
        else if(parentInfo[5] == 1 && modelDimensionsAsPerRoot[5] == 1){
            // then Child needs to be in flipped state
            flipHorizontal = 0;
        }
        // If Parent is already Flipped and Child is Flipped
        else if(parentInfo[5] == 1 && modelDimensionsAsPerRoot[5] == 0){
            // then Child needs to be in flipped state
            flipHorizontal = 1;
        }
        // Vertical
        if(parentInfo[6] == 0 && modelDimensionsAsPerRoot[6] == 0){
            flipVertical = 0;
        }else if(parentInfo[6] == 0 && modelDimensionsAsPerRoot[6] == 1){
            // then Child needs to be in flipped state
            flipVertical = 1;
        }
        // If Parent is already Flipped and Child is Flipped
        else if(parentInfo[6] == 1 && modelDimensionsAsPerRoot[6] == 1){
            // then Child needs to be in flipped state
            flipVertical = 0;
        }
        // If Parent is already Flipped and Child is Flipped
        else if(parentInfo[6] == 1 && modelDimensionsAsPerRoot[6] == 0){
            // then Child needs to be in flipped state
            flipVertical = 1;
        }

        // The Model Dimension needs to be wrt to Parent
        // if Parent has Rotation then we would need to rotate the Center Point
        float cXChild = modelDimensionsAsPerRoot[0]+modelDimensionsAsPerRoot[2]/2;
        float cYChild = modelDimensionsAsPerRoot[1] + modelDimensionsAsPerRoot[3]/2;

        float cXParent = parentInfo[0] + parentInfo[2]/2;
        float cYParent = parentInfo[1] + parentInfo[3]/2;

        // We turn the Child Dimensions in the Opposite Direction // So we are matching how the Child will look after turning
        PointF newCXChild = getRotatedPoint(new PointF(cXChild,cYChild), new PointF(cXParent,cYParent),-parentInfo[4]);

        float newX = newCXChild.x - modelDimensionsAsPerRoot[2]/2;
        float newY = newCXChild.y - modelDimensionsAsPerRoot[3]/2;

        float x = (newX - parentInfo[0])/parentInfo[2]; // This is the total Shift in Root Dimension
        float y = (newY - parentInfo[1])/parentInfo[3]; // In Y direction
        float width = modelDimensionsAsPerRoot[2]/parentInfo[2];
        float height = modelDimensionsAsPerRoot[3]/parentInfo[3];
        // Angle
        float angle = modelDimensionsAsPerRoot[4] - parentInfo[4];
        // If Parent is Flipped
        if(parentInfo[5] == 1){
            float rightPoint = x + width;
            x=1-rightPoint;
            angle = - angle;
        }
        if(parentInfo[6] == 1){
            float bottomPoint = y + height;
            y = 1-bottomPoint;
            angle = - angle;
        }

        float [] out = new float[9];//

        out[0] = x;
        out[1] = y;
        out[2] = width;
        out[3] = height;
        out[4] = angle;
        out[5] = flipHorizontal;
        out[6] = flipVertical;

        out[7] = modelDimensionsAsPerRoot[7] - parentInfo[7];
        out[8] = modelDimensionsAsPerRoot[8];
        // 0f, 0.5f, 1f, 0.5f, 0, 0f, 5f);

        return out;
    }

    private float[] getModelDimensionsAsPerRootV2(int modelId){
        float x = 0;
        float y = 0;
        float width =   scene.ratioWidth;//pageWidth;//1; // //surfaceWidth;
        float height =  scene.ratioHeight;// pageHeight;//1 surfaceHeight;
        float angle = 0;
        float flipHorizontal = 0;
        float flipVertical = 0;

        float[] out = new float[9];
        Model model = getModel(modelId);
        if(model!=null && model.parent!=null){
            float[] parentInfo = getModelDimensionsAsPerRootV2(model.parent.modelId);
            width = model.width * parentInfo[2];
            height = model.height * parentInfo[3];
            x = model.x * parentInfo[2] + parentInfo[0];
            y = model.y * parentInfo[3] + parentInfo[1];
            float tempAngle = model.angle;
            flipHorizontal = (int) parentInfo[5];
            flipVertical = (int) parentInfo[6];

            if(flipHorizontal == 1){
                // the Right point
                float rightPoint = (model.x * parentInfo[2]) + (model.width * parentInfo[2]);
                float centerXOfParent = parentInfo[2] /2;
                // new X will be mirrored from center
                float flippedX = centerXOfParent - (rightPoint-centerXOfParent);
                x = flippedX + parentInfo[0];
                tempAngle = -tempAngle;

            }
            if(flipVertical == 1){
                // the Bottom point
                float bottomPoint = model.y * parentInfo[3] + model.height * parentInfo[3] ;
                float centerYOfParent = parentInfo[3] /2;
                // new Y will be mirrored from center
                float flippedY = centerYOfParent- (bottomPoint-centerYOfParent);
                y = flippedY + parentInfo[1];
                tempAngle = -tempAngle;
            }

            // If Parent has an Angle then the X and Y needs to be rotated
            float cXParent = parentInfo[0] + parentInfo[2]/2;
            float cYParent = parentInfo[1] + parentInfo[3]/2;

            float cXChild = x + width/2;
            float cYChild = y + height/2;

            PointF rotatedCenterPoint = getRotatedPoint(new PointF(cXChild,cYChild),new PointF(cXParent, cYParent),parentInfo[4]);

            angle = tempAngle + parentInfo[4];
            out[0] = rotatedCenterPoint.x - width/2;
            out[1] = rotatedCenterPoint.y - height/2;
            out[2] = width;
            out[3] = height;
            out[4] = angle;

            if(flipHorizontal == 0 &&  model.flipHorizontal == 0){
                flipHorizontal = 0;
            }else if(flipHorizontal == 1 && model.flipHorizontal == 0)
            {
                flipHorizontal = 1;
            } else if(flipHorizontal==0 && model.flipHorizontal ==1){
                flipHorizontal = 1;
            } else if(flipHorizontal == 1 && model.flipHorizontal == 1){
                flipHorizontal = 0;
            }

            if(flipVertical == 0 && model.flipVertical == 0){
                flipVertical = 0;
            }else if(flipVertical == 1 && model.flipVertical == 0)
            {
                flipVertical = 1;
            } else if(flipVertical==0 && model.flipVertical ==1){
                flipVertical = 1;
            } else if(flipVertical == 1 && model.flipVertical == 1){
                flipVertical = 0;
            }

            out[5] =  flipHorizontal;
            out[6] =  flipVertical;

            out[7] = model.startTime + parentInfo[7];
            out[8] = model.duration;

        } else{

            out[0] = x;
            out[1] = y;
            out[2] = width;
            out[3] = height;
            out[4] = angle;
            out[5] =  flipHorizontal;
            out[6] =  flipVertical;

            if (model == null) {
                model = getPage(modelId);
            }

            if (model != null) {
                out[7] = 0.0f;//model.startTime;
                out[8] = model.duration;
            }

        }

        return out;
    }
    private PointF getRotatedPoint(PointF point, PointF centerPoint, float angleInDegrees ){
        // Translate Point to Origin

        float tempX = point.x - centerPoint.x;
        float tempY = point.y - centerPoint.y;


        double theta =  Math.toRadians(angleInDegrees);

//// now apply rotation
//
        float rotatedX = (float) (tempX*Math.cos(theta) - tempY* Math.sin(theta));
        float rotatedY = (float) (tempX*Math.sin(theta) + tempY* Math.cos(theta));

// translate back
        float x = rotatedX + centerPoint.x;
        float y = rotatedY + centerPoint.y;
        return new PointF(x,y);
    }
    private float[] getDimensionsAfterRotation(float[] dimensions){
        float x = dimensions[0] * pageWidth;// surfaceWidth;
        float y = dimensions[1] * pageHeight;// surfaceHeight;
        float width = dimensions[2] * pageWidth;//surfaceWidth;
        float height = dimensions[3] * pageHeight;//surfaceHeight;
        float angle = dimensions[4];

        float[] out = new float[5];


            // We are going to find the new rec

            PointF centerPoint = new PointF(x+width/2,y+height/2);
            PointF rotatedLeftTop = getRotatedPoint(new PointF(x,y),centerPoint,angle);
            PointF rotatedLeftBottom = getRotatedPoint(new PointF(x,y+height),centerPoint,angle);
            PointF rotatedRightTop = getRotatedPoint(new PointF(x+width,y),centerPoint,angle);
            PointF rotatedRightBottom = getRotatedPoint(new PointF(x+width,y+height),centerPoint,angle);


            float newLeft = Math.min(Math.min(rotatedLeftTop.x, rotatedLeftBottom.x),Math.min(rotatedRightBottom.x,rotatedRightTop.x));
            float newRight = Math.max(Math.max(rotatedLeftTop.x, rotatedLeftBottom.x),Math.max(rotatedRightBottom.x,rotatedRightTop.x));
            float newTop = Math.min(Math.min(rotatedLeftTop.y, rotatedLeftBottom.y),Math.min(rotatedRightBottom.y,rotatedRightTop.y));
            float newBottom = Math.max(Math.max(rotatedLeftTop.y, rotatedLeftBottom.y),Math.max(rotatedRightBottom.y,rotatedRightTop.y));



            out[0] = newLeft/pageWidth;//surfaceWidth;
            out[1] = newTop/pageHeight;//surfaceHeight;
            out[2] = (newRight - newLeft)/pageWidth;//surfaceWidth;
            out[3] = (newBottom - newTop)/pageHeight;//surfaceHeight;
            out[4] = angle;
            return out;
    }
    private float[] getDimensionsAfterRotationWithPivot(float[] dimensions, PointF pivotPoint , float angle){
        float x = dimensions[0] * pageWidth;//surfaceWidth;
        float y = dimensions[1] * pageHeight;//surfaceHeight;
        float width = dimensions[2] * pageWidth;//surfaceWidth;
        float height = dimensions[3] * pageHeight;//surfaceHeight;
//        float angle = dimensions[4];
        pivotPoint.x=pivotPoint.x*pageWidth;//surfaceWidth;
        pivotPoint.y=pivotPoint.y*pageHeight;//surfaceHeight;

        float[] out = new float[5];


            // We are going to find the new rec

//            PointF pivotPoint = new PointF(x+width/2,y+height/2);
            PointF rotatedLeftTop = getRotatedPoint(new PointF(x,y),pivotPoint,angle);
            PointF rotatedLeftBottom = getRotatedPoint(new PointF(x,y+height),pivotPoint,angle);
            PointF rotatedRightTop = getRotatedPoint(new PointF(x+width,y),pivotPoint,angle);
            PointF rotatedRightBottom = getRotatedPoint(new PointF(x+width,y+height),pivotPoint,angle);


            float newLeft = Math.min(Math.min(rotatedLeftTop.x, rotatedLeftBottom.x),Math.min(rotatedRightBottom.x,rotatedRightTop.x));
            float newRight = Math.max(Math.max(rotatedLeftTop.x, rotatedLeftBottom.x),Math.max(rotatedRightBottom.x,rotatedRightTop.x));
            float newTop = Math.min(Math.min(rotatedLeftTop.y, rotatedLeftBottom.y),Math.min(rotatedRightBottom.y,rotatedRightTop.y));
            float newBottom = Math.max(Math.max(rotatedLeftTop.y, rotatedLeftBottom.y),Math.max(rotatedRightBottom.y,rotatedRightTop.y));

//        float newLeft =  rotatedLeftTop.x;
//        float newRight = rotatedRightTop.x;
//        float newTop = rotatedLeftTop.y;
//        float newBottom = rotatedRightBottom.y;



            out[0] = newLeft/pageWidth;//surfaceWidth;
            out[1] = newTop/pageHeight;//surfaceHeight;
            out[2] = (newRight - newLeft)/pageWidth;//surfaceWidth;
            out[3] = (newBottom - newTop)/pageHeight;//surfaceHeight;
            out[4] = angle;
            return out;
    }
    //endregion

//    public boolean changeParentOfModel2(int modelId, int parentId){
//        synchronized (lock) {
//            boolean didSucceed = false;
//            //TODO CHECK If i am making a Page as a CHild of another Parent
//            // Check if model & parent are valid
//            Model model = getModel(modelId);
//            if(model == null){
//                model = getPage(modelId);
//                if(model == null) {
//                    return didSucceed;
//                }
//            }
//            Model parentModel = getModel(parentId);
//            if(parentModel == null){
//                parentModel = getPage(parentId);
//                if(parentModel == null){
//                    return didSucceed;
//                }
//            }
//
//            // We have the Model and The Parent
//            // get the
//            float[] modelRootDimensions  = getModelDimensionsAsPerRoot(modelId);  // This is with Rotation Angle Cumulative
//
//            float[] parentRootDimensions = getModelDimensionsAsPerRoot(parentId); // This is with Rotation Angle Cumulative
//
//
//            // We want to make the Parent Dimensions as per "ITS" parent such that the new Model child looks same on the screen
//            if(parentModel.parent == null){
//                // This is the Main parent - its like as if adding a Page
//                //TODO What should happen here?
//                return didSucceed;
//            }
//
//            //1. Check if Parent has any childs
//            if(parentModel.childlist.size()==0){
//                // this is the first child thats getting added.
//                // we need to hug the parent to model
//                // Check if ParentModel has a Parent..
//
//                // We need to make parent as the same size of Model
//                float[] parentDimensionsWeWant = getDimensionsAfterRotation(modelRootDimensions);
//                float[] parentNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), parentDimensionsWeWant);
//                // Now ModeNew
//                moveModel(parentId,parentNewDimension[0], parentNewDimension[1],parentNewDimension[2],parentNewDimension[3],0);
//                // Get Child Dimension as per New Parent
//                float[] childDimension = getModelDimensionsAsPerParent(parentId, modelRootDimensions);
//                moveModel(modelId,childDimension[0],childDimension[1],childDimension[2],childDimension[3],childDimension[4]);
//                changeModelParent(modelId,parentId);
//                didSucceed = true;
//
//            } else {
//                // Now we need to consider the existing Parent Dimensions and the Model Dimensions
//                float[] modelRootDimensionsAfterRotation1 = getDimensionsAfterRotation(modelRootDimensions); // This is the rotated on Self
//                float[] modelRootDimensionsAfterRotation = getDimensionsAfterRotationWithPivot(modelRootDimensionsAfterRotation1, new PointF(parentRootDimensions[0] + parentRootDimensions[2]/2, parentRootDimensions[1] + parentRootDimensions[3]/2), -parentRootDimensions[4]);
//                // This is rotated by Parent After child is rotated // These are used to calculate the Nee Parent Dimensions
//                float[] modelRootDimensionsWithPivot = getDimensionsAfterRotationWithPivot(modelRootDimensions, new PointF(parentRootDimensions[0] + parentRootDimensions[2]/2, parentRootDimensions[1] + parentRootDimensions[3]/2), -parentRootDimensions[4]);
//                // These are the Points that will be before rotation
//             //   parentRootDimensions = getDimensionsAfterRotation(parentRootDimensions);
//                float combinedParentLeft = Math.min(modelRootDimensionsAfterRotation[0], parentRootDimensions[0]);
//                float combinedParentTop = Math.min(modelRootDimensionsAfterRotation[1], parentRootDimensions[1]);
//                float combinedParentRight = Math.max(modelRootDimensionsAfterRotation[0] + modelRootDimensionsAfterRotation[2], parentRootDimensions[0] + parentRootDimensions[2]);
//                float combinedParentBottom = Math.max(modelRootDimensionsAfterRotation[1] + modelRootDimensionsAfterRotation[3], parentRootDimensions[1] + parentRootDimensions[3]);
//
//                float[] parentDimensionsWeWant = new float[5];
//                parentDimensionsWeWant[0] = combinedParentLeft;
//                parentDimensionsWeWant[1] = combinedParentTop;
//                parentDimensionsWeWant[2] = combinedParentRight - combinedParentLeft;
//                parentDimensionsWeWant[3] = combinedParentBottom - combinedParentTop;
//                parentDimensionsWeWant[4] = parentRootDimensions[4];
//                float[] parentNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), parentDimensionsWeWant);
//
//                // Now we need to readjust all Childs as per the new Parent Dimensions
//                // Temporarily Store all the Childs current Dimensions
//                ArrayList<float[]> childDimensions = new ArrayList<>();
//                for(int i = 0 ; i < parentModel.childlist.size(); i++){
//                    // Resize each model as per the new Parent Dimensions
//                    float[] childDimension = getModelDimensionsAsPerRoot(parentModel.childlist.get(i).modelId);
//                    childDimensions.add(childDimension);
//                    //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
//                }
//                // CHANGE PARENT DIMENSIONS TO NEW
//                moveModel(parentId,parentNewDimension[0], parentNewDimension[1],parentNewDimension[2],parentNewDimension[3],parentNewDimension[4]);
//                // Re Adjust everything back
//                for(int i = 0 ; i < parentModel.childlist.size(); i++){
//                    // Resize each model as per the new Parent Dimensions
//                    float[] childNewDimension = getModelDimensionsAsPerParent(parentId, childDimensions.get(i));
//
//                    moveModel(parentModel.childlist.get(i).modelId,childNewDimension[0],childNewDimension[1],childNewDimension[2],childNewDimension[3],childNewDimension[4]);
//                }
//                // Now we are going to add the New Model
//                // This time we need the values as per the orignal state and not the rotated state
//
//                float[] modelNewDimension = getModelDimensionsAsPerParent(parentId, modelRootDimensions);
//                changeModelParent(modelId,parentId);
//
//                moveModel(modelId,modelNewDimension[0],modelNewDimension[1],modelNewDimension[2],modelNewDimension[3],  modelNewDimension[4] );
//                didSucceed = true;
//
//
//            }
//
//
//            return didSucceed;
//        }
//
//    }
//    public boolean changeParentOfModel(int modelId, int parentId){
//        synchronized (lock) {
//            boolean didSucceed = false;
//            //TODO CHECK If i am making a Page as a CHild of another Parent
//            // Check if model & parent are valid
//            Model model = getModel(modelId);
//            if(model == null){
//                model = getPage(modelId);
//                if(model == null) {
//                    return didSucceed;
//                }
//            }
//            Model parentModel = getModel(parentId);
//            if(parentModel == null){
//                parentModel = getPage(parentId);
//                if(parentModel == null){
//                    return didSucceed;
//                }
//            }
//
//            // We have the Model and The Parent
//            // get the
//            float[] modelRootDimensions  = getModelDimensionsAsPerRoot(modelId);  // This is with Rotation Angle Cumulative
//
//            float[] parentRootDimensions = getModelDimensionsAsPerRoot(parentId); // This is with Rotation Angle Cumulative
//
//
//            // We want to make the Parent Dimensions as per "ITS" parent such that the new Model child looks same on the screen
//            if(parentModel.parent == null){
//                // This is the Main parent - its like as if adding a Page
//                //TODO What should happen here?
//                return didSucceed;
//            }
//
//            //1. Check if Parent has any childs
//            if(parentModel.childlist.size()==0){
//                // this is the first child thats getting added.
//                // we need to hug the parent to model
//                // Check if ParentModel has a Parent..
//
//                // We need to make parent as the same size of Model
//                float[] parentDimensionsWeWant = getDimensionsAfterRotation(modelRootDimensions);
//                float[] parentNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), parentDimensionsWeWant);
//                // Now ModeNew
//                moveModel(parentId,parentNewDimension[0], parentNewDimension[1],parentNewDimension[2],parentNewDimension[3],0);
//                // Get Child Dimension as per New Parent
//                float[] childDimension = getModelDimensionsAsPerParent(parentId, modelRootDimensions);
//                moveModel(modelId,childDimension[0],childDimension[1],childDimension[2],childDimension[3],childDimension[4]);
//                changeModelParent(modelId,parentId);
//                didSucceed = true;
//
//            } else {
//                // Now we need to consider the existing Parent Dimensions and the Model Dimensions
//                float[] modelRootDimensionsAfterRotation1 = getDimensionsAfterRotation(modelRootDimensions); // This is the rotated on Self
//                float[] modelRootDimensionsAfterRotation = getDimensionsAfterRotationWithPivot(modelRootDimensionsAfterRotation1, new PointF(parentRootDimensions[0] + parentRootDimensions[2]/2, parentRootDimensions[1] + parentRootDimensions[3]/2), -parentRootDimensions[4]);
//                // This is rotated by Parent After child is rotated // These are used to calculate the Nee Parent Dimensions
//                float[] modelRootDimensionsWithPivot = getDimensionsAfterRotationWithPivot(modelRootDimensions, new PointF(parentRootDimensions[0] + parentRootDimensions[2]/2, parentRootDimensions[1] + parentRootDimensions[3]/2), -parentRootDimensions[4]);
//                // These are the Points that will be before rotation
//             //   parentRootDimensions = getDimensionsAfterRotation(parentRootDimensions);
//                float combinedParentLeft = Math.min(modelRootDimensionsAfterRotation[0], parentRootDimensions[0]);
//                float combinedParentTop = Math.min(modelRootDimensionsAfterRotation[1], parentRootDimensions[1]);
//                float combinedParentRight = Math.max(modelRootDimensionsAfterRotation[0] + modelRootDimensionsAfterRotation[2], parentRootDimensions[0] + parentRootDimensions[2]);
//                float combinedParentBottom = Math.max(modelRootDimensionsAfterRotation[1] + modelRootDimensionsAfterRotation[3], parentRootDimensions[1] + parentRootDimensions[3]);
//
//                float[] parentDimensionsWeWant = new float[5];
//                parentDimensionsWeWant[0] = combinedParentLeft;
//                parentDimensionsWeWant[1] = combinedParentTop;
//                parentDimensionsWeWant[2] = combinedParentRight - combinedParentLeft;
//                parentDimensionsWeWant[3] = combinedParentBottom - combinedParentTop;
//                parentDimensionsWeWant[4] = parentRootDimensions[4];
//                float[] parentNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), parentDimensionsWeWant);
//
//                // Now we need to readjust all Childs as per the new Parent Dimensions
//                // Temporarily Store all the Childs current Dimensions
//                ArrayList<float[]> childDimensions = new ArrayList<>();
//                for(int i = 0 ; i < parentModel.childlist.size(); i++){
//                    // Resize each model as per the new Parent Dimensions
//                    float[] childDimension = getModelDimensionsAsPerRoot(parentModel.childlist.get(i).modelId);
//                    childDimensions.add(childDimension);
//                    //float[] childNewDimension = getModelDimensionsAsPerParent(parentModel.parent.getModelId(), childDimension);
//                }
//                // CHANGE PARENT DIMENSIONS TO NEW
//                moveModel(parentId,parentNewDimension[0], parentNewDimension[1],parentNewDimension[2],parentNewDimension[3],parentNewDimension[4]);
//                // Re Adjust everything back
//                for(int i = 0 ; i < parentModel.childlist.size(); i++){
//                    // Resize each model as per the new Parent Dimensions
//                    float[] childNewDimension = getModelDimensionsAsPerParent(parentId, childDimensions.get(i));
//
//                    moveModel(parentModel.childlist.get(i).modelId,childNewDimension[0],childNewDimension[1],childNewDimension[2],childNewDimension[3],childNewDimension[4]);
//                }
//                // Now we are going to add the New Model
//                // This time we need the values as per the orignal state and not the rotated state
//
//                float[] modelNewDimension = getModelDimensionsAsPerParent(parentId, modelRootDimensionsWithPivot);
//                changeModelParent(modelId,parentId);
//
//                moveModel(modelId,modelNewDimension[0],modelNewDimension[1],modelNewDimension[2],modelNewDimension[3],  modelRootDimensions[4] - parentNewDimension[4]);
//
//                didSucceed = true;
//
//
//            }
//
//
//            return didSucceed;
//        }
//
//    }



//    private boolean setProperXAndTime(int pageId){
//        synchronized (lock) {
//            if (scene != null) {
//                // Check if Page already exists
//                if (getPage(pageId) == null) {
//                    if(debug) Log.i("SceneManager", "Page " + pageId + " doesnt exists");
//                    return false;
//                }
//                // Which Page is being deleted
//                int pagePositionDelete = 0;
//                float startX = 0;
//                float startTime = 0;
//                boolean didfindPageToDelete = false;
//                int totalNumberOfActivePages = 0;
//
//                for(int i = 0 ; i< scene.models.size(); i++) {
//                    Model model = scene.models.get(i);
//                    if(model.removeFlag==false){
//                        if (model.modelId == pageId) {
//                            pagePositionDelete = i;
//                            startX = model.x;
//                            startTime = model.startTime;
//                            model.removeFlag = true;
//                            pageHashMap.remove(pageId);
//                            setDataChanged(true);
//                            didfindPageToDelete = true;
//                        }
//                        totalNumberOfActivePages = totalNumberOfActivePages + 1;
//                    }
//                }
//                //
//                if(didfindPageToDelete){
//                // Adjust X and Timings of the pages
//                    // Adjusting X
//                    if(pagePositionDelete == 0){
//                        // This is the First Page
//                        if(startX < 0){
//                            // This means its not showing the current page
//                            for(int i = 0; i != toPosition; i++){
//                                Model model = scene.models.get(i);
//                                if( !model.removeFlag ) {
//                                    model.startTime = startTime;
//                                    model.x = startX;
//                                    startTime = startTime + model.duration;
//                                    startX = startX + 1.0f;
//                                    model.timeChangeFlag = true;
//                                    setDataChanged(true);
//                                }
//                            }
//
//                        } else if(startX == 0){
//                            // this is the current page
//                            setProperXValuesAndTimesForPages(0,scene.models.size(),0,0);
//
//                        } else {
//                            if(debug) Log.e("SceneManager"," Something is wrong");
//                        }
//                    }
//
//                }
//
//            }
//        }
//
//        int pageIdToDelete;
//
//
//        if(pagePositionDelete == 0){
//
//            if(startX == 0){
//                // We need to pull all above this
//            }else if(startX < 0) {
//                // We need to update X till 0
//            } else {
//                // SOmething is Wrong
//            }
//        } else if(pagePositionDelete > 0 && pagePositionDelete < Final){
//            if(startX >= 0){
//                // update all after this position with
//
//            } else if(startX < 0){
//                // update all before this position
//            }
//        } else if( this is the final one){
//            if (startX == 0)
//            {
//                // update all prior to this
//            } else if( startX > 0){
//                // update till the model is 0
//            } else {
//                // something is wrong
//            }
//
//        }
//
//        //get position
//        //get start Time
//        // get startX
//        if(fromPosition == 0){
//            // this is the first element
//            for(int i = 0; i<scene.models.size(); i++){
//                Model model = scene.models.get(i);
//                if( !model.removeFlag ) {
//                    model.startTime = startTime;
//                    model.x = startX;
//                    startTime = startTime + model.duration;
//                    startX = startX + 1.0f;
//                    model.timeChangeFlag = true;
//                    setDataChanged(true);
//                }
//            }
//
//        }
//
//
//    }
//    public boolean onChangeRatio(){
//        synchronized (lock){
//
//            boolean didSucceed = resetXValuesAndTimesForPages();
//            setDataChanged(true);
//            return didSucceed;
//        }
//    }





//    private ImageModel createImageModel(  Model parentModel, int modelId, String imagePath, Bitmap bitmap, float x , float y , float width, float height, float angle){
//        synchronized (lock) {
//            ImageModel imageModel = new ImageModel(modelId, parentModel,  imagePath, bitmap, x, y, width, height, angle);
//            return imageModel;
//        }
//    }
//    public  boolean createUpdateImage(int modelId, int parentModelId, String imagePath, Bitmap bitmap, float x , float y , float width, float height, float angle){
//        // I need to get Who is the Parent?
//        createImageModel(modelId)
//    }
//    public Model getModelById(String sceneName, int id){
//        for(Scene scene: scenes) {
//            if (scene.sceneName.equals(sceneName)) {
//                for (Model model : scene.models) {
//                    if (model instanceof ImageModel) {
//                        if (model.modelId == id) {
//                            return model;
//                        }
//                    }
//                }
//            }
//        }
//        return null;
//    }





//    public void removeFPS(String sceneName, String objName){
//         // Find Scene
//        for(Scene scene: scenes){
//            if(scene.sceneName.equals(sceneName)){
//                // find Model
//                for(Model model: scene.models){
//                    if(model instanceof FPSModel){
//                        if(((FPSModel) model).objectName.equals(objName)){
//                            model.removeFlag = true;
//                            setDataChanged(true);
//                        }
//                    }
//                }
//            }
//        }
//    }




    private double fps() {
        long lastTime = System.nanoTime();
        double difference = (lastTime - times.getFirst()) / NANOS;
        times.addLast(lastTime);
        int size = times.size();
        if (size > MAX_SIZE) {
            times.removeFirst();
        }
        return difference > 0 ? times.size() / difference : 0.0;
    }
    //region GLThread Object Management function
//****************HANDLING OBJECT MANAGEMENT IN C++ and JAVA



    private void handleObjectChangesInC(Context context){
        progress = 0;
        setDataChanged(false);
        // Check if background changed
        if(didChangeRendererBackground) {
            if(rendererObjectPointer!=-1){
                didChangeRendererBackground = false;
                NativeBrigde.setRendererBackgroundColor(rendererObjectPointer,rendererBGColorRed,rendererBGColorGreen,rendererBGColorBlue);
            }
        }
        if(scene.removeFlag){
            if(debug) Log.i("SceneManager", "Remove The Entire Scene");
        } else {
            // Check if Scene is initialize
            if (scene.sceneObjectPointer == -1) {
                if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null){

                    sceneManagerListenerWeakReference.get().isInitializing(true);
                }
                scene.sceneObjectPointer = NativeBrigde.addScene(rendererObjectPointer, scene.sceneName);
//                if(sceneManagerListener!=null){
//                    sceneManagerListener.isInitializing(false);
//                }
                if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null){
                    sceneManagerListenerWeakReference.get().isInitializing(false);
                }
            }
        }
        if(sceneManagerListenerWeakReference!=null && sceneManagerListenerWeakReference.get()!=null ) {
            sceneManagerListenerWeakReference.get().isSceneLoading(designId,  true, getTotalTimeForScene());
        }


        //
        // We need to see what changes in the scene
        Iterator<Model> modelIterator = scene.models.iterator();

        while (modelIterator.hasNext()) {
            Model model = modelIterator.next();
            // check if model needs to be removed
            if (model.removeFlag) {
                model.removeAllChildModels(scene.sceneObjectPointer);
                if (model.modelObjectPointer == -1) {
                    modelIterator.remove();
                } else {
                    // Clean up in C++
                    boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.modelObjectPointer);
                    if (didSucceed) {
                        modelIterator.remove();
                    }
                }
            } else {
                // Check if this model is initialzed
                if (model.modelObjectPointer == -1) {
                    if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                        sceneManagerListenerWeakReference.get().isInitializing(true);
                    }
                    //model.initialzeModelAndItsChilds(scene.sceneObjectPointer,surfaceWidth,surfaceHeight);
                    model.initializeModelAndItsChildren(context, scene.sceneObjectPointer, pageWidth, pageHeight, offsetX, offsetY);
                    if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                        sceneManagerListenerWeakReference.get().isInitializing(false);
                    }
                    model.moveModelAndItsChildren(context, scene.sceneObjectPointer, pageWidth, pageHeight, offsetX, offsetY, model.flipHorizontal, model.flipVertical);


                } else {
                    // We just need to see if any changes

                    if (model.animFlagIn) {
                        model.changeAnimationParametersIn(context);
                        model.animFlagIn = false;
                    }
                    if (model.animFlagOut) {
                        model.changeAnimationParametersOut(context);
                        model.animFlagOut = false;
                    }
                    if (model.animFlagLoop) {
                        model.changeAnimationParametersLoop(context);
                        model.animFlagLoop = false;
                    }
                    if (model.timeChangeFlag) {
                        model.changeStartTimeAndDuration();
                        model.timeChangeFlag = false;
                    }
                    // If this is a parent
                    if (model instanceof ParentModel) {
                        if (((ParentModel) model).backgroundChange == true) {
                            ((ParentModel) model).changeBackground();
                        }
                        if (((ParentModel) model).backgroundBlurChange == true) {
                            ((ParentModel) model).changeBackgroundBlur();
                        }
                        if (((ParentModel) model).backgroundTileMultiplierChange == true) {
                            ((ParentModel) model).changeBackgroundTileMultiplier();
                        }
                        if (((ParentModel) model).overlayImageChange == true) {
                            ((ParentModel) model).changeOverlayImage();
                        }
                        if (((ParentModel) model).overlayImageOpacityChange == true) {
                            ((ParentModel) model).changeOverlayImageOpacity();
                        }
                    }
                    // if Parent Changed
                    if (model.didParentChangeFlag) {
                        model.changeParentInNative();
                        model.didParentChangeFlag = false;
                    }
                    if (model.didChildResequenced) {
                        model.resequenceChildsInNative();
                        model.didChildResequenced = false;
                    }
                    if (model.didSetVisiblityChanged) {
                        model.changeModelVisiblity();
                        model.didSetVisiblityChanged = false;
                    }
                    //model.moveModelAndItsChilds(scene.sceneObjectPointer, surfaceWidth, surfaceHeight );
                    model.moveModelAndItsChildren(context, scene.sceneObjectPointer, pageWidth, pageHeight, offsetX, offsetY, model.flipHorizontal, model.flipVertical);
                }


            }

        }
        if (scene.sceneObjectPointer != -1 && scene.pageSequenceChanged) {
            // Call Native Function to rearange PageSequences
            boolean didSucceed = NativeBrigde.changePageSequence(scene.sceneObjectPointer);
            if (didSucceed) {
                scene.pageSequenceChanged = false;
            }
        }
        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
            // We need to call the Native Function to update the Thumbnails

            sceneManagerListenerWeakReference.get().isSceneLoading(designId,false, getTotalTimeForScene());
            // First Time the Design is loaded


        }

    }

    private void handleObjectChangesInCOld() {
        setDataChanged(false);
        //    Iterator<Scene> sceneIterator = scenes.iterator();
        //   while (sceneIterator.hasNext()){
        //Scene scene = scene;
        if (scene.removeFlag) {
            // if scene was ever initialized?
            if (scene.sceneObjectPointer == -1) {
                //sceneIterator.remove();
                scene = null;
            } else {
                // Remove all Models first
                Iterator<Model> modelIterator = scene.models.iterator();
                while (modelIterator.hasNext()) {
                    Model model = modelIterator.next();
                    if (model.modelObjectPointer == -1) {
                        modelIterator.remove();
                    } else {
                        // Clean up in C++
                        boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.modelObjectPointer);
                        if (didSucceed) {
                            modelIterator.remove();
                        }
                    }
                }
                boolean didSucceed = NativeBrigde.removeScene(rendererObjectPointer, scene.sceneObjectPointer);
                //sceneIterator.remove();
                scene = null;
            }
        } else {
            // Check if its not already initialized
            if (scene.sceneObjectPointer == -1) {
                if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                    sceneManagerListenerWeakReference.get().isInitializing(true);
                }
                scene.sceneObjectPointer = NativeBrigde.addScene(rendererObjectPointer, scene.sceneName);
                if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                    sceneManagerListenerWeakReference.get().isInitializing(false);
                }
            }
        }
        Iterator<Model> modelIterator = scene.models.iterator();
        while (modelIterator.hasNext()) {
            Model model = modelIterator.next();
            // Does this model needs to be removed
            if (model.removeFlag) {
                // if Model was ever initiated
                if (model.modelObjectPointer == -1) {
                    modelIterator.remove();
                } else {
                    // Clean up in C++
                    boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.modelObjectPointer);
                    if (didSucceed) {
                        modelIterator.remove();
                    }
                }
            } else {
                // Check if this needs to be initialized
                if (model.modelObjectPointer == -1) {
                    if (model instanceof FontModel) {
                        // Cast it to FontModel
                        String fontName = ((FontModel) model).fontName;
                        String fontFilePath = ((FontModel) model).fontFilePath;
                        int fontSize = ((FontModel) model).fontSize;
                        model.modelObjectPointer = NativeBrigde.addFont(scene.sceneObjectPointer, fontFilePath, fontSize, fontName);
                    }
                    if (model instanceof FPSModel) {
                        // Cast to FPS
                        String objectName = ((FPSModel) model).objectName;
                        int xPos = (int) model.x;
                        int yPos = (int) ((FPSModel) model).y;
                        model.modelObjectPointer = NativeBrigde.addFPS(scene.sceneObjectPointer, objectName, xPos, yPos);
                    }
                    if (model instanceof ImageModel) {
                        // Cast to ImageModel
                        String filePath = ((ImageModel) model).pathOrAsset;
                        int x = (int) (((ImageModel) model).x * surfaceWidth);
                        int y = (int) (((ImageModel) model).y * surfaceHeight);
                        int width = (int) (((ImageModel) model).width * surfaceWidth);
                        int height = (int) (((ImageModel) model).height * surfaceHeight);
                        float angle = ((ImageModel) model).angle;
                        Bitmap bitmap = ((ImageModel) model).bitmap;
                        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                            sceneManagerListenerWeakReference.get().isInitializing(true);
                        }
                        long parent = -1;
                        if (model.parent != null) {
                            parent = model.parent.modelObjectPointer;
                        }

                        model.modelObjectPointer = NativeBrigde.addImage(scene.sceneObjectPointer, parent, model.modelId, model.getSequenceInParent(),
                                ((ImageModel) model).pathOrAsset, ((ImageModel) model).getImageTypeForNative(),
                                ((ImageModel) model).getIsEncryptedForNative(), ((ImageModel) model).bitmap, ((ImageModel) model).cropX,
                                ((ImageModel) model).cropY, ((ImageModel) model).cropW, ((ImageModel) model).cropH, ((ImageModel) model).cropStyle,
                                x, y, width, height, angle,
                                model.opacity, model.flipHorizontal, model.flipVertical, model.startTime, model.duration);
                        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                            sceneManagerListenerWeakReference.get().isInitializing(false);
                        }
                    }
                } else {
                    // Object is already initialized
                    // TODO Handle changes
                    if (model instanceof ImageModel) {
                        int x = (int) (((ImageModel) model).x * surfaceWidth);
                        int y = (int) (((ImageModel) model).y * surfaceHeight);
                        int width = (int) (((ImageModel) model).width * surfaceWidth);
                        int height = (int) (((ImageModel) model).height * surfaceHeight);
                        //boolean didSucceed = NativeBrigde.moveImage(model.modelObjectPointer,(int)((ImageModel) model).x * surfaceWidth,(int)((ImageModel) model).y * surfaceHeight,(int)((ImageModel) model).width * surfaceWidth, (int)((ImageModel) model).height * surfaceHeight, ((ImageModel) model).angle);
                        boolean didSucceed = NativeBrigde.moveImage(model.modelObjectPointer, x, y, width, height, ((ImageModel) model).angle, model.flipHorizontal, model.flipVertical);
                    }
                }
            }
        }
        //  }


    }

    //endregion
    private boolean removeModelFromScene(Model model) {
        // TODo we need to handle the removal from a Parent Model
        boolean didSucceed = false;
        if (scene != null) {
            if (model.modelObjectPointer == -1) {
                didSucceed = scene.models.remove(model);
            } else {
                // Clean up in C++
                didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.modelObjectPointer);
                if (didSucceed) {
                    didSucceed = scene.models.remove(model);
                }
            }
        }
        return didSucceed;
    }
    //
//region Rendering Life Cycle
    // *************************Renderer LifeCycle Events*************************

    public void onSurfaceCreated() {

        if (contextWeakReference != null) {
            if (rendererObjectPointer == -1) {
                synchronized (Utils.INIT_RENDERERLOCK) {
                    rendererObjectPointer = NativeBrigde.initRenderer(contextWeakReference.get().getPackageResourcePath(), contextWeakReference.get().getAssets());
                }
            }

        }
        if(debug) Log.i("glOpenGLES3Native", "Surface Created - Thread " + Thread.currentThread().getName());
    }

    public boolean setRendererBackgroundColor(int red, int green, int blue) {
        synchronized (lock) {
            rendererBGColorRed = red;
            rendererBGColorGreen = green;
            rendererBGColorBlue = blue;
            didChangeRendererBackground = true;
            setDataChanged(true);
        }
        return true;
    }

    public void onSurfaceChanged(int width, int height) {

        if (rendererObjectPointer == -1) {
            if (contextWeakReference != null) {
                rendererObjectPointer = NativeBrigde.initRenderer(contextWeakReference.get().getPackageResourcePath(), contextWeakReference.get().getAssets());
            }
        }
        if(debug) Log.i("glOpenGLES3Native", "Surface Changed - Thread " + Thread.currentThread().getName());
        this.surfaceWidth = width;
        this.surfaceHeight = height;
        NativeBrigde.resize(rendererObjectPointer, this.surfaceWidth, this.surfaceHeight, this.pageWidth, this.pageHeight, this.offsetX, this.offsetY);

        setDataChanged(true);


    }

    private int getNativeOpenGLViewMode(OpenGLViewMode glViewMode) {
        int viewMode = 0;
        switch (glViewMode) {
            case EDIT:
                viewMode = 0;
                break;

            case FULL_PREVIEW_PLAYING:
            case FULL_PREVIEW_PAUSED:
            case PREVIEW_PLAYING:
                viewMode = 1;
                break;
            case SELECTIVE_PREVIEW:
                viewMode = 2;
                break;
            case BLANK:
                viewMode = 3;
                break;
            case TIMING:
                viewMode = 4;
                break;
        }
        return viewMode;
    }
//    public void onOpenGLViewModeChanged(OpenGLViewMode glViewMode){
//        int viewMode = 0;
//        switch (glViewMode){
//            case EDIT:
//                viewMode = 0;
//                break;
//            case PREVIEW:
//                viewMode = 1;
//                break;
//            case SELECTIVE_PREVIEW:
//                viewMode = 2;
//                break;
//            case BLANK:
//                viewMode = 3;
//                break;
//            case TIMING:
//                viewMode = 4;
//                break;
//        }
//        if(debug) Log.i("ViewMode", "View Mode changed to "  + viewMode);
//        NativeBrigde.setGLViewMode(rendererObjectPointer,viewMode);
//        setDataChanged(true);
//
//        if(debug) Log.i("glOpenGLES3Native","GLView Mode  Changed - Thread " + Thread.currentThread().getName());
//    }
//    public void onSelectedModelIdChanged(int modelId){
//        boolean didSucceed = NativeBrigde.setSelectedModelId(rendererObjectPointer,modelId);
//        setDataChanged(true);
//    }

    public void onDrawFrame(float timeToRender, OpenGLViewMode glViewMode, int modelId, float otherModelsTime) {

        if (didDataChanged) {
            //TODO - VERY IMPORTANT Make SUre LOCK is used correctly
            synchronized (lock) {
                handleObjectChangesInC(contextWeakReference.get());

            }
        }
        double fps = fps();
        frameNumber++;
        int glViewModeNative = getNativeOpenGLViewMode(glViewMode);
        // if(debug) Log.i("FPS - Java", "fps is " + fps + " frame number " + frameNumber) ;
        if (glThreadNativeListenerWeakReference == null || glThreadNativeListenerWeakReference.get() == null) {
            NativeBrigde.step(null, rendererObjectPointer, timeToRender, glViewModeNative, modelId, otherModelsTime);


        } else {
            if (refreshThumbnails && (glViewMode == OpenGLViewMode.EDIT || glViewMode == OpenGLViewMode.TIMING)) {
                //todo check thumbs are not created unnecessarily in timing mode
                if(debug) Log.i("RKTHUMB", "Updating Thumb");
                NativeBrigde.updateThumb(glThreadNativeListenerWeakReference.get(), rendererObjectPointer, timeToRender, false);
                refreshThumbnails = false;
            }
            if(debug) Log.i("RKAnim", "ViewMode " + glViewModeNative + " selected Model " + modelId + " timeToRender" + timeToRender + " Other time" + otherModelsTime);
            NativeBrigde.step(glThreadNativeListenerWeakReference.get(), rendererObjectPointer, timeToRender, glViewModeNative, modelId, otherModelsTime);

        }


//        double t = 10;

    }

    // TODO Ideally it will be best if we can send the View Mode as a parameter rather than setting another call
    // Parameter will tell 1. if it needs to update the thumbnails bitmap 2. it should animate
    // 1. Thumbnails should be captured only when something is changed so you can use the didDataChanged Parameter
    // 2. should animate will tell if the thread should render with animations
    // When you are saving we dont change the data - hence we dont need to create thumbnails
    // Animation will be always on when you are rendering in Preview Mode
    public void onDrawFrame(float timeToRender, GLThreadNativeListener glThreadNativeListener, int viewMode) {
        if (didDataChanged) {
            //TODO - VERY IMPORTANT Make SUre LOCK is used correctly
            synchronized (lock) {
                if (contextWeakReference != null && contextWeakReference.get() != null) {
                    handleObjectChangesInC(contextWeakReference.get());
                }
            }
        }
        double fps = fps();
        frameNumber++;
        // if(debug) Log.i("FPS - Java", "fps is " + fps + " frame number " + frameNumber) ;
        if (glThreadNativeListenerWeakReference == null || glThreadNativeListenerWeakReference.get() == null) {
            NativeBrigde.step(null, rendererObjectPointer, timeToRender, viewMode, 0, 0);
        } else {
            NativeBrigde.step(glThreadNativeListenerWeakReference.get(), rendererObjectPointer, timeToRender, viewMode, 0, 0);
        }


//        double t = 10;

    }

    public Bitmap getTemplateThumbnail(float timeToRender, OpenGLViewMode glViewMode) {

        if (didDataChanged) {
            //TODO - VERY IMPORTANT Make SUre LOCK is used correctly
            synchronized (lock) {
                handleObjectChangesInC(contextWeakReference.get());
            }
        }
        int glViewModeNative = getNativeOpenGLViewMode(glViewMode);
        Bitmap bitmap = NativeBrigde.getThumnailImageForTemplate(rendererObjectPointer, timeToRender, glViewModeNative);
        // This is a static bitmap - create a copy and release it
        Bitmap bmp2 = bitmap.copy(bitmap.getConfig(), true);
        bitmap.recycle();
        bitmap = null;
        return bmp2;

    }

    public void onDrawFrame() {
        if (didDataChanged) {
            //TODO - VERY IMPORTANT Make SUre LOCK is used correctly
            synchronized (lock) {
                handleObjectChangesInC(contextWeakReference.get());
            }
        }
        double fps = fps();
        frameNumber++;
        //  if(debug) Log.i("FPS - Java", "fps is " + fps + " frame number " + frameNumber) ;
        NativeBrigde.step(glThreadNativeListenerWeakReference.get(), rendererObjectPointer, 0, 0, 0, 0);
    }

    public void onSurfaceDestroyed() {

        //
        // CREANUP All SceneManager Objects Created in C++

        // Remove All Models in SceneManager JAVA
        cleanUpSceneManager();
        NativeBrigde.deinit(rendererObjectPointer);
        if(debug) Log.i("Renderer", " Destroy " + Thread.currentThread().getName());

    }
    // *************************Renderer LifeCycle Events End *************************


    private void cleanUpSceneManager() {
        if(debug) Log.i("CleanUp", "In CleanUpSceneManager");
        // Iterator<Scene> sceneIterator = scenes.iterator();
        //   while (sceneIterator.hasNext()) {
        //     Scene scene = sceneIterator.next();
        if (scene != null) {
            Iterator<Model> modelIterator = scene.models.iterator();
            while (modelIterator.hasNext()) {
                Model model = modelIterator.next();
                if (model.modelObjectPointer == -1) {
                    modelIterator.remove();
                } else {
                    // Clean up in C++
                    boolean didSucceed = NativeBrigde.removeModel(scene.sceneObjectPointer, model.modelObjectPointer);
                    if (didSucceed) {
                        modelIterator.remove();
                    }
                }
            }
            if (scene.sceneObjectPointer != -1) {
                boolean didSucceed = NativeBrigde.removeScene(rendererObjectPointer, scene.sceneObjectPointer);
            }
            scene.models.clear();
        }
        // }
    }
    // endregion

    @Override
    public void isModelInitializing(boolean isInitializing, int modelId) {
        if (isInitializing && scene.models.size() > 0) {
            progress = (float) progress + 1.0f / (pageHashMap.size() + modelHashMap.size());
            // Post Progres to listener

        }
        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
            sceneManagerListenerWeakReference.get().isInitializing(isInitializing);


            sceneManagerListenerWeakReference.get().sceneLoadingProgress((int) (100 * progress));

        }

    }

    @Override
    public void onModelBitmapChanged(int modelId) {
        // Check if this model Id is page
        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
                if (model == null) {
                    // Did not find the model
                    String crashMsg = "Crash in SceneManager.onModelBitmapChanged. Did not find the model : " + modelId ;
                    CrashlyticsTracker.report(new RuntimeException(crashMsg), crashMsg);
                    if(debug) Log.i("RBTest", crashMsg);
                } else {
                    sceneManagerListenerWeakReference.get().onPageImageChanged(modelId, model.getModelThumbnailBitmap());
                }
            } else {
                sceneManagerListenerWeakReference.get().onParentImageChanged(modelId, model.getModelThumbnailBitmap());
            }
        } else {
            String crashMsg = "Crash in SceneManager.onModelBitmapChanged" + modelId + ". sceneManagerListenerWeakReference is null : " + (sceneManagerListenerWeakReference == null)
                    + " or sceneManagerListenerWeakReference.get() == null : " + (sceneManagerListenerWeakReference.get() == null);
            CrashlyticsTracker.report(new RuntimeException(crashMsg), crashMsg);
            if(debug) Log.i("RBTest", crashMsg);
        }

    }

    @Override
    public void onTextBitmapChanged(int modelId) {
        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
            sceneManagerListenerWeakReference.get().onTextImageChanged(modelId);
        }
    }

    @Override
    public void onTextModelFontSizeChanged(int modelId, int fontSize) {
        if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
            sceneManagerListenerWeakReference.get().onTextModelFontSizeChanged(modelId, fontSize);
        }
    }

    public boolean isTouchOnNonTransparentPartOfModelV2(int modelId, int x, int y, int viewWidth, int viewHeight, boolean isFlippedHorizontal, boolean isFlippedVertical) {
        // get Model
        boolean didSucceed = false;

        Model model = getModel(modelId);
        if (model != null) {
            //float [] parentDim = getModelDimensionsAsPerRootV2(getModel(modelId).parent.modelId);
            didSucceed = model.isTouchOnNonTransparentPartOfModelV2(x, y, viewWidth, viewHeight,isFlippedHorizontal,isFlippedVertical);
        }
        return didSucceed;
    }

    public boolean isTouchOnNonTransparentPartOfModel(int modelId, int x, int y, int pageX, int pageY) {
        // get Model
        boolean didSucceed = false;
        float[] out = checkIfTouchPointIsOutsideOfVisbleAreaAndGetDimensions(modelId, pageX, pageY);
        if (out[5] == 0) {
            // Clipped
            return false;
        }
        Model model = getModel(modelId);
        if (model != null) {
            //float [] parentDim = getModelDimensionsAsPerRootV2(getModel(modelId).parent.modelId);
            didSucceed = model.isTouchOnNonTransparentPartOfModel(x, y, (int) out[6], (int) out[7]);
        }
        return didSucceed;
    }

    private float[] checkIfTouchPointIsOutsideOfVisbleAreaAndGetDimensions(int modelId, int touchX, int touchY) {
        float x = 0;
        float y = 0;
        float width = pageWidth; //surfaceWidth;
        float height = pageHeight;// surfaceHeight;
        float angle = 0;

        float[] out = new float[10];
        Model model = getModel(modelId);
        if (model != null && model.parent != null) {
            float[] parentInfo = checkIfTouchPointIsOutsideOfVisbleAreaAndGetDimensions(model.parent.modelId, touchX, touchY);
            if (parentInfo[5] == 0) {
                // this means parent is cliping - we dont need to calculate further
                return parentInfo;
            }
            width = model.width * parentInfo[2];
            height = model.height * parentInfo[3];

            x = model.x * parentInfo[2] + parentInfo[0];
            y = model.y * parentInfo[3] + parentInfo[1];
//            boolean flipHorizontal = false;
//            boolean flipVertical = false;
            float flipHorizontal = (int) parentInfo[8];
            float flipVertical = (int) parentInfo[9];
//            if(parentInfo[8]==1){
//                flipHorizontal = true;
//            }
//            if(parentInfo[9]==1){
//                flipVertical = true;
//            }
            float tempAngle = model.angle;
            if (flipHorizontal == 1) {
                // the Right point
                float rightPoint = (model.x * parentInfo[2]) + (model.width * parentInfo[2]);
                float centerXOfParent = parentInfo[2] / 2;
                // new X will be mirrored from center
                float flippedX = centerXOfParent - (rightPoint - centerXOfParent);
                x = flippedX + parentInfo[0];
                tempAngle = -tempAngle;

            }
            if (flipVertical == 1) {
                // the Bottom point
                float bottomPoint = model.y * parentInfo[3] + model.height * parentInfo[3];
                float centerYOfParent = parentInfo[3] / 2;
                // new Y will be mirrored from center
                float flippedY = centerYOfParent - (bottomPoint - centerYOfParent);
                y = flippedY + parentInfo[1];
                tempAngle = -tempAngle;
            }
            // If Parent has an Angle then the X and Y needs to be rotated
            float cXParent = parentInfo[0] + parentInfo[2] / 2;
            float cYParent = parentInfo[1] + parentInfo[3] / 2;

            float cXChild = x + width / 2;
            float cYChild = y + height / 2;

            PointF rotatedCenterPoint = getRotatedPoint(new PointF(cXChild, cYChild), new PointF(cXParent, cYParent), parentInfo[4]);

            angle = tempAngle + parentInfo[4];
            out[0] = rotatedCenterPoint.x - width / 2;
            out[1] = rotatedCenterPoint.y - height / 2;
            out[2] = width;
            out[3] = height;
            out[4] = angle;


            if (checkIfPointIsInRect(new RectF(out[0], out[1], out[0] + out[2], out[1] + out[3]), angle, new PointF(touchX, touchY))) {
                out[5] = 1;
            } else {
                out[5] = 0;
            }
            out[6] = parentInfo[2]; // Send the Parents Width so we dont need to calculate again
            out[7] = parentInfo[3]; // Send the Parents Height so we dont need to calculate again

            if (flipHorizontal == 0 && model.flipHorizontal == 0) {
                flipHorizontal = 0;
            } else if (flipHorizontal == 1 && model.flipHorizontal == 0) {
                flipHorizontal = 1;
            } else if (flipHorizontal == 0 && model.flipHorizontal == 1) {
                flipHorizontal = 1;
            } else if (flipHorizontal == 1 && model.flipHorizontal == 1) {
                flipHorizontal = 0;
            }

            if (flipVertical == 0 && model.flipVertical == 0) {
                flipVertical = 0;
            } else if (flipVertical == 1 && model.flipVertical == 0) {
                flipVertical = 1;
            } else if (flipVertical == 0 && model.flipVertical == 1) {
                flipVertical = 1;
            } else if (flipVertical == 1 && model.flipVertical == 1) {
                flipVertical = 0;
            }

            out[8] = flipHorizontal;
            out[9] = flipVertical;

        } else {
            // get page Model
            Model pageModel = getPage(modelId);
            if (pageModel == null) {

                out[5] = 0;
                return out;
                //  throw new RuntimeException("How did this happend");
            }

            out[0] = x;
            out[1] = y;
            out[2] = pageWidth * pageModel.width;
            out[3] = pageHeight * pageModel.height;
            out[4] = angle;
            if (checkIfPointIsInRect(new RectF(out[0], out[1], out[0] + out[2], out[1] + out[3]), angle, new PointF(touchX, touchY))) {
                out[5] = 1;
            } else {
                out[5] = 0;
            }
            out[6] = surfaceWidth;
            out[7] = surfaceHeight;
            out[8] = pageModel.flipHorizontal;
            out[9] = pageModel.flipVertical;


        }
//        if(checkIfPointIsInRect(new RectF(x,y,x+width,y+height),angle,new PointF(touchX,touchY))){
//            out[5] = 1;
//        } else{
//            out[5] = 0;
//        }
        return out;
    }

    private boolean checkIfPointIsInRect(RectF rect, float angle, PointF point) {
        //

        PointF pivotPoint = new PointF(rect.left + rect.width() / 2, rect.top + rect.height() / 2);
        PointF rotatedLeftTop = getRotatedPoint(new PointF(rect.left, rect.top), pivotPoint, angle);
        PointF rotatedLeftBottom = getRotatedPoint(new PointF(rect.left, rect.bottom), pivotPoint, angle);
        PointF rotatedRightTop = getRotatedPoint(new PointF(rect.right, rect.top), pivotPoint, angle);
        PointF rotatedRightBottom = getRotatedPoint(new PointF(rect.right, rect.bottom), pivotPoint, angle);

        // Area of Rect
        float area_Of_Rect = rect.width() * rect.height();

        float areaOfTriangle1 = areaOfTriangle(point, rotatedLeftTop, rotatedLeftBottom);
        float areaOfTriangle2 = areaOfTriangle(point, rotatedLeftBottom, rotatedRightBottom);
        float areaOfTriangle3 = areaOfTriangle(point, rotatedRightBottom, rotatedRightTop);
        float areaOfTriangle4 = areaOfTriangle(point, rotatedRightTop, rotatedLeftTop);
        float totalArea = areaOfTriangle1 + areaOfTriangle2 + areaOfTriangle3 + areaOfTriangle4;
        if (totalArea > area_Of_Rect + 1) {
            return false;
        } else {
            return true;
        }

    }

    private float areaOfTriangle(PointF point1, PointF point2, PointF point3) {
        float area = Math.abs((point1.x * (point2.y - point3.y) + point2.x * (point3.y - point1.y) + point3.x * (point1.y - point2.y)) / 2);
        return area;
    }

    public TimelineModel getTimeLineModelForParent(int modelId) {
        // Check if Model Exists
        boolean isModelTypePage = false;
        Model model = getModel(modelId);
        if (model == null) {
            // check if is page
            model = getPage(modelId);
            if (model == null) {
                throw new RuntimeException("Cannot find Model" + modelId);
            } else {
                isModelTypePage = true;
            }
        }
        // You should have a Model now
        TimelineModel timelineModel = new TimelineModel(modelId);
        timelineModel.setImage(model.modelThumbnailBitmap);
        timelineModel.setModelType(isModelTypePage ? ModelType.PAGE : model.modelType);
        float realStartTimeOfModel = getRealTimeOfModel(model);
        timelineModel.setmStartTime(realStartTimeOfModel);
        timelineModel.setmDuration(model.duration);
        // Check Child Models
        for (int i = 0; i < model.childlist.size(); i++) {
            Model childModel = model.childlist.get(i);
            if (!childModel.removeFlag && childModel.getModelType() != ModelType.WATERMARK) { // not adding watermark type model in list
                TimelineModel childTimeLine = new TimelineModel(childModel.modelId);
                childTimeLine.setmStartTime(realStartTimeOfModel + childModel.startTime);
                childTimeLine.setmDuration(childModel.duration);
                childTimeLine.setModelType(childModel.modelType);
                childTimeLine.setImage(childModel.modelThumbnailBitmap);
                timelineModel.addChildTimeLineModel(childTimeLine);
            }
        }
        return timelineModel;
    }

    public float[] getAnimationTimes(int modelId) {
        float[] actualTime = new float[6];
        Model model = getModel(modelId);
        if (model == null) {
            // check if is page
            model = getPage(modelId);
            if (model == null) {
                throw new RuntimeException("Cannot find Model" + modelId);
            }
        }
        float realtime = getRealTimeOfModel(model);
        // InStart - In End - Loop Start - Loop End - Out Start - Out End
        float inStartTime = 0f;
        float inEndTime = 0f;
        float outStartTime = 0f;
        float outEndTime = 0f;
        float loopStartTime = 0f;
        float loopEndTime = 0f;
        //TODO What if the Parent is tripping the TIMELINE OF CHILD
        if (model.animationInTemplateId != 1) {
            inStartTime = realtime;
            inEndTime = inStartTime + model.animationInDuration;
        } else {
            inStartTime = realtime;
            inEndTime = realtime;
        }

        if (model.animationOutTemplateId != 1) {
            outStartTime = realtime + model.duration - model.animationOutDuration;
            outEndTime = realtime + model.duration;
        } else {
            outStartTime = realtime + model.duration;
            outEndTime = outStartTime;
        }
        if (model.animationLoopTemplateId != 1) {
            loopStartTime = inEndTime;
            loopEndTime = loopStartTime + model.animationLoopDuration * 2;
        }
        actualTime[0] = inStartTime;
        actualTime[1] = inEndTime;
        actualTime[2] = outStartTime;
        actualTime[3] = outEndTime;
        actualTime[4] = loopStartTime;
        actualTime[5] = loopEndTime;

        return actualTime;
    }

    public float getRealTimeOfModel(int modelId) {
        // find model
        float realtime = 0;
        Model model = getModel(modelId);
        if (model == null) {
            model = getPage(modelId);
        }
        if (model != null) {
            realtime = getRealTimeOfModel(model);
        }
        return realtime;
    }

    private float getRealTimeOfModel(Model model) {
        if (model.parent == null) {
            return model.startTime;
        } else {
            return getRealTimeOfModel(model.parent) + model.startTime;
        }
    }

    public TimelineModel getTimeLineModelForTemplate() {


        TimelineModel timelineModel = new TimelineModel(0);
        timelineModel.setImage(null); // TODO there should be a image for Template and should be in Scene

        timelineModel.setmStartTime(0);
        timelineModel.setmDuration(getTotalTimeForScene());
        // Check Child Models
        for (int i = 0; i < scene.models.size(); i++) {
            Model childModel = scene.models.get(i);
            if (!childModel.removeFlag) {
                TimelineModel childTimeLine = new TimelineModel(childModel.modelId);
                childTimeLine.setmStartTime(childModel.startTime);
                childTimeLine.setmDuration(childModel.duration);
                //childTimeLine.setModelType(childModel.modelType);
                childTimeLine.setModelType(ModelType.PAGE);
                childTimeLine.setImage(childModel.modelThumbnailBitmap);
                timelineModel.addChildTimeLineModel(childTimeLine);
            }
        }
        return timelineModel;
    }

    public ArrayList<ColorModel> getColorDataForTemplate() {
        ArrayList<ColorModel> colorDataList = new ArrayList<>();

        // Check Child Models
        for (int i = 0; i < scene.models.size(); i++) {
            getColorDataForModel(scene.models.get(i).modelId, colorDataList);
        }

        return colorDataList;
    }

    public ArrayList<ColorModel> getColorDataForParent(int parentId) {
        ArrayList<ColorModel> colorDataList = new ArrayList<>();

        getColorDataForModel(parentId, colorDataList);

        return colorDataList;
    }

    private void getColorDataForModel(int parentId, ArrayList<ColorModel> colorDataList) {
        Model model = getModel(parentId);
        if (model == null) {
            model = getPage(parentId);
        }

        if (model == null) {
            throw new RuntimeException("model id " + parentId + " not found");
        }

        if (model.isRemoveFlag()){
            return;
        }

        if (model.modelType == ModelType.PARENT && model instanceof ParentModel){
            ParentModel parentModel = (ParentModel) model;

            //add model color in hashmap
            if (parentModel.backgroundType == 0){

                addColorDataIntoList(colorDataList, Color.argb(parentModel.alpha, parentModel.red, parentModel.green, parentModel.blue));

            } else if (parentModel.backgroundType == 3){
                addColorDataIntoList(colorDataList, Color.argb(255, parentModel.color1Red, parentModel.color1Green, parentModel.color1Blue));
                addColorDataIntoList(colorDataList, Color.argb(255, parentModel.color2Red, parentModel.color2Green, parentModel.color2Blue));
            }

            // Check Child Models
            for (int i = 0; i < model.childlist.size(); i++) {
                getColorDataForModel(model.childlist.get(i).modelId, colorDataList);
            }
        } else if (model.modelType == ModelType.TEXT && model instanceof TextModel){

            TextModel textModel = (TextModel) model;
            addColorDataIntoList(colorDataList, textModel.textColor);
            addColorDataIntoList(colorDataList, textModel.shadowColor);
            addColorDataIntoList(colorDataList, Color.argb(textModel.alpha, textModel.red, textModel.green, textModel.blue));

        } else if (model.modelType == ModelType.IMAGE && model instanceof ImageModel){

            ImageModel imageModel = (ImageModel) model;
            if (imageModel.colorFilter == 2) { // checking if color(2) applied
                addColorDataIntoList(colorDataList, Color.argb(255, imageModel.colorFilterRed, imageModel.colorFilterGreen, imageModel.colorFilterBlue));
            }
        }
    }

    private void addColorDataIntoList(ArrayList<ColorModel> colorDataList, int color){
        if (Color.alpha(color) != 0) {// not inserting transparent color
            int colorDataIndex = getColorDataIndex(color, colorDataList);

            if (colorDataIndex == NO_DATA) {
                colorDataList.add(new ColorModel(color, 1));
            } else {
                ColorModel colorModel = colorDataList.get(colorDataIndex);
                colorModel.setColorCount(colorModel.getColorCount() + 1);
            }
        }
    }

    private int getColorDataIndex(int color, ArrayList<ColorModel> colorDataList){
        for (int i = 0; i < colorDataList.size(); i++){
            if (colorDataList.get(i).getColor() == color){
                return i;
            }
        }
        return NO_DATA;
    }

    public LayerModel getLayerInfoForModel(int modelId) {
        // Check if Model Exists
        Model model = getModel(modelId);
        if (model == null) {
            // check if is page
            model = getPage(modelId);
            if (model == null) {
                throw new RuntimeException("Cannot find Model" + modelId);
            }
        }
        LayerModel layerModel = new LayerModel();
        // Check if it has any childs
        layerModel.setId(modelId);
        layerModel.setBitmap(model.modelThumbnailBitmap);
        layerModel.setModelType(model.getModelType());
        layerModel.setLocked(model.isLocked);
        if (model.parent != null) {
            layerModel.setParentId(model.parent.modelId);
        } else {
            layerModel.setParentId(-1);
        }
        layerModel.setChildList(new ArrayList<LayerModel>());
        for (int i = 0; i < model.childlist.size(); i++) {
            if (!model.childlist.get(i).removeFlag) {
                if (model.childlist.get(i).getModelType() != ModelType.WATERMARK) { // not adding watermark type model in list
                    LayerModel child = getLayerInfoForModel(model.childlist.get(i).modelId);
                    // Insert into the layerModelChildList
                    layerModel.getChildList().add(child);
                }
            }
        }
        return layerModel;
    }

    public Bitmap getModelThumbnail(int modelId) {
        // Check if model exists
        Model model = getModel(modelId);
        if (model == null) {
            // check if is page
            model = getPage(modelId);
            if (model == null) {
                return null;
            }
        }
        return model.getModelThumbnailBitmap();
    }

    public ModelType getModeType(int modelId) {
        Model model = getModel(modelId);
        if (model == null) {
            return null;
        }
        return model.modelType;

    }

    public float getThumbNailRenderingTime() {
        return thumbNailRenderingTime;
    }

    public void setThumbNailRenderingTime(float thumbNailRenderingTime) {
        this.thumbNailRenderingTime = thumbNailRenderingTime;
    }

    public int getDesignId() {
        return designId;
    }

    public void setDesignId(int designId) {
        this.designId = designId;

    }


    public boolean changeText(int modelId, String newText) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setText(newText);
                ((TextModel) model).contentChangeFlag = true;
                ((TextModel) model).contentTextFlag = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeText(int modelId, String newText, PointF pos, SizeF size) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setText(newText);
                moveModel(modelId, pos.x, pos.y, size.getWidth(), size.getHeight(), model.getAngle(), size.getWidth(), size.getHeight(), true);
                ((TextModel) model).contentChangeFlag = true;
                ((TextModel) model).contentTextFlag = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeTextFont(int modelId, Typeface typeface) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setFontTypeface(typeface);
                ((TextModel) model).contentChangeFlag = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeTextAlignment(int modelId, TextModel.TextAlignment textAlignment) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setTextAlignment(textAlignment);
                ((TextModel) model).contentChangeFlag = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeTextLineSpacing(int modelId, float lineSpacing) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setLineSpacing(lineSpacing);
                ((TextModel) model).contentChangeFlag = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeTextLetterSpacing(int modelId, float letterSpacing) {
        // Find the Model
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setLetterSpacing(letterSpacing);
                ((TextModel) model).contentChangeFlag = true;
                didSucceed = true;
                refreshThumbnails = true;
                setDataChanged(true);
            }

            return didSucceed;
        }
    }

    public SizeF getNewTextRect(int modelId, String newText) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return null;
            }
            if (model instanceof TextModel) {
                if (model.parent == null) {
                    throw new RuntimeException("Models Parent is null ");
                }
                float[] dimensionsAsPerRoot = getModelDimensionsAsPerRoot(model.parent.modelId);
                float parentWidthFloat = dimensionsAsPerRoot[2];// * mRatioWidth;
                float parentHeightFloat = dimensionsAsPerRoot[3];//* mRatioHeight;
                // The ParentWidth is already considering the Page Ratio
                // So reversing it
                parentWidthFloat = parentWidthFloat / scene.ratioWidth;
                parentHeightFloat = parentHeightFloat / scene.ratioHeight;

                int parentWidth = (int) (parentWidthFloat * pageWidth);
                int parentHeight = (int) (parentHeightFloat * pageHeight);
                SizeF newTextSize = ((TextModel) model).getNewTextSize(parentWidth, parentHeight, newText);
                return new SizeF((float) newTextSize.getWidth() / parentWidth, (float) newTextSize.getHeight() / parentHeight);
            }

            return null;
        }
    }

    public SizeF getModelParentSizeInPx(int modelId) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return null;
            }

            if (model.parent == null) {
                throw new RuntimeException("Models Parent is null ");
            }
            float[] dimensionsAsPerRoot = getModelDimensionsAsPerRoot(model.parent.modelId);
            float parentWidthFloat = dimensionsAsPerRoot[2];// * mRatioWidth;
            float parentHeightFloat = dimensionsAsPerRoot[3];//* mRatioHeight;
            // The ParentWidth is already considering the Page Ratio
            // So reversing it
            parentWidthFloat = parentWidthFloat / scene.ratioWidth;
            parentHeightFloat = parentHeightFloat / scene.ratioHeight;

            int parentWidth = (int) (parentWidthFloat * pageWidth);
            int parentHeight = (int) (parentHeightFloat * pageHeight);

            return new SizeF(parentWidth, parentHeight);

        }
    }

    public SizeF getNewTextRect(int modelId, int textSize) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return null;
            }
            if (model instanceof TextModel) {
                float[] dimensionsAsPerRoot = getModelDimensionsAsPerRoot(model.parent.modelId);
                float parentWidthFloat = dimensionsAsPerRoot[2];// * mRatioWidth;
                float parentHeightFloat = dimensionsAsPerRoot[3];//* mRatioHeight;
                int parentWidth = (int) parentWidthFloat * pageWidth;
                int parentHeight = (int) parentHeightFloat * pageHeight;


                SizeF newTextSize = ((TextModel) model).getNewTextSize(parentWidth, parentHeight, textSize);
                return new SizeF((float) newTextSize.getWidth() / parentWidth, (float)
                        newTextSize.getHeight() / parentHeight);
            }

            return null;
        }
    }

    public boolean changeTextColor(int modelId, int color) {
        // Find the Model
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setTextColor(color);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
            }
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean setTextBackgroundColor(int modelId, int red, int green, int blue, int alpha) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                model = getPage(modelId);
            }
            if (model != null) {
                // Check if model is Parent
                if (model instanceof TextModel) {
                    ((TextModel) model).setBackgroundColor(red, green, blue, alpha);
                    refreshThumbnails = true;
                    setDataChanged(true);
                    didSucceed = true;
                }

            } else {

            }

            return didSucceed;
        }
    }

    public boolean changeModelOpacity(int modelId, int opacity) {
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (opacity < 0 || opacity > 255) {
                throw new RuntimeException("Opacity value " + opacity + " not between 0 to 255");
            }
            model.opacity = opacity;
            model.opacityChangeFlag = true;
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeFlipHorizontal(int modelId) {
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model.flipHorizontal == 0) {
                model.flipHorizontal = 1;
            } else {
                model.flipHorizontal = 0;
            }

            model.flipChangeFlag = true;
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeFlipVertical(int modelId) {
        synchronized (lock) {
            Model model = getModel(modelId);
            if (model == null) {
                return false;
            }
            if (model.flipVertical == 0) {
                model.flipVertical = 1;
            } else {
                model.flipVertical = 0;
            }
            model.flipChangeFlag = true;
            refreshThumbnails = true;
            setDataChanged(true);
            return true;
        }
    }

    public boolean changeTextModelShadowColor(int modelId, int shadowColor) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setShadowColor(shadowColor);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    public boolean changeTextModelShadowOpacity(int modelId, int shadowOpacity) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setShadowOpacity(shadowOpacity);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    public boolean changeTextModelShadowRadius(int modelId, float shadowRadius) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setShadowRadius(shadowRadius);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    public boolean changeTextModelShadowDx(int modelId, float deltaX) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setShadowDx(deltaX);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    public boolean changeTextModelShadowDy(int modelId, float deltaY) {
        synchronized (lock) {
            boolean didSucceed = false;
            Model model = getModel(modelId);
            if (model == null) {
                return didSucceed;
            }
            if (model instanceof TextModel) {
                ((TextModel) model).setShadowDy(deltaY);
                ((TextModel) model).contentChangeFlag = true;
                refreshThumbnails = true;
                setDataChanged(true);
                didSucceed = true;
            }
            return didSucceed;
        }
    }

    public SizeF getSceneRatio() {
        return new SizeF(scene.ratioWidth, scene.ratioHeight);
    }

    public Scene getSceneCopy() {
        Scene newScene = new Scene(scene.sceneName);
        newScene.ratioWidth = scene.ratioWidth;
        newScene.ratioHeight = scene.ratioHeight;
        // Loop Thorough each model in the scene
        for (int i = 0; i < scene.models.size(); i++) {
            Model model = getCopyOfModel(scene.models.get(i), null);
//            model.x = 0;
//            model.y = 0;
//            model.width = 1.0f;
//            model.height = 1.0f;
            newScene.addModel(model);
        }
        return newScene;
    }

    private Model getCopyOfModel(Model model, Model parent) {
        // Check if this is an instance of model
        if (model instanceof ParentModel) {

            ParentModel copiedModel = new ParentModel(null, model.modelId, parent, model.x, model.y, model.width,
                    model.height, model.angle, model.previousAvailableWidth, model.previousAvailableHeight, model.opacity, model.flipHorizontal, model.flipVertical, model.isLocked, model.startTime, model.duration, model.getSequenceInParent());
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.IN, model.animationInTemplateId, model.animationInDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.OUT, model.animationOutTemplateId, model.animationOutDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.LOOP, model.animationLoopTemplateId, model.animationLoopDuration);
            if (((ParentModel) model).backgroundType == 0) {
                copiedModel.setBackgroundColor(((ParentModel) model).red, ((ParentModel) model).green, ((ParentModel) model).blue, ((ParentModel) model).alpha);
            } else if (((ParentModel) model).backgroundType == 1) {
                copiedModel.setBackgroundImage(((ParentModel) model).backgroundBitmap, ((ParentModel) model).backgroundBlurPercentage, ((ParentModel) model).backgroundImagePathOrAsset, ((ParentModel) model).backgroundImageType, ((ParentModel) model).backgroundImageIsEncrypted, ((ParentModel) model).backgroundImageCropX,
                        ((ParentModel) model).backgroundImageCropY, ((ParentModel) model).backgroundImageCropW, ((ParentModel) model).backgroundImageCropH);
            } else if (((ParentModel) model).backgroundType == 2) {
                copiedModel.setBackgroundTileImage(((ParentModel) model).backgroundBitmap, ((ParentModel) model).backgroundBlurPercentage, ((ParentModel) model).tileMultiple);
            } else if (((ParentModel) model).backgroundType == 3) {
                if (((ParentModel) model).gradientType == 0) {
                    // Gradient Linear
                    copiedModel.setBackgroundGradientLinear(((ParentModel) model).color1Red, ((ParentModel) model).color1Green, ((ParentModel) model).color1Blue, ((ParentModel) model).color2Red, ((ParentModel) model).color2Green, ((ParentModel) model).color2Blue, ((ParentModel) model).gradientAngle, ((ParentModel) model).backgroundBlurPercentage);
                } else {
                    // Gradiendt Radial
                    copiedModel.setBackgroundGradientRadial(((ParentModel) model).color1Red, ((ParentModel) model).color1Green, ((ParentModel) model).color1Blue, ((ParentModel) model).color2Red, ((ParentModel) model).color2Green, ((ParentModel) model).color2Blue, ((ParentModel) model).gradientRadius, ((ParentModel) model).backgroundBlurPercentage);
                }
            }
            if (copiedModel.overlayImagePath != "" || copiedModel.overlayImageBitmap != null) {
                copiedModel.setOverlayImage(((ParentModel) model).overlayImageBitmap, ((ParentModel) model).overlayImageOpacity);
            }
            for (int i = 0; i < model.childlist.size(); i++) {
                Model childmodel = model.childlist.get(i);
                Model copiedChildModel = getCopyOfModel(childmodel, copiedModel);
                copiedModel.childlist.add(copiedChildModel);
            }

            return copiedModel;
        } else if (model instanceof ImageModel) {
            ImageModel copiedModel = new ImageModel(model.getModelType(), null, model.modelId, parent, ((ImageModel) model).pathOrAsset, ((ImageModel) model).imageType, ((ImageModel) model).isEncrypted,
                    ((ImageModel) model).bitmap, model.x, model.y, model.width,
                    model.height, model.angle, ((ImageModel) model).cropX, ((ImageModel) model).cropY, ((ImageModel) model).cropW,
                    ((ImageModel) model).cropH, ((ImageModel) model).cropStyle,
                    model.previousAvailableWidth, model.previousAvailableHeight, model.opacity, model.flipHorizontal, model.flipVertical, model.isLocked, model.startTime, model.duration, model.getSequenceInParent());
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.IN, model.animationInTemplateId, model.animationInDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.OUT, model.animationOutTemplateId, model.animationOutDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.LOOP, model.animationLoopTemplateId, model.animationLoopDuration);
//            for(int i= 0; i<model.childlist.size(); i++){
//                Model childmodel = model.childlist.get(i);
//                copiedModel.childlist.add(getCopyOfModel(childmodel));
//            }
            return copiedModel;
        } else if (model instanceof TextModel) {
            TextModel copiedModel = new TextModel(null, null, model.modelId, parent,
                    ((TextModel) model).getText(), ((TextModel) model).fontTypeface, ((TextModel) model).getTextColor(), ((TextModel) model).lineSpacing, ((TextModel) model).letterSpacing, ((TextModel) model).textAlignment
                    , ((TextModel) model).shadowRadius, ((TextModel) model).shadowDx, ((TextModel) model).shadowDy, ((TextModel) model).shadowColor, ((TextModel) model).shadowOpacity, ((TextModel) model).internalWidthMargin, ((TextModel) model).internalHeightMargin,
                    model.x, model.y, model.width, model.height, model.angle,
                    model.previousAvailableWidth, model.previousAvailableHeight, model.opacity, model.flipHorizontal, model.flipVertical, model.isLocked, model.startTime, model.duration, model.getSequenceInParent(), false);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.IN, model.animationInTemplateId, model.animationInDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.OUT, model.animationOutTemplateId, model.animationOutDuration);
            copiedModel.setModelAnimation(contextWeakReference.get(), AnimationType.LOOP, model.animationLoopTemplateId, model.animationLoopDuration);
//            for(int i= 0; i<model.childlist.size(); i++){
//                Model childmodel = model.childlist.get(i);
//                copiedModel.childlist.add(getCopyOfModel(childmodel));
//            }
            return copiedModel;
        } else {
            throw new RuntimeException("Model is base model");
        }
    }

    public boolean setScene(Scene scene) {
        this.scene = scene;
        return true;
    }

    public int getModelIndex(int modelId) {
        int modelIndex = -1;
        // check if valid model

        Model model = getModel(modelId);
        if (model == null) {
            // do nothing will send -1
        } else {
            // check if has valid parent
            if (model.parent == null) {
                // do nothing - will send -1
            } else {
                // we need to find whats the index
                modelIndex = model.parent.childlist.indexOf(model);
            }
        }
        return modelIndex;
        // get Parent of the Model

    }

    public ArrayList<Integer> getModelHierarchyForModel(int modelId) {
        // We need to find the Models Parents until its Parent is a Page
        Model model = getModel(modelId);
        if (model != null) {
            ArrayList<Integer> modelHeierarchy = new ArrayList<>();
            modelHeierarchy.add(modelId);
            while (model.parent != null) {
                model = model.parent;
                modelHeierarchy.add(model.modelId);
            }
            return modelHeierarchy;
        }
        return null;
    }

    public String getSequenceNumberAsPerPage(Integer modelId) {
        String sequenceNumber = "";
        Model model = getModel(modelId);
        while (model != null) {
            sequenceNumber = String.format("%02d", model.getSequenceInParent()) + "." + sequenceNumber;
            int parentId = getParentIdOfModel(model.modelId);
            model = getModel(parentId);
        }
        if(debug) Log.i("GroupItems", " Sequence Number of Model " + modelId + " is " + sequenceNumber);
        return sequenceNumber;


    }


    public void onTemplateThumbnailChanged(Bitmap bitmap, int errorCode, float requestedTimeToRender) {
        // This is on Main Thread..
        // tell to the Listener
        // Crop the Bitmap as per the Ratio required
        int bitmapWidth = bitmap.getWidth();
        int bitmapHeight = (int) (bitmapWidth * scene.ratioHeight / scene.ratioWidth);
        // lets try with width first
        if (bitmapHeight > bitmap.getHeight()) {
            bitmapHeight = bitmap.getHeight();
            bitmapWidth = (int) (bitmapHeight * scene.ratioWidth / scene.ratioHeight);
        }
        // Crop it if required
        if (bitmapWidth != bitmap.getWidth() || bitmapHeight != bitmap.getHeight()) {
            //
            Matrix matrix = new Matrix();
            // Cut the  THE BIT MAP
            int x = (bitmap.getWidth() - bitmapWidth) / 2;
            int y = (bitmap.getHeight() - bitmapHeight) / 2;

            Bitmap croppedBitmap = Bitmap.createBitmap(bitmap, x, y, bitmapWidth, bitmapHeight, matrix, false);
            if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                sceneManagerListenerWeakReference.get().onTemplateImageChanged(croppedBitmap, errorCode, requestedTimeToRender);
            } else {
                String crashMsg = "Crash in SceneManager.onTemplateThumbnailChanged. sceneManagerListenerWeakReference is null : " + (sceneManagerListenerWeakReference == null)
                        + " or sceneManagerListenerWeakReference.get() == null : " + (sceneManagerListenerWeakReference.get() == null);
                CrashlyticsTracker.report(new RuntimeException(crashMsg), crashMsg);
                if(debug) Log.i("RBTest", crashMsg);
            }
        } else {
            if (sceneManagerListenerWeakReference != null && sceneManagerListenerWeakReference.get() != null) {
                sceneManagerListenerWeakReference.get().onTemplateImageChanged(bitmap, errorCode, requestedTimeToRender);
            } else {
                String crashMsg = "Crash in SceneManager.onTemplateThumbnailChanged. sceneManagerListenerWeakReference is null : " + (sceneManagerListenerWeakReference == null)
                        + " or sceneManagerListenerWeakReference.get() == null : " + (sceneManagerListenerWeakReference.get() == null);
                CrashlyticsTracker.report(new RuntimeException(crashMsg), crashMsg);
                if(debug) Log.i("RBTest", crashMsg);
            }
        }


    }

    public long getRendererPointer() {
        return rendererObjectPointer;
    }

    public void setRendererPointer(long rendererPointer) {
        rendererObjectPointer = rendererPointer;
    }


    public void updateAllThumbnails() {
        if (glThreadNativeListenerWeakReference != null && glThreadNativeListenerWeakReference.get() != null) {
            // We need different TimeSlices for the Level 1 and Level 2

            NativeBrigde.updateThumb(glThreadNativeListenerWeakReference.get(), rendererObjectPointer, 0, true);
        }
    }

    public RectF getViewPortOfPage(){
        RectF viewPort = new RectF(offsetX,offsetY,pageWidth + offsetX, pageHeight + offsetY);
        return viewPort;
    }
}
