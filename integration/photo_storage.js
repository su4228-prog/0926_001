// Integration module: pass a signed-in @supabase/supabase-js v2 client.
// Not enabled in the current single-file workspace; see the setup guide.
export async function uploadOriginalPhoto(supabase, file, metadata = {}) {
 const {data:{user},error:authError}=await supabase.auth.getUser();
 if(authError||!user)throw new Error('먼저 로그인해 주세요.');
 const ext={'image/jpeg':'jpg','image/png':'png','image/webp':'webp'}[file.type];
 if(!ext||file.size>20*1024*1024)throw new Error('20MB 이하 JPG·PNG·WebP를 선택하세요.');
 const id=crypto.randomUUID(),path=`${user.id}/${id}.${ext}`;
 const {error:uploadError}=await supabase.storage.from('article-photos').upload(path,file,{contentType:file.type,upsert:false});
 if(uploadError)throw uploadError;
 const {data,error}=await supabase.from('photo_assets').insert({id,owner_id:user.id,object_path:path,original_filename:file.name,mime_type:file.type,byte_size:file.size,article_id:metadata.article_id||null,caption:metadata.caption||'',source:metadata.source||'',source_style:metadata.source_style||'copyright',shot_date:metadata.shot_date||null,verified_context:metadata.verified_context||'',generated:!!metadata.generated}).select().single();
 if(error){await supabase.storage.from('article-photos').remove([path]);throw error}
 return data;
}
export async function listPhotoAssets(supabase){
 const {data,error}=await supabase.from('photo_assets').select('*').order('created_at',{ascending:false});
 if(error)throw error;return data;
}
export async function previewPhotoURL(supabase,asset){
 const {data,error}=await supabase.storage.from('article-photos').createSignedUrl(asset.object_path,3600);
 if(error)throw error;return data.signedUrl;
}
export async function originalPhotoBlob(supabase,asset){
 const {data,error}=await supabase.storage.from('article-photos').download(asset.object_path);
 if(error)throw error;return data;
}
