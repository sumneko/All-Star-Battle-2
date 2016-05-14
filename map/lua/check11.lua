    
    globals.hasLua = true
    
    cmd.main()
    
    timer.wait(5,
        function()
    
            local name = jass.GetPlayerName(jass.Player(12))
            
            jass.SetPlayerName(jass.Player(12), '|cffff1111小神|r')
            japi.EXDisplayChat(jass.Player(12), 0, '                                               全明星战役' .. cmd.ver_name)
            
            jass.SetPlayerName(jass.Player(12), '|cffffff11幻雷|r')
            japi.EXDisplayChat(jass.Player(12), 0, '                                               作者：小神 幻雷 最萌小汐 裂魂')
            
            jass.SetPlayerName(jass.Player(12), '|cffff11cc小汐|r')
            japi.EXDisplayChat(jass.Player(12), 0, '                                               感谢玩家s芙兰朵露z和东风谷早面对本地图的支持！')
            
            jass.SetPlayerName(jass.Player(12), '|cff11ffff裂魂|r')
            japi.EXDisplayChat(jass.Player(12), 0, '                                               游戏指令.更新内容.游戏专房请查看F9')
            
            jass.SetPlayerName(jass.Player(12), name)
        end
    )