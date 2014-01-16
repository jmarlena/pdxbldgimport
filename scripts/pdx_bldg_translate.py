#
# Run like this, from the ogr2osm directory:
# python ogr2osm.py ~/pdxbldgimport/pdx_bldgs_export.shp \
#    -o ~/pdxbldgimport/pdx_bldgs_export.osm \
#    -t ~/pdxbldgimport/scripts/pdx_bldg_translate.py
# 

"""
Translation rules for the PDX Building import

"""

def filterTags(attrs):
    if not attrs: return

    tags = {}
    
    if attrs['BLDG_ID']:
        tags.update({'pdxbldgs:id':attrs['BLDG_ID'].strip(' ')})

    if attrs['HOUSENUMBE']:
        tags.update({'addr:housenumber':attrs['HOUSENUMBE'].strip(' ')})

    if attrs['STREET']:
        tags.update({'addr:street':attrs['STREET'].strip(' ')})

    if attrs['POSTCODE']:
        tags.update({'addr:postcode': attrs['POSTCODE'].strip(' ')})

    if attrs['CITY']:
        tags.update({'addr:city': attrs['CITY'].strip(' ')})

    if attrs['COUNTRY']:
        tags.update({'addr:country': attrs['COUNTRY'].strip(' ')})

    if attrs['STATE']:
        tags.update({'addr:state': attrs['STATE'].strip(' ')})  

    if attrs['LEVELS']:
        tags.update({'building:levels': attrs['LEVELS']})

    if attrs['BUILDING']:
        tags.update({'building': attrs['BUILDING'].strip(' ')}) 

    if attrs['ELE'] and isinstance(attrs['ELE'], float):
        tags.update({'ele': round(attrs['ELE'], 2)})

    if attrs['HEIGHT'] and isinstance(attrs['HEIGHT'], float):
        height = 0
        height = round(attrs['HEIGHT'], 2)
        if height == 0.00:
            pass
        else:
            tags.update({'height': attrs['HEIGHT']}) 

    if attrs['NAME']:
        formattedname = ""
        formattedname = attrs['NAME'].strip(' ').title()
        
        #Expand "St. "
        #TODO: any other expansions necessary?
        if "St. " in formattedname:
            formattedname.replace("St. ", "Saint ")
         
        #Get rid of some obvious addresses (do this last). 
        #TODO: make sure this isn't removing good stuff
        if ("Nw " in formattedname or "Ne " in formattedname or
            "Sw " in formattedname or "Sw " in formattedname or
            "N " in formattedname):
            formattedname = ""

        if formattedname != "":
            tags.update({'name': formattedname})

    return tags

