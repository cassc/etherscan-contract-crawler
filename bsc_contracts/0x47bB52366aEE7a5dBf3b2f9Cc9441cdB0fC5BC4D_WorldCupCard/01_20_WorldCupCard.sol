// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC1155Snapshot.sol";

contract WorldCupCard is Ownable, AccessControl, Pausable, ERC1155, ERC1155Snapshot,ERC1155Burnable {
    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    string private _baseURI = "https://nftstorage.link/ipfs/bafybeiacaiehtaepyv7tp6rpno6ffykxj6qztxo7cvw46e2zncfktu2qmu/";

    event BaseURIUpdated(string previousURI,string newURI);

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        grantRole(URI_SETTER_ROLE, _msgSender());
        grantRole(PAUSER_ROLE, _msgSender());
        grantRole(MINTER_ROLE, _msgSender());
    }

    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function uri(uint256 id) public view virtual override(ERC1155) returns (string memory) {
        string memory baseURI_ = baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, id.toString(),".json")) : "";
    }

    function setBaseURI(string memory baseURI_) public onlyRole(URI_SETTER_ROLE){
        string memory previous = _baseURI;
        _baseURI = baseURI_;
        emit BaseURIUpdated(previous,baseURI_);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused override(ERC1155,ERC1155Snapshot) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function snapshot() external onlyRole(SNAPSHOT_ROLE) returns (uint256) {
        return super._snapshot();
    }
}