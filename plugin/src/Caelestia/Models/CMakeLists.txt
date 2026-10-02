qml_module(caelestia-models
    URI Caelestia.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
        musictags.cpp
        musiccovers.cpp
    LIBRARIES
        Qt::Gui
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Taglib
)
