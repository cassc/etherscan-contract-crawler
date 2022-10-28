/**
 * Submitted for verification at BscScan.com on 2022-09-29
 */

// File: contracts/NichoNFTMarketplace.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// Openzeppelin libraries
import "@openzeppelin/contracts/access/Ownable.sol";

import "./MarketplaceHelper.sol";
import "./interfaces/INichoNFTAuction.sol";
import "./interfaces/INichoNFTRewards.sol";
import "./interfaces/ICreatorNFT.sol";
import "./interfaces/IFactory.sol";

interface IERC721URI {
    function tokenURI(uint256 tokenId) external returns (string memory);
}

// NichoNFT marketplace
contract NichoNFTMarketplace is Ownable, MarketplaceHelper {
    // Interface for nichonft auction
    INichoNFTAuction public nichonftAuctionContract;
    // Interface from the reward contract
    INichoNFTRewards public nichonftRewardsContract;

    // Enable if nichonftauction exists
    bool public auctionEnabled = false;
    // Trade rewards enable
    bool public tradeRewardsEnable = false;
    // Factory address
    address public factory;

    // Offer Item
    struct OfferItem {
        uint256 price;
        uint256 expireTs;
        bool isLive;
    }

    // Marketplace Listed Item
    // token address => tokenId => item
    mapping(address => mapping(uint256 => Item)) private items;

    // Offer Item
    // token address => token id => creator => offer item
    mapping(address => mapping(uint256 => mapping(address => OfferItem))) private offerItems;

    // NichoNFT and other created owned-collections need to list it while minting.
    // nft contract address => tokenId => item
    mapping(address => bool) public directListable;
    /**
     * @dev Emitted when `token owner` list/mint/auction NFT on marketplace
     * - expire_at: in case of auction sale
     * - auction_id: in case of auction sale
     */
    event ListedNFT(
        address token_address,
        uint token_id,
        string token_uri,
        address indexed creator,
        uint price,
        uint expire_at, 
        uint80 auction_id,
        string collection_id,
        bool is_mint
    );

    /**
     * @dev Emitted when `token owner` cancel NFT from marketplace
     */
    event ListCancel(
        address token_address,
        uint token_id,
        address indexed owner,
        bool is_listed
    );

    /**
     * @dev Emitted when create offer for NFT on marketplace
     */
    event Offers(
        address token_address,
        uint token_id,
        address indexed creator,
        uint price,
        uint expire_at
    );

    /**
     * @dev Emitted when `Offer creator` cancel offer of NFT on marketplace
     */
    event OfferCancels(
        address token_address,
        uint token_id,
        address indexed creator
    );

    /**
     * @dev Emitted when `token owner` list NFT on marketplace
     */
    event TradeActivity(
        address token_address,
        uint token_id,
        address indexed previous_owner,
        address indexed new_owner,
        uint price,
        string trade_type
    );

    // Initialize configurations
    constructor(
        address _blacklist,
        address _nichonft,
        address _factory
    ) MarketplaceHelper(_blacklist) {
        require(_factory != address(0x0), "Invalid address");
        directListable[_nichonft] = true;
        factory = _factory;
    }

    /**
     * @dev set Factory address for owned collection
     */
    function setFactoryAddress(address _factory) external onlyOwner {
        require(_factory != address(0x0), "Invalid address");
        require(_factory != factory, "Same Factory Address");
        factory = _factory;
    }

    /**
     * @dev set direct listable contract
     */
    function setDirectListable(address _target) external {
        require(
            msg.sender == factory || msg.sender == owner(),
            "You have no right to call setDirectListable"
        );
        directListable[_target] = true;
    }
    /**
     * @dev If you need auction sales, you can enable auction contract
     */
    function enableNichoNFTAuction(INichoNFTAuction _nichonftAuctionContract) external onlyOwner {
        nichonftAuctionContract = _nichonftAuctionContract;
        auctionEnabled = true;
    }

    function disableAuction() external onlyOwner {
        auctionEnabled = false;
    }

    /**
     * @dev trade to reward contract
     */
    function setRewardsContract(
        INichoNFTRewards _nichonftRewardsContract
    ) external onlyOwner {
        require(nichonftRewardsContract != _nichonftRewardsContract, "Rewards: has been already configured");
        nichonftRewardsContract = _nichonftRewardsContract;
    }

    function setTradeRewardsEnable(bool _tradeRewardsEnable) external onlyOwner {
        require(tradeRewardsEnable != _tradeRewardsEnable, "Already set enabled");
        tradeRewardsEnable = _tradeRewardsEnable;
    }

    // Middleware to check if NFT is already listed on not.
    modifier onlyListed(address tokenAddress, uint256 tokenId) {
        Item memory item = items[tokenAddress][tokenId];
        require(item.isListed == true, "Token: not listed on marketplace");

        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);
        require(item.creator == tokenOwner, "You are not creator");
        _;
    }

    // Middleware to check if NFT is already listed on not.
    modifier onlyListableContract() {
        require(
            directListable[msg.sender] == true,
            "Listable: not allowed to list"
        );
        _;
    }

    // List NFTs on marketplace as same price with fixed price sale
    function batchListItemToMarket(
        address[] calldata tokenAddress,
        uint256[] calldata tokenId,
        uint256 askingPrice
    ) external notPaused {
        require(
            tokenAddress.length == tokenId.length,
            "Array size does not match"
        );

        for (uint idx = 0; idx < tokenAddress.length; idx++) {
            address _tokenAddress = tokenAddress[idx];
            uint _tokenId = tokenId[idx];

            // List
            listItemToMarket(_tokenAddress, _tokenId, askingPrice);
        }
    }

    // List an NFT on marketplace as same price with fixed price sale
    function listItemToMarket(
        address tokenAddress,
        uint256 tokenId,
        uint256 askingPrice
    )
        public
        notBlackList(tokenAddress, tokenId)
        onlyTokenOwner(tokenAddress, tokenId)
        notPaused
    {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;

        // Token owner need to approve NFT on Token Contract first so that Listing works.
        require(checkApproval(_tokenAddress, _tokenId), "First, Approve NFT");

        Item storage item = items[_tokenAddress][_tokenId];
        item.price = askingPrice;
        item.isListed = true;
        // creator
        item.creator = msg.sender;

        // cancel auction
        if (auctionEnabled) {
            nichonftAuctionContract.cancelAuctionFromFixedSaleCreation(_tokenAddress, _tokenId);
        }

        string memory token_uri = IERC721URI(_tokenAddress).tokenURI(_tokenId);

        emit ListedNFT(_tokenAddress, _tokenId, token_uri, msg.sender, askingPrice, 0, 0, "", false);
    }

    // List an NFT/NFTs on marketplace as same price with fixed price sale
    function listItemToMarketFromMint(
        address tokenAddress,
        uint256 tokenId,
        uint256 askingPrice,
        address _creator,
        string memory cId
    ) external onlyListableContract {
        Item storage item = items[tokenAddress][tokenId];
        item.price = askingPrice;
        item.isListed = true;

        // creator
        item.creator = _creator;

        string memory token_uri = IERC721URI(tokenAddress).tokenURI(tokenId);
        emit ListedNFT(tokenAddress, tokenId, token_uri, _creator, askingPrice, 0, 0, cId, true);
    }

    // Cancel nft listing
    function cancelListing(
        address tokenAddress,
        uint tokenId
    )   external
        onlyTokenOwner(tokenAddress, tokenId)
    {
        // scope for _token{Id, Address}, price, avoids stack too deep errors
        uint _tokenId = tokenId;
        address _tokenAddress = tokenAddress;

        if (items[_tokenAddress][_tokenId].isListed) {
            Item storage item = items[_tokenAddress][_tokenId];
            item.isListed = false;
            item.price = 0;
        }

        if (auctionEnabled) {
            if (nichonftAuctionContract.getAuctionStatus(_tokenAddress, _tokenId) == true) {            
                // cancel auction
                nichonftAuctionContract.cancelAuctionFromFixedSaleCreation(_tokenAddress, _tokenId);
            }
        }

        emit ListCancel(_tokenAddress, _tokenId, msg.sender, false);
    }

    /**
     * @dev Purchase the listed NFT with BNB.
     */
    function buy(address tokenAddress, uint tokenId)
        external
        payable
        notBlackList(tokenAddress, tokenId)
        onlyListed(tokenAddress, tokenId)        
    {
        _validate(tokenAddress, tokenId, msg.value);

        IERC721 tokenContract = IERC721(tokenAddress);
        address _previousOwner = tokenContract.ownerOf(tokenId);
        address _newOwner = msg.sender;

        _trade(tokenAddress, tokenId, msg.value);

        setTradeRewards(tokenAddress, tokenId, _newOwner, block.timestamp);

        emit TradeActivity(
            tokenAddress,
            tokenId,
            _previousOwner,
            _newOwner,
            msg.value,
            "normal"
        );
    }

    /**
     * @dev Check validation for Trading conditions
     *
     * Requirement:
     *
     * - `amount` is token amount, should be greater than equal seller price
     */
    function _validate(
        address tokenAddress,
        uint tokenId,
        uint256 amount
    ) private view {
        require(
            checkApproval(tokenAddress, tokenId),
            "Not approved from owner."
        );

        IERC721 tokenContract = IERC721(tokenAddress);
        require(
            tokenContract.ownerOf(tokenId) != msg.sender,
            "Token owner can not buy your NFTs."
        );

        Item memory item = items[tokenAddress][tokenId];
        require(amount >= item.price, "Error, the amount is lower than price");
    }

    /**
     * @dev Execute Trading once condition meets.
     *
     * Requirement:
     *
     * - `amount` is token amount, should be greater than equal seller price
     */
    function _trade(
        address tokenAddress,
        uint tokenId,
        uint amount
    ) internal notPaused {
        IERC721 tokenContract = IERC721(tokenAddress);

        address payable _buyer = payable(msg.sender);
        address _seller = tokenContract.ownerOf(tokenId);

        Item storage item = items[tokenAddress][tokenId];
        uint price = item.price;
        uint remainAmount = amount - price;

        IFactory factoryContract = IFactory(factory);
        if (factoryContract.checkRoyaltyFeeContract(tokenAddress) == true) {
            uint256 fee = ICreatorNFT(tokenAddress).getRoyaltyFeePercentage();
            address feeTo = ICreatorNFT(tokenAddress).owner();
            uint256 feeAmount = price * fee / 1000;
            uint256 transferAmount = price - feeAmount;
            payable(_seller).transfer(transferAmount);
            payable(feeTo).transfer(feeAmount);
        } else {
            // From marketplace contract to seller
            payable(_seller).transfer(price);
        }

        // If buyer sent more than price, we send them back their rest of funds
        if (remainAmount > 0) {
            _buyer.transfer(remainAmount);
        }

        // Transfer NFT from seller to buyer
        tokenContract.safeTransferFrom(_seller, msg.sender, tokenId);

        // Update Item
        item.isListed = false;
        item.price = 0;
    }

    // Create offer with BNB
    function createOffer(
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline // count in seconds
    ) external payable {
        _createOffer(
            tokenAddress,
            tokenId,
            deadline, // count in seconds
            msg.value
        );
    }

    // Create offer logic
    function _createOffer(
        address tokenAddress,
        uint256 tokenId,
        uint256 deadline,
        uint256 amount
    ) private notPaused {
        require(amount > 0, "Invalid amount");
        // 30 seconds
        require(deadline >= 5, "Invalid deadline");
        IERC721 nft = IERC721(tokenAddress);
        require(
            nft.ownerOf(tokenId) != msg.sender,
            "Owner cannot create offer"
        );

        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];
        require(
            item.price == 0 || item.isLive == false,
            "You've already created offer"
        );

        uint expireAt = block.timestamp + deadline;

        item.price = amount;
        item.expireTs = expireAt;
        item.isLive = true;

        emit Offers(
            tokenAddress,
            tokenId,
            msg.sender,
            amount,
            expireAt
        );
    }

    /**
     * @dev NFT owner accept the offer created by buyer
     * Requirement:
     * - offerCreator: creator address that have created offer.
     */
    function acceptOffer(
        address tokenAddress,
        uint256 tokenId,
        address offerCreator
    )
        external
        notBlackList(tokenAddress, tokenId)
        onlyTokenOwner(tokenAddress, tokenId)
    {
        address _tokenAddress = tokenAddress;
        uint256 _tokenId = tokenId;

        OfferItem memory item = offerItems[_tokenAddress][_tokenId][offerCreator];
        require(item.isLive, "Offer creator withdrawed");
        require(item.expireTs >= block.timestamp, "Offer already expired");
        require(checkApproval(_tokenAddress, _tokenId), "First, approve NFT");

        IERC721(_tokenAddress).safeTransferFrom(
            msg.sender,
            offerCreator,
            _tokenId
        );

        uint oldPrice = item.price;
        OfferItem memory itemStorage = offerItems[_tokenAddress][_tokenId][
            offerCreator
        ];

        itemStorage.isLive = false;
        itemStorage.price = 0;
        uint price = item.price;

        IFactory factoryContract = IFactory(factory);
        if (factoryContract.checkRoyaltyFeeContract(_tokenAddress) == true) {
            uint256 fee = ICreatorNFT(_tokenAddress).getRoyaltyFeePercentage();
            uint256 feeAmount = price * fee / 1000;
            uint256 transferAmount = price - feeAmount;
            payable(msg.sender).transfer(transferAmount);
            payable(owner()).transfer(feeAmount);
        } else {
            payable(msg.sender).transfer(item.price);
        }

        Item storage marketItem = items[_tokenAddress][_tokenId];

        // Update Item
        marketItem.isListed = false;
        marketItem.price = 0;
        // emit OfferSoldOut(_tokenAddress, _tokenId, msg.sender, item.creator, item.price);

        setTradeRewards(_tokenAddress, _tokenId, msg.sender, block.timestamp);


        emit TradeActivity(
            _tokenAddress,
            _tokenId,
            msg.sender,
            offerCreator,
            oldPrice,
            "offer"
        );
    }

    /**
     * @dev Offer creator cancel offer
     */
    function cancelOffer(address tokenAddress, uint256 tokenId) external {
        require(
            offerItems[tokenAddress][tokenId][msg.sender].isLive,
            "Already withdrawed"
        );
        OfferItem storage item = offerItems[tokenAddress][tokenId][msg.sender];

        uint oldPrice = item.price;
        item.isLive = false;
        item.price = 0;

        payable(msg.sender).transfer(oldPrice);

        emit OfferCancels(tokenAddress, tokenId, msg.sender);
    }

    //----------- Calls from auction contract ------------
    /**
     * @dev when auction is created, cancel fixed sale
     */
    function cancelListFromAuctionCreation(
        address tokenAddress, uint256 tokenId
    ) external {
        require(msg.sender == address(nichonftAuctionContract), "Invalid nichonft contract");
        Item storage item = items[tokenAddress][tokenId];
        item.isListed = false;
        item.price = 0;
    }

    /**
     * @dev emit whenever token owner created auction
     */
    function emitListedNFTFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _creator, 
        uint256 _startPrice, 
        uint256 _expireTs, 
        uint80  _nextAuctionId
    ) external {
        require(
            msg.sender == address(nichonftAuctionContract), 
            "Invalid nichonft contract"
        );
        
        string memory _token_uri = IERC721URI(_tokenAddress).tokenURI(_tokenId);
        emit ListedNFT(
            _tokenAddress, 
            _tokenId, 
            _token_uri,
            _creator,
            _startPrice, 
            _expireTs, 
            _nextAuctionId,
            "",
            false
        );
    }

    /**
     * @dev when auction is traded
     */
    function emitTradeActivityFromAuctionContract(
        address _tokenAddress, 
        uint256 _tokenId, 
        address _prevOwner, 
        address _newOwner, 
        uint256 _price
    ) external {
        require(
            msg.sender == address(nichonftAuctionContract), 
            "Invalid nichonft contract"
        );

        setTradeRewards(_tokenAddress, _tokenId, _newOwner, block.timestamp);


        emit TradeActivity(
            _tokenAddress,
            _tokenId, 
            _prevOwner, 
            _newOwner, 
            _price,
            "auction"
        );
        
    }

    /**
     * @dev Get offer created based on NFT (address, id)
     */
    function getOfferItemInfo(
        address tokenAddress,
        uint tokenId,
        address sender
    ) external view returns (OfferItem memory item) {
        item = offerItems[tokenAddress][tokenId][sender];
    }

    // get ItemInfo listed on marketplace
    function getItemInfo(address tokenAddress, uint tokenId)
        external
        view
        returns (Item memory item)
    {
        item = items[tokenAddress][tokenId];
    }

    /**
     * @dev pause market
     */
    function pause(bool _pause) external onlyOwner {
        isPaused = _pause;
    }
    
    // For unusual/emergency case,
    function withdrawETH(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Wrong amount");

        payable(msg.sender).transfer(_amount);
    }

    function setTradeRewards(address tokenAddress, uint256 tokenId, address userAddress, uint256 timestamp) private returns (bool) {
        if (tradeRewardsEnable) {
            return nichonftRewardsContract.tradeRewards(tokenAddress, tokenId, userAddress, timestamp);
        }
        return false;
    }
}