// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SelectiveCollectionToken is ERC721 {
    uint256 private _limit;
    address private _creator;
    uint256 private _quantity = 1;
    uint256 private _royalty;

    mapping(uint256 => string) public _token_uris;

    constructor(string memory name_, string memory symbol_, address creator_, uint256 limit_, uint256 royalty_) ERC721(name_, symbol_) {
        _limit = limit_;
        _creator = creator_;
        _royalty = royalty_;
    }

    function batchMint(string[] memory token_uris) public {
        require(_limit >= _quantity + token_uris.length, "Limits tokens exceeded");
        require(msg.sender == _creator, "You are not an creator");
        for (uint256 i = 0; i < token_uris.length; i++) {
            _mint(msg.sender, _quantity);
            _token_uris[_quantity] = token_uris[i];
            _quantity++;
        }
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "Token does not exists");
        return _token_uris[token_id];
    }

    function getRoyalty(uint256 token_id) public view returns (uint256) {
        require(_exists(token_id), "Token does not exists");
        return _royalty;
    }

    function getCreator(uint256 token_id) public view returns (address) {
        require(_exists(token_id), "Token does not exists");
        return _creator;
    }
}