pragma solidity ^0.8.13;

// libs
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";
import "./ArtsyApes.sol";
import "./interfaces/IShop.sol";

contract Shop is IShop, AccessControl, Pausable{
    // =============================================================
    //                         Constants
    // =============================================================
    string constant MASTERPIECE = "masterpiece";

    string constant GICLEE = "giclee";

    bytes32 public constant ADMIN = keccak256("ADMIN");

    // =============================================================
    //                         Storage
    // =============================================================

    // ArtsyApes contract
    ArtsyApes public artsyApes;

    // USD stable coin contract
    ERC20 public usdStableCoinContract;

    // Contains information about the current live auction
    AuctionInfo public auctionInfo;

    // Highest in a live auction
    Bid public highestBid;

    // ProductInfo by a product name
    mapping(string => ProductInfo) public productInfo;

    // =============================================================
    //                      Constructor
    // =============================================================

    constructor(address artsyApesAddress) {
        AccessControl._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        artsyApes = ArtsyApes(artsyApesAddress);

        productInfo[MASTERPIECE] = ProductInfo(1, 2500 * 10 ** 6);
        productInfo[GICLEE] = ProductInfo(3, 480 * 10 ** 6);
    }

    // =============================================================
    //                      Stable coin
    // =============================================================
    function setErc20USDAddress(address erc20UsdAddress) onlyRole(ADMIN) override public{
        usdStableCoinContract = ERC20(erc20UsdAddress);
    }

    function withdraw(address to) onlyRole(ADMIN) override public{
        if(isAuctionLive()) revert OnGoingAuction();
        usdStableCoinContract.transfer(to, usdStableCoinContract.balanceOf(address(this)));
    }

    // =============================================================
    //                       Pausable
    // =============================================================
    function pause() whenNotPaused onlyRole(ADMIN) public{
        Pausable._pause();
    }

    function unpause() whenPaused onlyRole(ADMIN) public{
        Pausable._unpause();
    }

    // =============================================================
    //                        Auction
    // =============================================================
    function startAuction(uint32 duration) onlyRole(ADMIN) whenNotPaused override public{
        if(duration < 1 days) revert AuctionDurationLessThanDay();
        if(isAuctionLive()) revert OnGoingAuction();
        if(highestBid.$usdc != 0) revert AuctionNotResolved();
        
        auctionInfo = AuctionInfo(uint32(block.timestamp), uint32(block.timestamp) + duration);
        emit AuctionStart(uint32(block.timestamp), uint32(block.timestamp) + duration);
    }

    function setAuctionDuration(
        uint32 duration
    ) onlyRole(ADMIN) override public {
        if(!isAuctionLive()) revert NoOnGoingAuction();
        if(duration < 1 days) revert AuctionDurationLessThanDay();
        
        auctionInfo.expires = auctionInfo.start + duration;
    }
    
    function resolveBidding() whenNotPaused override public {
        if(isAuctionLive()) revert OnGoingAuction();
        artsyApes.createPhysicalItem(highestBid.tokenId, highestBid.owner, MASTERPIECE);
        highestBid = Bid(address(0), 0 ,0);
    }

    function isAuctionLive() public view override returns (bool){
        return (
            block.timestamp >= auctionInfo.start &&
            block.timestamp <= auctionInfo.expires
        );
    }

    // =============================================================
    //                 Product order/bidding
    // =============================================================
    function orderProduct(uint256 tokenId, string memory pName) whenNotPaused override public{
        if(address(usdStableCoinContract) == address(0)) revert UnsetERC20USDContract();
        if(artsyApes.ownerOf(tokenId) != msg.sender) revert Unauthorized();
        
        ProductInfo memory product = getProductInfo(pName);
        usdStableCoinContract.transferFrom(msg.sender, address(this), product.price);
        if(compareStrings(GICLEE, pName)){
            if(!artsyApes.isPhysicalItemAvailable(tokenId, GICLEE, product.physical_supply)) revert NoPhysicalAvailable();
            artsyApes.createPhysicalItem(tokenId, msg.sender, pName);
        }
        emit Order(tokenId, pName);
    }

    function placeBid(uint256 tokenId, uint256 $usdc) whenNotPaused override public {
        ProductInfo memory product = getProductInfo(MASTERPIECE);
        $usdc = $usdc * 10 ** 6;

        if(address(usdStableCoinContract) == address(0)) revert UnsetERC20USDContract();
        if (!isAuctionLive()) revert NoOnGoingAuction();
        if($usdc < product.price) revert UnderBid();
        if(artsyApes.ownerOf(tokenId) != msg.sender) revert Unauthorized();
        if(!artsyApes.isPhysicalItemAvailable(tokenId, MASTERPIECE, product.physical_supply)) revert NoPhysicalAvailable();
        
        if(highestBid.$usdc > 0){
            if ($usdc < highestBid.$usdc + 10 * 10 ** 6) revert UnderBid();
            usdStableCoinContract.transfer(highestBid.owner, highestBid.$usdc);
        }
        usdStableCoinContract.transferFrom(msg.sender, address(this), $usdc);
        highestBid = Bid(msg.sender, tokenId, $usdc);
        emit AuctionBid(msg.sender, tokenId, $usdc);
    }

    // =============================================================
    //                Product operations & queries
    // =============================================================    
    function getProductInfo(string memory pName) public view override returns(ProductInfo memory){
        return _getProductInfo(pName);
    }

    function _getProductInfo(string memory pName) private view returns(ProductInfo storage){
        ProductInfo storage product = productInfo[pName];
        if(product.price == 0 && product.physical_supply == 0) revert NonExistingProduct();
        return product;
    }

    function addProductInfo(string memory pName, uint8 supply, uint256 price) onlyRole(ADMIN) override public {
        if(compareStrings(pName, "")) revert ProductNoName();
        if(supply == 0) revert ProductZeroSupply();
        if(price == 0) revert ProductZeroPrice();
        productInfo[pName] = ProductInfo(supply, price * 10 ** 6);
        emit ProductAdded(pName, supply, price * 10 ** 6);
    }

    function updateProductInfo(string memory pName, uint8 supply, uint256 price) onlyRole(ADMIN) override public{
        ProductInfo storage product = _getProductInfo(pName);

        if(supply > 0){
            product.physical_supply = supply;
        }
        if(price > 0){
            product.price = price * 10 ** 6;
        }
    }

    function removeProductInfo(string memory pName) onlyRole(ADMIN) override public {
        delete productInfo[pName];
        emit ProductRemoved(pName);
    }

    // =============================================================
    //                       Helpers
    // =============================================================
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));  
    }
}