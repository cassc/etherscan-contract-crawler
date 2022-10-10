// SPDX-License-Identifier: MIT
// Creator: OwlyLabs - twitter.com/Owlylab

pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract TestNFT is ERC721AUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, IERC2981Upgradeable {
    using StringsUpgradeable for uint256;

    /* Variables */
    uint256 public _txLimit;
    uint256 public _walletLimitTeam;
    uint256 public _walletLimitGmi;
    uint256 public _walletLimitAllow;
    uint256 public _walletLimitPublic;
    uint256 public _maxSupply;
    uint256 public _cost;
    uint256 private _communityLimit;
    uint256 private _communityMinted;
    uint256 private _royaltyAmount;
    string private _apiUri;
    address private _royaltyOwner;
    address private _projectOwner;
    bytes32 private _rootTeam;
    bytes32 private _rootGmi;
    bytes32 private _rootAllow;
    bool public _mintActiveTeam;
    bool public _mintActiveGmi;
    bool public _mintActiveAllow;
    bool public _mintActivePublic;
    mapping(address => uint256) private _mintedBalances;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory name, string memory symbol, address royaltyOwner) initializerERC721A initializer public {
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __AccessControl_init();

        _txLimit = 5;
        _walletLimitTeam = 5;
        _walletLimitGmi = 2;
        _walletLimitAllow = 2;
        _walletLimitPublic = 2;
        _maxSupply = 4242;
        _cost = 0.001 ether; //TODO: Check
        _communityLimit = 242;
        _communityMinted = 0;
        _royaltyAmount = 750;
        _apiUri = "https://eth.bulent.dev/meta/"; //TODO: Check
        _royaltyOwner = royaltyOwner;
        _mintActiveTeam = false;
        _mintActiveGmi = false;
        _mintActiveAllow = false;
        _mintActivePublic = false;

        _projectOwner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, _projectOwner);
    }

    /* Public */
    function teamMint(uint256 mintAmount, bytes32[] calldata proof)
            mintRequires(mintAmount)
            isTeamListed(proof)
            checkAmount(mintAmount, _walletLimitTeam)
            checkPrice(mintAmount, _cost) public payable {
        require(_mintActiveTeam, "Team list sale has not started");
        
        _mintedBalances[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    function gmiMint(uint256 mintAmount, bytes32[] calldata proof)
            mintRequires(mintAmount)
            isGmiListed(proof)
            checkAmount(mintAmount, _walletLimitGmi)
            checkPrice(mintAmount, _cost) public payable {
        require(_mintActiveGmi, "Gmi list sale has not started");
        
        _mintedBalances[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    function allowMint(uint256 mintAmount, bytes32[] calldata proof)
            mintRequires(mintAmount)
            isAllowListed(proof)
            checkAmount(mintAmount, _walletLimitAllow)
            checkPrice(mintAmount, _cost) public payable {
        require(_mintActiveAllow, "Allow list sale has not started");
        
        _mintedBalances[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    function publicMint(uint256 mintAmount)
            mintRequires(mintAmount)
            checkAmount(mintAmount, _walletLimitPublic)
            checkPrice(mintAmount, _cost) public payable {
        require(_mintActivePublic, "Public sale has not started");

        _mintedBalances[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    /* Override */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC165Upgradeable, AccessControlUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyOwner;
        royaltyAmount = (value * _royaltyAmount) / 10000;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /* Private */
    function withdrawPrivate(address wallet, uint256 amount) private {
        (bool success, ) = wallet.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /* Internal */
    function _baseURI() internal view virtual override returns (string memory) {
        return _apiUri;
    }

    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "Royalty too high");
        _royaltyAmount = value;
        _royaltyOwner = recipient;
    }

    /* Admin / Project Owner */
    function communityMint(address wallet, uint256 mintAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_communityMinted + mintAmount <= _communityLimit, "Max limit exceeded");

        _communityMinted += mintAmount;
        _mintedBalances[wallet] += mintAmount;
        _safeMint(wallet, mintAmount);
    }

    function setMerkleRoot(bytes32 rootTeam, bytes32 rootGmi, bytes32 rootAllow) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _rootTeam = rootTeam;
        _rootGmi = rootGmi;
        _rootAllow = rootAllow;
    }

    function setMintActive(bool teamActive, bool gmiActive, bool allowActive, bool publicActive) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintActiveTeam = teamActive;
        _mintActiveGmi = gmiActive;
        _mintActiveAllow = allowActive;
        _mintActivePublic = publicActive;
    }

    function setBaseURI(string memory baseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _apiUri = baseUri;
    }

    function setRoyalties(address recipient, uint256 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoyalties(recipient, value);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0);

        withdrawPrivate(0x581ca361b24Fb71c31488F80D2a1A46E5CAa207f, balance); //TODO: Check
    }

    function setWalletLimits(uint256 walletLimitTeam, uint256 walletLimitGmi, uint256 walletLimitAllow, uint256 walletLimitPublic) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _walletLimitTeam = walletLimitTeam;
        _walletLimitGmi = walletLimitGmi;
        _walletLimitAllow = walletLimitAllow;
        _walletLimitPublic = walletLimitPublic;
    }

    function setProjectOwner(address projectOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_projectOwner != address(0)) {
            _revokeRole(DEFAULT_ADMIN_ROLE, _projectOwner);
        }
        
        _projectOwner = projectOwner;
        _grantRole(DEFAULT_ADMIN_ROLE, _projectOwner);
    }

    /* Modifiers */
    modifier mintRequires(uint256 mintAmount) {
        require(mintAmount > 0, "Invalid amount");
        require(_mintedBalances[msg.sender] + mintAmount <= _maxSupply, "Max amount exceeded");
        _;
    }

    modifier checkAmount(uint256 mintAmount, uint256 maxAmount) {
        require(_mintedBalances[msg.sender] + mintAmount <= maxAmount, "Max limit exceeded");
        _;
    }

    modifier checkPrice(uint256 mintAmount, uint cost) {
        require(msg.value >= cost * mintAmount, "Insufficient funds");
        _;
    }

    modifier isTeamListed(bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(proof, _rootTeam, leaf), "Invalid proof");
        _;
    }

    modifier isGmiListed(bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(proof, _rootGmi, leaf), "Invalid proof");
        _;
    }

    modifier isAllowListed(bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(proof, _rootAllow, leaf), "Invalid proof");
        _;
    }
}