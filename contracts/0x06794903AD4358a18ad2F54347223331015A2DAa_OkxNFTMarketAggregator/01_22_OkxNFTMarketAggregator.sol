// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../tools/SecurityBaseFor8.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./markets/MarketRegistry.sol";
import "./interfaces/markets/IOkxNFTMarketAggregator.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../Adapters/libs/OKXSeaportLib.sol";
import "../Adapters/libs/SeaportLib.sol";
//import "hardhat/console.sol";

library MyTools {
    function getSlice(
        uint256 begin,
        uint256 end,
        bytes memory text
    ) internal pure returns (bytes memory) {
        uint256 length = end - begin;
        bytes memory a = new bytes(length + 1);
        for (uint256 i = 0; i <= length; i++) {
            a[i] = text[i + begin - 1];
        }
        return a;
    }

    function bytesToAddress(bytes memory bys)
        internal
        view
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function bytesToBytes4(bytes memory bys)
        internal
        view
        returns (bytes4 addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}

contract OkxNFTMarketAggregator is
    IOkxNFTMarketAggregator,
    SecurityBaseFor8,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder
{
    bool private _initialized;
    MarketRegistry public marketRegistry;

    bytes4 private constant _SEAPORT_ADAPTER_SEAPORTBUY = 0xb30f2249;
    bytes4 private constant _SEAPORT_ADAPTER_SEAACCEPT = 0x13a6f9b9;
    bytes4 private constant _SEAPORT_ADAPTER_SEAPORTBUY_ETH = 0x3f4a7fd1;
    uint private  constant _SEAPORT_LIB = 7;
    uint private constant _OKX_SEAPORT_LIB = 8;

    uint256 private constant _SEAPORT_BUY_ETH = 1;
    uint256 private constant _SEAPORT_BUY_ERC20 = 2;
    uint256 private constant _SEAPORT_ACCEPT = 3;

    event MatchOrderResults(bytes32[] orderHashes, bool[] results);

    struct AggregatorParam{
        uint256 payAmount;
        address payToken;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 tradeType;
    }

    function init(address newOwner) external {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _transferOwnership(newOwner);
    }

    function setMarketRegistry(address _marketRegistry) external onlyOwner {
        marketRegistry = MarketRegistry(_marketRegistry);
    }

    //compatibleOldVersion
    function trade(MarketRegistry.TradeDetails[] memory tradeDetails)
        external
        payable
        nonReentrant
    {
        uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](length);
        bool[] memory results = new bool[](length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < length; i++) {
            (address proxy, bool isLib, bool isActive) = marketRegistry.markets(
                tradeDetails[i].marketId
            );

            if (!isActive) {
                continue;
            }

            bytes memory tradeData = tradeDetails[i].tradeData;
            uint256 ethValue = tradeDetails[i].value;

            //okc wyvern
            if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.OKEXCHANGE_ERC20_ADAPTER)
            ) {
                bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(
                    orderToAddress == msg.sender,
                    "OKExchange orderToAddress error!"
                );
            } else if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.LOOKSRARE_ADAPTER)
            ) {
                //looksrare
                bytes memory tempAddr = MyTools.getSlice(81, 100, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(
                    orderToAddress == msg.sender,
                    "Loosrare orderToAddress error!"
                );
            } else if (
                tradeDetails[i].marketId ==
                uint256(MarketInfo.OPENSEA_SEAPORT_ADAPTER)
            ) {
                //opensea seaport
                bytes memory tempSelector = MyTools.getSlice(1, 4, tradeData);
                bytes4 functionSelector = MyTools.bytesToBytes4(tempSelector);
                if (
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY ||
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY_ETH
                ) {
                    bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "Opensea Seaport Buy orderToAddress error!"
                    );
                } else if (functionSelector == _SEAPORT_ADAPTER_SEAACCEPT) {
                    bytes memory tempAddr = MyTools.getSlice(
                        81,
                        100,
                        tradeData
                    );
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "Opensea Seaport Accept orderToAddress error!"
                    );
                } else {
                    revert("seaport adapter function error");
                }
            }

            (bool success, ) = isLib
                ? proxy.delegatecall(tradeData)
                : proxy.call{value: ethValue}(tradeData);

            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            if (!success) {
                giveBackValue += ethValue;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue-1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    //TODO
    function trade(
        MarketRegistry.TradeDetails[] memory tradeDetails,
        bool isFailed
    ) external payable nonReentrant {
        uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](length);
        bool[] memory results = new bool[](length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < length; i++) {
            (address proxy, bool isLib, bool isActive) = marketRegistry.markets(
                tradeDetails[i].marketId
            );

            if (!isActive) {
                continue;
            }

            bytes memory tradeData = tradeDetails[i].tradeData;
            uint256 ethValue = tradeDetails[i].value;

            //okc wyvern
            if (tradeDetails[i].marketId == 4) {
                bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(orderToAddress == msg.sender, "orderToAddress error!");
            } else if (tradeDetails[i].marketId == 2) {
                //looksrare
                bytes memory tempAddr = MyTools.getSlice(81, 100, tradeData);
                address orderToAddress = MyTools.bytesToAddress(tempAddr);
                require(orderToAddress == msg.sender, "orderToAddress error!");
            } else if (tradeDetails[i].marketId == 3) {
                //opensea seaport
                bytes memory tempSelector = MyTools.getSlice(1, 4, tradeData);
                bytes4 functionSelector = MyTools.bytesToBytes4(tempSelector);
                if (
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY ||
                    functionSelector == _SEAPORT_ADAPTER_SEAPORTBUY_ETH
                ) {
                    bytes memory tempAddr = MyTools.getSlice(49, 68, tradeData);
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "orderToAddress error!"
                    );
                } else if (functionSelector == _SEAPORT_ADAPTER_SEAACCEPT) {
                    bytes memory tempAddr = MyTools.getSlice(
                        81,
                        100,
                        tradeData
                    );
                    address orderToAddress = MyTools.bytesToAddress(tempAddr);
                    require(
                        orderToAddress == msg.sender,
                        "orderToAddress error!"
                    );
                } else {
                    revert("seaport adapter function error");
                }
            }

            (bool success, ) = isLib
                ? proxy.delegatecall(tradeData)
                : proxy.call{value: ethValue}(tradeData);
            if (isFailed && !success) {
                revert("Transaction Failed!");
            }
            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            if (!success) {
                giveBackValue += ethValue;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue-1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    //TODO
    function tradeV2(
        MarketRegistry.TradeDetails[] calldata tradeDetails,
        AggregatorParam[] calldata aggregatorParam,
        bool isAtomic
    ) external payable nonReentrant {
        //uint256 length = tradeDetails.length;
        bytes32[] memory orderHashes = new bytes32[](tradeDetails.length);
        bool[] memory results = new bool[](tradeDetails.length);
        uint256 giveBackValue;

        for (uint256 i = 0; i < tradeDetails.length;) {

            require(tradeDetails[i].marketId > 6,"tradeV2 didn't support!");

            (address proxy, bool isLib, bool isActive) = marketRegistry.markets(
                tradeDetails[i].marketId
            );

            if (!isActive) {
                continue;
            }

            bool success;
            //bytes memory tradeData = tradeDetails[i].tradeData;
            //uint256 ethValue = tradeDetails[i].value;

            if(tradeDetails[i].marketId==_SEAPORT_LIB||tradeDetails[i].marketId==_OKX_SEAPORT_LIB){

                processSeaport(tradeDetails[i],aggregatorParam[i]);
                success = true;
            }else{

                (success, ) = isLib
                ? proxy.delegatecall(tradeDetails[i].tradeData)
                : proxy.call{value: tradeDetails[i].value}(tradeDetails[i].tradeData);
            }

            if (isAtomic && !success) {
                revert("Transaction Failed!");
            }
            orderHashes[i] = tradeDetails[i].orderHash;
            results[i] = success;

            if (!success) {
                giveBackValue += tradeDetails[i].value;
            }
            unchecked {
                ++i;
            }
        }

        if (giveBackValue > 0) {
            (bool transfered, bytes memory reason) = msg.sender.call{
                value: giveBackValue - 1
            }("");
            require(transfered, string(reason));
        }

        emit MatchOrderResults(orderHashes, results);
    }

    function processSeaport(MarketRegistry.TradeDetails calldata tradeDetail,AggregatorParam calldata param) internal {
        //native token
        if(param.tradeType==_SEAPORT_BUY_ETH){
            if(tradeDetail.marketId==_SEAPORT_LIB){
                SeaportLib.buyAssetForETH(tradeDetail.tradeData, param.payAmount);
            }else if(tradeDetail.marketId==_OKX_SEAPORT_LIB){
                OKXSeaportLib.buyAssetForETH(tradeDetail.tradeData,param.payAmount);
            }
        }else if(param.tradeType==_SEAPORT_BUY_ERC20){
            //erc20 buy
            //console.logBytes(seaportData);
            if(tradeDetail.marketId==_SEAPORT_LIB){
                SeaportLib.buyAssetForERC20(tradeDetail.tradeData,param.payToken,param.payAmount);
            }else if(tradeDetail.marketId==_OKX_SEAPORT_LIB){
                OKXSeaportLib.buyAssetForERC20(tradeDetail.tradeData,param.payToken,param.payAmount);
            }
        }else if(param.tradeType==_SEAPORT_ACCEPT){
            //take offer
            if(tradeDetail.marketId==_SEAPORT_LIB){
                SeaportLib.takeOfferForERC20(tradeDetail.tradeData, param.tokenAddress, param.tokenId,
                    param.amount, param.payToken, param.tradeType);
            }else if(tradeDetail.marketId==_OKX_SEAPORT_LIB){
                OKXSeaportLib.takeOfferForERC20(tradeDetail.tradeData, param.tokenAddress, param.tokenId,
                    param.amount, param.payToken, param.tradeType);
            }
        }
    }
}