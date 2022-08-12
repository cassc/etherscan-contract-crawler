// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721Claimable is ERC721A, Pausable, AccessControl {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public startMintId;
    address public ownerAddress;
    string public contractURI;
    string public baseTokenURI;
    string public baseTokenURIClaimed;
    mapping(uint => bool) public claimed;
    address public feeCollectorAddress;

    bool public claimStarted;
    bool public publicMint;
    uint public max;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
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
    /// @param _baseTokenURIClaimed //the base URI after token has been claimed
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, string memory _baseTokenURI, string memory _baseTokenURIClaimed, address _feeCollectorAddress) ERC721A(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _baseTokenURI;
        baseTokenURIClaimed = _baseTokenURIClaimed;
        startMintId = 0;
        max = 16;
        feeCollectorAddress = _feeCollectorAddress;
        claimStarted = false;

        ownerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function claim(uint tokenId) external {
        require(claimStarted, "Claim period has not begun");
        require(ownerOf(tokenId) == msg.sender, "Must be owner");
        claimed[tokenId] = true;
    }

    function mint(address to, uint quantity) external onlyMinter {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function mintDirect(address to, uint quantity) external onlyOwner {
        require(startMintId < max, "No more left");
        _mint(to, quantity);
        startMintId = quantity + startMintId;
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (claimed[tokenId]) {
            return string(abi.encodePacked(baseTokenURIClaimed, tokenId.toString()));
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setOwner(address _newOwner) public onlyOwner {
        ownerAddress = _newOwner;
    }

    function setMaxQuantity(uint _quantity) public onlyOwner {
        max = _quantity;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseURIClaimed(string memory _baseTokenURIClaimed) public onlyOwner {
        baseTokenURIClaimed = _baseTokenURIClaimed;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function _beforeTokenTransfers(address from, address to, uint tokenId, uint quantity) internal virtual override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);

        require(!claimed[tokenId], "ERC721Claimable: token has already been claimed");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    function owner() external view returns (address) {
        return ownerAddress;
    }
}