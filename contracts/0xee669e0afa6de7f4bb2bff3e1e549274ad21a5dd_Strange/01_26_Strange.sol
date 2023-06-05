// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//          __
//    _____/ /__________ _____  ____ ____
//   / ___/ __/ ___/ __ `/ __ \/ __ `/ _ \
//  (__  / /_/ /  / /_/ / / / / /_/ /  __/
// /____/\__/_/   \__,_/_/ /_/\__, /\___/
//     __  __                /____/
//    / / / ____ _____  ____/ _____
//   / /_/ / __ `/ __ \/ __  / ___/
//  / __  / /_/ / / / / /_/ (__  )
// /_/ /_/\__,_/_/ /_/\__,_/____/

// 🧑‍💻 @nftchef
// onionchef.eth

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721SeqEnumerable.sol";

//----------------------------------------------------------------------------
// OpenSea proxy
//----------------------------------------------------------------------------
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IStrange.sol";

//----------------------------------------------------------------------------
// helper contracts
//----------------------------------------------------------------------------

contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Strange is
    ERC721SeqEnumerable,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    VRFConsumerBase,
    IStrange,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint128 internal PUBLIC_SUPPLY = 9850; // 150 reserved.
    uint128 internal MAX_SUPPLY = 10000;
    uint128 public PUBLIC_MINT_LIMIT = 10;
    uint128 public PRESALE_MINT_LIMIT = 5;
    uint128 public PRESALE_PRICE = 0.08 ether;
    uint128 public PUBLIC_PRICE = 0.09 ether;

    // @dev enforce a per-address lifetime limit based on the mintBalances mapping
    bool public publicWalletLimit = true;
    bool public isPresale = true;
    bool public isRevealed = false;

    string public PROVENANCE_HASH; // keccak256

    mapping(address => uint256) public mintBalances;

    uint256 public tokenOffset;
    string internal baseTokenURI;
    address[] internal payees;
    address internal _SIGNER;

    // opensea proxy
    address private immutable _proxyRegistryAddress;

    // LINK
    uint256 internal LINK_FEE;
    bytes32 internal LINK_KEY_HASH;

    constructor(
        string memory _initialURI,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _linkFee,
        address[] memory _payees,
        uint256[] memory _shares,
        address proxyRegistryAddress
    )
        payable
        ERC721Sequencial("Strange Hands", "STRGHNDZ")
        Pausable()
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        PaymentSplitter(_payees, _shares)
    {
        _pause();
        baseTokenURI = _initialURI;
        payees = _payees;

        LINK_KEY_HASH = _keyHash;
        LINK_FEE = _linkFee;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("Strange Hands");
    }

    function purchase(uint256 _quantity)
        public
        payable
        override
        nonReentrant
        whenNotPaused
    {
        require(!isPresale, "Presale only.");
        require(
            _quantity <= PUBLIC_MINT_LIMIT,
            "Quantity exceeds PUBLIC_MINT_LIMIT"
        );
        if (publicWalletLimit) {
            require(
                _quantity + mintBalances[msg.sender] <= PUBLIC_MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }
        require(_quantity * PUBLIC_PRICE <= msg.value, "Not enough minerals");

        _mint(_quantity);
    }

    function presalePurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable override nonReentrant whenNotPaused {
        require(
            checkHash(_hash, _signature, _SIGNER),
            "Address is not on Presale List"
        );
        // @dev Presale always enforces a per-wallet limit
        require(
            _quantity + mintBalances[msg.sender] <= PRESALE_MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );
        require(_quantity * PRESALE_PRICE <= msg.value, "Not enough minerals");

        _mint(_quantity);
    }

    function _mint(uint256 _quantity) internal {
        require(
            _quantity + _owners.length <= PUBLIC_SUPPLY,
            "Purchase exceeds available supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender);
        }

        mintBalances[msg.sender] += _quantity;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function senderMessageHash() internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender))
            )
        );
        return message;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function checkHash(
        bytes32 _hash,
        bytes memory signature,
        address _account
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash();
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    function setSigner(address _address) external override onlyOwner {
        _SIGNER = _address;
    }

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external override onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + _owners.length <= MAX_SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i]);
        }
    }

    function setPaused(bool _state) external override onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setPresale(bool _state) external override onlyOwner {
        isPresale = _state;
    }

    function setWalletLimit(bool _state) external override onlyOwner {
        publicWalletLimit = _state;
    }

    function setTokenOffset() public override onlyOwner {
        require(tokenOffset == 0, "Offset is already set");

        requestRandomness(LINK_KEY_HASH, LINK_FEE);
    }

    // @dev chainlink callback function for requestRandomness
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        tokenOffset = randomness % MAX_SUPPLY;
    }

    function setProvenance(string memory _provenance)
        external
        override
        onlyOwner
    {
        PROVENANCE_HASH = _provenance;
    }

    // @dev: blockchain is forever, you never know, you might need these...
    function setPresalePrice(uint128 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    function setPublicPrice(uint128 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setPresaleLimit(uint128 _limit) external onlyOwner {
        PRESALE_MINT_LIMIT = _limit;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _limit;
    }

    function setReveal(bool _state) external override onlyOwner {
        isRevealed = _state;
    }

    function setBaseURI(string memory _URI) external override onlyOwner {
        baseTokenURI = _URI;
    }

    function withdrawAll() external override onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}