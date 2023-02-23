//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Marketplace is ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter public marketplaceIndex;

    uint public minPrice = 5000000000000000; // 最低出品額(wei)
    uint private _marketFee = 20; // マーケットフィー
    address payable private _feeAddress; // マーケットフィー回収用アドレス

    // アーリーアクセス
    bool useAccessList = true;
    bytes32 public merkleRoot;

    mapping(uint => Listing) private _marketplaceIdToListingItem;
    mapping(address => uint) public buyCounts;

    struct Listing {
        uint marketplaceId;
        address contractAddress;
        uint tokenId;
        address payable seller;
        uint listPrice;
        uint listAmount;
    }

    event ListingCreated(
        uint indexed marketplaceId,
        address indexed contractAddress,
        uint indexed tokenId,
        address seller,
        uint listPrice,
        uint listAmount
    );

    event PriceChanged(
        uint indexed marketplaceId,
        uint listPrice
    );

    event ListingCancel(uint indexed marketplaceId);

    event Bought(
        uint indexed marketplaceId,
        address buyer
    );

    // アーリーアクセス判定
    function checkMerkleProof(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setUseAccessList(bool _state) public onlyOwner {
        useAccessList = _state;
    }

    // マーケットフィー関係
    function setMerketFee(uint _fee) external onlyOwner {
        _marketFee = _fee;
    }

    function setFeeAddress(address payable _address) external onlyOwner {
        _feeAddress = _address;
    }

    // 最低出品額を変更
    function setMinPrice(uint _price) external onlyOwner {
        minPrice = _price;
    }

    // コントラクトタイプを判別
    function isERC721(address _contractAddress) public view returns (bool) {
        IERC165 erc165 = IERC165(_contractAddress);
        return erc165.supportsInterface(0x80ac58cd);
    }

    function isERC1155(address _contractAddress) public view returns (bool) {
        IERC165 erc165 = IERC165(_contractAddress);
        return erc165.supportsInterface(0xd9b67a26);
    }

    // オーナー確認
    function checkContractOwner(address _contractAddress) public view returns (address) {
            return Ownable(_contractAddress).owner();
    }

    // 所有していることを確認
    function isOwned(address _contractAddress, uint _tokenId) public view returns (bool) {
        if (isERC721(_contractAddress)) {
            return IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender;
        } else if (isERC1155(_contractAddress)) {
            return IERC1155(_contractAddress).balanceOf(msg.sender, _tokenId) > 0;
        } else {
            return false;
        }
    }

    // 出品する
    function createListing(
        address _contractAddress,
        uint _tokenId,
        uint _price,
        uint _listAmount
    ) public nonReentrant {
        require(checkContractOwner(_contractAddress) == msg.sender, 'Only primary sales are available.');
        // require(isERC721(_contractAddress) || isERC1155(_contractAddress), 'Only ERC721 or ERC1155 contracts.');
        require(isOwned(_contractAddress, _tokenId), 'Not owned.');
        require(_price >= minPrice, "Below the minimum possible amount.");

        if (isERC721(_contractAddress)) {
            require(_listAmount == 1, "Insufficient number of possessions.");
        } else {
            require(_listAmount <= IERC1155(_contractAddress).balanceOf(msg.sender, _tokenId), "Insufficient number of possessions.");
        }

        marketplaceIndex.increment();
        uint marketplaceId = marketplaceIndex.current();
        _marketplaceIdToListingItem[marketplaceId] = Listing(
            marketplaceId,
            _contractAddress,
            _tokenId,
            payable(msg.sender),
            _price,
            _listAmount
        );

        emit ListingCreated(
            marketplaceId,
            _contractAddress,
            _tokenId,
            msg.sender,
            _price,
            _listAmount
        );
    }

    // 出品金額を変更
    function changeListingPrice(
        uint _marketplaceId,
        uint _price
    ) public nonReentrant {
        address contractAddress = _marketplaceIdToListingItem[_marketplaceId].contractAddress;
        uint tokenId = _marketplaceIdToListingItem[_marketplaceId].tokenId;
        uint listAmount = _marketplaceIdToListingItem[_marketplaceId].listAmount;

        require(checkContractOwner(contractAddress) == msg.sender, 'Only primary sales are available.');
        require(isOwned(contractAddress, tokenId), 'Not owned.');
        require(_price >= minPrice, "Below the minimum possible amount.");
        require(listAmount > 0, "Sold out.");

        _marketplaceIdToListingItem[_marketplaceId].listPrice = _price;

        emit PriceChanged(_marketplaceId, _price);
    }

    // 出品を取り消す
    function cancelListing(
        uint _marketplaceId
    ) public nonReentrant {
        address contractAddress = _marketplaceIdToListingItem[_marketplaceId].contractAddress;

        require(checkContractOwner(contractAddress) == msg.sender, 'Only primary sales are available.');

        _marketplaceIdToListingItem[_marketplaceId].listAmount = 0;

        emit ListingCancel(_marketplaceId);
    }

    // 購入する
    function buyListing(uint _marketplaceId, address _contractAddress, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        if (useAccessList) {
            require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");
        }

        uint _price = _marketplaceIdToListingItem[_marketplaceId].listPrice;
        require(
            msg.value == _price,
            "Value sent does not meet list price for NFT"
        );

        require(
            msg.sender != _marketplaceIdToListingItem[_marketplaceId].seller,
            "Value sent does not meet list price for NFT"
        );
        uint tokenId = _marketplaceIdToListingItem[_marketplaceId].tokenId;

        // 送金処理
        uint marketFee = (msg.value * _marketFee) / 100;
        _marketplaceIdToListingItem[_marketplaceId].seller.transfer(msg.value - marketFee);
        _feeAddress.transfer(marketFee);

        if (isERC721(_contractAddress)) {
            IERC721(_contractAddress).transferFrom(_marketplaceIdToListingItem[_marketplaceId].seller, msg.sender, tokenId);
        } else if (isERC1155(_contractAddress)) {
            IERC1155(_contractAddress).safeTransferFrom(_marketplaceIdToListingItem[_marketplaceId].seller, msg.sender, tokenId, 1, '');
        }

        buyCounts[msg.sender]++;
        _marketplaceIdToListingItem[_marketplaceId].listAmount--;

        emit Bought(_marketplaceId, msg.sender);
    }

    // マーケットプレースの情報を参照する
    function getMarketItem(uint marketplaceId)
        public
        view
        returns (Listing memory)
    {
        return _marketplaceIdToListingItem[marketplaceId];
    }

    function getMarketItemPrice(uint marketplaceId)
        public
        view
        returns (uint)
    {
        return _marketplaceIdToListingItem[marketplaceId].listPrice;
    }

    function getMarketItemAmount(uint marketplaceId)
        public
        view
        returns (uint)
    {
        return _marketplaceIdToListingItem[marketplaceId].listAmount;
    }
}