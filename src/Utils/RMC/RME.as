class RME : RMC
{
    int Skips = 0;
    int SurvivedTimeStart = -1;
    int SurvivedTime = -1;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string GetModeName() override { return "Random Map Endless";}

    int TimeLimit() override { return 10 * 60 * 1000; }

    void RenderTimer() override
    {
        UI::PushFont(TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0 || RMC::StartTime > 0) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
            else UI::Text(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));

            SurvivedTime = RMC::StartTime - SurvivedTimeStart;
            if (SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                UI::PopFont();
                UI::Dummy(vec2(0, 8));
                UI::PushFont(g_fontHeaderSub);
                UI::Text(RMC::FormatTimer(SurvivedTime));
                UI::SetPreviousTooltip("Total time survived");
            } else {
                UI::Dummy(vec2(0, 8));
            }
            if (PluginSettings::RMC_DisplayMapTimeSpent) {
                if(SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                    UI::SameLine();
                }
                UI::PushFont(g_fontHeaderSub);
                UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
                UI::SetPreviousTooltip("Time spent on this map");
                UI::PopFont();
            }
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit()));
            UI::Dummy(vec2(0, 8));
        }

        UI::PopFont();
    }

    void RenderBelowGoalMedal() override
    {
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(TimerFont);
        UI::Text(tostring(Skips));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }

    void SkipButton() override
    {
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("RME: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
            MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
#if TMNEXT
            if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson)) {
                RMC::EndTime += RMC::TimeSpentMap;
            }
#endif
        }
        if (UI::OrangeButton(Icons::PlayCircleO + " Free Skip")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(SurvivalFreeSkipWarnModalDialog());
        }
    }

    void NextMapButton() override
    {
        if(UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMS: Next map");
            UI::ShowNotification("Please wait...");
            RMC::EndTime += (3*60*1000);
            startnew(RMC::SwitchMap);
        }
    }

    void StartTimer() override
    {
        RMC::StartTime = Time::get_Now();
        RMC::EndTime = RMC::StartTime + TimeLimit();
        SurvivedTimeStart = Time::get_Now();
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
    }

    void GameEndNotification() override
    {
        if (RMC::selectedGameMode == RMC::GameMode::Endless)
        UI::ShowNotification(
            "\\$0f0Random Map Endless ended!",
            "You survived with a time of " + RMC::FormatTimer(RMC::Endless.SurvivedTime) +
            ".\nYou got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) +
            " medals and " + RMC::Endless.Skips + " skips."
        );
    }

    void GotGoalMedalNotification() override
    {
        Log::Trace("RME: Got "+ tostring(PluginSettings::RMC_GoalMedal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "We're searching for another map...");
            RMC::EndTime += (3*60*1000);
            startnew(RMC::SwitchMap);
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() override {}
}