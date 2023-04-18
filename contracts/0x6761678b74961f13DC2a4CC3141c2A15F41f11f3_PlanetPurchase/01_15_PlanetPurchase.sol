pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "./utils/Utils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract PlanetPurchase is OwnableUpgradeable, UUPSUpgradeable {
    uint8 private ROUND_PLANET_COUNT;
    uint8 private PRESALES_PLANET_COUNT;
    uint64 private _publicSalesIndex;

    struct PurchaseData {
        uint256 planetPrice;
        uint256 blockHeight;
        uint64 serialNo;
        uint64 planetID;
        uint32 round;
        string ethAddress;
    }

    bool public _activated;
    address public _signer;
    address public _treasury;
    uint64 private _salesCompleteCount;
    uint32 private _curRound;
    
    IERC20Upgradeable public _USDT;
    mapping(uint => PurchaseData) public _purchaseDataByPlanetID;
    mapping(string => PurchaseData[]) public _purchaseDataListByAddress;

    uint32 public _endRound;

    event PurchasePlanet(uint32 indexed round, uint64 indexed planetID, uint64 indexed serialNo, string ethAddress, 
        uint256 planetPrice, uint256 blockHeight);

    function initialize(address udst) public initializer {
        require(udst != address(0));
        _USDT = IERC20Upgradeable(udst);

        _publicSalesIndex = 101;
        _salesCompleteCount = 0;
        _activated = false;
        _curRound = 1;
        _endRound = 999;
        ROUND_PLANET_COUNT = 100;
        PRESALES_PLANET_COUNT = 100;

        __Ownable_init();   
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
    }

    function parseInvoice(bytes memory invoice) internal pure returns (bytes[] memory retData) {
        uint256 tokenLength = 0;
        uint256 idx = 0;
        uint256 startIdx = 0;
    
        retData = new bytes[](4);

        for(uint256 pos = 0; pos < invoice.length; pos++) {
            if (invoice[pos] == 0x7c) {                 
                retData[idx] = Utils.slice(invoice, startIdx, tokenLength);
                startIdx += tokenLength + 1;
                tokenLength = 0;
                idx++;
            } else {
                tokenLength++;
            }
        }
        if (idx < 4)
            retData[idx] = Utils.slice(invoice, startIdx,tokenLength);

        return retData;
    }

    function requestPurchase(bytes memory invoice, uint8 v, bytes32 r, bytes32 s) external {
        bytes[] memory invoiceData;
        uint256 price = 0;
        uint64 serialNo = 0;
        string memory ethAddress = "";
        uint64 saleIdx = _publicSalesIndex;
        uint64 saledCount = _salesCompleteCount;
        uint32 round = 0;
        
        require(_activated, "Smart contract is not activated");
        require(_signer != address(0), "Singer Address is empty");
        require(_treasury != address(0), "Treasury Address is empty");

        if (ecrecover(keccak256(invoice), v, r, s) == _signer) {
            invoiceData = parseInvoice(invoice);

            require(invoiceData[0].length != 0, "Ethereum address is null");
            require(invoiceData[1].length != 0, "Round is null");
            require(invoiceData[2].length != 0, "SerialNo is null");
            require(invoiceData[3].length != 0, "Planet price is null");

            ethAddress = Utils.bytesToString(invoiceData[0]);
            round = Utils.bytesToUint32(invoiceData[1]);
            serialNo = Utils.bytesToUint64(invoiceData[2]);
            price = Utils.bytesToUint256(invoiceData[3]);

            require(price != 0, "price is zero");
            require(_curRound == round, "Please check the round you are requesting for purchase");
            require(_curRound <= _endRound, "Smart contract is closed.");
            require(_purchaseDataByPlanetID[saleIdx].planetPrice == 0, "Planet has already been sold");
            require(_USDT.balanceOf(msg.sender) >= price, "not enough balance");
            SafeERC20Upgradeable.safeTransferFrom(_USDT, msg.sender, _treasury, price);

            PurchaseData memory data = PurchaseData(price, block.number, serialNo,
                    saleIdx, round, ethAddress);
            _purchaseDataByPlanetID[saleIdx] = data;
            _purchaseDataListByAddress[ethAddress].push(data);

            emit PurchasePlanet(round, saleIdx, serialNo, ethAddress, price, block.number);
            saleIdx++;
            saledCount++;                

            _publicSalesIndex = saleIdx;
            _salesCompleteCount = saledCount;

            if (ROUND_PLANET_COUNT == _salesCompleteCount) {
                _curRound++;
                _salesCompleteCount = 0;
            }
        } else {
            revert("The signatures are different");
        }
    }

    function sendTreasury(uint256 amount) external {
        // _USDT.transferFrom(msg.sender, address(this), amount);
        // _USDT.transfer(_treasury, amount);
        require(_USDT.balanceOf(msg.sender) >= amount, "not enough balance");
        SafeERC20Upgradeable.safeTransferFrom(_USDT, msg.sender, _treasury, amount);
    }

    function getSalesCompleteCount() external view returns (uint) {
        return SafeMath.sub(_publicSalesIndex, PRESALES_PLANET_COUNT+1);
    }

    function setActivate(bool activate) external onlyOwner {
        _activated = activate;
    }

    function isActivated() external view returns (bool)  {
        return _activated;
    }

    function setSigner(address signer) external onlyOwner {
        require(signer != address(0), "new signer is the zero address");
        _signer = signer;
    }

    function getPurchaseDataByPlanetID(uint256 planetID) external view returns (PurchaseData memory) {
        return _purchaseDataByPlanetID[planetID];
    }

    function getPurchaseDataListByAddress(string memory addr) external view returns(PurchaseData[] memory) {
        return _purchaseDataListByAddress[addr];
    }

    function setTreasury(address treasury) external onlyOwner {
        require(treasury != address(0), "new treasury is the zero address");
        _treasury = treasury;
    }

    function getLastPlanetID() external view returns(uint256) {
        return SafeMath.sub(_publicSalesIndex, 1);
    }

    function getSalesInfo() external view returns(uint32, uint256) {
        return (_curRound, SafeMath.sub(_publicSalesIndex, PRESALES_PLANET_COUNT+1));
    }

    function setEndRound(uint32 round) external onlyOwner {
        require(_curRound <= round, "check value round is bigger current round");
        _endRound = round;
    }
}