package com.example.kalinote

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewScreenSizes
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import java.io.InputStream
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Menu
import androidx.compose.material.icons.automirrored.filled.Send
import com.example.kalinote.data.*
import com.example.kalinote.ui.theme.KaliNoteTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            KaliNoteTheme {
                KaliNoteApp()
            }
        }
    }
}

@Composable
fun KaliNoteApp(viewModel: KaliNoteViewModel = viewModel()) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Open)
    val scope = rememberCoroutineScope()
    
    val folders by viewModel.folders.collectAsState()
    val isConnected by viewModel.nearbyManager.isConnected.collectAsState()
    val scanRequested by viewModel.nearbyManager.receivedScanRequest.collectAsState()
    var selectedPage by remember { mutableStateOf<PageEntity?>(null) }

    // GMS Document Scanner setup
    val scannerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            val scanResult = com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult.fromActivityResultIntent(result.data)
            scanResult?.pages?.firstOrNull()?.let { page ->
                val imageUri = page.imageUri
                val inputStream: InputStream? = context.contentResolver.openInputStream(imageUri)
                val bytes = inputStream?.readBytes()
                if (bytes != null && selectedPage != null) {
                    viewModel.handleReceivedImage(selectedPage!!.id, bytes)
                }
            }
        }
    }

    LaunchedEffect(scanRequested) {
        if (scanRequested) {
            val options = GmsDocumentScannerOptions.Builder()
                .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                .build()
            val scanner = GmsDocumentScanning.getClient(options)
            scanner.getStartScanIntent(context as ComponentActivity)
                .addOnSuccessListener { intentSender ->
                    scannerLauncher.launch(IntentSenderRequest.Builder(intentSender).build())
                }
            viewModel.nearbyManager.resetScanRequest()
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                SidebarContent(
                    folders = folders,
                    viewModel = viewModel,
                    onPageClick = { 
                        selectedPage = it
                        scope.launch { drawerState.close() }
                    }
                )
            }
        }
    ) {
        Scaffold(
            topBar = {
                CenterAlignedTopAppBar(
                    title = { Text(selectedPage?.title ?: "Kali Note") },
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.AutoMirrored.Filled.Menu, contentDescription = "Menu")
                        }
                    },
                    actions = {
                        IconButton(
                            onClick = { viewModel.nearbyManager.requestRemoteScan() },
                            enabled = isConnected
                        ) {
                            Icon(
                                Icons.Default.PhoneIphone, 
                                contentDescription = "Remote Scan",
                                tint = if (isConnected) Color(0xFF2196F3) else Color.Gray.copy(alpha = 0.5f)
                            )
                        }
                    }
                )
            }
        ) { innerPadding ->
            Box(modifier = Modifier.padding(innerPadding).fillMaxSize()) {
                if (selectedPage != null) {
                    DrawingCanvas(selectedPage!!)
                } else {
                    Text("Select a page from the sidebar", modifier = Modifier.align(Alignment.Center))
                }
            }
        }
    }
}

@Composable
fun SidebarContent(
    folders: List<FolderEntity>,
    viewModel: KaliNoteViewModel,
    onPageClick: (PageEntity) -> Unit
) {
    LazyColumn(modifier = Modifier.padding(16.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Library", fontSize = 24.sp, modifier = Modifier.weight(1f))
                IconButton(onClick = { viewModel.addFolder("New Folder") }) {
                    Icon(Icons.Default.CreateNewFolder, contentDescription = "Add Folder")
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
        items(folders) { folder ->
            FolderItem(folder, viewModel, onPageClick)
        }
    }
}

@Composable
fun FolderItem(
    folder: FolderEntity,
    viewModel: KaliNoteViewModel,
    onPageClick: (PageEntity) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    val notebooks by viewModel.dao.getNotebooksForFolder(folder.id).collectAsState(emptyList())

    Column {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().clickable { expanded = !expanded }.padding(vertical = 4.dp)
        ) {
            Icon(if (expanded) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowRight, null)
            Icon(Icons.Default.Folder, null, tint = androidx.compose.ui.graphics.Color(0xFF6200EE))
            Spacer(Modifier.width(8.dp))
            Text(folder.name)
            Spacer(Modifier.weight(1f))
            IconButton(onClick = { viewModel.addNotebook(folder.id, "New Notebook") }) {
                Icon(Icons.Default.Add, null)
            }
        }
        if (expanded) {
            Column(modifier = Modifier.padding(start = 24.dp)) {
                notebooks.forEach { notebook ->
                    NotebookItem(notebook, viewModel, onPageClick)
                }
            }
        }
    }
}

@Composable
fun NotebookItem(
    notebook: NotebookEntity,
    viewModel: KaliNoteViewModel,
    onPageClick: (PageEntity) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    val pages by viewModel.dao.getPagesForNotebook(notebook.id).collectAsState(emptyList())

    Column {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().clickable { expanded = !expanded }.padding(vertical = 4.dp)
        ) {
            Icon(if (expanded) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowRight, null)
            Icon(Icons.Default.Book, null)
            Spacer(Modifier.width(8.dp))
            Text(notebook.name)
            Spacer(Modifier.weight(1f))
            IconButton(onClick = { viewModel.addPage(notebook.id, "Side 1") }) {
                Icon(Icons.Default.Add, null)
            }
        }
        if (expanded) {
            Column(modifier = Modifier.padding(start = 24.dp)) {
                pages.forEach { page ->
                    Text(
                        page.title,
                        modifier = Modifier.fillMaxWidth().clickable { onPageClick(page) }.padding(vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun DrawingCanvas(page: PageEntity) {
    Text("Drawing Area for ${page.title}", modifier = Modifier.fillMaxSize())
}