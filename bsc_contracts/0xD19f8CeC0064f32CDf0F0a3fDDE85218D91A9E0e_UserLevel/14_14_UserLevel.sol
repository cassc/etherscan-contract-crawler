//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libraries/Math.sol";
import "../interfaces/IUserLevel.sol";
import "../interfaces/IAvatar.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IFarming.sol";


contract UserLevel is Ownable, IUserLevel {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Address for address;

    EnumerableSet.AddressSet validators;
    EnumerableSet.AddressSet staking;

    mapping(address => BonusInfo) boostLevel;
    mapping(address => UserInfo) user;
    mapping(address => Counters.Counter) private _nonces;

    uint constant public ONE_HUNDRED_PERCENT = 10000;
    uint public baseLevel = 5000;

    IAvatar public avatarUserLevel;
    IFarming public farming;

    //===================EVENT=================== //
    event ConfigBaseLevel(uint _old, uint _new);
    event UpdateUserExp(address _user, uint _oldExp, uint _newExp, uint _oldLevel, uint _newLevel, address[] _validators);
    event ConfigBonus(address _contract, uint[] _bonus, uint[] _level);
    event AddValidator(address[] _validators);
    event RemoveValidator(address[] _validators);
    event AvatarAddressChanged(address _avatar);
    event FarmingAddressChanged(address _farming);
    event SetUserExp(address _user, uint _oldExp, uint _newExp, uint _oldLevel, uint _newLevel);

    // ================= PUBLIC FUNCTIONS ================= //
    function nonces(address _owner) public view override returns (uint) {
        return _nonces[_owner].current();
    }

    function getUserLevel(address _user) public view override returns(uint _level){
        _level= user[_user].level;
    }

    function getUserExp(address _user) public view override returns(uint _exp){
        _exp= user[_user].exp;
    }

    function getUserInfo(address _user) public view override returns(UserInfo memory _userInfo){
        _userInfo = user[_user];
    }

    function getConfigBonus(address _contract) external view returns(uint256[] memory, uint256[] memory) {
        return (boostLevel[_contract].level, boostLevel[_contract].bonus);
    }

    // ================= EXTERNAL FUNCTIONS ================= //
    function getBonus(address _user, address _contract) external view override returns(uint256, uint256) {
        if(boostLevel[_contract].level.length == 0){
            return(0, ONE_HUNDRED_PERCENT);
        }

        uint _levelUser = getUserLevel(_user);
        BonusInfo storage info = boostLevel[_contract];

        for(uint i = 0; i < info.level.length; i++) {
            if(_levelUser <= info.level[i]) {
                return (info.bonus[i], ONE_HUNDRED_PERCENT);
            }
        }

        return (info.bonus[info.bonus.length - 1], ONE_HUNDRED_PERCENT);
    }

    function updateUserExp(uint _exp, uint _expiredTime, address[] memory _lStaking, uint[] memory _pIds, bytes[] memory _signature) external override{
        require(msg.sender != address(0),"UserLevel: Address not zero");
        require(block.timestamp <= _expiredTime, "UserLevel: Expired time");

        bytes32 _hash = _prefixed(keccak256(abi.encodePacked(_exp, _expiredTime, _lStaking, _pIds, msg.sender, address(this), _useNonce(msg.sender))));
        address[] memory _validatorSignature = _getValidatorSignature(_hash, _signature);

        require(_validatorSignature.length > 0, "UserLevel: Signature not empty");
        for(uint i = 0; i < _validatorSignature.length; i++){
            require(validators.contains(_validatorSignature[i]), "UserLevel: Signature invalid");
        }

        UserInfo storage userInfo = user[msg.sender];
        uint _oldExp = userInfo.exp;
        uint _oldLevel = userInfo.level;
        userInfo.exp = _oldExp + _exp;
        userInfo.level = _calculatorLevel(userInfo.exp, userInfo.level, baseLevel);

        if(_oldLevel < userInfo.level){
            if(address(avatarUserLevel) != address(0)){
                for(uint i = 1; i <= (userInfo.level - _oldLevel); i++){
                    avatarUserLevel.createAvatar(_oldLevel + i, msg.sender);
                }
            }
            _updateBonusStaking(_lStaking);
            _updateBonusFarming(_pIds);
        }

        emit UpdateUserExp(msg.sender, _oldExp, userInfo.exp, _oldLevel, userInfo.level, _validatorSignature);
    }

    function listValidator() external view override returns(address[] memory _list) {
        _list = validators.values();
    }

    function estimateExpNeed(uint _level) external view override returns(uint _exp){
        _exp = _calculatorExpNeed(_level, baseLevel);
    }

    function estimateLevel(uint _epx) external view override returns(uint _level){
        _level = _calculatorLevel(_epx, 0, baseLevel);
    }

    // ================= ADMIN FUNCTIONS ================= //
    function setUserExp(address _user, uint _exp, address[] memory _lStaking, uint[] memory _pIds) public onlyOwner{
        UserInfo storage userInfo = user[_user];
        uint _oldExp = userInfo.exp;
        uint _oldLevel = userInfo.level;
        userInfo.exp = _exp;
        userInfo.level = _calculatorLevel(_exp, 0, baseLevel);

        _updateBonusStaking(_lStaking);
        _updateBonusFarming(_pIds);

        emit SetUserExp(_user,  _oldExp, userInfo.exp, _oldLevel, userInfo.level);
    }

    function configBaseLevel(uint _baseLevel) external onlyOwner override{
        uint _old = baseLevel;
        baseLevel = _baseLevel;
        emit ConfigBaseLevel(_old, _baseLevel);
    }

    function configBonus(address _contractAddress, uint[] memory _bonus, uint[] memory _level) external onlyOwner override{
        require(_level.length == _bonus.length, "UserLevel: length not equal");

        BonusInfo storage _info = boostLevel[_contractAddress];

        if(_info.level.length > 0){
            delete _info.level;
            delete _info.bonus;
        }

        for(uint i = 0; i < _level.length; i++) {
            if(i > 0) {
                require(_level[i] > _level[i-1], "UserLevel: level incorrect");
            }
            _info.level.push(_level[i]);
            _info.bonus.push(_bonus[i]);
        }

        emit ConfigBonus(_contractAddress, _bonus, _level);
    }

    function addValidator(address[] memory _validator) external override onlyOwner {
        for(uint i = 0; i < _validator.length; i++){
            if(!validators.contains(_validator[i])){
                validators.add(_validator[i]);
            }
        }

        emit AddValidator(_validator);
    }

    function removeValidator(address[] memory _validator) external override onlyOwner{
        for(uint i = 0; i < _validator.length; i++){
            if(validators.contains(_validator[i])){
                validators.remove(_validator[i]);
            }
        }

        emit RemoveValidator(_validator);
    }

    function changeAvatarAddress(address _avatar) external override onlyOwner{
        avatarUserLevel = IAvatar(_avatar);
        emit AvatarAddressChanged(_avatar);
    }

    function changeFarmingAddress(address _farming) external override onlyOwner{
        farming = IFarming(_farming);
        emit FarmingAddressChanged(_farming);
    }

    // ================= INTERNAL FUNCTIONS ================= //
    function _getValidatorSignature(bytes32 _hash, bytes[] memory _signature) internal view returns (address[] memory) {
        uint length = _signature.length;
        address[] memory signer = new address[](length);
        for(uint i = 0; i < length; i++){
            signer[i] = ECDSA.recover(_hash, _signature[i]);
        }
        return signer;
    }

    function _prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    function _calculatorLevel(uint _exp, uint _lastLevel, uint _baseLevel) internal pure returns(uint _level){
        _level = _lastLevel;
        while(_exp >= _calculatorExpNeed(_level + 1, _baseLevel)){
            _level++;
        }
    }

    function _calculatorExpNeed(uint _level, uint _baseLevel) internal pure returns(uint _exp){
        _exp = (25**_level)* _baseLevel/(10**(_level+1));
    }

    function _useNonce(address _owner) internal virtual returns (uint256 _current) {
        Counters.Counter storage nonce = _nonces[_owner];
        _current = nonce.current();
        nonce.increment();
    }

    function _updateBonusFarming(uint[] memory _pIds) internal{
        if(address(farming) != address(0)){
            for(uint i = 0; i < _pIds.length; i++){
                farming.update(_pIds[i], msg.sender);
            }
        }
    }

    function _updateBonusStaking(address[] memory _listStaking) internal{
        for(uint i = 0; i < _listStaking.length; i++){
            if(_listStaking[i].isContract()){
                IStaking(_listStaking[i]).update(msg.sender);
            }
        }
    }
}