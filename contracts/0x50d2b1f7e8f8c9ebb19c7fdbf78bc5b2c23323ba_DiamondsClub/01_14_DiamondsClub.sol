// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721A.sol";

/*
* @title Main contract for Diamonds Club
*/
contract DiamondsClub is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant ALLOW_LIST_MAX_SUPPLY = 500;

    uint256 public mintPrice;
    address public multisigWallet;
    address public royaltiesMultisigWallet;
    uint256 public royaltiesBasisPoint;
    address public signerPublicAddress;
    bool public whitelistSaleOpen;
    bool public publicSaleOpen;
    string public _tokenURI;
    uint256 public maxMintPublic;
    uint256 public maxMintAllowlisted;

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
        string memory __tokenURI,
        address _signerPublicAddress,
        address communityWallet
    ) ERC721A(_name, _symbol) {
        _tokenURI = __tokenURI;
        multisigWallet = _multisigWallet;
        royaltiesMultisigWallet = _royaltiesMultisigWallet;
        signerPublicAddress = _signerPublicAddress;
        maxMintPublic = 5;
        maxMintAllowlisted = 2;
        mintPrice = 0.25 ether;
        royaltiesBasisPoint = 500; // 5%
        _safeMint(communityWallet, 50);
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
    * @notice Mint New Token for whitelist only
    */
    function mintAllowlist(uint16 _quantity, uint8 v, bytes32 r, bytes32 s) external payable {
        require(whitelistSaleOpen, "whitelist mint not open");
        require(_isAllowlisted(v, r, s), "you are not allowlisted");
        require(balanceOf(msg.sender) + _quantity <= maxMintAllowlisted, "passed max per wallet");
        require(totalSupply() + _quantity <= ALLOW_LIST_MAX_SUPPLY, "passed max supply");

        _collectFeeAndMintToken(_quantity);
    }

    /**
    * @notice Mint New Token for Public sale only
    */
    function mint(uint16 _quantity) external payable {
        require(publicSaleOpen, "public mint not open");
        require(balanceOf(msg.sender) + _quantity <= maxMintPublic, "passed max per wallet");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "passed max supply");

        _collectFeeAndMintToken(_quantity);
    }

    /**
    * @notice The NFT URI
    */
    function tokenURI(uint256) public view virtual override returns (string memory) {
        return _tokenURI;
    }

    // ===================== Management =====================

    /**
    * @notice Configure whitelistSaleOpen
    *
    * @param _whitelistSaleOpen whitelist Sale Started Or Stopped
    */
    function setWhitelistSaleOpen(bool _whitelistSaleOpen) external onlyOwner {
        whitelistSaleOpen = _whitelistSaleOpen;
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
    * @param _mintPrice Mint Price
    */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
    * @notice Configure Max Mint Public
    *
    * @param _maxMintPublic Value
    */
    function setMaxMintPublic(uint256 _maxMintPublic) external onlyOwner {
        maxMintPublic = _maxMintPublic;
    }

    /**
    * @notice Configure Max Mint Allowlisted
    *
    * @param _maxMintAllowlisted Value
    */
    function setMaxMintAllowlisted(uint256 _maxMintAllowlisted) external onlyOwner {
        maxMintAllowlisted = _maxMintAllowlisted;
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
    * @notice Setting NFT URI
    *
    * @param __tokenURI string
    */
    function setTokenURI(string memory __tokenURI)  external onlyOwner  {
        _tokenURI = __tokenURI;
    }

    // ===================== Internals =====================

    /**
    * @notice _CollectFeeAndMintToken
    *
    * @param _quantity Total tokens to mint
    */
    function _collectFeeAndMintToken(uint16 _quantity) internal {
        uint256 amount = mintPrice * _quantity;
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