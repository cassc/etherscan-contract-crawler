pragma solidity 0.8.19;

import "../interface/INFT.sol";
import "../interface/ISTBL.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Preseed is Ownable {
    struct DepositInfo {
        uint256 minimalValue;
        uint256 lockPeriod;
        uint256 apr;
    }

    struct UserInfo {
        INFT.Rarity rarity;
        uint256 value;
        uint256 claimDate;
        bool claimed;
    }

    mapping(INFT.Rarity => DepositInfo) public availableDeposits;
    mapping(address => UserInfo[]) public userInfos;

    ISTBL public stbl;
    INFT public nft_slag;

    uint256 public startDate;
    uint256 public endDate;
    bool public startCheck;

    uint256 constant public HUNDRED_PERCENT = 10 ** 30;

    modifier onlyWhenActive() {
        require(block.timestamp >= startDate && block.timestamp <= endDate, "not active");
        _;
    }

    constructor(address _stbl, address _nft_slag, DepositInfo[] memory _depositInfo) {
        require(_stbl != address(0), "invalid stbl address");
        require(_nft_slag != address(0), "invalid nft_slag address");
        require(_depositInfo.length == 4, "deposit info doesn't match with numbers of rarity");

        stbl = ISTBL(_stbl);
        nft_slag = INFT(_nft_slag);
        
        availableDeposits[INFT.Rarity.Common] = _depositInfo[0];
        availableDeposits[INFT.Rarity.Rare] = _depositInfo[1];
        availableDeposits[INFT.Rarity.Legendary] = _depositInfo[2];
        availableDeposits[INFT.Rarity.Epic] = _depositInfo[3];
    }

    function start() public onlyOwner {
        require(!startCheck, "already was started");
        startDate = block.timestamp;
        endDate = block.timestamp + 30 days;
        startCheck = true;
    }

    function deposit(uint256 _value, INFT.Rarity _rarity) public onlyWhenActive {
        DepositInfo memory _depositInfo = availableDeposits[_rarity];
        require(_value >= _depositInfo.minimalValue, "value too small");

        stbl.transferFrom(msg.sender, address(this), _value);
        stbl.burn(_value);
        userInfos[msg.sender].push(UserInfo(_rarity, _value, block.timestamp + _depositInfo.lockPeriod, false));
    }

    function claim(uint256 _index) public {
        UserInfo memory _userInfo = userInfos[msg.sender][_index];
        require(!_userInfo.claimed, "already claimed");
        require(block.timestamp >= _userInfo.claimDate, "not available for claim");

        nft_slag.claim(msg.sender, _userInfo.rarity, _userInfo.value);
        uint256 reward = _userInfo.value * availableDeposits[_userInfo.rarity].apr / HUNDRED_PERCENT;
        stbl.mint(msg.sender, reward + _userInfo.value);

        userInfos[msg.sender][_index] = UserInfo(_userInfo.rarity, _userInfo.value, _userInfo.claimDate, true);
    }

    function getUserInfoLength(address _user) public view returns(uint256) {
        return userInfos[_user].length;
    }

    function getUserInfoIndexed(address _user, uint256 _from, uint256 _to) public view returns(UserInfo[] memory) {
        UserInfo[] memory _info = new UserInfo[](_to - _from);

        for(uint256 _index = 0; _from < _to; ++_index) {
            _info[_index] = userInfos[_user][_from];
            _from++;
        }

        return _info;
    }
}