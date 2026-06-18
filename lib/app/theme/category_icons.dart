import 'package:flutter/cupertino.dart';

/// Curated set of icons a category can use. Stored in the DB as a stable string
/// key (the map key) rather than a raw [IconData] codepoint — that keeps
/// `--no-tree-shake-icons` unnecessary and survives Flutter upgrades.
const Map<String, IconData> kCategoryIcons = {
  'bolt': CupertinoIcons.bolt,
  'bandage': CupertinoIcons.bandage,
  'sparkles': CupertinoIcons.sparkles,
  'drop': CupertinoIcons.drop,
  'flame': CupertinoIcons.flame,
  'heart': CupertinoIcons.heart,
  'moon': CupertinoIcons.moon,
  'sun': CupertinoIcons.sun_max,
  'cloud': CupertinoIcons.cloud,
  'cloud_rain': CupertinoIcons.cloud_rain,
  'bed': CupertinoIcons.bed_double,
  'eye': CupertinoIcons.eye,
  'bell': CupertinoIcons.bell,
  'alarm': CupertinoIcons.alarm,
  'hourglass': CupertinoIcons.hourglass,
  'gift': CupertinoIcons.gift,
  'airplane': CupertinoIcons.airplane,
  'car': CupertinoIcons.car_detailed,
  'house': CupertinoIcons.house,
  'briefcase': CupertinoIcons.briefcase,
  'person': CupertinoIcons.person,
  'star': CupertinoIcons.star,
  'music': CupertinoIcons.music_note,
  'flask': CupertinoIcons.lab_flask,
  'leaf': CupertinoIcons.leaf_arrow_circlepath,
  'tag': CupertinoIcons.tag,
};

/// Default icon used when a category has no (or an unknown) icon key.
const IconData kDefaultCategoryIcon = CupertinoIcons.tag;

/// Ordered list of selectable icon keys for the picker grid.
List<String> get categoryIconKeys => kCategoryIcons.keys.toList();

IconData iconForKey(String? key) => kCategoryIcons[key] ?? kDefaultCategoryIcon;
