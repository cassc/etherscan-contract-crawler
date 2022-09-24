// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingState {

    // struct UserInfo {
    //     uint256 weight;
    //     uint256 totalWeight;
    // }

    struct UserState {
        uint256[6] weightCollection;
        uint256 bonusWeight;
        uint256 pid;
        // key only
        address user;
    }

    struct GlobalState {
        uint256[6] totalWeightCollection;
        uint256 totalBonusWeight;
        uint256 pid;
    }

    struct Config {
        uint256[6] factor;
        // key only
        uint256 pid;
    }

    uint256 private _globalState;
    mapping(uint256 => uint256) private _collectionConfig;
    mapping(address => uint256) private _userState;
    mapping(uint256 => mapping(address => uint256)) private _rewardDebt;

    function setUserWeight(UserState memory _state) internal {
        _userState[_state.user] = _state.weightCollection[0]
            | (_state.weightCollection[1] <<  32)
            | (_state.weightCollection[2] <<  64)
            | (_state.weightCollection[3] <<  96)
            | (_state.weightCollection[4] << 128)
            | (_state.weightCollection[5] << 160)
            | (_state.bonusWeight         << 192)
            | (_state.pid                 << 224);
    }

    function userState(address _user) public view returns(UserState memory _state) {
        uint256 state = _userState[_user];
        _state.weightCollection[0] = uint256(uint32(state       ));
        _state.weightCollection[1] = uint256(uint32(state >>  32));
        _state.weightCollection[2] = uint256(uint32(state >>  64));
        _state.weightCollection[3] = uint256(uint32(state >>  96));
        _state.weightCollection[4] = uint256(uint32(state >> 128));
        _state.weightCollection[5] = uint256(uint32(state >> 160));
        _state.bonusWeight         = uint256(uint32(state >> 192));
        _state.pid                 = uint256(uint32(state >> 224));

        _state.user = _user;
    }

    function setRewardDebt(uint256 _pid, address _user, uint256 rewardDebt_) internal {
        _rewardDebt[_pid][_user] = rewardDebt_; 
    }

    function rewardDebt(uint256 _pid, address _user) internal view returns (uint256) {
        return _rewardDebt[_pid][_user];   
    }

    function setGlobalState(GlobalState memory _state) internal {
        _globalState = _state.totalWeightCollection[0]
            | (_state.totalWeightCollection[1] <<  32)
            | (_state.totalWeightCollection[2] <<  64)
            | (_state.totalWeightCollection[3] <<  96)
            | (_state.totalWeightCollection[4] << 128)
            | (_state.totalWeightCollection[5] << 160)
            | (_state.totalBonusWeight         << 192)
            | (_state.pid                      << 224);
    }

    function globalState() public view returns(GlobalState memory _state) {
        uint256 state = _globalState;
        _state.totalWeightCollection[0] = uint256(uint32(state       ));
        _state.totalWeightCollection[1] = uint256(uint32(state >>  32));
        _state.totalWeightCollection[2] = uint256(uint32(state >>  64));
        _state.totalWeightCollection[3] = uint256(uint32(state >>  96));
        _state.totalWeightCollection[4] = uint256(uint32(state >> 128));
        _state.totalWeightCollection[5] = uint256(uint32(state >> 160));
        _state.totalBonusWeight         = uint256(uint32(state >> 192));
        _state.pid                      = uint256(uint32(state >> 224));
    }

    function setCollectionConfig(Config memory _config) internal {
        _collectionConfig[_config.pid] = _config.factor[0]
            | (_config.factor[1]          <<  8)
            | (_config.factor[2]          << 16)
            | (_config.factor[3]          << 24)
            | (_config.factor[4]          << 32)
            | (_config.factor[5]          << 40);
    }

    function collectionConfig(uint256 _pid) public view returns(Config memory _config) {
        uint256 config = _collectionConfig[_pid];
        _config.factor[0]          = uint256( uint8(config      ));
        _config.factor[1]          = uint256( uint8(config >>  8));
        _config.factor[2]          = uint256( uint8(config >> 16));
        _config.factor[3]          = uint256( uint8(config >> 24));
        _config.factor[4]          = uint256( uint8(config >> 32));
        _config.factor[5]          = uint256( uint8(config >> 40));
        _config.pid = _pid;
    }

    // function userInfo(address _user) external view returns (UserInfo memory _info) {
    //     UserState memory state = userState(_user);
    //     GlobalState memory global = globalState();
    //     Config memory config = collectionConfig(global.pid);

    //     _info.weight = getWeight(state, config);
    //     _info.totalWeight = getTotalWeight(global, config);
    // }

    function nextPid() internal returns (GlobalState memory _global) {
        _global = globalState();
        if (getTotalWeight(_global, collectionConfig(_global.pid)) == 0 && _global.totalBonusWeight == 0) {
            return _global;
        }

        _global.pid += 1;
        _global.totalBonusWeight = 0;
        setGlobalState(_global);
        return _global;
    }

    function getWeight(UserState memory _state, Config memory _config) internal pure returns (uint256) {
        return getCollectionsWeight(_state, _config) + getBonusWeight(_state, _config);
    }

    function getBonusWeight(UserState memory _state, Config memory _config) internal pure returns (uint256) {
        return _state.pid == _config.pid ? _state.bonusWeight : 0;
    }

    function getCollectionsWeight(UserState memory _state, Config memory _config) internal pure returns (uint256) {
        return _state.weightCollection[0] * _config.factor[0]
             + _state.weightCollection[1] * _config.factor[1]
             + _state.weightCollection[2] * _config.factor[2]
             + _state.weightCollection[3] * _config.factor[3]
             + _state.weightCollection[4] * _config.factor[4]
             + _state.weightCollection[5] * _config.factor[5];
    }

    function getTotalWeight(GlobalState memory _global, Config memory _config) internal pure returns (uint256) {
        return _global.totalWeightCollection[0] * _config.factor[0]
             + _global.totalWeightCollection[1] * _config.factor[1]
             + _global.totalWeightCollection[2] * _config.factor[2]
             + _global.totalWeightCollection[3] * _config.factor[3]
             + _global.totalWeightCollection[4] * _config.factor[4]
             + _global.totalWeightCollection[5] * _config.factor[5]
             + _global.totalBonusWeight;
    }
}