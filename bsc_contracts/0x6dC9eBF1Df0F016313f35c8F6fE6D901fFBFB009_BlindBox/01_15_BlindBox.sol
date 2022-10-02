// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlindBox is Ownable, AccessControl, Pausable, ERC1155, ERC1155Burnable {
    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint32 public constant MAX_CARDS = 500000;
    uint256 public totalMinted = 0;

    string private _baseURI = "https://nftstorage.link/ipfs/bafybeiepszrrmkf7rik72m3epjro27wqhcnhvh2dy26tvatoe7i5goypce/";

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
        totalMinted += amount;
        require(totalMinted <= MAX_CARDS,"Maximum supply exceeded");
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        for(uint256 i = 0; i < amounts.length; i++) {
            totalMinted += amounts[i];
            require(totalMinted <= MAX_CARDS,"Maximum supply exceeded");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}