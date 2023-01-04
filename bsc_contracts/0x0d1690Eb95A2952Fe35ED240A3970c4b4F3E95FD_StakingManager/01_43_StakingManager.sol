// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../piglet/Pigletz.sol";
import "../boosters/IBooster.sol";
import "./IStakingManager.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";
contract StakingManager is IStakingManager, IERC721Receiver, Ownable, Pausable {

    using EnumerableSet for EnumerableSet.UintSet;

    uint256[] private _periodsInSeconds;

    mapping (uint256 => StakedPigletInfo) private _stakeData;
    mapping (address => EnumerableSet.UintSet) private _tokensByOwner;

    Pigletz private _pigletz;
    IBooster private _stakingBooster;

    constructor(Pigletz pigletz, uint256[] memory periodsInSeconds) {
        _pigletz = pigletz;
        _stakingBooster = _pigletz.getBoosters()[9];
        _periodsInSeconds = periodsInSeconds;
    }

    function setPeriods(uint256[] calldata periodsInSeconds) external onlyOwner {
        _periodsInSeconds = periodsInSeconds;
    }

    function getPeriods() external view returns(uint256[] memory) {
        return _periodsInSeconds;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4) {
        require(data.length == 1, "Invalid or missing period");
        require(operator != address(this) && from != address(this), "Circular transfer not allowed");
        uint8 periodId;
        assembly {
            periodId := mload(add(data, add(0x01, 0)))
        }
        _stake(tokenId, from, periodId, false);
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(uint256 tokenId, uint8 periodId)
    external returns (StakedPigletInfo memory) {
        return _stake(tokenId, msg.sender, periodId, true);
    }

    function _stake(uint256 tokenId, address tokenOwner, uint8 periodId, bool transfer)
    internal returns (StakedPigletInfo memory) {
        StakedPigletInfo memory data = _stakeData[tokenId];
        require(data.tokenOwner == address(0), "This Piglet is already staked");

        if (transfer) {
            require(_pigletz.ownerOf(tokenId) == tokenOwner, "This Piglet is not owned by you");
            require(_pigletz.getApproved(tokenId) == address(this) ||
                    _pigletz.isApprovedForAll(tokenOwner, address(this)),
                "StakingManager not approved for this token");
            _pigletz.transferFrom(tokenOwner, address(this), tokenId);
        }

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        _stakingBooster.boost(tokenIds);

        uint256 periodInSeconds = _periodsInSeconds[periodId];
        _tokensByOwner[tokenOwner].add(tokenId);
        uint256 stakedUntilDate = block.timestamp + periodInSeconds;
        _stakeData[tokenId] = StakedPigletInfo({
           tokenOwner: tokenOwner,
            periodInSeconds: periodInSeconds,
            stakedOnDate: block.timestamp,
            stakedUntilDate: stakedUntilDate
        });
        emit Staked(tokenOwner, tokenId, periodInSeconds, block.timestamp, stakedUntilDate);
        return _stakeData[tokenId];
    }

    function stakeBatch(uint256[] calldata tokenIds, uint8 periodId)
    external returns (StakedPigletInfo[] memory info) {
        info = new StakedPigletInfo[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i ++) {
            info[i] = _stake(tokenIds[i], msg.sender, periodId, true);
        }
    }

    function unstake(uint256 tokenId) public {
        address tokenOwner = msg.sender;
        require(_tokensByOwner[tokenOwner].contains(tokenId), "Token not found in your stakes");
        StakedPigletInfo memory data = _stakeData[tokenId];
        require(block.timestamp >= data.stakedUntilDate, "This stake period hasn't expired yet");
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        _stakingBooster.unBoost(tokenIds);
        _tokensByOwner[tokenOwner].remove(tokenId);
        _pigletz.transferFrom(address(this), tokenOwner, tokenId);
        emit Unstaked(tokenOwner, tokenId, data.periodInSeconds, data.stakedOnDate, block.timestamp);
    }

    function unstakeBatch(uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i ++) {
            unstake(tokenIds[i]);
        }
    }

    function isStakable(uint256 tokenId) public view returns(bool) {
        StakedPigletInfo memory data = _stakeData[tokenId];
        return data.tokenOwner == address(0);
    }

    function areStakable(uint256[] calldata tokenIds) external view returns(bool[] memory result) {
        result = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i ++) {
            result[i] = isStakable(tokenIds[i]);
        }
    }

    function isStaked(uint256 tokenId) public view returns (bool) {
        StakedPigletInfo memory data = _stakeData[tokenId];
        return (data.tokenOwner != address(0) && _tokensByOwner[data.tokenOwner].contains(tokenId));
    }

    function areStaked(uint256[] calldata tokenIds) external view returns (bool[] memory result) {
        result = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i ++) {
            result[i] = isStaked(tokenIds[i]);
        }
    }

    function countPigletzByOwner(address account) public view returns (uint256) {
        return _tokensByOwner[account].length();
    }

    function listTokenIdsByOwner(address account) public view returns (uint256[] memory tokenIds) {
        return _tokensByOwner[account].values();
    }

    function listPigletzByOwner(address account) external view returns (StakedPigletInfo[] memory info) {
        uint256[] memory tokenIds = listTokenIdsByOwner(account);
        info = getStakeBatchData(tokenIds);
    }

    function getStakeData(uint256 tokenId) external view returns (StakedPigletInfo memory) {
        return _stakeData[tokenId];
    }

    function getStakeBatchData(uint256[] memory tokenIds) public view returns (StakedPigletInfo[] memory info) {
        info = new StakedPigletInfo[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i ++) {
            info[i] = _stakeData[tokenIds[i]];
        }
    }

    function pigletzByOwner(
        address tokenOwner,
        uint256 start,
        uint256 limit
    ) external view returns (Pigletz.PigletData[] memory) {
        uint256 total = countPigletzByOwner(tokenOwner);
        require(start <= total, "Start index must be less than or equal to total pigletz");
        uint256 end = start + limit;

        if (start == 0 && limit == 0) {
            end = total;
        }
        uint256 size = Math.min(total, end) - start;
        Pigletz.PigletData[] memory pigletz = new Pigletz.PigletData[](size);
        uint256[] memory tokenIds = listTokenIdsByOwner(tokenOwner);
        for (uint256 i = start; i < start + size; i++) {
            pigletz[i - start] = _pigletz.getPigletData(tokenIds[i]);
        }
        return pigletz;
    }
}