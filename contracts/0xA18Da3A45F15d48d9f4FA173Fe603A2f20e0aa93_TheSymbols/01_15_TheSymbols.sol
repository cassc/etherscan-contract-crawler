// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721A.sol";

/*
* @title ERC721 token for TheSymbols
*
* @author TheSymbols
*/
contract TheSymbols is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant MAX_SUPPLY = 9775;

    bool public reveal;
    uint256 public publicMintPrice;
    address public multisigWallet;
    address public royaltiesMultisigWallet;
    uint256 public royaltiesBasisPoint;
    address public signerPublicAddress;
    bool public allowlistSaleOpen;
    bool public publicSaleOpen;
    string public foundersIPFSURI;
    string public ipfsStaticURI;
    string public genesisIPFSURI;
    uint256 public maxMintPublic;
    uint256[] public allowlistMintPrices;
    uint256[] public allowlistMintPricesAfterFreeMintDone;
    uint256 public maxFreeMints;

    uint256 private _maxMintAllowlisted;

    /**
    * @notice Constructor to create Genesis contract
    *
    * @param _name the token Name
    * @param _symbol the token Symbol
    */
    constructor (
        string memory _name,
        string memory _symbol,
        address _multisigWallet,
        address _royaltiesMultisigWallet,
        string memory _foundersIPFSURI,
        string memory _ipfsStaticURI,
        string memory _genesisIPFSURI,
        address _signerPublicAddress
    ) ERC721A(_name, _symbol) {

        foundersIPFSURI = _foundersIPFSURI;
        ipfsStaticURI = _ipfsStaticURI;
        genesisIPFSURI = _genesisIPFSURI;
        multisigWallet = _multisigWallet;
        royaltiesMultisigWallet = _royaltiesMultisigWallet;
        signerPublicAddress = _signerPublicAddress;

        maxMintPublic = 2;
        _maxMintAllowlisted = 5;
        publicMintPrice = 0.16 ether;
        royaltiesBasisPoint = 750; // 7.5%
        maxFreeMints = 2500;

        allowlistMintPrices.push(0);
        allowlistMintPrices.push(0.04 ether);
        allowlistMintPrices.push(0.08 ether);
        allowlistMintPrices.push(0.16 ether);
        allowlistMintPrices.push(0.32 ether);

        allowlistMintPricesAfterFreeMintDone.push(0.04 ether);
        allowlistMintPricesAfterFreeMintDone.push(0.08 ether);
        allowlistMintPricesAfterFreeMintDone.push(0.16 ether);
        allowlistMintPricesAfterFreeMintDone.push(0.32 ether);

        // Founders + reserved for ecosystem
        _safeMint(msg.sender, 500);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A) returns (bool) {
        return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // =========== ERC721A ===========

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesMultisigWallet, (_salePrice * royaltiesBasisPoint) / PERCENTAGE_DENOMINATOR);
    }

    /**
    * @notice Mint New Token for allowlist only
    */
    function mintAllowlist(uint16 _quantity, uint8 v, bytes32 r, bytes32 s) external payable {
        require(allowlistSaleOpen, "allowlist mint not open");
        require(_isAllowlisted(v, r, s), "you are not allowlisted");
        require(_numberMinted(msg.sender) + _quantity <= maxMintAllowlisted(), "passed max per wallet");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "passed max supply");

        _collectFeeAndMintToken(_quantity, false);
    }

    /**
    * @notice Mint New Token for Public sale only
    */
    function mint(uint16 _quantity) external payable {
        require(publicSaleOpen, "public mint not open");
        require(balanceOf(msg.sender) + _quantity <= maxMintPublic, "passed max per wallet");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "passed max supply");

        _collectFeeAndMintToken(_quantity, true);
    }

    // ===================== Views =====================

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *
    */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI(tokenId);

        if (!reveal && (tokenId > 26 || bytes(foundersIPFSURI).length == 0)) {
            // Static unrevealed
            return baseURI;
        } else {
            // Founders or reveal
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    function maxMintAllowlisted() public view returns (uint256) {
        if (totalSupply() >= maxFreeMints) {
            return _maxMintAllowlisted - 1;
        }
        return _maxMintAllowlisted;
    }

    function getAllowlistMintPrice(address minter, uint256 quantity) public view returns (uint256) {
        uint256 totalToPay;
        uint256[] memory prices = totalSupply() >= maxFreeMints ? allowlistMintPricesAfterFreeMintDone : allowlistMintPrices;
        for (uint256 i = _numberMinted(minter); i < _numberMinted(minter) + quantity; i++) {
            totalToPay += prices[i];
        }
        return totalToPay;
    }

    function getTotalMinted(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    // ===================== Management =====================

    /**
    * @notice Configure Reveal
    *
    * @param _reveal Reveal Started or Stopped
    */
    function setRevealStatus(bool _reveal) external onlyOwner {
        reveal = _reveal;
    }


    /**
    * @notice Configure allowlistSaleOpen
    *
    * @param _allowlistSaleOpen allowlist Sale Started Or Stopped
    */
    function setAllowlistSaleOpen(bool _allowlistSaleOpen) external onlyOwner {
        allowlistSaleOpen = _allowlistSaleOpen;
    }

    /**
    * @notice Configure publicSaleOpen
    *
    * @param _publicSaleOpen Public Sale Started Or Stopped
    */
    function setPublicSaleOpen(bool _publicSaleOpen) external onlyOwner {
        publicSaleOpen = _publicSaleOpen;
    }

    /**
    * @notice Configure Mint Price
    *
    * @param _publicMintPrice Mint Price
    */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    /**
    * @notice Configure Mint Price
    *
    * @param _allowlistMintPrices Mint Price
    */
    function setAllowlistMintPrices(uint256[] memory _allowlistMintPrices) external onlyOwner {
        allowlistMintPrices = _allowlistMintPrices;
    }

    /**
    * @notice Configure Mint Price
    *
    * @param _allowlistMintPricesAfterFreeMintDone Mint Price
    */
    function setAllowlistMintPricesAfterFreeMintDone(uint256[] memory _allowlistMintPricesAfterFreeMintDone) external onlyOwner {
        allowlistMintPricesAfterFreeMintDone = _allowlistMintPricesAfterFreeMintDone;
    }

    /**
    * @notice Configure Max Mint Public
    *
    * @param _max_mint_public Value
    */
    function setMaxMintPublic(uint256 _max_mint_public) external onlyOwner {
        maxMintPublic = _max_mint_public;
    }

    /**
    * @notice Configure Max Mint Allowlisted
    *
    * @param _max_mint_allowlisted Value
    */
    function setMaxMintAllowlisted(uint256 _max_mint_allowlisted) external onlyOwner {
        _maxMintAllowlisted = _max_mint_allowlisted;
    }

    /**
    * @notice Configure Max Free Mints
    *
    * @param _maxFreeMints Value
    */
    function setMaxFreeMints(uint256 _maxFreeMints) external onlyOwner {
        maxFreeMints = _maxFreeMints;
    }

    /**
    * @notice Configure Signer Public Address
    *
    * @param _signerPublicAddress Address
    */
    function setSignerPublicAddress(address _signerPublicAddress) external onlyOwner {
        signerPublicAddress = _signerPublicAddress;
    }

    /**
    * @notice Configure Multisig Wallet for minting
    *
    * @param _multisigWallet Address
    */
    function setMultisigWallet(address _multisigWallet) external onlyOwner {
        multisigWallet = _multisigWallet;
    }

    /**
    * @notice Configure Multisig Wallet for royalties
    *
    * @param _royaltiesMultisigWallet Address
    */
    function setRoyaltiesMultisigWallet(address _royaltiesMultisigWallet) external onlyOwner {
        royaltiesMultisigWallet = _royaltiesMultisigWallet;
    }

    /**
    * @notice Configure royalties %
    *
    * @param _royaltiesBasisPoint uint256
    */
    function setRoyaltiesBasisPoint(uint256 _royaltiesBasisPoint) external onlyOwner {
        require(_royaltiesBasisPoint <= 1000, "max is 10%");
        royaltiesBasisPoint = _royaltiesBasisPoint;
    }

    /**
    * @notice Change the base URI for returning metadata
    *
    * @param _foundersIPFSURI the respective base URI
    * @param _ipfsStaticURI the static base URI
    * @param _genesisIPFSURI the different base URI
    */
    function setBaseURI(string memory _foundersIPFSURI, string memory _ipfsStaticURI, string memory _genesisIPFSURI) external onlyOwner {
        foundersIPFSURI = _foundersIPFSURI;
        ipfsStaticURI = _ipfsStaticURI;
        genesisIPFSURI = _genesisIPFSURI;
    }

    // ===================== Internals =====================

    /**
    * @notice Check baseURI for token
    *
    * @param tokenId Token ID
    */
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        if (tokenId <= 26 && bytes(foundersIPFSURI).length != 0) {
            // Founders only (might be revealed first)
            return foundersIPFSURI;
        } else if (reveal == false) {
            return ipfsStaticURI;
        }
        return genesisIPFSURI;
    }

    /**
    * @notice _CollectFeeAndMintToken
    *
    * @param _quantity Total tokens to mint
    */
    function _collectFeeAndMintToken(uint16 _quantity, bool forPublicMint) internal {
        uint256 amount = forPublicMint ? publicMintPrice * _quantity : getAllowlistMintPrice(msg.sender, _quantity);
        require(msg.value >= amount, "Amount sent is not enough");

        // Send excess Payment return
        uint256 excessPayment = msg.value - amount;
        if (excessPayment > 0) {
            Address.sendValue(payable(msg.sender), excessPayment);
        }

        Address.sendValue(payable(multisigWallet), amount);

        _safeMint(msg.sender, _quantity);
    }

    /**
    * @notice Check if address is allowlisted
    *
    */
    function _isAllowlisted(uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        return keccak256(abi.encodePacked(_msgSender())).toEthSignedMessageHash().recover(v, r, s) == signerPublicAddress;
    }
}