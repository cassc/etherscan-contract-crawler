// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidationBurnRewards is Ownable {
    address public activeContract;
    address public inactiveContract;
    address public storageLayerContract;

    mapping(uint256 => uint256) private _heartLiqs;

    modifier onlyActive {
        require(msg.sender == activeContract, "na");
        _;
    }

    modifier onlyInactive {
        require(msg.sender == inactiveContract, "ni");
        _;
    }

    modifier onlyStorage {
        require(msg.sender == storageLayerContract, "nsl");
        _;
    }

    modifier onlyHearts {
        require(msg.sender == activeContract || msg.sender == inactiveContract, "na");
        _;
    }

    /********/

    constructor (
        address _activeContract,
        address _inactiveContract,
        address _storageLayerContract
    ) {
        activeContract = _activeContract;
        inactiveContract = _inactiveContract;
        storageLayerContract = _storageLayerContract;
    }

    /********/

    function liquidationRewardOf(uint256 heartId) public view returns (uint256) {
        return _heartLiqs[heartId]%(1<<128);
    }

    function batchLiquidationRewardOf(uint256[] calldata heartIds) public view returns (uint256) {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            amtToDisburse += _heartLiqs[heartId]%(1<<128);
        }

        return amtToDisburse;
    }

    function burnRewardOf(uint256 heartId) public view returns (uint256) {
        return _heartLiqs[heartId]>>128;
    }

    function batchBurnRewardOf(uint256[] calldata heartIds) public view returns (uint256) {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            amtToDisburse += (_heartLiqs[heartId]>>128);
        }

        return amtToDisburse;
    }

    function migrationRewardOf(uint256 heartId) public view returns (uint256) {
        return (liquidationRewardOf(heartId) + burnRewardOf(heartId));
    }

    function batchMigrationRewardOf(uint256[] calldata heartIds) public view returns (uint256) {
        return (batchLiquidationRewardOf(heartIds) + batchBurnRewardOf(heartIds));
    }

    /********/

    function _storeReward(uint256 heartId, uint256 msgValue) private {
        uint256 liqPortion = (msgValue*7)/10;
        _heartLiqs[heartId] += liqPortion + ((msgValue - liqPortion)<<128);
    }

    function storeReward(uint256 heartId) public payable onlyHearts {
        _storeReward(heartId, msg.value);
    }

    function disburseLiquidationReward(uint256 heartId, address to) public onlyActive {
        uint256 toPay = _heartLiqs[heartId]%(1<<128);
        (bool success, ) = payable(to).call{value: toPay}("");
        require(success, "pf");
        _heartLiqs[heartId] -= toPay;
    }

    function disburseBurnReward(uint256 heartId, address to) public onlyInactive {
        uint256 toPay = _heartLiqs[heartId]>>128;
        (bool success, ) = payable(to).call{value: toPay}("");
        require(success, "pf");
        _heartLiqs[heartId] -= (toPay<<128);
    }

    function batchStoreReward(uint256[] calldata heartIds) public payable onlyHearts {
        uint256 remToDistribute = msg.value;
        uint256 perHeart = msg.value/heartIds.length;

        for (uint256 i = 0; i < (heartIds.length - 1); i++) {
            _storeReward(heartIds[i], perHeart);
            remToDistribute -= perHeart;
        }

        _storeReward(heartIds[heartIds.length - 1], remToDistribute);
    }

    function batchDisburseLiquidationReward(uint256[] calldata heartIds, address to) public onlyActive {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            amtToDisburse += _heartLiqs[heartId]%(1<<128);
            _heartLiqs[heartId] -= _heartLiqs[heartId]%(1<<128);
        }

        (bool success, ) = payable(to).call{value: amtToDisburse}("");
        require(success, "pf");
    }

    function batchDisburseBurnReward(uint256[] calldata heartIds, address to) public onlyInactive {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            uint256 amtToAdd = _heartLiqs[heartId]>>128;
            amtToDisburse += amtToAdd;
            _heartLiqs[heartId] -= amtToAdd<<128;
        }

        (bool success, ) = payable(to).call{value: amtToDisburse}("");
        require(success, "pf");
    }

    /********/

    function disburseMigrationReward(uint256 heartId, address to) public onlyStorage {
        uint256 toPay = (_heartLiqs[heartId]%(1<<128)) + (_heartLiqs[heartId]>>128);
        (bool success, ) = payable(to).call{value: toPay}("");
        require(success, "pf");
        _heartLiqs[heartId] = 0;
    }

    function batchDisburseMigrationReward(uint256[] calldata heartIds, address to) public onlyStorage {
        uint256 amtToDisburse = 0;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
            amtToDisburse += (_heartLiqs[heartId]%(1<<128)) + (_heartLiqs[heartId]>>128);
            _heartLiqs[heartId] = 0;
        }
        (bool success, ) = payable(to).call{value: amtToDisburse}("");
        require(success, "pf");
    }

    /********/

    function setActiveContract(address newActiveContract) public onlyOwner {
        activeContract = newActiveContract;
    }

    function setInactiveContract(address newInactiveContract) public onlyOwner {
        inactiveContract = newInactiveContract;
    }

    function setStorageLayerContract(address newStorageLayerContract) public onlyOwner {
        storageLayerContract = newStorageLayerContract;
    }

    /********/

    receive() external payable {
        require(false, "This address should not be receiving funds by fallback!");
    }

    /**
     * @notice Tokens should not be sent to this address, but this function prevents
     *   tokens sent to this address from being "dead"/irretrievable
    **/
    function withdrawTokens(address to, address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////////////////////////