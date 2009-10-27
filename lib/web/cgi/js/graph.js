$(function {
    // 各グラフのチェックボックスを作成する
    // TODO: DRYにリファクタリング
    var cache_checkbox = $("cache_type");
    var ncache_checkbox = $("ncache_type");
    var hitrate_checkbox = $("hit_type");
    var query_checkbox = $("query_type");
    $.each(cache_datasets, function(key, val) {
        cache_checkbox.append(
            '</br>' +
            '<input type="checkbox" name="cache_' + key +
            '" checked="checked">' + val.label + '</input>');
    });
    $.each(negativecashe_datasets, function(key, val) {
        ncache_checkbox.append(
            '</br>' +
            '<input type="checkbox" name="ncache_"' + key +
            '" checked="checked">' + val.label + '</input>'
        );
    });
    $.each(hitrate_datasets, function(key, val) {
        hitrate_checkbox.append(
            '</br>' +
            '<input type="checkbox" name="hitrate_"' + key +
            '" checked="checked">' + val.label + '</input>'
        );
    });
    $.each(query_datasets, function(key, val) {
        query_checkbox.append(
            '</br>' +
            '<input type="checkbox" name="query_"' + key +
            '" checked="checked">' + val.label + '</input>'
        );
    });
    cache_checkbox.find("input").click(plot_cache);
    ncache_checkbox.find("input").click(plot_ncache);
    hitrate_checkbox.find("input").click(plot_hitrate);
    query_checkbox.find("input").click(plot_query);

    var options = {
        xaxis: { mode: "time" }
        yaxis: { min: 0 }
    };
    
    // グラフ描画関数
    function plot_cache() {
        // checkboxでチェックされているtypeだけデータを集める
        var data = [];
        cache_checkbox.find("input:checked").each(function () {
            var key = $(this).attr("name").split('_')[1]; //=> cache_a, cache_aaaaとかなので'_'で切り出す
            if (key && cache_datasets[key]) {
                data.push(cache_datasets[key]);
            }
        });
        if (data.length > 0) {
            $.plot($("#cache_graph"), data, options);
        }
    }
    plot_cache();

    function plot_ncache() {
        var data = [];
        ncache_checkbox.find("input:checked").each(function () {
            var key = $(this).attr("name").split('_')[1]; 
            if (key && cache_datasets[key]) {
                data.push(cache_datasets[key]);
            }
        });
        if (data.length > 0) {
            $.plot($("#ncache_graph"), data, options);
        }
    }
    
    function plot_hitrate() {
       var data = []; 
       hitrate_checkbox.find("input:checked").each(function () {
           var key = $(this).attr("name").split('_')[1];
           if (key && hitrate_datasets[key]) {
               data.push(cache_dataset[key]);
           }
       });
       if (data.length > 0) {
           $.plot($("#hit_graph"), data, options);
       }
    }

    function plot_query() {
        var data = [];
        query_checkbox.find("input:checked").each(function () {
            var key = $(this).attr("name").split('_')[1];
            if (key && query_datasets[key]) {
                data.push(query_datasets[key]);
            }
        });
        if (data.length > 0) {
            $.plot($("#query_graph"), data, options);
        }
    }
});
