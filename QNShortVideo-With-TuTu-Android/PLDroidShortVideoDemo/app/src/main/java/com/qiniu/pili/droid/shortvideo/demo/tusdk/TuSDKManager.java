package com.qiniu.pili.droid.shortvideo.demo.tusdk;


import android.content.Context;

import org.lasque.tusdk.api.engine.TuSdkFilterEngine;
import org.lasque.tusdk.api.engine.TuSdkFilterEngineImpl;
import org.lasque.tusdk.api.video.preproc.filter.TuSDKFilterEngine;
import org.lasque.tusdk.core.utils.image.ImageOrientation;
import org.lasque.tusdk.video.editor.TuSdkMediaEffectData;
import org.lasque.tusdk.video.editor.TuSdkMediaFilterEffectData;
import org.lasque.tusdk.video.editor.TuSdkMediaSceneEffectData;
import org.lasque.tusdk.video.editor.TuSdkTimeRange;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

public class TuSDKManager {
    // 特效信息集合
    private volatile List<TuSdkMediaEffectData> mSavedMediaEffects = new ArrayList<>();
    private LinkedList<TuSdkMediaEffectData> mDataList = new LinkedList<>();

    // TuSDK 处理引擎 负责预览时处理
    private TuSdkFilterEngine mPreviewFilterEngine;

    // TuSDK 处理引擎 负责保存时处理
    private TuSdkFilterEngine mSaveFilterEngine;

    private Context mContext;

    public TuSDKManager(Context context) {
        mContext = context;
    }

    /**
     * 初始化预览 TuSdkFilterEngine
     */
    public void setupPreviewFilterEngine() {
        if (mPreviewFilterEngine != null) return;
        mPreviewFilterEngine = createFilterEngine();
    }

    /**
     * 初始化保存 TuSdkFilterEngine
     */
    public void setupSaveFilterEngine() {
        if (mSaveFilterEngine != null) return;
        mSaveFilterEngine = createFilterEngine();
    }

    /**
     * 获取预览 TuSDKFilterEngine
     */
    public TuSdkFilterEngine getPreviewFilterEngine() {
        return mPreviewFilterEngine;
    }

    /**
     * 获取保存 TuSDKFilterEngine
     */
    public TuSdkFilterEngine getSaveFilterEngine() {
        return mSaveFilterEngine;
    }

    /**
     * 销毁预览 TuSDKFilterEngine
     */
    public void destroyPreviewFilterEngine() {
        if (mPreviewFilterEngine != null) {
            mPreviewFilterEngine.release();
            mPreviewFilterEngine = null;
        }
    }

    /**
     * 销毁保存 TuSDKFilterEngine
     */
    public void destroySaveFilterEngine() {
        if (mSaveFilterEngine != null) {
            mSaveFilterEngine.release();
            mSaveFilterEngine = null;
        }
    }

    /**
     * 添加一个场景特效信息
     *
     * @param magicModel
     */
    public synchronized void addMagicModel(TuSdkMediaSceneEffectData magicModel) {
        mPreviewFilterEngine.addMediaEffectData(magicModel);
        mDataList.add(magicModel);
    }

    /**
     * 删除一个场景特效信息
     *
     * @param magicModel
     */
    public synchronized void removeMagicModel(TuSdkMediaEffectData magicModel) {
        mPreviewFilterEngine.removeMediaEffectData(magicModel);
        mDataList.remove(magicModel);
    }

    /**
     * 清除场景特效
     */
    public synchronized void reset() {
        this.mSavedMediaEffects.clear();
        this.mPreviewFilterEngine.removeAllMediaEffects();
    }

    public void saveState() {
        mSavedMediaEffects = getAllMediaEffects();
    }

    public void resumeState() {
        for (TuSdkMediaEffectData data : mSavedMediaEffects)
            mPreviewFilterEngine.addMediaEffectData(data);
    }


    public List<TuSdkMediaEffectData> getAllMediaEffects() {
        List<TuSdkMediaEffectData> copyMediaEffects = new ArrayList<>();

        List<TuSdkMediaEffectData> mediaEffects = mPreviewFilterEngine.getAllMediaEffectData();
        for (TuSdkMediaEffectData effectData : mediaEffects)
            copyMediaEffects.add(effectData.clone());

        return  copyMediaEffects;
    }

    /**
     * 获取当前正在编辑的最后一个特效信息
     *
     * @return 特效信息
     */
    public synchronized TuSdkMediaEffectData getLastMagicModel() {
        return mDataList.getLast();
    }

    /**
     * 根据Code获取滤镜特效对象
     * @param filterCode
     * @return
     */
    public TuSdkMediaFilterEffectData createFilterEffectData(String filterCode)
    {
        TuSdkMediaFilterEffectData filterEffectData = new TuSdkMediaFilterEffectData(filterCode);
        filterEffectData.setAtTimeRange(TuSdkTimeRange.makeRange(0,Float.MAX_VALUE));
        return filterEffectData;
    }


    /**
     * 根据SceneCode获取场景特效对象
     * @param sceneCode
     * @return
     */
    public TuSdkMediaSceneEffectData createSceneEffectData(String sceneCode, float starTime)
    {
        TuSdkMediaSceneEffectData sceneEffectData = new TuSdkMediaSceneEffectData(sceneCode);
        sceneEffectData.setAtTimeRange(TuSdkTimeRange.makeRange(starTime,Float.MAX_VALUE));
        return sceneEffectData;
    }

    private TuSdkFilterEngine createFilterEngine() {
        // 美颜处理
        TuSdkFilterEngine filterEngine = new TuSdkFilterEngineImpl(false, true);

        // 设置是否输出原始图片朝向 false: 图像被转正后输出
        filterEngine.setOriginalCaptureOrientation(true);
        // 设置输入的图片朝向 如果输入的图片不是原始朝向 该选项必须配置
        filterEngine.setInputImageOrientation(ImageOrientation.Up);
        // 设置是否开启动态贴纸功能
        filterEngine.setEnableLiveSticker(true);
        return filterEngine;
    }


}
