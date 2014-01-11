file 'Building_Footprints_pdx.zip' do 
  sh %Q{ wget --quiet --timestamping ftp://ftp02.portlandoregon.gov/CivicApps/Building_Footprints_pdx.zip }
end 

bldg_date=File.stat('Building_Footprints_pdx.zip').mtime.strftime('%Y-%m-%d')

file "PortlandBuildings-#{bldg_date}/Building_Footprints_pdx.shp" => 'Building_Footprints_pdx.zip' do
  sh %Q{unzip -n -j Building_Footprints_pdx.zip -d PortlandBuildings-#{bldg_date};true}
  # we have to do this, because the individual files are newer than the zipfile that contains them
  sh %Q{touch -t #{(File.stat('Building_Footprints_pdx.zip').mtime+1).strftime('%Y%m%d%H%M.%S')}  PortlandBuildings-#{bldg_date}/*}
end

desc "Dowloads and unzips the latest building footprints"
task :pdx_download => "PortlandBuildings-#{bldg_date}/Building_Footprints_pdx.shp" do
end


pdx_shapes = { 
            :pdx_bldgs_orig =>  "PortlandBuildings-#{bldg_date}/Building_Footprints_pdx.shp",
            :master_address => './rlis/TAXLOTS/master_address.shp',
            :taxlots => './rlis/TAXLOTS/taxlots.shp'
}


pdx_shape_tasks=[]
pdx_shapes.each do |k,v|
  x=table k => shapefile(v) do |t|
      t.drop_table
      t.load_shapefile(t.prerequisites.first, :append => false)
  end
  pdx_shape_tasks << x
end

desc "Run all building and address related tasks"
task :all_pdx => [:pdx_bldgs, :pdx_addrs, :taxlots]

desc "load raw building footprints. Used only by :pdx_bldgs tasks"
task :pdx_bldgs_orig do |t|
  t.run %Q{
    UPDATE #{t.name}
      SET the_geom=st_makevalid(the_geom) 
      WHERE not st_isvalid(the_geom);
  }
  t.add_centroids
  # t.run %Q{
  #   ALTER TABLE #{t.name} ADD COLUMN tlid varchar(20);
  #   ALTER TABLE #{t.name} ADD COLUMN neighborhood varchar(60);
  #   UPDATE #{t.name} SET the_geom=st_makevalid(the_geom) WHERE NOT st_isvalid(the_geom);
  #   UPDATE #{t.name} b SET tlid=t.tlid FROM taxlots t WHERE st_intersects(b.the_geom_centroids,t.the_geom);
  # }
end

desc "Generate final format building footprint data"
table :pdx_bldgs => [:pdx_bldgs_orig, :pdx_addrs] do |t|
  t.drop_table
  t.run %Q{
  CREATE table pdx_bldgs as 
    SELECT  b.bldg_id,
    --b.tlid,
    b.num_story as levels,
    round(b.surf_elev::numeric * 0.3048,2) as ele,
    round(b.max_height::numeric * 0.3048,2) as height,
    b.bldg_name as name,
    'yes'::varchar(20) as building,
    b.bldg_use,
    0::integer as no_addrs,
    the_geom_centroids,
    the_geom
  FROM pdx_bldgs_orig b;

  UPDATE #{t.name} bl
    SET no_addrs=addr_count
    FROM (
      SELECT bldg_id,count(*) as addr_count
        FROM pdx_bldgs b
        JOIN pdx_addrs a ON st_intersects(a.the_geom,b.the_geom)
        WHERE bldg_id IS NOT NULL
        GROUP by bldg_id
    ) ad
    WHERE ad.bldg_id=bl.bldg_id;

  } 
  t.add_spatial_index(:the_geom)
  t.add_spatial_index(:the_geom_centroids)
  # t.add_index(:tlid)
  t.add_index(:bldg_id)
  t.add_index(:no_addrs)
  t.add_update_column
end
