// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./abstract/AbstractERC1155Factory.sol";
import "./library/Strings.sol";

contract PortalPass is AbstractERC1155Factory {
    using Strings for uint256;

    struct Collection {
        // Max amount of tickets of the event
        uint256 maxSupply;
        // Max amount of tickets allowed to buy in a tx
        uint8 maxPerTx;
        // Max amount of tickets allowed to own in a wallet
        uint8 maxPerWallet;
        // Ticket price
        uint256 price;
        // Status - 0: close, 1: public sale 2: only signature
        uint8 status;
    }

    uint256 private _currentCollectionId = 0; // The last event id

    mapping(uint256 => Collection) public collections;
    // Minted amount of the wallet
    mapping(address => mapping(uint256 => uint256)) public numberMinted;

    // Verify Signature
    address public secret;

    event CreatedCollection(
        uint256 indexed collectionId,
        uint256 maxSupply,
        uint8 maxPerTx,
        uint8 maxPerWallet,
        uint256 price,
        uint8 status
    );
    event Purchased(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "200:ZERO_ADDRESS");
        _;
    }

    modifier availableCollection(uint256 _id) {
        require(_id > 0 && _id <= _currentCollectionId, "No exist collection");
        _;
    }

    /**
     * @notice set collection id that can be minted
     *
     * @param _maxSupply the max amount of tickets in the collection
     * @param _maxPerTx the new max amount of tickets allowed to buy in a tx
     * @param _maxPerWallet the new max amount of tickets allowed to own in a wallet
     * @param _price the price of ticket
     * @param _status status of the collection // 0: close, 1: public sale 2: only signature
     */
    function createCollection(
        uint256 _maxSupply,
        uint8 _maxPerTx,
        uint8 _maxPerWallet,
        uint256 _price,
        uint8 _status
    ) external onlyOwner {
        require(_status < 3, "Wrong status value");

        _currentCollectionId++;
        collections[_currentCollectionId] = Collection({
            maxSupply: _maxSupply,
            maxPerTx: _maxPerTx,
            maxPerWallet: _maxPerWallet,
            price: _price,
            status: _status
        });

        emit CreatedCollection(
            _currentCollectionId,
            _maxSupply,
            _maxPerTx,
            _maxPerWallet,
            _price,
            _status
        );
    }

    /**
     * @notice get collection data
     */
    function getCollection(uint256 collectionId)
        public
        view
        availableCollection(collectionId)
        returns (Collection memory)
    {
        return collections[collectionId];
    }

    /**
     * @notice edit the mint price
     *
     * @param _price the new price in wei
     */
    function setPrice(uint256 _collectionId, uint256 _price)
        external
        availableCollection(_collectionId)
        onlyOwner
    {
        collections[_currentCollectionId].price = _price;
    }

    /**
     * @notice edit sale restrictions
     *
     * @param _maxSupply the max supply in this collection
     * @param _maxPerTx the new max amount of tokens allowed to buy in one tx
     * @param _maxPerWallet the new max amount of tokens allowed to own in a wallet
     * @param _status the new status. 0- close, 1-public, 2-private
     */
    function updateSaleRestrictions(
        uint256 _collectionId,
        uint256 _maxSupply,
        uint8 _maxPerTx,
        uint8 _maxPerWallet,
        uint8 _status
    ) external availableCollection(_collectionId) onlyOwner {
        require(_status < 4, "Wrong status value");

        Collection storage collection = collections[_collectionId];
        collection.maxSupply = _maxSupply;
        collection.maxPerTx = _maxPerTx;
        collection.maxPerWallet = _maxPerWallet;
        collection.status = _status;
    }

    /**
     * @notice set new secret address to verify signature
     *
     * @param _secret the new secret address
     */
    function setSecretAddress(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }

    /**
     * @notice airdrop tickets
     *
     * @param account address to airdrop
     * @param amount the amount of cards to purchase
     */
    function airdrop(
        uint256 collectionId,
        address account,
        uint256 amount
    )
        external
        availableCollection(collectionId)
        whenNotPaused
        noZeroAddress(account)
        onlyOwner
    {
        require(
            totalSupply(collectionId) + amount <=
                collections[collectionId].maxSupply,
            "Airdrop: Max supply reached"
        );

        _mint(account, collectionId, amount, "");
    }

    /**
     * @notice purchase
     *
     * @param amount the amount of tokens
     */
    function purchase(
        uint256 collectionId,
        uint256 amount,
        bytes memory signature
    ) external payable availableCollection(collectionId) whenNotPaused {
        require(
            collections[collectionId].status > 0 &&
                collections[collectionId].status < 3,
            "Sale is close or invalid status."
        );

        if (collections[collectionId].status == 2) {
            // 2: only signature - only users with a valid signature
            require(
                _verifyHashSignature(
                    keccak256(abi.encode(collectionId, amount, msg.sender)),
                    signature
                ),
                "Signature is invalid"
            );
        }

        _purchase(collectionId, amount);
    }

    /**
     * @notice global purchase function used in early access and public sale
     *
     * @param amount the amount of tokens to purchase
     */
    function _purchase(uint256 collectionId, uint256 amount) private {
        Collection memory collection = collections[collectionId];

        require(
            amount > 0 && amount <= collection.maxPerTx,
            "Purchase: amount prohibited"
        );
        require(
            numberMinted[msg.sender][collectionId] + amount <=
                collection.maxPerWallet,
            "Purchase: balance is over."
        );
        require(
            totalSupply(collectionId) + amount <= collection.maxSupply,
            "Purchase: Max supply reached"
        );
        require(
            msg.value == amount * collection.price,
            "Purchase: Incorrect payment"
        );

        _mint(msg.sender, collectionId, amount, "");
        numberMinted[msg.sender][collectionId] += amount;

        emit Purchased(collectionId, msg.sender, amount);
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the card id to return metadata for
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        noZeroAddress(_address)
        onlyOwner
    {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");

        require(success, "Unable to send eth");
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}