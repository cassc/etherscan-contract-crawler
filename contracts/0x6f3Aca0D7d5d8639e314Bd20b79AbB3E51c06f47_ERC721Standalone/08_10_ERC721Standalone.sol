// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721Standalone is ERC721A, Pausable, AccessControl {
    using Strings for uint;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint public startMintId;
    string public contractURI;
    string public baseTokenURI;
    address public ownerAddress;

    bool public reveal;
    bool public publicMint;
    uint public max;
    uint public mintedPublic;
    uint public mintedWhitelist;
    uint public maxPerWallet;
    uint public whitelistSize;
    uint public mintsPerWhitelist;
    mapping(address => uint) public minted;
    mapping(address => bool) public whitelist;

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), "Must have burner role.");
        _;
    }
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _contractURI the contract URI
    /// @param _baseTokenURI the base URI for computing the tokenURI
    constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI) ERC721A(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;
        max = 6969;
        startMintId = 1;
        maxPerWallet = 2;
        mintsPerWhitelist = 2;

        ownerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _mint(msg.sender, 1);
    }

    function viewPublicMax() public view returns (uint) {
        return max - viewPrivateMax();
    }

    function viewPrivateMax() public view returns (uint) {
        return whitelistSize * mintsPerWhitelist;
    }

    function mintPublic(uint quantity) public {
        require(publicMint, "public mint has not started");
        require(mintedPublic + quantity <= viewPublicMax(), "No more left");
        require(minted[msg.sender] + quantity <= maxPerWallet, "already minted with this wallet");

        _mint(msg.sender, quantity);

        mintedPublic = mintedPublic + quantity;
        minted[msg.sender] = minted[msg.sender] + quantity;
        startMintId = quantity + startMintId;
    }

    function mintWhitelist() public {
        require(whitelist[msg.sender], "Address not whitelisted");
        require(mintedWhitelist + mintsPerWhitelist <= viewPrivateMax(), "No more left");
        _mint(msg.sender, mintsPerWhitelist);

        mintedWhitelist = mintedWhitelist + mintsPerWhitelist;
        whitelist[msg.sender] = false;
        startMintId++;
    }

    function burn(uint tokenId) public virtual onlyBurner {
        _burn(tokenId);
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (reveal) {
            return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
        }
        return baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setWhitelist(address[] memory _whitelist) public onlyOwner {
        whitelistSize = whitelistSize + _whitelist.length;
        for (uint i = 0; i < _whitelist.length; i++) {
            require(!whitelist[_whitelist[i]], "already whitelisted");
            whitelist[_whitelist[i]] = true;
        }
    }

    function revokeWhitelist(address[] memory _whitelist) public onlyOwner {
        whitelistSize = whitelistSize - _whitelist.length;
        for (uint i = 0; i < _whitelist.length; i++) {
            require(whitelist[_whitelist[i]], "not whitelisted");
            whitelist[_whitelist[i]] = false;
        }
    }

    function setMaxQuantity(uint _quantity) public onlyOwner {
        max = _quantity;
    }

    function setMaxPerWallet(uint _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintStart(bool _isStarted) public onlyOwner {
        publicMint = _isStarted;
    }

    function setReveal(bool _isRevealed) public onlyOwner {
        reveal = _isRevealed;
    }

    function owner() external view returns (address) {
        return ownerAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }
}