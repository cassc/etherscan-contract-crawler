// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract MusebotAi is ERC1155,ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;
    uint96  private _royaltyFraction;

    // storage for token's uri
    mapping(uint256 => string) private _Uris;

    constructor(address owner,uint96 royaltyFraction) ERC1155("") {
        _owner = owner;
        _royaltyFraction = royaltyFraction;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155,ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function mintOne(address reciver, string memory tokenURIs)
        public
    {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(reciver, newTokenId, 1, "");
        _Uris[newTokenId] = tokenURIs;
        _setTokenRoyalty(newTokenId,_owner,_royaltyFraction);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(from,id,amount);
        _resetTokenRoyalty(id);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _Uris[id];
    }
}