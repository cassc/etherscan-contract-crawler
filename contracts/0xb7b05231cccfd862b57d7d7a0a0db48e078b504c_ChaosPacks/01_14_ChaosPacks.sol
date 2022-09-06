// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "./external/erc721a/ERC721A.sol";
import "./Royalties/ERC2981/IERC2981Royalties.sol";

error OnlyOneCallPerBlockForNonEOA();
error SaleDisabled();
error MaxSupplyExceeded();
error MaxReserveExceeded();
error MaxPerTxExceeded();
error InvalidPurchaseValue();
error OnlySongContractCanBurn();
error LengthMismatch();
error SongContractLocked();

/// @title Chaos Packs
/// @notice Sale contract for Songcamp Chaos Packs
contract ChaosPacks is ERC721A, Ownable, IERC2981Royalties {
    using SafeTransferLib for address payable;
    using Strings for uint256;

    uint256 constant MAX_PER_MINT = 100; /*Don't let people buy more than 100 per transaction*/
    uint256 reserved; /*Max amount for reserve*/
    uint256 immutable maxSupply; /*Max token ID - set in constructor*/
    uint256 public constant PRICE = 0.2 ether; /*Public sale price*/

    address public songContract; /*Address that can burn packs to open them*/
    bool public songContractLocked; /*Allow song contract to be locked against further change*/

    uint256 public royaltyPoints; /*Royalty percentage / 10000*/

    string public contractURI; /*contractURI contract metadata json*/

    address payable public ethSink; /*recipient for ETH*/
    string public baseURI; /*baseURI_ String to prepend to token IDs*/

    bool public saleEnabled; /*Sale disabled by default*/

    mapping(address => uint256) lastCallFrom; /*Track last call to prevent contract bots*/

    modifier oncePerBlock() {
        if (msg.sender != tx.origin) {
            /*If caller is a contract only allow one call per block*/
            if (lastCallFrom[tx.origin] == block.number) {
                revert OnlyOneCallPerBlockForNonEOA();
            }
            lastCallFrom[tx.origin] = block.number; /*Store block to check on next mint*/
        }
        _;
    }

    /// @notice Constructor sets contract metadata configurations and sale configurations
    /// @param baseURI_ Base URI for token metadata
    /// @param _contractURI URI for marketplace contract metadata
    /// @param _reserved Max amount that can be minted by admin
    /// @param _maxSupply Max amount that can be minted total
    /// @param _sink Destination for sale ETH
    /// @param _royaltyPoints BP of royalties to send to song contract
    constructor(
        string memory baseURI_,
        string memory _contractURI,
        uint256 _reserved,
        uint256 _maxSupply,
        uint256 _royaltyPoints,
        address payable _sink
    ) ERC721A("Chaos Packs", "\u0024PACKS") {
        ethSink = _sink; /*Set the ETH destination - should be immutable split*/
        contractURI = _contractURI; /*Set contract metadata*/
        baseURI = baseURI_; /*Set token metadata*/

        reserved = _reserved; /*Set max admin mint*/
        maxSupply = _maxSupply; /*Set max total mint*/

        royaltyPoints = _royaltyPoints; /*Set royalty amount out of 10000*/
    }

    /*****************
    EXTERNAL MINTING FUNCTIONS
    *****************/
    /// @notice Mint pack by anyone
    /// @dev Sale state must be enabled
    /// @param _quantity How many tokens to buy - up to 100 at a time
    function purchase(uint256 _quantity) external payable oncePerBlock {
        if (!saleEnabled) revert SaleDisabled(); /*Sale must be enabled*/
        if (msg.value != (PRICE * _quantity)) revert InvalidPurchaseValue(); /*Purchase price must be exact*/
        if ((totalSupply() + _quantity) > maxSupply) revert MaxSupplyExceeded(); /*Check against max supply*/
        if (_quantity > MAX_PER_MINT) revert MaxPerTxExceeded(); /*Check against max per mint*/

        _safeMint(msg.sender, _quantity); /*Mint packs to sender*/
    }

    /// @notice Mint special reserve by owner
    /// @param _tos Addresses to mint tokens to
    /// @param _amounts How many tokens to mint
    function batchMintReserve(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (_tos.length != _amounts.length) revert LengthMismatch();
        for (uint256 index = 0; index < _tos.length; index++) {
            _mintReserve(_amounts[index], _tos[index]);
        }
    }

    /// @notice Mint special reserve by owner
    /// @param _to Address to mint tokens to
    /// @param _quantity How many tokens to mint
    function mintReserve(uint256 _quantity, address _to) external onlyOwner {
        _mintReserve(_quantity, _to);
    }

    /*****************
    INTERNAL MINTING FUNCTIONS
    *****************/
    /// @notice Mint special reserve by owner
    /// @param _to Address to mint tokens to
    /// @param _quantity How many tokens to mint
    function _mintReserve(uint256 _quantity, address _to) internal {
        if (_quantity > reserved) revert MaxReserveExceeded(); /*Check against max admin mint*/
        if ((totalSupply() + _quantity) > maxSupply)
            /*Check against max supply*/
            revert MaxSupplyExceeded();
        reserved -= _quantity; /*Decrement reserve*/
        _safeMint(_to, _quantity); /*Mint packs to specified destination*/
    }

    /*****************
    PACK OPENING
    *****************/
    /// @notice Burn pack by song contract
    /// @param _packId Which pack to burn
    function burnPack(uint256 _packId) external returns (bool) {
        if (msg.sender != songContract) revert OnlySongContractCanBurn(); /*Packs can only be burned by opening in song contract*/
        _burn(_packId); /*Burn the pack*/
        return true;
    }

    /*****************
    CONFIG FUNCTIONS
    *****************/
    /// @notice Set sale proceeds address
    /// @param _sink new sink
    function setSink(address payable _sink) external onlyOwner {
        ethSink = _sink;
    }

    /// @notice Set states enabled or disabled as owner
    /// @param _enabled specified state on or off
    function setSaleEnabled(bool _enabled) external onlyOwner {
        saleEnabled = _enabled;
    }

    /// @notice Set royalty percentage
    /// @param _royaltyPoints Royalty percentage out of 10000
    function setRoyaltyPoints(uint256 _royaltyPoints) external onlyOwner {
        royaltyPoints = _royaltyPoints;
    }

    /// @notice Set song contract as owner
    /// @param _songContract Song contract address
    function setSongContract(address _songContract) external onlyOwner {
        if (songContractLocked) revert SongContractLocked();
        songContract = _songContract;
    }

    /// @notice Lock song contract against further changes
    function lockSongContract() external onlyOwner {
        if (songContractLocked) revert SongContractLocked();
        songContractLocked = true;
    }

    /// @notice Set new base URI
    /// @param baseURI_ String to prepend to token IDs
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Set new contract URI
    /// @param _contractURI Contract metadata json
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /*****************
    DISTRIBUTION FUNCTIONS
    *****************/
    /// @notice Withdraw sale proceeds to sink
    function withdrawToSink() external onlyOwner {
        ethSink.safeTransferETH(address(this).balance);
    }

    /*****************
    Public view interfaces
    *****************/
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        override(IERC2981Royalties)
        returns (address _receiver, uint256 _royaltyAmount)
    {
        return (songContract, (_value * royaltyPoints) / 10000);
    }
}