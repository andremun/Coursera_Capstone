rootdir = './';
data = jsondecode(fileread([rootdir 'victoria_suburb_geocoordiantes.json']));
num_suburb = length(data);
data_table = cell(num_suburb,10);
for i=1:num_suburb
    data_table(i,1:5) = struct2cell(data(i).properties);
    data_table(i,6:7) = struct2cell(data(i).geometry);
    
    if isnumeric(data_table{i,7})
        data_table{i,7} = squeeze(data_table{i,7});
        [data_table{i,8},data_table{i,9}] = centroid(polyshape(data_table{i,7}));
        data_table{i,10} = area(polyshape(deg2km(data_table{i,7})));
        data_table{i,7} = polyshape(data_table{i,7});
    elseif iscell(data_table{i,7})
        for j=1:length(data_table{i,7})
            if j==1
                auxkm = polyshape(deg2km(squeeze(data_table{i,7}{j})));
                auxdeg = polyshape(squeeze(data_table{i,7}{j}));
            else
                if iscell(data_table{i,7}{j})
                    for k=1:length(data_table{i,7}{j})
                        auxkm = union(auxkm,polyshape(deg2km(squeeze(data_table{i,7}{j}{k}))));
                        auxdeg = union(auxdeg,polyshape(squeeze(data_table{i,7}{j}{k})));
                    end
                else
                    auxkm = union(auxkm,polyshape(deg2km(squeeze(data_table{i,7}{j}))));
                    auxdeg = union(auxdeg,polyshape(squeeze(data_table{i,7}{j})));
                end
            end
        end
        [data_table{i,8},data_table{i,9}] = centroid(auxdeg);
        data_table{i,10} = area(auxkm);
        data_table{i,7} = auxdeg;
    end
end

data_final = data_table(:,[1 8 9 10]);
data_final(:,1) = lower(data_final(:,1));

data_pcode = table2cell(readtable([rootdir 'victoria_postcodes.csv']));
data_pcode(:,2:3) = lower(data_pcode(:,2:3));
sel = false(num_suburb,1);

for i=1:num_suburb
    data_final{i,1} = replaceBetween(data_final{i,1},'(',')','');
    data_final{i,1} = strrep(data_final{i,1},' ()','');
    idx = find(strcmp(data_pcode(:,2),data_final{i,1}));
    sel(i) = ~strcmp(data_pcode{idx(1),3},'vic country') && ~strcmp(data_pcode{idx(1),3},'vic far country');
    data_final{i,1} = regexprep(data_final{i,1},'(\<[a-z])','${upper($1)}');
end

data_final = cell2table(data_final(sel,:),'VariableNames',{'Suburb','Longitude','Latitude','Area'});
writetable(data_final,[rootdir 'greater_melbourne_suburb_data.csv']);
