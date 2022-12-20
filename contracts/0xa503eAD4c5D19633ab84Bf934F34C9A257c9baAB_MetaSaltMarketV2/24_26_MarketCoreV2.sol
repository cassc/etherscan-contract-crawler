// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../common/lib/LibOrder.sol";
import "../common/lib/LibTransfer.sol";
import "../common/lib/LibAsset.sol";
import "../common/OrderValidator.sol";
import "./TransferManagerV2.sol";
import "../common/lib/LibERC721LazyMint.sol";
contract MarketCoreV2 is Initializable, PausableUpgradeable, OrderValidator, TransferManagerV2 {
    using SafeMathUpgradeable for uint;
    using LibTransfer for address;
    //state of the orders
    mapping(bytes32 => uint) public orderState;    
    bytes constant EMPTY = "";    
    //events
    event Cancel(bytes32 hash, address maker, LibAsset.AssetType makeAssetType, LibAsset.AssetType takeAssetType);
    event OrderCompleted(bytes32 leftHash, bytes32 rightHash, address leftMaker, address rightMaker, LibAsset.AssetType leftAsset, LibAsset.AssetType rightAsset);    

    function matchAndTransfer(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal {        
                // Excute Order
        address seller = orderLeft.maker;
        address buyer = orderRight.maker;
        uint256 price = orderLeft.takeAsset.value;
        uint256 fee = price.mul(protocolFee).div(1000);    
        uint256 remainPrice = price.sub(fee);    
        address(defaultFeeReceiver).transferEth1(fee);
        uint256[] memory royaltyPrices;        
        address payable[] memory creators;
        if (orderLeft.makeAsset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {                               
            transferERC721(orderLeft.makeAsset, seller, buyer);             
            (creators, royaltyPrices) = getRoyaltyInfoERC721(orderLeft.makeAsset, price);    
            if (creators.length > 0 || (creators.length == 1 && creators[0] != seller && creators[0] != address(0))) {
                for (uint i = 0; i < creators.length; i++){
                    if (creators[i] != address(0) && royaltyPrices[i] > 0) {
                        remainPrice -= royaltyPrices[i];
                        address(creators[i]).transferEth2(royaltyPrices[i]);
                    }                    
                }
            }                
        } else if (orderLeft.makeAsset.assetType.assetClass == LibAsset.ERC721_LAZY_ASSET_CLASS){                     
            transferERC721LazyMint(orderLeft.makeAsset, seller, buyer);
            (creators, royaltyPrices) = getRoyaltyInfoERC721Lazy(orderLeft.makeAsset, price);                        
            if (creators.length > 0 || (creators.length == 1 && creators[0] != seller && creators[0] != address(0))) {
                for (uint i = 0; i < creators.length; i++){
                    if (creators[i] != address(0) && royaltyPrices[i] > 0) {
                        remainPrice -= royaltyPrices[i];
                        address(creators[i]).transferEth2(royaltyPrices[i]);
                    }                    
                }
            }       
        } else if (orderLeft.makeAsset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {                        
            transferERC1155(orderLeft.makeAsset, seller, buyer);
            (creators, royaltyPrices) = getRoyaltyInfoERC1155(orderLeft.makeAsset, price);                        
            if (creators.length > 0 || (creators.length == 1 && creators[0] != seller && creators[0] != address(0))) {
                for (uint i = 0; i < creators.length; i++){
                    if (creators[i] != address(0) && royaltyPrices[i] > 0) {
                        remainPrice -= royaltyPrices[i];
                        address(creators[i]).transferEth3(royaltyPrices[i]);
                    }                    
                }
            }      
        } else if (orderLeft.makeAsset.assetType.assetClass == LibAsset.ERC1155_LAZY_ASSET_CLASS){                     
            transferERC1155LazyMint(orderLeft.makeAsset, seller, buyer);
            (creators, royaltyPrices) = getRoyaltyInfoERC1155Lazy(orderLeft.makeAsset, price);                        
            if (creators.length > 0 || (creators.length == 1 && creators[0] != seller && creators[0] != address(0))) {
                for (uint i = 0; i < creators.length; i++){
                    if (creators[i] != address(0) && royaltyPrices[i] > 0) {
                        remainPrice -= royaltyPrices[i];
                        address(creators[i]).transferEth3(royaltyPrices[i]);
                    }                    
                }
            }      
        }    
        if (remainPrice > 0)         
            address(seller).transferEth4(remainPrice);   
    }

    function fundContract() public payable
    {
    }

    function withdraw(uint256 value) public onlyOwner
    {
        address(msg.sender).transferEth1(value);
    }

    function withdrawTest(uint256 amount) public onlyOwner
    {
        (bool success, ) = msg.sender.call{value: amount}("");        
        require(success, "transfer failed");
    }

    function cancel(LibOrder.Order memory order) external {
        require(_msgSender() == order.maker, "not a maker");        
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        orderState[orderKeyHash] = 3;
        emit Cancel(orderKeyHash, order.maker, order.makeAsset.assetType, order.takeAsset.assetType);
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable nonReentrant{                        
        require(orderRight.makeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS, "only ETH supports.");
        require(orderLeft.takeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS, "only ETH supports.");
        require(orderLeft.taker == address(0), "leftOrder.taker verification failed");
        require(orderRight.taker == address(0), "rightOrder.taker verification failed");
        require(orderRight.maker == msg.sender, "should be buyer!");
        require(orderLeft.takeAsset.value == msg.value, "price should be correct!");                        
        validateFull(orderLeft, signatureLeft);        
        validateFull(orderRight, signatureRight);        
        checkMatchAssets(orderLeft, orderRight);    
        matchAndTransfer(orderLeft, orderRight);        
        bytes32 orderLeftKeyHash = LibOrder.hashKey(orderLeft);
        bytes32 orderRightKeyHash = LibOrder.hashKey(orderRight);
        emit OrderCompleted(orderLeftKeyHash, orderRightKeyHash, orderLeft.maker, orderRight.maker, orderLeft.makeAsset.assetType, orderLeft.takeAsset.assetType);
    }

    function checkMatchAssets(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal pure returns (LibAsset.AssetType memory makeMatch, LibAsset.AssetType memory takeMatch) {
        makeMatch = matchAssets(orderLeft.makeAsset.assetType, orderRight.takeAsset.assetType);
        require(makeMatch.assetClass != 0, "assets don't match");
        takeMatch = matchAssets(orderLeft.takeAsset.assetType, orderRight.makeAsset.assetType);
        require(takeMatch.assetClass == 0, "assets don't match");
    }

    function matchAssets(LibAsset.AssetType memory leftAssetType, LibAsset.AssetType memory rightAssetType) public pure returns (LibAsset.AssetType memory) {
        if (
            (rightAssetType.assetClass == LibAsset.ERC721_ASSET_CLASS) || 
            (rightAssetType.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS) ||
            (rightAssetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) || 
            (rightAssetType.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS)
        ) {
            (address leftToken, uint leftTokenId) = abi.decode(leftAssetType.data, (address, uint256));
            (address rightToken, uint rightTokenId) = abi.decode(rightAssetType.data, (address, uint256));
            if (leftToken == rightToken && leftTokenId == rightTokenId) {
                return LibAsset.AssetType(rightAssetType.assetClass, rightAssetType.data);
            }
        }
        return LibAsset.AssetType(0, EMPTY);
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature) internal view {        
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        require(orderState[orderKeyHash] == 0, "Order Should be Valid.");
        //LibOrder.validate(order);
        validate(order, signature);
    }

    uint256[49] private __gap;
}