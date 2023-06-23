// SPDX-LICENSE-IDENTIFIER: UNLICENSED

pragma solidity ^0.8.0;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../SimpleFactory.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IWETH.sol";
import "./MintSaleBase.sol";

contract NFTMintSaleMultiple is MintSaleBase {
    event Created(bytes data);
    event LogNFTBuy(address indexed recipient, uint256 tokenId, uint256 tier);
    event LogNFTBuyMultiple(address indexed recipient, uint256[] tiers);

    using BoringERC20 for IERC20;

    struct TierInfo {
        uint128 price;
        uint32 beginId;
        uint32 endId;
        uint32 currentId;
    }

    TierInfo[] public tiers;

    constructor (SimpleFactory vibeFactory_, IWETH WETH_) MintSaleBase(vibeFactory_, WETH_) {
    }

    function init(bytes calldata data) external {
        (address proxy, uint32 beginTime_, uint32 endTime_, TierInfo[] memory tiers_, IERC20 paymentToken_, address owner_) = abi.decode(data, (address, uint32, uint32, TierInfo[], IERC20, address));
        require(nft == VibeERC721(address(0)), "Already initialized");
        require(proxy != address(0), "Invalid proxy address");

        require(beginTime_ < endTime_, "Invalid time range");

        _transferOwnership(owner_);


        {
            (address treasury, uint96 feeTake )= NFTMintSaleMultiple(vibeFactory.masterContractOf(address(this))).fees();

            fees = VibeFees(treasury, feeTake);
        }

        nft = VibeERC721(proxy);

        {
            // circumvents UnimplementedFeatureError: Copying of type struct NFTMintSaleMultiple.TierInfo calldata[] calldata to storage not yet supported.
            for(uint256 i; i < tiers_.length; i++) {
                // enforce that the currentId starts at beginId
                tiers_[i].currentId = tiers_[i].beginId;
                tiers.push(tiers_[i]);
            }
        }
        

        paymentToken = paymentToken_;
        beginTime = beginTime_;
        endTime = endTime_;

        {
            // checks parameter for correct values, can be commented out for increased gas efficiency.
            for (uint256 i = tiers_.length - 1; i > 0; i--) {
                require(tiers_[i].endId >= tiers_[i].beginId && tiers_[i-1].endId < tiers_[i].beginId, "Parameter verification failed");
            }
            require(tiers_[0].endId >= tiers_[0].beginId, "Parameter verification failed");
        }
        
        emit Created(data);
    }

    function _preBuyCheck(address recipient, uint256 tier) internal virtual {}

    function buyNFT(address recipient, uint256 tier) public payable {
        require(block.timestamp >= beginTime && block.timestamp <= endTime, "Sale not active");
        uint256 price = _buyNFT(recipient, tier);
        getPayment(price);
    }

    function _buyNFT(address recipient, uint256 tier) internal returns (uint256 price){
        _preBuyCheck(recipient, tier);
        TierInfo memory tierInfo = tiers[tier];
        uint256 id = uint256(tierInfo.currentId);
        require(id <= tierInfo.endId, "Tier sold out");
        price = uint256(tierInfo.price);
        nft.mintWithId(recipient, id);
        tiers[tier].currentId++;
        emit LogNFTBuy(recipient, id, tier);
    }

    function buyMultipleNFT(address recipient, uint256[] calldata tiersToBuy) external payable {
        require(block.timestamp >= beginTime && block.timestamp <= endTime, "Sale not active");
        uint256 totalPrice;
        for (uint i; i < tiersToBuy.length; i++) {
            totalPrice += _buyNFT(recipient, tiersToBuy[i]);
        }

        getPayment(totalPrice);

        emit LogNFTBuyMultiple(recipient, tiersToBuy);
    }
}