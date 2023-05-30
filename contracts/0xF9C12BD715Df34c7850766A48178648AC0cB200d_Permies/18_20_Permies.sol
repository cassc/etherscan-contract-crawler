// SPDX-License-Identifier: None
pragma solidity 0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import './ERC2981ContractWideRoyalties.sol';

/*
                            _
  _ __   ___ _ __ _ __ ___ (_) ___  ___
 | '_ \ / _ \ '__| '_ ` _ \| |/ _ \/ __|
 | |_) |  __/ |  | | | | | | |  __/\__ \
 | .__/ \___|_|  |_| |_| |_|_|\___||___/
 |_|                       by Blockworks

*/

// Custom errors
error MetadataFrozen();
error SupplyReached();
error PresaleNotActive(Permies.SaleStatus currentStatus);
error PublicSaleNotActive(Permies.SaleStatus currentStatus);
error AddressNotPresaleEligible();
error TooManyPerWallet(uint256 limit);
error WrongPriceSent(uint256 sent, uint256 required);
error NotAuthorized();
error TeamReserveReached();

/// @title  Permies
/// @author Dennis Stücken <[email protected]> - @itsdennis_s
contract Permies is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter, ERC2981ContractWideRoyalties {
    using Strings for uint256;

    // Status of the token & token sale
    enum SaleStatus {
        Paused,
        Presale,
        PublicSale,
        SoldOut,
        Revealed
    }

    // Contract events
    event StatusUpdate(SaleStatus _status);
    event BaseURIUpdated(string _newBaseUri);
    event ContractLocked();
    event PermanentURI(string _value, uint256 indexed _id);
    event RoyaltiesUpdated(uint256 value);

    // Metadata base URI
    string public baseURI;
    string private prerevealTokenURI;

    // Max mints per wallet & transaction
    uint256 public maxMints = 1;

    // Mint price & supply
    uint256 public constant mintPrice = 1.11 ether;
    uint256 public maxSupply = 555;

    // Amount of tokens held back for the team
    uint256 private maxMintReserve = 55;
    // Current amount minted by the team
    uint256 private mintReserve = 0;

    // Max mints registry
    mapping(address => uint256) private mintsPerWallet;

    // Merkle root for pre-sale list
    bytes32 public merkleRoot;

    // Contract states
    SaleStatus public status = SaleStatus.Paused;
    bool public isLocked = false;

    /// @notice Constructor
    /// @param _baseURI token metadata base URI
    /// @param _payees payment split payees
    /// @param _shares payment split share percentages
    /// @param _royalties royalty percentage
    constructor(string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint256 _royalties) ERC721A("Permies", "PERM") PaymentSplitter(_payees, _shares) payable {
        baseURI = _baseURI;
        setRoyalties(_royalties);
    }

    /// @notice structure with some details about the current state of the contract
    struct ContractDetails {
        uint256 maxMints;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 mintPrice;
        string baseURI;
        bool isLocked;
        SaleStatus status;
    }

    /// @notice helper method that returns relevant contract states all in one call
    function contractDetails() public view returns (ContractDetails memory) {
        ContractDetails memory details;
        details.maxMints = maxMints;
        details.maxSupply = maxSupply;
        details.totalSupply = totalSupply();
        details.mintPrice = mintPrice;
        details.baseURI = baseURI;
        details.status = status;
        details.isLocked = isLocked;
        return details;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Modify contract status
    /// @param _status new contract status (@see SaleStatus)
    function setStatus(SaleStatus _status) public onlyOwner {
        status = _status;
        emit StatusUpdate(_status);
    }

    /// @notice Locking the contract prevents future baseURI changes and therefore freezes the metadata URLs for all tokens.
    ///         lockContract also emits PermanentURI event for every token for exchanges to be aware of frozen Metadata.
    function lockContract() public onlyOwner {
        isLocked = true;

        uint256 s = totalSupply();
        for (uint i = 0; i < s; ++i) {
            emit PermanentURI(tokenURI(i), i);
        }

        emit ContractLocked();
    }

    /// @notice Set metadata base URI
    /// @param newBaseURI new base URI
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        if (isLocked) revert MetadataFrozen();

        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /// @notice Update amount of mints per wallet
    /// @param _maxMints new number of mints allowed
    function setMaxMints(uint256 _maxMints) external onlyOwner {
        maxMints = _maxMints;
    }

    /// @notice Set pre-sale merkle root.
    /// @param _merkleRoot merkle root hash
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Set prerevealed token URI
    /// @param _newTokenURI uri of the prereveal metadata
    function setPrerevealTokenURI(string memory _newTokenURI) external onlyOwner {
        prerevealTokenURI = _newTokenURI;
    }

    /// @notice Allows to set the royalties on the contract
    /// @param value updated royalties (between 0 and 10000)
    function setRoyalties(uint256 value) public onlyOwner {
        _setRoyalties(owner(), value);
        emit RoyaltiesUpdated(value);
    }

    /// @notice Check if address is pre-sale eligible
    /// @param _addr address to check
    /// @param _merkleProof proof to verify against
    function isPresaleEligible(address _addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));

        // Verify merkle proof
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /// @notice Mint token in presale mode
    /// @param amount number of tokens to mint
    /// @param _merkleProof proof to verify if address is eligible for presale
    function mintPresale(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        if (status != SaleStatus.Presale) revert PresaleNotActive(status);

        // Check if address is allowed to mint in presale status
        if (!isPresaleEligible(msg.sender, _merkleProof)) revert AddressNotPresaleEligible();

        uint256 s = totalSupply();
        if (s + amount > maxSupply) revert SupplyReached();
        if (amount > maxMints) revert TooManyPerWallet(maxMints);
        if (mintsPerWallet[msg.sender] + amount > maxMints) revert TooManyPerWallet(maxMints);
        if (msg.value < mintPrice * amount) revert WrongPriceSent(msg.value, mintPrice * amount);

        _safeMint(msg.sender, amount);
        mintsPerWallet[msg.sender] += amount;
        delete s;
    }

    /// @notice Mint token
    /// @param amount number of tokens to mint
    function mint(uint256 amount) external payable nonReentrant {
        if (status != SaleStatus.PublicSale) revert PublicSaleNotActive(status);

        uint256 s = totalSupply();
        if (s + amount > maxSupply) revert SupplyReached();
        if (amount > maxMints) revert TooManyPerWallet(maxMints);
        if (mintsPerWallet[msg.sender] + amount > maxMints) revert TooManyPerWallet(maxMints);
        if (msg.value < mintPrice * amount) revert WrongPriceSent(msg.value, mintPrice * amount);

        _safeMint(msg.sender, amount);
        mintsPerWallet[msg.sender] += amount;
        delete s;
    }

    /// @notice Function used by Blockworks to mint a total of "maxMintReserve" tokens for the team.
    ///         maxMintReserve is set to a fix limit of 55.
    /// @param toAddresses addresses to send the tokens to
    /// @param amount number of tokens to mint per address
    function teamMint(address[] calldata toAddresses, uint256 amount) public onlyOwner nonReentrant {
        uint total = 0;
        uint len = toAddresses.length;
        uint256 s = totalSupply();
        for (uint i = 0; i < len; ++i) {
            total += amount;
        }
        if (s + total >= maxSupply) revert SupplyReached();
        if (total + mintReserve > maxMintReserve) revert TeamReserveReached();

        for (uint256 i = 0; i < len; i++) {
            _safeMint(toAddresses[i], amount);
        }

        mintReserve = mintReserve + total;

        delete total;
        delete s;
        delete len;
    }

    /// @notice Retrieve token metadata url
    /// @param tokenId id of the token to retrieve metadata for
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        if (status != SaleStatus.Revealed) return prerevealTokenURI;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @notice Release contract funds through payment splitter
    /// @param addresses payable addresses to send the split to
    function withdrawSplit(address[] calldata addresses) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < addresses.length; i++) {
            address payable wallet = payable(addresses[i]);
            release(wallet);
        }
    }

    /// @notice Release contract funds funds to contract owner
    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}