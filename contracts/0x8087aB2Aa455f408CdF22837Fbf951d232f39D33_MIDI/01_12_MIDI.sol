// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IMIDI.sol";

contract MIDI is ERC1155, ERC1155Supply, IMIDI {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155("") {}

    function mint(
        address to,
        uint256 amount,
        string memory tokenURI,
        bytes memory data
    ) external {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _setTokenUri(newItemId, tokenURI);
        _mint(to, newItemId, amount, data);
    }

    function currentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        _burnBatch(from, ids, amounts);
    }

    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

    //=================================== OVERRIDES ==============================================

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_tokenURIs[tokenId]);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}