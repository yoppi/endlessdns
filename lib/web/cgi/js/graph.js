$(function() {
    // 各グラフのチェックボックスを作成する
    // TODO: DRYにリファクタリング
    var cache_checkbox = $("#cache_type");
    var ncache_checkbox = $("#ncache_type");
    var hitrate_checkbox = $("#hit_type");
    var query_checkbox = $("#query_type");
    $.each(cache_datasets, function(key, val) {
        cache_checkbox.append('<br/>' + '<input type="checkbox" name="cache_' + key + '" checked="checked">' + val.label + '</input>');
    });
    $.each(negativecache_datasets, function(key, val) {
        ncache_checkbox.append('<br/>' + '<input type="checkbox" name="ncache_"' + key + '" checked="checked">' + val.label + '</input>');
    });
    $.each(hitrate_datasets, function(key, val) {
        hitrate_checkbox.append('<br/>' + '<input type="checkbox" name="hit_' + key + '" checked="checked">' + val.label + '</input>');
    });
    $.each(query_datasets, function(key, val) {
        query_checkbox.append('<br/>' + '<input type="checkbox" name="query_' + key + '" checked="checked">' + val.label + '</input>');
    });
    cache_checkbox.find("input").click(plot_cache);
    ncache_checkbox.find("input").click(plot_ncache);
    hitrate_checkbox.find("input").click(plot_hitrate);
    query_checkbox.find("input").click(plot_query);

    // グラフのオプション
    var options = {
        xaxis: { mode: "time" },
        yaxis: { min: 0 }
    };

    // グラフのデータをJSTにあわせる
    function fix_timezone(datasets, move) {
        $.each(datasets, function(key, val) {
            for (var i=0; i<val.data.length; i++) {
                val.data[i][0] = val.data[i][0] + move;
            }
        });
    }
    var jst = 9 * 60 * 60 * 1000;
    fix_timezone(cache_datasets, jst);
    fix_timezone(negativecache_datasets, jst);
    fix_timezone(hitrate_datasets, jst);
    fix_timezone(query_datasets, jst);

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
        data = data.length > 0 ? data : [{data: []}];
        $.plot($("#cache_graph"), data, options);
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
        data = data.length > 0 ? data : [{data: []}];
        $.plot($("#ncache_graph"), data, options);
    }
    plot_ncache();

    function plot_hitrate() {
        var data = [];
        hitrate_checkbox.find("input:checked").each(function () {
            var key = $(this).attr("name").split('_')[1];
            if (key && hitrate_datasets[key]) {
                data.push(hitrate_datasets[key]);
            }
        });
        data = data.length > 0 ? data : [{data: []}];
        $.plot($("#hit_graph"), data, options);
    }
    plot_hitrate();

    function plot_query() {
        var data = [];
        query_checkbox.find("input:checked").each(function () {
            var key = $(this).attr("name").split('_')[1];
            if (key && query_datasets[key]) {
                data.push(query_datasets[key]);
            }
        });
        data = data.length > 0 ? data : [{data: []}];
        $.plot($("#query_graph"), data, options);
    }
    plot_query();
});
