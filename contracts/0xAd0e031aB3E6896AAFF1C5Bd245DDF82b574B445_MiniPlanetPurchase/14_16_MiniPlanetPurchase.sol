pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "./utils/Utils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

contract MiniPlanetPurchase is OwnableUpgradeable, UUPSUpgradeable {
    uint64 private _purchaseId;

    struct PurchaseData {
        uint256 price;
        uint256 blockHeight;
        uint64 purchaseNo;
        uint32 round;
        uint8 count;
        address ethAddress;
    }

    struct SalesInfo {
        uint256 price;
        uint32 round;
        uint32 salesCount;
    }

    bool public _activated;
    address public _treasury;
    uint64 public _salesCompleteCount;
    
    IERC20Upgradeable public _USDT;
    mapping(uint => PurchaseData) public _purchaseDataByPurchaseId;
    mapping(address => PurchaseData[]) public _purchaseDataListByAddress;
    SalesInfo public _salesInfo;

    event PurchasePlanet(uint32 indexed round, uint64 indexed purchaseNo, address ethAddress, 
        uint256 price, uint8 count, uint256 blockHeight);

    function initialize(address udst) public initializer {
        require(udst != address(0));
        _USDT = IERC20Upgradeable(udst);

        _salesCompleteCount = 0;
        _activated = false;
        _purchaseId = 1;

        __Ownable_init();   
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setSalesInfo(uint32 round, uint32 totalCount, uint256 price) external onlyOwner {
        require(!_activated, "smart contract is activated");
        require(totalCount != 0, "sales planet count is zero");
        require(price != 0, "sales price is zero");

        _salesInfo.round = round;
        _salesInfo.salesCount = totalCount;
        _salesInfo.price = price;

        _salesCompleteCount = 0;
    }

    function requestPurchase(uint8 count) external {
        uint64 saleIdx = _purchaseId;
        uint64 saledCount = _salesCompleteCount;
        
        require(_activated, "smart contract is not activated");
        require(_treasury != address(0), "treasury Address is empty");
        require(count != 0, "purchase count is zero");
        require(count <= 50, "can purchase up to 50 pieces");
        require(_salesInfo.salesCount >= _salesCompleteCount + count, "over the total sales count");
        require(_USDT.balanceOf(msg.sender) >= _salesInfo.price * count, "not enough balance");
        SafeERC20Upgradeable.safeTransferFrom(_USDT, msg.sender, _treasury, _salesInfo.price  * count);

        PurchaseData memory data = PurchaseData(_salesInfo.price, block.number, saleIdx, _salesInfo.round, count, msg.sender);
        _purchaseDataByPurchaseId[saleIdx] = data;
        _purchaseDataListByAddress[msg.sender].push(data);

        emit PurchasePlanet(_salesInfo.round, saleIdx, msg.sender, _salesInfo.price, count, block.number);
        saleIdx++;
        saledCount += count;                

        _purchaseId = saleIdx;
        _salesCompleteCount = saledCount;

        if (_salesInfo.salesCount == _salesCompleteCount) {
            _activated = false;
        }
    }

    function sendTreasury(uint256 amount) external {
        _USDT.transferFrom(msg.sender, _treasury, amount);
    }

    function setActivate(bool activate) external onlyOwner {
        _activated = activate;
    }

    function isActivated() external view returns (bool)  {
        return _activated;
    }

    function getPurchaseDataByPurchaseId(uint256 purchaseNo) external view returns (PurchaseData memory) {
        return _purchaseDataByPurchaseId[purchaseNo];
    }

    function getPurchaseDataListByAddress(address addr) external view returns(PurchaseData[] memory) {
        return _purchaseDataListByAddress[addr];
    }

    function setTreasury(address treasury) external onlyOwner {
        require(treasury != address(0), "new treasury is the zero address");
        _treasury = treasury;
    }

    function getSalesInfo() external view returns(SalesInfo memory) {
        return (_salesInfo);
    }

    function getAvailableCount() external view returns(uint64) {
        return _salesInfo.salesCount - _salesCompleteCount;
    }
}