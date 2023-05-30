// SPDX-License-Identifier: MIT
/*
Sarugami factory smart contract:
An Sarugami factory contract based on Chiru Lab's ERC-721A.

Legal Overview:

*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Sarugami is ERC721A, AccessControl, Ownable {
    using Strings for uint256;

    string public uri;
    uint256 public minted = 0;
    uint256 public maxSupply;

    constructor(
        string memory _name, string memory _symbol, string memory _uri, uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        uri = _uri;
        maxSupply = _maxSupply;
    }

    function mint(address _account, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        require(minted + amount <= maxSupply, "No more Sarugami available to mint");
        minted = minted + amount;
        _safeMint(_account, amount);
        return minted;
    }

    function setBaseURI(string memory _newUri) external onlyOwner {
        uri = _newUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function changeMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721A)
    returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

}