// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract InfinitySet is ERC721A, ERC721ABurnable, AccessControl {
    using Strings for uint;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public mintId;
    string public contractURI;
    string public baseTokenURI;
    address public feeCollectorAddress;

    uint public max;

    bool public reveal;

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
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _feeCollectorAddress) ERC721A(_name, _symbol) {
        contractURI = _contractURI;
        baseTokenURI = _contractURI;
        mintId = 1;
        max = 250;
        feeCollectorAddress = _feeCollectorAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, 1);
    }

    function mint(address to, uint quantity) external onlyMinter {
        require(mintId + quantity <= max + 1, "No more left");
        _mint(to, quantity);
        mintId = quantity + mintId;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        if (reveal) {
            return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
        }
        return baseTokenURI;
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setMaxQuantity(uint _quantity) public onlyOwner {
        max = _quantity;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setReveal(bool _isRevealed) public onlyOwner {
        reveal = _isRevealed;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    function owner() external view returns (address) {
        return feeCollectorAddress;
    }
}