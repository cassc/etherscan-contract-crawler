// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Mothz
/// @author SecuroMint
/// @notice wën thę lämp göęs brïght, thę möthz gët hypę!
/// @custom:security-contact [email protected]
contract Mothz is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {

    enum MintState {
        Public,
        Whitelisted
    }

    struct SecuroMintData {
        // @dev The total supply of the token.
        uint16 supplyTotal;

        // @dev The maximum number of tokens that can be minted to a single address.
        uint16 maxPerWallet;

        // @dev The maximum number of tokens that can be minted in a single transaction.
        uint16 maxPerTx;

        // @dev The price for a private, whitelist-only mint.
        uint72 preSalePrice;

        // @dev The price for a public mint.
        uint72 salePrice;

        // @dev Whether the pre-sale is active.
        bool preSaleActive;

        // @dev Whether the public sale is active.
        bool saleActive;
    }

    // @dev The number of tokens a specific address has minted.
    mapping(address => uint16) public hasMinted;

    // @dev The merkle root for the pre-sale whitelist.
    bytes32 public presaleMerkleRoot;

    // @dev The merkle root for the regular sale whitelist.
    bytes32 public saleMerkleRoot;

    // @dev The base URI for metadata.
    string private baseURI;

    // @dev SecuroMint platform data.
    SecuroMintData private _securoMintData;

    // @dev The mint state.
    MintState private _mintState;

    using Strings for uint256;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory _base,
        address _owner,
        SecuroMintData memory _data
    ) ERC721A("mothz", "MOTHZ") PaymentSplitter(_payees, _shares) {
        baseURI = _base;
        transferOwnership(_owner);
        _securoMintData = _data;
        _mintState = MintState.Public;
    }

    ///////////////
    /// Minting ///
    ///////////////

    function mint(uint16 _quantity, bytes32[] memory _proof) public payable nonReentrant {
        require(getPrice() * _quantity <= msg.value, "SECUROMINT_INSUFFICIENT_ETH");

        // Retrieve in memory the token data for maximums.
        uint16 _totalSupply = _securoMintData.supplyTotal;
        uint16 _maxPerWallet = _securoMintData.maxPerWallet;
        uint16 _maxPerTx = _securoMintData.maxPerTx;

        // Ensure the user has not exceeded the maximums.
        require(_quantity <= _maxPerTx, "SECUROMINT_EXCEEDS_MAX_PER_TX");
        require(totalSupply() + _quantity <= _totalSupply, "SECUROMINT_EXCEEDS_TOTAL_SUPPLY");

        // Retrieve the current sale status.
        bool _saleActive = _securoMintData.saleActive;
        bool _preSaleActive = _securoMintData.preSaleActive;

        // Require the sale to be active.
        // If the sale is public, require the public sale to be active. If the sale is private, require the private
        // sale to be active.
        if (_mintState == MintState.Public) {
            require(_saleActive, "SECUROMINT_SALE_NOT_ACTIVE");
        } else {
            require(_preSaleActive, "SECUROMINT_PRE_SALE_NOT_ACTIVE");
        }

        // Ensure the user has not exceeded the maximum per wallet.
        require(hasMinted[msg.sender] + _quantity <= _maxPerWallet, "SECUROMINT_EXCEEDS_MAX_PER_WALLET");

        // If the sale is private, ensure the user is whitelisted.
        if (_mintState == MintState.Whitelisted) {
            require(_verifyWhitelist(msg.sender, _proof), "SECUROMINT_NOT_WHITELISTED");
        }

        // Mint the tokens.
        hasMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // @dev Verify a user's address against a merkle root.
    function _verifyWhitelist(address _address, bytes32[] memory _proof) internal view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_address));

        if (_mintState == MintState.Public) {
            return MerkleProof.verify(_proof, saleMerkleRoot, _leaf);
        } else {
            return MerkleProof.verify(_proof, presaleMerkleRoot, _leaf);
        }
    }

    // @dev Allow the owner to mint tokens to a specific address.
    function reserve(address _address, uint16 _quantity) public nonReentrant onlyOwner {
        require(totalSupply() + _quantity <= _securoMintData.supplyTotal, "SECUROMINT_EXCEEDS_TOTAL_SUPPLY");
        _safeMint(_address, _quantity);
    }

    ///////////////
    /// Getters ///
    ///////////////

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function readData() public view returns (SecuroMintData memory) {
        return _securoMintData;
    }

    function getPrice() public view returns (uint72) {
        if (_securoMintData.preSaleActive) {
            return _securoMintData.preSalePrice;
        } else {
            return _securoMintData.salePrice;
        }
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function getMintState() public view returns (MintState) {
        return _mintState;
    }

    function getSaleActive() public view returns (bool) {
        return _securoMintData.saleActive;
    }

    function getMerkleRoots() public view returns (bytes32, bytes32) {
        return (presaleMerkleRoot, saleMerkleRoot);
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getHasMinted(address _address) public view returns (uint16) {
        return hasMinted[_address];
    }

    ///////////////
    /// Setters ///
    ///////////////

    function setBase(string memory _base) public onlyOwner {
        baseURI = _base;
    }

    function setPresaleMerkleRoot(bytes32 _root) public onlyOwner {
        presaleMerkleRoot = _root;
    }

    function setSaleMerkleRoot(bytes32 _root) public onlyOwner {
        saleMerkleRoot = _root;
    }

    function updateData(uint16 _supplyTotal, uint16 _maxPerWallet, uint16 _maxPerTx, uint72 _preSalePrice, uint72 _salePrice) public onlyOwner {
        require(_supplyTotal >= 0, "SECUROMINT_MANAGE_ERR_SUPPLY_LESS_THAN_ZERO");
        require(_maxPerWallet >= 0, "SECUROMINT_MANAGE_ERR_MAX_PER_WALLET_LESS_THAN_ZERO");
        require(_maxPerTx >= 0, "SECUROMINT_MANAGE_ERR_MAX_PER_TX_LESS_THAN_ZERO");
        require(_preSalePrice >= 0, "SECUROMINT_MANAGE_ERR_PRE_SALE_PRICE_LESS_THAN_ZERO");
        require(_salePrice >= 0, "SECUROMINT_MANAGE_ERR_SALE_PRICE_LESS_THAN_ZERO");

        require(_supplyTotal >= totalSupply(), "SECUROMINT_MANAGE_ERR_SUPPLY_LESS_THAN_TOTAL_SUPPLY");

        _securoMintData.supplyTotal = _supplyTotal;
        _securoMintData.maxPerWallet = _maxPerWallet;
        _securoMintData.maxPerTx = _maxPerTx;
        _securoMintData.preSalePrice = _preSalePrice;
        _securoMintData.salePrice = _salePrice;
    }

    // @dev Change the mint state.
    function setState(MintState _mint, bool _presale, bool _sale) public onlyOwner {
        if (_presale) {
            require(!_sale, "SECUROMINT_MANAGE_ERR_SALE_AND_PRE_SALE_ACTIVE");
        } else if (_sale) {
            require(!_presale, "SECUROMINT_MANAGE_ERR_SALE_AND_PRE_SALE_ACTIVE");
        }

        _mintState = _mint;
        _securoMintData.preSaleActive = _presale;
        _securoMintData.saleActive = _sale;
    }
}