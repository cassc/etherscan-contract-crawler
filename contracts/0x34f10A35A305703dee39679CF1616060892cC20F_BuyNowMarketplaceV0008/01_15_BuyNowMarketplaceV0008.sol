// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./extensions/IHPMarketplaceMint.sol";
import "./extensions/HPApprovedMarketplace.sol";
import "./extensions/IHPRoles.sol";

// import "hardhat/console.sol";

contract BuyNowMarketplaceV0008 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    // Variables
    bool private hasInitialized;
    address public mintAdmin;
    address payable private feeAccount; // the account that receives fees
    uint private feePercent; // the fee percentage on sales 
    uint private initialFeePercent; // the fee percentage on sales 
    CountersUpgradeable.Counter private itemCount;

    struct Item {
        uint256 itemId;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
        bool canceled;
        IERC721Upgradeable nft;
    }

    struct MintItem {
        address royaltyAddress;
        uint96 feeNumerator;
        bool shouldMint;
        string uri;
        string trackId;
    }

    // itemId -> Item
    mapping(uint256 => Item) public items;
    mapping(uint256 => MintItem) public mintItems;

    address public hpRolesContractAddress;
    bool private hasUpgradeInitialzed;

    event Offered(
        uint256 itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );

    event Bought(
        uint256 itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    event PaymentSplit(
        uint256 itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed from,
        address indexed to
    );

    event Cancelled(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId
    );

    event UpdateSalePrice(
        uint256 indexed itemId,
        address indexed nft,
        uint256 indexed tokenId,
        uint price,
        address seller
    );

    function initialize(uint _feePercent, uint _initialFeePercent, address payable _feeAccount, address _mintAdmin) initializer public {
        require(hasInitialized == false, "This has already been initialized");
        hasInitialized = true;
        feeAccount = _feeAccount;
        feePercent = _feePercent;
        initialFeePercent = _initialFeePercent;
        mintAdmin = _mintAdmin;
        __Ownable_init_unchained();
        __ReentrancyGuard_init();

    }

    function upgrader(address _hpRolesContractAddress) external {
        require(hasUpgradeInitialzed == false, "already upgraded");
        hasUpgradeInitialzed = true;
        hpRolesContractAddress = _hpRolesContractAddress;
    }

    function setHasUpgradeInitialized(bool upgraded) external onlyOwner {
        hasUpgradeInitialzed = upgraded;
    }
    // Make item to offer on the marketplace
    function makeItem(IERC721Upgradeable _nft, uint _tokenId, uint _price) external nonReentrant {
        // transfer nft
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        generateSaleItem(_nft, _tokenId, _price, msg.sender);
    }

    function makeItemMintable(
        IERC721Upgradeable _nft, 
        uint _price,
        address _royaltyAddress,
        uint96 _feeNumerator,
        string memory _uri,
        string memory _trackId
        ) public nonReentrant {
            IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
            require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
            IHPMarketplaceMint marketplaceNft = IHPMarketplaceMint(address(_nft));
            require(marketplaceNft.canMarketplaceMint() == true, "This token is not compatible with marketplace minting");
            uint256 itemId = generateSaleItem(_nft, 0, _price, _royaltyAddress);

            mintItems[itemId] = MintItem (
                _royaltyAddress,
                _feeNumerator,
                true,
                _uri,
                _trackId
            );
    }

    function generateSaleItem(IERC721Upgradeable _nft, uint _tokenId, uint _price, address _seller) private returns(uint256) {
        calculateFee(_price, feePercent); // Check if the figure is too small
        require(_price > 0, "Price must be greater than zero");
        // increment itemCount
        uint256 newItemId = CountersUpgradeable.current(itemCount);
        // add new item to items mapping
        items[newItemId] = Item (
            newItemId,
            _tokenId,
            _price,
            payable(_seller),
            false,
            false,
            _nft
        );

        // emit Offered event
        emit Offered(
            newItemId,
            address(_nft),
            _tokenId,
            _price,
            msg.sender
        );

        CountersUpgradeable.increment(itemCount);
        return newItemId;
    }

    function purchaseItem(uint256 _itemId) external payable nonReentrant {
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        MintItem memory mintingItem = mintItems[_itemId];
        bool shouldMint = mintingItem.shouldMint;
        require(address(item.nft) != address(0), "Sale does not exist");
        require(item.canceled == false, "Sale has been cancled");
        require(!item.sold, "Item already sold");
        if (!shouldMint) {
            require(item.nft.ownerOf(item.tokenId) == address(this), "The contract does not have ownership of token");
        }
        require(msg.value >= _totalPrice, "not enough ether to cover item price");
        

        uint256 tokenId = item.tokenId;
        // Resale purchaseItem implementation
        if (shouldMint) {
            tokenId = purchaseMintItem(_itemId, item, mintingItem);
        } else {
            purchaseResaleItem(_itemId, item);
        }
        
        // End Resale purchaseItem implementation
        item.sold = true;
        
        // emit Bought event
        emit Bought(
            _itemId,
            address(item.nft),
            tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }

    function purchaseMintItem(uint256 _itemId, Item memory item, MintItem memory mintingItem) private returns(uint256) {
        uint fee = getInitialFee(_itemId);

        uint256 sellerTransferAmount = item.price - fee;
        item.seller.transfer(sellerTransferAmount);
        feeAccount.transfer(fee);

        IHPMarketplaceMint hpMarketplaceNft = IHPMarketplaceMint(address(item.nft));
        uint256 newTokenId = hpMarketplaceNft.marketplaceMint(
            msg.sender, 
            mintingItem.royaltyAddress,
            mintingItem.feeNumerator,
            mintingItem.uri,
            mintingItem.trackId);

        emit PaymentSplit(
            _itemId,
            address(item.nft),
            newTokenId,
            sellerTransferAmount,
            msg.sender,
            item.seller);

        emit PaymentSplit(
            _itemId,
            address(item.nft),
            newTokenId,
            fee,
            msg.sender,
            feeAccount);

        return newTokenId;
        
    }

    function purchaseResaleItem(uint256 _itemId, Item memory item) private {
        uint fee = getFee(_itemId);
        IERC2981Upgradeable royaltyNft = IERC2981Upgradeable(address(item.nft));
        try royaltyNft.royaltyInfo(item.tokenId, item.price) returns (address receiver, uint256 amount) {
            uint256 sellerTransferAmount = item.price - fee - amount;
            item.seller.transfer(sellerTransferAmount);
            feeAccount.transfer(fee);
            payable(receiver).transfer(amount);

            emit PaymentSplit(
                _itemId,
                address(item.nft),
                item.tokenId,
                sellerTransferAmount,
                msg.sender,
                item.seller);

            emit PaymentSplit(
                _itemId,
                address(item.nft),
                item.tokenId,
                amount,
                msg.sender,
                receiver);
        } catch {
            uint256 sellerTransferAmount = item.price - fee;
            item.seller.transfer(sellerTransferAmount);
            feeAccount.transfer(fee);

            emit PaymentSplit(
                _itemId,
                address(item.nft),
                item.tokenId,
                sellerTransferAmount,
                msg.sender,
                item.seller);
        }

        emit PaymentSplit(
            _itemId,
            address(item.nft),
            item.tokenId,
            fee,
            msg.sender,
            feeAccount);
        
            item.nft.transferFrom(address(this), msg.sender, item.tokenId);
    }

    function cancelSale(uint256 _itemId) external nonReentrant {
        Item storage item = items[_itemId];
        MintItem memory mintingItem = mintItems[_itemId];
        require(item.sold == false, "Item has already been sold!");

        IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
        require(msg.sender == item.seller || (hpRoles.isAdmin(msg.sender) == true && mintingItem.shouldMint), "You do not have permission to cancel sale");

        item.canceled = true;
        
        if (!mintingItem.shouldMint) {
            item.nft.transferFrom(address(this), item.seller, item.tokenId);
        } 
        

        emit Cancelled(_itemId, address(item.nft), item.tokenId);
    }

    function updateSalePrice(uint256 _itemId, uint _price) external nonReentrant {
        Item storage item = items[_itemId];
        require(item.sold == false, "Item has already been sold!");
        require(msg.sender == item.seller, "You do not have permission to cancel sale");
        require(item.nft.ownerOf(_itemId) == address(this), "The contract does not have ownership of token");

        item.price = _price;

        emit UpdateSalePrice(_itemId, address(item.nft), item.tokenId, _price, item.seller);
    }

    function getTotalPrice(uint256 _itemId) view public returns(uint){
        return items[_itemId].price;
    }

    function getFee(uint256 _itemId) view public returns(uint) {
        return calculateFee(items[_itemId].price, feePercent);
    }

    function getInitialFee(uint256 _itemId) view public returns(uint) {
        return calculateFee(items[_itemId].price, initialFeePercent);
    }


    function calculateFee(uint amount, uint percentage)
        public
        pure
        returns (uint)
    {
        require((amount / 10000) * 10000 == amount, "Too Small");
        return (amount * percentage) / 10000;
    }

      function setMintAdmin(address newAdmin) public onlyOwner {
        mintAdmin = newAdmin;
    }

    function getMintAdmin() public view returns(address) {
        return mintAdmin;
    }

    function nftContractEmit(address nftContract) public {
        HPApprovedMarketplace emittingContract = HPApprovedMarketplace(address(nftContract));
        emittingContract.msgSenderEmit();
    }

    function setFeeAccount(address payable _feeAccount) onlyOwner public {
        feeAccount = _feeAccount;
    }

    function updateMintRoyaltyAddress(uint256 _itemId, address _royaltyAddress) public {
        IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
        require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
        MintItem storage item = mintItems[_itemId];

        item.royaltyAddress = _royaltyAddress;
    }

    function updateMintRoyaltyMintOwners(uint256[] memory _itemIds, address _royaltyAddress) public {
        IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
        require(mintAdmin == msg.sender || hpRoles.isAdmin(msg.sender) == true, "Admin rights required");

        for (uint256 i = 0; i < _itemIds.length; i++ ) {
            uint256 id = _itemIds[i];
            MintItem storage mintItem = mintItems[id];
            mintItem.royaltyAddress = _royaltyAddress;

            Item storage item = items[id];
            item.seller = payable(_royaltyAddress);
        }
    }

    function getHpRolesContractAddress() public view returns(address) {
        return hpRolesContractAddress;
    }

    function setHpRolesContractAddress(address contractAddress) external onlyOwner {
        hpRolesContractAddress = contractAddress;
    }

    function currentItemCount() public view returns(uint256) {
        return CountersUpgradeable.current(itemCount);
    }
}