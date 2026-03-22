package com.example.kalinote.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        UserEntity::class,
        FolderEntity::class,
        NotebookEntity::class,
        PageEntity::class,
        PageObjectEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class KaliNoteDatabase : RoomDatabase() {
    abstract fun dao(): KaliNoteDao
}
