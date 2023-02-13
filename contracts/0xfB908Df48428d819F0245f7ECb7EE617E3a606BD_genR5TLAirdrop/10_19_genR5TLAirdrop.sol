// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import "./Errors.sol";
import "./ReentrancyGuard.sol";
import "./Helpers.sol";

import "./RENRoyalties.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract genR5TLAirdrop is ERC721, ReentrancyGuard, AccessControl, Ownable, RENRoyalties, RevokableDefaultOperatorFilterer {
    // We have role for multiple accounts in case a transaction of one minter will stack (because of gas price)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constants
    // Maximum number of NFTs can be allocated
    uint256 public immutable maxSupply;

    // Base token and contract URI
    string private baseTokenURI;
    string private baseContractURI;

    // Current supply
    uint256 private _currentSupply;

    constructor(
        uint256 _maxSupply,
        string memory _baseTokenURI,
        string memory _baseContractURI,
        string memory _name,
        string memory _symbol,
        uint256 bps
    ) ERC721(_name, _symbol) RENRoyalties(bps){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        baseContractURI = _baseContractURI;
    }

    //Setup Royalties
    function setupRoyalties(address addr, uint256 bps) public {
        require(msg.sender == owner(), "only owner can setupRoyalties");
        super.setRoyalties(addr, bps);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, RENRoyalties) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || RENRoyalties.supportsInterface(interfaceId);
    }

    // Accounts with MINTER_ROLE can call this function to mint `tokens` into `addresses`
    function airdropTokens(address[] memory addresses, uint256[] memory tokens) external onlyRole(MINTER_ROLE) lock {
        uint256 length = addresses.length;
        if (length != tokens.length)
            revert Errors.WrongInputSize();

        for (uint i; i < length; i++) {
            uint256 tokenId = tokens[i];
            if (tokenId > maxSupply || tokenId == 0)
                revert Errors.IdBeyondSupplyLimit();

            address mintAddress = addresses[i];
            _mint(mintAddress, tokenId);
        }

        unchecked {
            _currentSupply += length;
        }
    }

    function burn(uint256 id) external {
        address tokenOwner = ownerOf(id);
        if (msg.sender != tokenOwner && !isApprovedForAll[tokenOwner][msg.sender] && getApproved[id] != msg.sender)
            revert Errors.NotAuthorized();
        _burn(id);
    }

    function setContractURI(string calldata baseContractURI_)
        external
        onlyOwner
    {
        if (bytes(baseContractURI_).length == 0)
            revert Errors.InvalidBaseContractURL();

        baseContractURI = baseContractURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        if (bytes(baseURI_).length == 0) revert Errors.InvalidBaseURI();

        baseTokenURI = baseURI_;
    }

    function totalSupply() external view returns (uint256) {
        return _currentSupply;
    }

    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))
                )
                : "";
    }


    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}