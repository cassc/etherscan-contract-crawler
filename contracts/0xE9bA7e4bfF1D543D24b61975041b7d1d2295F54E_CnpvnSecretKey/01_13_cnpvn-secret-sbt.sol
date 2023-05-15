// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CnpvnSecretKey is ERC1155, AccessControl, Ownable {
    using Strings for uint256;

    bytes32 public constant ADMIN = "ADMIN";
    string public baseURI;
    string public baseExtension;
    mapping(address => bool) public mintedAddresses;

    // Constructor
    constructor() ERC1155("") {
        _grantRole(ADMIN, msg.sender);
    }


    // Mint / AirDrop
    function airdrop(address[] calldata _addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (mintedAddresses[_addresses[i]] == false) {
                _mint(_addresses[i], 1, 1, "");
                mintedAddresses[_addresses[i]] = true;
            }
        }
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
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

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT.");
    }
    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(from == address(0) || to == address(0), "This token is SBT.");
        }
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }
}