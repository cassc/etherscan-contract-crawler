// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT1155 is Ownable, ERC1155, ERC1155Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) private _totalSupply;

    string public name;
    string public symbol;

    string private _baseUri;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri
    ) ERC1155("") {
        name = name_;
        symbol = symbol_;
        setBaseUri(baseUri);
    }

    function setBaseUri(string memory newuri) public virtual {
        _baseUri = newuri;
    }

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function mint(
        address owner,
        uint256 amountMint,
        uint256 amount
    ) public onlyOwner {
        for (uint256 i = 0; i < amountMint; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _mint(owner, tokenId, amount, "");
        }
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            exists(tokenId),
            "ERC1155Metadata: URI query for nonexistent token"
        );
        return
            bytes(_baseUri).length > 0
                ? string(abi.encodePacked(_baseUri, tokenId.toString()))
                : "";
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }
}