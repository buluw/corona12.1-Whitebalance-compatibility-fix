-- 修复由corona 12 update1 更新白平衡之后低版本打开场景闪退问题
-- 该脚本会将新版白平衡在原位置原值基础上自动替换为旧版，以兼容低版本corona
-- https://github.com/buluw/corona12.1-Whitebalance-compatibility-fix
-- 版本 : 1.0.1
-- 2025-05-07
-- 作者 : yanjicg
-- =========================================
-- ocgbuluw@gmail.com
-- https://yanjicg.com
-- =========================================
-- GPL-3.0 license
-- https://github.com/buluw/corona12.1-Whitebalance-compatibility-fix/blob/main/LICENSE
-- =========================================
ClassNodes=#()
for o in #(camera) do join ClassNodes o.classes
fn GetClassIdToNode ApiClassID =
(
    (for o in ClassNodes where o.classid[1] == ApiClassID[1] and o.classid[2] == ApiClassID[2] collect o)[1]
)
if CoronaCam == undefined do CoronaCam = GetClassIdToNode #(2776904324L, 1699230924L)
struct crnToneMapping (
	fn GetTMOperators target = (
		tmOPs = #()
		local tmOP = if classOf target == CoronaCam then target.colorMappingPipeline else renderers.current.colorMap_pipeline
		if (not ( isProperty tmOP #colorMappingOperator_nextOperator )) then ClearTMOperators target
		while ((tmOP != undefined ) and (classof tmOP != IdentityOperatorPlugin) and ( isProperty tmOP #colorMappingOperator_nextOperator )) do (
			insertItem tmOP tmOPs (tmOPs.count+1)
			tmOP = tmOP.colorMappingOperator_nextOperator
		) 
		tmOPs
	),
	fn ClearTMOperators target = (
		if classOf target == CoronaCam then target.colorMappingPipeline = IdentityOperatorPlugin()
		else renderers.current.colorMap_pipeline = IdentityOperatorPlugin()
    )
)

fn replaceWhiteBalanceOperator tmOP = (
	op = WhiteBalanceOperatorPlugin()
	for prop in #("id", "enabled", "colorTemperature") do (
		setProperty op ("colorMappingOperator_" + prop) (getProperty tmOP ("colorMappingOperator_" + prop))
	)

	return op
)

fn rebuildOperatorPipeline target tmOPs = (
    crnToneMapping.ClearTMOperators target
	RevAlltmOPs = #()
	RevAlltmOPs = for idx = tmOPs.count to 1 by -1 collect tmOPs[idx]
    for tmOP in RevAlltmOPs do 	
	(
		if classOf target == CoronaCam then 
		(
			tmOP.colorMappingOperator_nextOperator = target.colorMappingPipeline
			target.colorMappingPipeline = tmOP
		)
		else 
		(
			tmOP.colorMappingOperator_nextOperator = renderers.current.colorMap_pipeline
			renderers.current.colorMap_pipeline = tmOP
		)
	)
)
fn processToneMapping target = (
    local tmOps = crnToneMapping.GetTMOperators target

    for i = tmOps.count to 1 by -1 do (
		if classof tmOps[i] == WhiteBalanceImprovedOperatorPlugin do 
		(
			local newOP = replaceWhiteBalanceOperator tmOps[i]
			if newOP != undefined do tmOps[i] = newOP
		)
    )
    rebuildOperatorPipeline target tmOps
)

productRenderer = renderers.production
if((productRenderer.classid[1] == 1655201228) and (productRenderer.classid[2] == 1379677700)) then (
	processToneMapping renderers.current

	for cam in (for o in cameras where classOf o == CoronaCam collect o) do (
		processToneMapping cam
	)
)
else
(
	q_answer = queryBox "是否切换当前渲染器为 Corona ?" title:"提示" beep:false  
	if q_answer == true do 
	(
		renderers.current = corona()
		processToneMapping renderers.current

		for cam in (for o in cameras where classOf o == CoronaCam collect o) do (
			processToneMapping cam
		)
	)
)
