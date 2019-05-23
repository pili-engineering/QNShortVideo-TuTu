package com.qiniu.pili.droid.shortvideo.demo.tusdk;

/**
 * @author xujie
 * @Date 2018/11/26
 */

public class TuConfig {
    // 录制滤镜 code 列表, 每个 code 代表一种滤镜效果, 具体 code 可在 lsq_tusdk_configs.json 查看 (例如:lsq_filter_SkinNature02 滤镜的 code 为 SkinNature02)
    public static final String[] CAMERA_FILTER_CODES = new String[]{"none", "SkinNature10_1","SkinPink10_1","SkinJelly10_1","SkinRuddy10_1","SkinSoft10_1"};

    public static final String[] VIDEO_EDIT_FILTERS = new String[]{"none","Relaxed_1","Instant_1","Artistic_1","Olympus_1",
            "Beautiful_1","Elad_1","Green_1","Qiushi_1","Winter_1","Elegant_1","Vatican_1","Leica_1","Gloomy_1","SilentEra_1","s1950_1"};

    // 漫画代号
    public static final String[] VIDEO_CARTOON_CODES = new String[]{
            "none","CHComics_Video","USComics_Video","JPComics_Video","Lightcolor_Video","Ink_Video","Monochrome_Video"};
}
