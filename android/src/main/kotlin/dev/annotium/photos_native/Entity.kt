// Copyright Annotium 2021

package dev.annotium.photos_native

data class PHGallery(val albums: MutableList<PHAlbum> = mutableListOf())
{
    fun toMessageCodec(): List<Any> {
        return albums.map {
            it.toMessageCodec()
        }
    }
}

//data class PHGallery(private val allPhotosTitle: String)
//{
//    private val allIds = mutableSetOf<String>()
//    val allPhotosAlbum = PHAlbum(Constants.Album.AllPhotos, allPhotosTitle, allIds.toList())
//
//    fun addPhoto(album: String, id: String) {
//
//    }
//
//    fun toMessageCodec(): List<Any> {
//        return albums.map {
//            it.toMessageCodec()
//        }
//    }
//}

data class PHAlbum(val id: String,
              var title: String = "",
              val items: MutableList<String> = mutableListOf())
{
    fun toMessageCodec(): Map<String, Any> {
        return mapOf(
             "id" to id,
             "title" to title,
             "items" to items
        )
    }
}

data class PHImageDescriptor(val width: Int, val height: Int, val data: ByteArray)
{
    fun toMessageCodec(): Map<String, Any> {
        return mapOf(
            "width" to width,
            "height" to height,
            "data" to data
        )
    }
}
