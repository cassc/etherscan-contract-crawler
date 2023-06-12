// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract QuadHash is ERC721, Pausable, AccessControl, DefaultOperatorFilterer {

    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 private _totalSupply;
    string  _currentBaseURI;

    mapping(address => bool) private _restrictedAddress;

    constructor() ERC721("QuadHash", "QuadHash") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(OWNER_ROLE) {
        _currentBaseURI = baseURI;
    }

    function restrict(address addr) external {
        if (addr == msg.sender || hasRole(OWNER_ROLE, msg.sender)) {
            _restrictedAddress[addr] = true;
        }
    }

    function unrestrict(address addr) external onlyRole(OWNER_ROLE) {
        _restrictedAddress[addr] = false;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    //NFTs involved in crimes such as hacking can be suspended from trading,
    //and if the damage is/might be critical, they can be burned through the governance of the community.
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || hasRole(OWNER_ROLE, msg.sender), "ERC721: caller is not token owner/admin or approved");
        _burn(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid token ID");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _mint(address to, uint256 tokenId) internal override {
        _totalSupply += 1;
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override {
        _totalSupply -= 1;
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (from != address(0) && to != address(0)) {
            require(!_restrictedAddress[msg.sender], "Restricted: restricted");
            require(!paused(), "Pausable: paused");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Operator Filter
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}