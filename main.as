bool isIceSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Ice ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::RoadIce ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Snow ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Concrete);
}

bool isDirtSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Dirt ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::DirtRoad);
}

bool isTarmacSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Concrete ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Asphalt ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::RoadSynthetic ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::TechMagnetic ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::TechSuperMagnetic);
}

bool isGrassSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Grass ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Green);
}

Json::Value obtainVehicleInfo(CSceneVehicleVisState@ vis) {
    Json::Value jsonObject = Json::Object();
    
    // car states
    jsonObject["speed:"] = vis.WorldVel.Length() * 3.6;
    jsonObject["sideSpeed:"] = VehicleState::GetSideSpeed(vis);
    jsonObject["curGear:"] = vis.CurGear;
    jsonObject["isTurbo"] = vis.IsTurbo;

    // input
    jsonObject["inputSteer:"] = vis.InputSteer;
    jsonObject["inputIsBraking:"] = vis.InputIsBraking;
    jsonObject["inputVertical:"] = vis.InputVertical;

    // environment states
    jsonObject["isGroundContact:"] = vis.IsGroundContact;
    jsonObject["isWheelsBurning:"] = vis.IsWheelsBurning;
    jsonObject["groundDist:"] = vis.GroundDist;

    // surface
    EPlugSurfaceMaterialId flSurface = vis.FLGroundContactMaterial;
    EPlugSurfaceMaterialId rrSurface = vis.RRGroundContactMaterial;

    jsonObject["isIceSurface:"] = isIceSurface(flSurface) || isIceSurface(rrSurface);
    jsonObject["isDirtSurface:"] = isDirtSurface(flSurface) || isDirtSurface(rrSurface);
    jsonObject["isTarmacSurface:"] = isTarmacSurface(flSurface) || isTarmacSurface(rrSurface);
    jsonObject["isGrassSurface:"] = isGrassSurface(flSurface) || isGrassSurface(rrSurface);

    return jsonObject;
}

enum CameraType {
    FreeCam = 0x2,
    WeirdDefault = 0x5,
    Intro7Mb = 0x7,
    Intro10Mb = 0x10,
    FreeCam2 = 0x11,
    Cam1 = 0x12,
    Cam2 = 0x13,
    Cam3 = 0x14,
    Backwards = 0x15,
    Intro16Mb = 0x16,
}

CGameTerminal@ GetGameTerminal(CGameCtnApp@ app) {
	if (app.CurrentPlayground is null) return null;
	if (app.CurrentPlayground.GameTerminals.Length == 0) return null;
	auto gt = app.CurrentPlayground.GameTerminals[0];
    return gt;
}

void SetCamType(CGameCtnApp@ app) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
	auto setCamNod = Dev::GetOffsetNod(gt, 0x50);

    CameraType cameraType = CameraType::Cam3;
    Dev::SetOffset(setCamNod, 0x4, uint(cameraType));
}

Json::Value ObtainJsonFromVehicle(){
    CSceneVehicleVis@[] allVis = VehicleState::GetAllVis(GetApp().GameScene);

    // CSceneVehicleVisState@ customVis = onlyVis.AsyncState;
    
    Json::Value jsonObject;
    int arrayLength = int(allVis.Length);

    if (arrayLength != 0) {
        CSceneVehicleVis@ customVis = allVis[int(allVis.Length) - 1];
        if (customVis is null) {
            print("first vis is null");
        }

        print("The length of the array is: " + arrayLength);

        CSceneVehicleVisState@ customVisState = customVis.AsyncState;
        print(customVis.Turbo);
        print(customVisState.InputSteer);

        jsonObject = obtainVehicleInfo(customVisState);

        string jsonObjectStr = Json::Write(jsonObject);
        print(jsonObjectStr);
    }

    return jsonObject;
}

void SaveJsonAsTxt(Json::Value jsonValue) {
    const string filename = "E:\\study\\bachelor\\temp-files\\stored txt angelscript files\\output.txt";
    if (not IO::FileExists(filename)) {
        return;
    }

    Json::ToFile(filename, jsonValue);
}

void Main()
{
    IO::File file;

    const string filename = "E:\\study\\bachelor\\temp-files\\stored txt angelscript files\\output.txt";
    print(IO::FileExists(filename));

    const Json::Value value_from_file_json = Json::FromFile(filename);

    const string value_from_file_str = Json::Write(value_from_file_json);
                       
    print(value_from_file_str);
    
    while(true){
        bool gameUIVisible = UI::IsGameUIVisible();
        
        if (!gameUIVisible) {
            print("no gameUIVisible");
            sleep(500);
            continue;
        }

        CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
        if (vis is null) {
            print("We are looking for the best players");
        }
        else {
            if (vis.RaceStartTime == 0xFFFFFFFF) {
                print("it's pre-race mode");
                sleep(1000);
                continue;
            }
        }

        if (GetApp().CurrentPlayground is null || (GetApp().CurrentPlayground.UIConfigs.Length < 1)) {
            print("there is no playground on the back");
            sleep(1000);
            continue;
        }

        auto app = GetApp();
        SetCamType(app);

        Json::Value jsonObject = ObtainJsonFromVehicle();
        if (jsonObject is null) {
            print("No json info <3");
        }
        SaveJsonAsTxt(jsonObject);

        sleep(200);
    }    
}