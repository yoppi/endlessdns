$(function() {
    // 各グラフのチェックボックスを作成する
    function mk_checkbox(checkbox, datasets) {
        $.each(datasets, function(key, val) {
            checkbox.append('<br/>' + '<input type="checkbox" name="cache_' + key + '" checked="checked">' + val.label + '</input>');
        });
    }
    var cache_checkbox = $("#cache_type");
    var ncache_checkbox = $("#negativecache_type");
    var hitrate_checkbox = $("#hitrate_type");
    var query_checkbox = $("#query_type");
    mk_checkbox(cache_checkbox, cache_datasets);
    mk_checkbox(ncache_checkbox, negativecache_datasets);
    mk_checkbox(hitrate_checkbox, hitrate_datasets);
    mk_checkbox(query_checkbox, query_datasets);
    cache_checkbox.find("input").click(plot_cache);
    ncache_checkbox.find("input").click(plot_ncache);
    hitrate_checkbox.find("input").click(plot_hitrate);
    query_checkbox.find("input").click(plot_query);

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


    // 各グラフの変更
    function send_cache_form() {
        var form = $("#cache_form").serialize();
        $.ajax({
            type: "POST",
            url: "statistics",
            data: form,
            dataType: "json",
            success: function(ret) {
                cache_datasets = ret.datasets; 
                fix_timezone(cache_datasets, jst);
                plot_cache();
            }
        });
    }
    function send_ncache_form() {
        var form = $("#negativecache_form").serialize();
        $.ajax({
            type: "POST",
            url: "statistics",
            data: form,
            dataType: "json",
            success: function(ret) {
                negativecache_datasets = ret.datasets;
                fix_timezone(negativecache_datasets, jst);
                plot_ncache();
            }
        });
    }
    function send_hitrate_form() {
        var form = $("#hitrate_form").serialize();
        $.ajax({
            type: "POST",
            url: "statistics",
            data: form,
            dataType: "json",
            success : function(ret) {
                hitrate_datasets = ret.datasets;
                fix_timezone(hitrate_datasets, jst);
                plot_hitrate();
            }
        });
    }
    function send_query_form() {
        var form = $("#query_form").serialize();
        $.ajax({
            type: "POST",
            url: "statistics",
            data: form,
            dataType: "json",
            success: function(ret) {
                query_datasets = ret.datasets; 
                fix_timezone(query_datasets, jst);
                plot_hitrate();
            }
        });
    }

    $("#cache_graph_change").click(function(event) {
        send_cache_form();
    });
    $("#negativecache_graph_change").click(function(event) {
        send_ncache_form();
    });
    $("#hitrate_graph_change").click(function(event) {
        send_hitrate_form();
    });
    $("#query_graph_change").click(function(event) {
        send_query_change();
    });


    // グラフのオプション
    var options = {
        xaxis: { mode: "time" },
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
        $.plot($("#negativecache_graph"), data, options);
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
        $.plot($("#hitrate_graph"), data, options);
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
