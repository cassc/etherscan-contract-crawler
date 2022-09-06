// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IMetamon {
    function metamonOwnership(address owner, uint256 requiredMetamon)
        external
        returns (bool);
}

struct ItemTypeInfo {
    uint256 itemPrice;
    uint256 maxMintable;
    uint256 itemSupply;
    uint256[] requiredMetamon;
    bytes32 itemMerkleRoot;
    string uri;
    bool valid;
}

contract Wardrobe is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IMetamon public metamonContract;

    address payable public paymentContractAddress;

    string public name;
    string public symbol;

    mapping(uint256 => ItemTypeInfo) itemTypes;

    mapping(address => mapping(uint256 => uint256)) itemsMinted;

    uint256 numberOfItemTypes;

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ItemMinted(address _receiver, uint256 _tokenId, uint256 _quantity);
    event ItemsMinted(address _receiver, uint256[] _tokenId, uint256[] _quantity);

    constructor()
        payable
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json"
        )
    {
        name = "Metamon Wardrobe Collection";
        symbol = "Minimetamon-WC";
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier itemTypeCheck(uint256 _itemType) {
        require(itemTypes[_itemType].valid, "Item Type out of scope!");
        _;
    }

    modifier itemTypesCheck(uint256[] memory _itemTypes) {
        for (uint i = 0; i < _itemTypes.length; i++) {
            require(
                itemTypes[_itemTypes[i]].valid,
                "Item Type is out of scope!"
            );
        }
        _;
    }

    modifier maxMintableCheck(uint256 _itemType, uint256 _quantity) {
        require(
            itemsMinted[msg.sender][_itemType] + _quantity <=
                itemTypes[_itemType].maxMintable,
            "User is trying to mint more than allocated."
        );
        require(
            totalSupply(_itemType) + _quantity <=
                itemTypes[_itemType].itemSupply,
            "User is trying to mint more than total supply."
        );
        _;
    }

    modifier requiredMetamonCheck(uint256 _itemType) {
        uint256[] memory requiredMetamon = itemTypes[_itemType].requiredMetamon;
        for (uint256 i = 0; i < requiredMetamon.length; i++) {
            if (
                !metamonContract.metamonOwnership(
                    msg.sender,
                    requiredMetamon[i]
                )
            ) {
                revert("Required metamon not owned by sender");
            }
        }
        _;
    }

    modifier requiredMetamonChecks(uint256[] memory _itemTypes) {
        for (uint i = 0; i < _itemTypes.length; i++) {
            uint256[] memory _requiredMetamon = itemTypes[_itemTypes[i]].requiredMetamon;
            for (uint256 j = 0; j < _requiredMetamon.length; j++) {
                if (
                    !metamonContract.metamonOwnership(
                        msg.sender, 
                        _requiredMetamon[j]
                    )
                ) {
                    revert("Required metamon not owned by sender");
                }
            }
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Add/Del State Changes
    ///////////////////////////////////////////////////////////////////////////
    function addWardrobeItem(
        uint256 _itemType,
        uint256 _itemPrice,
        uint256 _maxMintable,
        uint256 _itemSupply,
        uint256[] memory _requiredMetamon,
        bytes32 _itemMerkleRoot,
        string memory _uri
    ) external onlyOwner {
        require(
            !itemTypes[_itemType].valid,
            "Item type ID has already been used"
        );
        itemTypes[_itemType] = ItemTypeInfo(
            _itemPrice,
            _maxMintable,
            _itemSupply,
            _requiredMetamon,
            _itemMerkleRoot,
            _uri,
            true
        );
        numberOfItemTypes++;
    }

    function setWardrobeItemValid(uint256 _itemType, bool _valid)
        external
        onlyOwner
    {
        itemTypes[_itemType].valid = _valid;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set/Add State Changes
    ///////////////////////////////////////////////////////////////////////////
    function setItemPrice(uint256 _newPrice, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].itemPrice = _newPrice;
    }

    function getItemPrice(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].itemPrice;
    }

    function setMaxMintable(uint256 _maxMintable, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].maxMintable = _maxMintable;
    }

    function getMaxMintable(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].maxMintable;
    }

    function setItemSupply(uint256 _itemSupply, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].itemSupply = _itemSupply;
    }

    function getItemSupply(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].itemSupply;
    }

    function setRequiredMetamon(
        uint256[] memory _requiredMetamon,
        uint256 _itemType
    ) external onlyOwner itemTypeCheck(_itemType) {
        itemTypes[_itemType].requiredMetamon = _requiredMetamon;
    }

    function getRequiredMetamon(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256[] memory)
    {
        return itemTypes[_itemType].requiredMetamon;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot, uint256 _itemType)
        external
        onlyOwner
    {
        itemTypes[_itemType].itemMerkleRoot = _newMerkleRoot;
    }

    function getMerkleRoot(uint256 _itemType)
        external
        view
        onlyOwner
        returns (bytes32)
    {
        return itemTypes[_itemType].itemMerkleRoot;
    }

    function totalItemTypes() public view returns (uint256) {
        return numberOfItemTypes;
    }

    function setMetamonContractAddress(address _metamonContractAddress)
        external
        onlyOwner
    {
        metamonContract = IMetamon(_metamonContractAddress);
    }

    function setPaymentAddress(
        address payable _contractAddress
    ) external onlyOwner {
            paymentContractAddress = _contractAddress;
    }

     function getPaymentAddress() public view onlyOwner returns (address){
        return paymentContractAddress;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////
    function mintSale(uint256 _itemType, uint256 _quantity)
        external
        payable
        itemTypeCheck(_itemType)
        maxMintableCheck(_itemType, _quantity)
        nonReentrant
    {
        require(
            itemTypes[_itemType].itemMerkleRoot == 0,
            "User is trying to mint a whitelisted item through incorrect function call."
        );

        require(
            itemTypes[_itemType].requiredMetamon.length == 0,
            "User is trying to mint a wardrobe item with metamon requirements - Claim only!"
        );

        require(
            msg.value == itemTypes[_itemType].itemPrice * _quantity,
            "Not enough ETH"
        );

        itemsMinted[msg.sender][_itemType] += _quantity;
        _mint(msg.sender, _itemType, _quantity, "");
        emit ItemMinted(msg.sender, _itemType, _quantity);
    }

    function mintMultipleSale(
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        uint256 totalMintCost;

        for (uint i = 0; i < _itemTypes.length; i++) {
            require(
                itemTypes[_itemTypes[i]].itemMerkleRoot == 0,
                "User is trying to mint a whitelisted item through incorrect function call."
            );

            require(
                itemsMinted[msg.sender][_itemTypes[i]] + _quantity[i] <=
                    itemTypes[_itemTypes[i]].maxMintable,
                "User is trying to mint more than allocated."
            );

            require(
                totalSupply(_itemTypes[i]) + _quantity[i] <=
                    itemTypes[_itemTypes[i]].itemSupply,
                "User is trying to mint more than total supply."
            );

            require(
                itemTypes[_itemTypes[i]].requiredMetamon.length == 0,
                "User is trying to mint a wardrobe item with metamon requirements - Claim only!"
            );

            totalMintCost += itemTypes[_itemTypes[i]].itemPrice * _quantity[i];
        }

        require(msg.value == totalMintCost, "Not enough ETH to mint!");

        for (uint i = 0; i < _itemTypes.length; i++) {
            itemsMinted[msg.sender][_itemTypes[i]] += _quantity[i];
        }

        _mintBatch(msg.sender, _itemTypes, _quantity, "");
        emit ItemsMinted(msg.sender, _itemTypes, _quantity);
    }

    function mintSpecialItem(
        uint256 _itemType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        itemTypeCheck(_itemType)
        maxMintableCheck(_itemType, _quantity)
        nonReentrant
    {
        require(
            MerkleProof.verify(
                _merkleProof,
                itemTypes[_itemType].itemMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Caller not whitelisted"
        );

        require(
            itemTypes[_itemType].requiredMetamon.length == 0,
            "User is trying to mint a wardrobe item with metamon requirements - Claim only!"
        );

        require(
            msg.value == itemTypes[_itemType].itemPrice * _quantity,
            "Not enough ETH"
        );

        itemsMinted[msg.sender][_itemType] += _quantity;
        _mint(msg.sender, _itemType, _quantity, "");
        
        emit ItemMinted(msg.sender, _itemType, _quantity);
    }

    function claimCollectionReward(uint256 _itemType, uint256 _quantity)
        external
        itemTypeCheck(_itemType)
        maxMintableCheck(_itemType, _quantity)
        requiredMetamonCheck(_itemType)
        nonReentrant
    {
        require(
            itemTypes[_itemType].itemMerkleRoot == 0,
            "User is trying to mint a whitelisted item through incorrect function call."
        );

        require(itemTypes[_itemType].itemPrice == 0, "must be a free mint");

        itemsMinted[msg.sender][_itemType] += _quantity;
        _mint(msg.sender, _itemType, _quantity, "");

        emit ItemMinted(msg.sender, _itemType, _quantity);
    }

    function happyEnding(
        address _user,
        uint256 _itemType,
        uint256 _quantity
    )
        external
        itemTypeCheck(_itemType)
        nonReentrant
    {
        require(msg.sender == address(metamonContract), "Caller not valid");

        require(
            itemsMinted[_user][_itemType] + _quantity <=
                itemTypes[_itemType].maxMintable,
            "User is trying to mint more than allocated."
        );

        require(
            totalSupply(_itemType) + _quantity <=
                itemTypes[_itemType].itemSupply,
            "User is trying to mint more than total supply."
        );
        
        itemsMinted[_user][_itemType] += _quantity;
        _mint(_user, _itemType, _quantity, "");

        emit ItemMinted(_user, _itemType, _quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 _itemType) public view override returns (string memory) {
        return (itemTypes[_itemType].uri);
    }

    function setTokenUri(uint256 _itemType, string memory newUri)
        external
        onlyOwner
    {
        itemTypes[_itemType].uri = newUri;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Withdraw
    ///////////////////////////////////////////////////////////////////////////
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = paymentContractAddress.call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}