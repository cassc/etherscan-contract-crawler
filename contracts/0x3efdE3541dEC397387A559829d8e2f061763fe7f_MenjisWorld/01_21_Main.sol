// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//   __  __           _ _ _     __      __       _    _
//  |  \/  |___ _ _  (_(_( )___ \ \    / ___ _ _| |__| |
//  | |\/| / -_| ' \ | | |/(_-<  \ \/\/ / _ | '_| / _` |
//  |_|  |_\___|_||__/ |_| /__/   \_/\_/\___|_| |_\__,_|
// ─────────────── |__/    ────────────┌▄▄┌─────────────────
// ──────────────────────────────────▄██▀▀▀▀█▄───────────────
// ─────────────────────────────────██───┌───▀█▄─────────────
// ───────────┌▄████▓┐──────────────█▄───▀█────██────────────
// ──────────▄█▀────╙█▌─────────────██────╙█▄───██───────────
// ─────────▓█─┌█▀───▀█═────────────▐█─────╙█▄───██──────────
// ────────▐█──█▌─────██─────────────█▌─────╙█╕──╙█▄─────────
// ────────██─╫█──────╫█──╓▄▓██████▓▌█▌──────██───██─────────
// ────────██─▓▌───────██▀▀└─────────█────────▀───▓█─────────
// ────────╫█──────────╙█▄────────────────────────▐█─────────
// ─────────█▌─▐█▀──────▀█────────╓───▄───────────╒█▌────────
// ─────────╙█─██──────╔───▓▀─────╙█▄█╙────────────█▀────────
// ──────────╙██▌──────╟▌╓█─┌▄─────▓█▒──█╕─────────█▌────────
// ───────────▐█▄───────██──█▌────┌███──╫█────────┌█▌────────
// ───────────▐█▒──────╓███─▀█═───█▌─██─╙─────────▐█─────────
// ───────────╒█▌──────█▌─▀█──────█───█▄──────────██─────────
// ────────────██──────█───╙█─────█────▀────────┌██──────────
// ────────────╙█▌─────└───────────────────────▄█▀───────────
// ─────────────╙█▄─────────────────────────┌▄█▀─────────────
// ──────────────╙██▄──────────────────┌╓▄▓██▀───────────────
// ────────────────╙▀██▄▄▄▄▄▄▄▄▄▄▄▄▓▓███▀▀└──────────────────
// ────────────────────└╙╙╙╙▀▀▀╙╙╙╙└─────────────────────────
// ──────────────────────────────────────────────────────────
// ──────────────────────────────────────────────────────────
// ──────────────────────────────────────────────────────────
// cooked by @nftchef  ─────────────────────────────────────

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

//----------------------------------------------------------------------------
// OpenSea proxy
//----------------------------------------------------------------------------
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//----------------------------------------------------------------------------
// Main contract
//----------------------------------------------------------------------------

contract MenjisWorld is
    ERC721A,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    VRFConsumerBase,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint128 public PUBLIC_SUPPLY = 4900;
    uint128 public MAX_SUPPLY = 5000;
    uint128 public PUBLIC_MINT_LIMIT = 10;
    uint128 public PRICE = 0.05 ether;

    bool public publicWalletLimit = true;
    bool public isPresale = true;

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
        string memory _uri,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _linkFee,
        address[] memory _payees,
        uint256[] memory _shares,
        address proxyRegistryAddress
    )
        payable
        ERC721A("MenjisWorld", "MW")
        Pausable()
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        PaymentSplitter(_payees, _shares)
    {
        _pause();
        baseTokenURI = _uri;
        payees = _payees;

        LINK_KEY_HASH = _keyHash;
        LINK_FEE = _linkFee;
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function purchase(uint256 _quantity) public payable whenNotPaused {
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

        require(_quantity * PRICE <= msg.value, "Not enough minerals");
        mint(_quantity);
    }

    function presalePurchase(
        uint256 _quantity,
        uint256 _tier,
        bytes32 _hash,
        bytes memory _signature
    ) external payable whenNotPaused {
        require(
            checkHash(_tier, _hash, _signature, _SIGNER),
            "PresaleMintNotAllowed"
        );
        // @dev Presale always enforces a per-wallet limit
        require(
            _quantity + mintBalances[msg.sender] <= _tier,
            "Quantity exceeds wallet limit"
        );
        require(_quantity * PRICE <= msg.value, "Not enough minerals");

        mint(_quantity);
    }

    function mint(uint256 _quantity) internal {
        require(
            _quantity + totalSupply() <= PUBLIC_SUPPLY,
            "Purchase exceeds available supply"
        );

        _safeMint(msg.sender, _quantity);

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

    function senderMessageHash(uint256 tier) internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender, tier))
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
        uint256 _tier,
        bytes32 _hash,
        bytes memory signature,
        address _account
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash(_tier);
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + totalSupply() <= MAX_SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i], 1);
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setPresale(bool _state) external onlyOwner {
        isPresale = _state;
    }

    function setWalletLimit(bool _state) external onlyOwner {
        publicWalletLimit = _state;
    }

    function setTokenOffset() public onlyOwner {
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

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    // blockchain is forever, you never know, you might need these...
    function setPrice(uint128 _price) external onlyOwner {
        PRICE = _price;
    }

    function releaseReserve() external onlyOwner {
        PUBLIC_SUPPLY = MAX_SUPPLY;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _limit;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}