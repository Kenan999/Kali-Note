package com.example.kalinote

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.room.Room
import com.example.kalinote.connectivity.NearbyManager
import kotlinx.coroutines.flow.*

class KaliNoteViewModel(application: Application) : AndroidViewModel(application) {
    private val db = Room.databaseBuilder(
        application,
        KaliNoteDatabase::class.java, "kali-note-db"
    ).build()

    val dao = db.dao()
    val nearbyManager = NearbyManager(application)

    private val _currentUserEmail = MutableStateFlow("user@example.com")
    
    init {
        nearbyManager.startP2P()
    }
    
    val folders: StateFlow<List<FolderEntity>> = _currentUserEmail
        .flatMapLatest { dao.getFoldersForUser(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun addFolder(name: String) {
        viewModelScope.launch {
            dao.insertFolder(FolderEntity(name = name, userEmail = _currentUserEmail.value))
        }
    }

    fun addNotebook(folderId: String, name: String) {
        viewModelScope.launch {
            dao.insertNotebook(NotebookEntity(name = name, folderId = folderId))
        }
    }

    fun addPage(notebookId: String, title: String) {
        viewModelScope.launch {
            dao.insertPage(PageEntity(title = title, notebookId = notebookId))
        }
    }

    fun handleReceivedImage(pageId: String, imageData: ByteArray) {
        viewModelScope.launch {
            dao.insertPageObject(
                PageObjectEntity(
                    pageId = pageId,
                    type = "PHOTO",
                    data = imageData,
                    isPencil = false
                )
            )
        }
    }
}
