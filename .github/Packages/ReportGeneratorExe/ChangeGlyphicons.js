$(function() {
		
  $('.list-group-item').on('click', function() {
	$('.glyphicon', this)
	  .toggleClass('glyphicon-plus')
	  .toggleClass('glyphicon-minus');
  });

});


$("#ShowOnlyFailures").click(function(){
	$(".Success").hide();
});

$("#ShowAll").click(function(){
	$(".Success").show();
	location.reload();
});

$("#OpenAllFailures").click(function(){
	//$(".Passed").hide();
	$(".Failure").click();
})

$(".OpenToAFailure").click(function(){
	var openToThisFailure = $(this).attr("Failure");
	var currentText = $(this).attr("value");
	//Find last '_'
	var index = openToThisFailure.lastIndexOf('_');
	//Remove everything after last '_'
	var EndstringToRemove = openToThisFailure.substring(index);
	var LinkWithoutScenario = openToThisFailure.replace(EndstringToRemove,"");
	//Re-find last '_'
	var FeatureToFind = '_Features_';
	var indexOfLast_ = LinkWithoutScenario.lastIndexOf(FeatureToFind);
	//Remove everything before last '_'
	var LinkWithoutNameSpace = LinkWithoutScenario.substring(indexOfLast_+(FeatureToFind.length));
	//Add '_Href' to string
	var FeatureLink = LinkWithoutNameSpace + '_Href';
	//alert(FeatureLink);
	if(currentText == "Open")
	{
		$(this).attr("value", "Close");
		$(this).addClass("btn-primary");
		$(this).removeClass("btn-default");
		if($('#'+FeatureLink).hasClass("collapsed")){
			$('#'+FeatureLink).click();
		}
		if($('#'+openToThisFailure).hasClass("collapsed")){
			$('#'+openToThisFailure).click();
		}
		
		$('#left_div').animate({
			scrollTop: $('#'+FeatureLink).offset().top
		}, 1000);
		
		$('#'+openToThisFailure).css('background-color','#ffa6a6')
		setTimeout(function () {
				$('#'+openToThisFailure).css('background-color','');
			}, 2500);
	//alert($(this).offset().top )	;
	}
	
	if(currentText == "Close")
	{
		
		$(this).attr("value", "Open");
		$(this).addClass("btn-default");
		$(this).removeClass("btn-primary");
		if(!$('#'+FeatureLink).hasClass("collapsed")){
			$('#'+FeatureLink).click();
		}
		if(!$('#'+openToThisFailure).hasClass("collapsed")){
			$('#'+openToThisFailure).click();
		}

	}

})

$('html, body').animate({
	scrollTop: ($('.error').first().offset().top)
},500);



