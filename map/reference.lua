local ids = {
    A0RK = true,
    A0RL = true,
    A0RM = true,
    A0RN = true,
    A0RO = true,
    A0RP = true,
    A0RQ = true,
    A0RR = true,
    A0RS = true,
    A0RT = true,
    A0RI = true,
    A0RU = true,
    A0RV = true,
    A0RW = true,
    A0RX = true,
    A0RY = true,
    A0RZ = true,
    A0S0 = true,
    A0S1 = true,
    A0S2 = true,
    A0TD = true,
    A0TE = true,
    A0TF = true,
    A0TG = true,
    A0TH = true,
    A0TI = true,
    A0TJ = true,
    A0TK = true,
    A0TL = true,
    A0TM = true,
    A0TN = true,
    n008 = true,
    A0TO = true,
    A0T6 = true,
    A0T7 = true,
    A0TB = true,
    A0T8 = true,
    A0T9 = true,
    A0TA = true,
    Arav = true,
    A0II = true,
    A0PX = true,
    A0PZ = true,
    A0Q0 = true,
    A0Q1 = true,
    Amgl = true,
}

local function search_txt()
    local buf = archive:get '11record.txt'
    if not buf then
        return
    end

    for id in buf:gmatch '信使=(%w%w%w%w)' do
        ids[id] = true
    end
    for id in buf:gmatch '皮肤=(%w%w%w%w)' do
        ids[id] = true
    end
end

search_txt()

return ids
