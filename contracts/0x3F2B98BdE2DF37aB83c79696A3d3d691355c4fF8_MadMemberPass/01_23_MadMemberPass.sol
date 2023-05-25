// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMadMemberPass.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MadMemberPass is DefaultOperatorFilterer, EIP2981RoyaltyOverrideCore, IMadMemberPass, ERC721AntiScam, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant MINTER = "MINTER";
    bytes32 public constant BURNER = "BURNER";

    // Metadata
    string public baseURI;
    string public baseExtension;

    // Constructor
    constructor() ERC721A("MadMemberPass", "MMP") {
        _grantRole(ADMIN, msg.sender);
    }

    // Mint
    function mint(address _address, uint256 _amount) external override onlyRole(MINTER) {
        _mint(_address, _amount);
    }

    // Burn
    function burn(uint256 _tokenId) external onlyRole(BURNER) {
        _burn(_tokenId);
    }

    // Getter
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    function getTotalBurned() view external returns (uint256) {
        return _totalBurned();
    }
    function isTokenOwner(address _owner, uint256 _tokenId) view external returns(bool) {
        return ownerOf(_tokenId) == _owner;
    }
    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    // Setter
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royalty
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyRole(ADMIN) {
        _setTokenRoyalties(royaltyConfigs);
    }
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyRole(ADMIN) {
        _setDefaultRoyalty(royalty);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721AntiScam, EIP2981RoyaltyOverrideCore) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // CAL
    function addLocalContractAllowListAdmin(address _contract) external onlyRole(ADMIN)  {
        localAllowedAddresses.add(_contract);
    }
    function removeLocalContractAllowListAdmin(address _contract) external onlyRole(ADMIN)  {
        localAllowedAddresses.remove(_contract);
    }
    function setCALAdmin(address _cal) external onlyRole(ADMIN) {
        CAL = IContractAllowListProxy(_cal);
    }
}