//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract GearNFT is ERC1155Supply, Ownable {
    // Max supply per token ID
    mapping(uint256 => uint256) public maxSupply;
    // Addresses allowed to mint
    mapping(address => bool) public minters;
    // Custom URI per token ID
    mapping(uint256 => string) public tokenURIs;

    constructor() ERC1155("") {}

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    function updateToken(uint256 _id, string calldata _uri, uint256 supply) public onlyOwner {
        maxSupply[_id] = supply;
        tokenURIs[_id] = _uri;
        emit URI(_uri, _id);
    }

    function createTokens(uint256[] calldata ids, string[] calldata uris, uint256[] calldata supply) external onlyOwner {
        require(ids.length == uris.length, "Invalid ID/URI length");
        require(ids.length == supply.length, "Invalid ID/supply length");
        for (uint256 i = 0; i < ids.length; i++) {
            updateToken(ids[i], uris[i], supply[i]);
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external {
        require(minters[msg.sender], "Caller is not a minter");
        require(bytes(tokenURIs[id]).length != 0, "Token not created");
        require(totalSupply(id) + amount <= maxSupply[id], "Token supply exceeded");
        _mint(to, id, amount, "");
    }

    function uri(uint256 id) public view override returns (string memory tokenURI) {
        return tokenURIs[id];
    }
}