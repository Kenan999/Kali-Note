package com.example.kalinote.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.PrimaryKey
import androidx.room.Index
import java.util.UUID

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val email: String,
    val username: String,
    val passwordHash: String? = null,
    val profilePhotoURL: String? = null,
    val isOffline: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val metadata: ByteArray? = null
)

@Entity(
    tableName = "folders",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["email"],
            childColumns = ["userEmail"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["userEmail"])]
)
data class FolderEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val userEmail: String,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "notebooks",
    foreignKeys = [
        ForeignKey(
            entity = FolderEntity::class,
            parentColumns = ["id"],
            childColumns = ["folderId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["folderId"])]
)
data class NotebookEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val folderId: String,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "pages",
    foreignKeys = [
        ForeignKey(
            entity = NotebookEntity::class,
            parentColumns = ["id"],
            childColumns = ["notebookId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["notebookId"])]
)
data class PageEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val notebookId: String,
    val orderIndex: Int = 0,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "page_objects",
    foreignKeys = [
        ForeignKey(
            entity = PageEntity::class,
            parentColumns = ["id"],
            childColumns = ["pageId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["pageId"])]
)
data class PageObjectEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val pageId: String,
    val type: String, // "PENCIL", "PHOTO", "TEXT"
    val data: ByteArray? = null,
    val isPencil: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)
