package com.example.kalinote.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface KaliNoteDao {
    // User
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Query("SELECT * FROM users WHERE email = :email")
    fun getUser(email: String): Flow<UserEntity?>

    // Folders
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFolder(folder: FolderEntity)

    @Query("SELECT * FROM folders WHERE userEmail = :userEmail")
    fun getFoldersForUser(userEmail: String): Flow<List<FolderEntity>>

    // Notebooks
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotebook(notebook: NotebookEntity)

    @Query("SELECT * FROM notebooks WHERE folderId = :folderId")
    fun getNotebooksForFolder(folderId: String): Flow<List<NotebookEntity>>

    // Pages
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPage(page: PageEntity)

    @Query("SELECT * FROM pages WHERE notebookId = :notebookId ORDER BY orderIndex")
    fun getPagesForNotebook(notebookId: String): Flow<List<PageEntity>>

    // PageObjects
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPageObject(pageObject: PageObjectEntity)

    @Query("SELECT * FROM page_objects WHERE pageId = :pageId")
    fun getObjectsForPage(pageId: String): Flow<List<PageObjectEntity>>

    @Delete
    suspend fun deleteFolder(folder: FolderEntity)

    @Delete
    suspend fun deleteNotebook(notebook: NotebookEntity)

    @Delete
    suspend fun deletePage(page: PageEntity)
}
