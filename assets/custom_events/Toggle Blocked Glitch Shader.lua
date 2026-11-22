local shaderEnabled = false

function onCreatePost()
    runHaxeCode([[
        var shaderCode = '
            #pragma header
            float RATE = 50.0;
            uniform float time;
            uniform float intensity;
            float rand(vec2 co){
                return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) * 2.0 - 1.0;
            }
            float offset(float blocks, vec2 uv) {
                float shaderTime = time*RATE;
                return rand(vec2(shaderTime, floor(uv.y * blocks)));
            }
            void main(void) {
                vec2 uv = openfl_TextureCoordv;
                gl_FragColor = flixel_texture2D(bitmap, uv);
                gl_FragColor.r = flixel_texture2D(bitmap, uv + vec2(offset(64.0, uv) * intensity, 0.0)).r;
                gl_FragColor.g = flixel_texture2D(bitmap, uv + vec2(offset(64.0, uv) * intensity * 0.16666666, 0.0)).g;
                gl_FragColor.b = flixel_texture2D(bitmap, uv + vec2(offset(64.0, uv) * intensity, 0.0)).b;
            }
        ';
        
        var shaderGame = new FlxRuntimeShader(shaderCode);
        var shaderHUD = new FlxRuntimeShader(shaderCode);
        
        shaderGame.setFloat('intensity', 0.01);
        shaderHUD.setFloat('intensity', 0.03);
        
        game.variables.set('glitchGame', shaderGame);
        game.variables.set('glitchHUD', shaderHUD);
        
        game.variables.set('glitchFilterGame', new ShaderFilter(shaderGame));
        game.variables.set('glitchFilterHUD', new ShaderFilter(shaderHUD));
    ]])
end

function onEvent(name, value1, value2)
    local n = string.lower(name)
    if string.find(n, 'glitch') and string.find(n, 'blocked') then
        shaderEnabled = not shaderEnabled
        if shaderEnabled then
            runHaxeCode([[
                var filterG = game.variables.get('glitchFilterGame');
                var filtersG = game.camGame.filters;
                if (filtersG == null) filtersG = [];
                if (!filtersG.contains(filterG)) {
                    filtersG.push(filterG);
                    game.camGame.setFilters(filtersG);
                }

                var filterH = game.variables.get('glitchFilterHUD');
                var filtersH = game.camHUD.filters;
                if (filtersH == null) filtersH = [];
                if (!filtersH.contains(filterH)) {
                    filtersH.push(filterH);
                    game.camHUD.setFilters(filtersH);
                }
            ]])
        else
            runHaxeCode([[
                var filterG = game.variables.get('glitchFilterGame');
                var filtersG = game.camGame.filters;
                if (filtersG != null && filtersG.contains(filterG)) {
                    filtersG.remove(filterG);
                    game.camGame.setFilters(filtersG);
                }

                var filterH = game.variables.get('glitchFilterHUD');
                var filtersH = game.camHUD.filters;
                if (filtersH != null && filtersH.contains(filterH)) {
                    filtersH.remove(filterH);
                    game.camHUD.setFilters(filtersH);
                }
            ]])
        end
    end
end

function onUpdate(elapsed)
    if shaderEnabled then
        runHaxeCode([[
            var shader1 = game.variables.get('glitchGame');
            var shader2 = game.variables.get('glitchHUD');
            var t = FlxG.game.ticks / 10;
            shader1.setFloat('time', t);
            shader2.setFloat('time', t);
        ]])
    end
end