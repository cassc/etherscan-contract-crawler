// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IWithBalance.sol";
import "./INFTFull.sol";

contract NFTShop is Ownable, ReentrancyGuard, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct Order {
        uint price;
        address stable;
    }

    struct ItemForSale {
        uint id;
        uint price;
        address stable;
    }

    struct RequiredToken {
        IWithBalance token;
        uint96 amount; // type(uint96).max = 79_228_162_514 * 10^18, big enough required amounts for common ERC20 tokens
    }

    RequiredToken[] public platformRequiredTokensToBuy;
    mapping(IERC721 => RequiredToken[]) public ownerRequiredTokensToBuy;

    /// @notice collection will receive tokens from sale NFTs to this address
    mapping(IERC721 => address) public projectTreasury;

    EnumerableSet.AddressSet private supportedStablesInternal;
    mapping(IERC721 => EnumerableSet.UintSet) private tokensForSaleInternal;
    mapping(IERC721 => mapping(uint => Order)) public tokensForSaleInfo;

    event PlatformRequiredTokenToBuySet(RequiredToken[] items);
    event OwnerRequiredTokenToBuySet(IERC721 indexed nft, RequiredToken[] items);
    event ProjectTreasurySet(IERC721 indexed nft, address treasury);

    event SupportedStableAdded(address token);
    event SupportedStableRemoved(address token);

    event NFTSold(IERC721 indexed nftContract, uint tokenId, address indexed from, address indexed to, address stable, uint price);
    event OrderCreated(IERC721 indexed nftContract, uint indexed tokenId, address indexed seller, address stable, uint price);
    event OrderCancelled(IERC721 indexed nftContract, uint indexed tokenId, address canceller);

    /**
     * @dev Throws if called by any account other than the owner of nft.
     * @dev Works only with NFTFactory NFT
     */
    modifier onlyNftContractOwner(INFTFull _nftContract) {
        try _nftContract.isNFTFactoryNFT{gas:20000}() returns (bytes32 _result) {
            require(_result == keccak256("NFTFactoryNFT"), "NFTShop: NFT_IS_NOT_SUPPORTED");
        } catch {
            revert("NFTShop: NFT_IS_NOT_SUPPORTED");
        }

        require(_nftContract.owner() == msg.sender, "NFTShop: AUTH_FAILED");
        _;
    }

    constructor(address[] memory _supportedStables, RequiredToken[] memory _platformRequiredTokensToBuy) {
        if (_supportedStables.length > 0) {
            addSupportedStables(_supportedStables);
        }

        if (_platformRequiredTokensToBuy.length > 0) {
            setPlatformRequiredTokensToBuy(_platformRequiredTokensToBuy);
        }
    }

    function getPlatformRequiredTokensToBuy() public view returns (RequiredToken[] memory) {
        return platformRequiredTokensToBuy;
    }

    function setPlatformRequiredTokensToBuy(RequiredToken[] memory _platformRequiredTokensToBuy) public onlyOwner {
        checkNewRequiredTokens(_platformRequiredTokensToBuy);

        delete platformRequiredTokensToBuy;
        for (uint i=0; i<_platformRequiredTokensToBuy.length; i++) {
            platformRequiredTokensToBuy.push(_platformRequiredTokensToBuy[i]);
        }

        emit PlatformRequiredTokenToBuySet(_platformRequiredTokensToBuy);
    }

    function getOwnerRequiredTokensToBuy(INFTFull _nftContract) public view returns (RequiredToken[] memory) {
        return ownerRequiredTokensToBuy[_nftContract];
    }

    function setOwnerRequiredTokensToBuy(INFTFull _nftContract, RequiredToken[] memory _ownerRequiredTokensToBuy) public onlyNftContractOwner(_nftContract) {
        checkNewRequiredTokens(_ownerRequiredTokensToBuy);

        delete ownerRequiredTokensToBuy[_nftContract];
        RequiredToken[] storage nftOwnerRequiredTokensToBuy = ownerRequiredTokensToBuy[_nftContract];

        for (uint i=0; i<_ownerRequiredTokensToBuy.length; i++) {
            nftOwnerRequiredTokensToBuy.push(_ownerRequiredTokensToBuy[i]);
        }

        emit OwnerRequiredTokenToBuySet(_nftContract, _ownerRequiredTokensToBuy);
    }

    function checkNewRequiredTokens(RequiredToken[] memory _requiredTokens) internal pure {
        for (uint i=0; i<_requiredTokens.length; i++) {
            RequiredToken memory item = _requiredTokens[i];
            require(address(item.token) != address(0), "NFTShop: ZERO_ADDRESS");
            require(item.amount > 0, "NFTShop: ZERO_AMOUNT");
            checkExistingAddresses(item, _requiredTokens, i);
        }
    }

    /**
     * @dev not optimal, but is is not expected many required tokens (~1-2)
     */
    function checkExistingAddresses(RequiredToken memory _item, RequiredToken[] memory _new, uint _newCurrent) internal pure {
        for (uint j=0; j<_newCurrent; j++) {
            if (_new[j].token == _item.token) {
                revert("NFTShop: ADDRESS_ALREADY_EXISTS");
            }
        }
    }

    function getSupportedStablesCount() public view returns (uint) {
        return supportedStablesInternal.length();
    }

    function getSupportedStables() public view returns (address[] memory) {
        return supportedStablesInternal.values();
    }

    function getSupportedStable(uint _index) public view returns (address) {
        return supportedStablesInternal.at(_index);
    }

    function addSupportedStables(address[] memory _supportedStables) public onlyOwner {
        require(_supportedStables.length > 0, "NFTShop: EMPTY_ARRAY");

        for (uint i=0; i<_supportedStables.length; i++) {
            address newStable = _supportedStables[i];
            require(newStable != address(0), "NFTShop: ZERO_ADDRESS");
            require(supportedStablesInternal.add(newStable), "NFTShop: STABLE_ALREADY_EXISTS");
            emit SupportedStableAdded(newStable);
        }
    }

    function deleteSupportedStable(address _supportedStable) public onlyOwner {
        require(_supportedStable != address(0), "NFTShop: ZERO_ADDRESS");
        require(supportedStablesInternal.remove(_supportedStable), "NFTShop: STABLE_DOES_NOT_EXIST");
        emit SupportedStableRemoved(_supportedStable);
    }

    function setProjectTreasury(INFTFull _nftContract, address _treasury) public onlyNftContractOwner(_nftContract) {
        require(_treasury != address(0), "NFTShop: ZERO_ADDRESS");

        projectTreasury[_nftContract] = _treasury;

        emit ProjectTreasurySet(_nftContract, _treasury);
    }

    function sell(INFTFull _nftContract, ItemForSale[] memory _items) public nonReentrant onlyNftContractOwner(_nftContract) {
        require(_items.length > 0, "NFTShop: EMPTY_ARRAY");
        require(projectTreasury[_nftContract] != address(0), "NFTShop: SELLER_TREASURY_ADDRESS_IS_NO_SET");

        for (uint i=0; i<_items.length; i++) {
            ItemForSale memory item = _items[i];

            require(item.price > 0, "NFTShop: INVALID_PRICE");
            require(!tokensForSaleInternal[_nftContract].contains(item.id), "NFTShop: TOKEN_ALREADY_FOR_SALE");
            require(supportedStablesInternal.contains(item.stable), "NFTShop: STABLE_IS_NOT_SUPPORTED");

            require(tokensForSaleInternal[_nftContract].add(item.id), "NFTShop: BROKEN_STRUCTURE");
            tokensForSaleInfo[_nftContract][item.id] = Order(item.price, item.stable);

            _nftContract.safeTransferFrom(msg.sender, address(this), item.id);

            emit OrderCreated(_nftContract, item.id, msg.sender, item.stable, item.price);
        }
    }

    function cancelSell(INFTFull _nftContract, uint[] memory _ids) public nonReentrant onlyNftContractOwner(_nftContract) {
        require(_ids.length > 0, "NFTShop: EMPTY_ARRAY");

        for (uint i=0; i<_ids.length; i++) {
            uint id = _ids[i];
            require(tokensForSaleInternal[_nftContract].contains(id), "NFTShop: TOKEN_NOT_FOR_SALE");

            require(tokensForSaleInternal[_nftContract].remove(id), "NFTShop: BROKEN_STRUCTURE");
            delete tokensForSaleInfo[_nftContract][id];

            _nftContract.safeTransferFrom(address(this), msg.sender, id);

            emit OrderCancelled(_nftContract, id, msg.sender);
        }
    }

    function buy(INFTFull _nftContract, uint[] memory _ids) public nonReentrant {
        require(_ids.length > 0, "NFTShop: EMPTY_ARRAY");
        checkRequiredTokens(platformRequiredTokensToBuy);
        checkRequiredTokens(ownerRequiredTokensToBuy[_nftContract]);

        address treasury = projectTreasury[_nftContract];
        require(treasury != address(0), "NFTShop: SELLER_TREASURY_ADDRESS_IS_NO_SET");

        for (uint i=0; i<_ids.length; i++) {
            uint id = _ids[i];
            require(tokensForSaleInternal[_nftContract].contains(id), "NFTShop: TOKEN_NOT_FOR_SALE");
            address nftContractOwner = _nftContract.owner();

            Order memory tokenInfo = tokensForSaleInfo[_nftContract][id];
            require(msg.sender != nftContractOwner && msg.sender != treasury, "NFTShop: INVALID_BUYER");

            require(supportedStablesInternal.contains(tokenInfo.stable), "NFTShop: STABLE_IS_NOT_SUPPORTED");

            require(tokensForSaleInternal[_nftContract].remove(id), "NFTShop: BROKEN_STRUCTURE");
            delete tokensForSaleInfo[_nftContract][id];

            IERC20(tokenInfo.stable).safeTransferFrom(msg.sender, treasury, tokenInfo.price);
            _nftContract.safeTransferFrom(address(this), msg.sender, id);

            emit NFTSold(_nftContract, id, nftContractOwner, msg.sender, tokenInfo.stable, tokenInfo.price);
        }
    }

    function checkRequiredTokens(RequiredToken[] memory requiredTokens) internal view {
        for (uint i=0; i<requiredTokens.length; i++) {
            RequiredToken memory token = requiredTokens[i];
            require(token.token.balanceOf(msg.sender) >= token.amount, "NFTShop: NOT_ENOUGH_REQUIRED_TOKEN_TO_BUY");
        }
    }

    function tokensForSale(INFTFull _nftContract) public view returns(uint[] memory _ids, Order[] memory _infos) {
        _ids = tokensForSaleInternal[_nftContract].values();
        _infos = new Order[](_ids.length);

        for(uint i=0; i< _ids.length; i++) {
            _infos[i] = tokensForSaleInfo[_nftContract][_ids[i]];
        }
    }

    function tokensForSaleCount(INFTFull _nftContract) public view returns(uint) {
        return tokensForSaleInternal[_nftContract].length();
    }

    function tokenForSale(INFTFull _nftContract, uint _index) public view returns(uint _id, Order memory info) {
        _id = tokensForSaleInternal[_nftContract].at(_index);
        info = tokensForSaleInfo[_nftContract][_id];
    }

    function onERC721Received(
        address operator,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external view returns (bytes4) {
        require(operator == address(this), "NFTSwap: TRANSFER_NOT_ALLOWED");

        return IERC721Receiver.onERC721Received.selector;
    }
}