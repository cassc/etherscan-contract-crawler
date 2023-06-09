// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

/// Local includes
import './BaseERC1155Burnable.sol';
import './BaseERC1155Mintable.sol';
import './BaseERC1155Pausable.sol';
import './Blacklist.sol';


contract BERC1155TokenBMP is ERC1155, BaseERC1155Burnable, BaseERC1155Mintable, BaseERC1155Pausable, Blacklist {

    bool internal _updatable;

    constructor(string memory uri_, bool updatable_)
            ERC1155(uri_)
            BaseERC1155Burnable()
            BaseERC1155Mintable()
            BaseERC1155Pausable() {

        _updatable = updatable_;
    }

    function setBaseURI(string memory baseURI_) onlyOwner public virtual {
        require(_updatable, 'Token is not updatable');
        _setURI(baseURI_);
    }

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(BaseERC1155Mintable, BaseERC1155Pausable, ERC1155) returns (bool) {

        return BaseERC1155Mintable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator,
                                  address from,
                                  address to,
                                  uint256[] memory ids,
                                  uint256[] memory amounts,
                                  bytes memory data)
        internal virtual override(ERC1155, ERC1155Pausable) {

        require(! isInBlacklist(operator), 'operator blacklisted');
        ERC1155Pausable._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Gets type of token
    function getType() view public virtual returns (
                bool burnable,
                bool mintable,
                bool pausable,
                bool updatable) {

        burnable = true;
        mintable = true;
        pausable = true;
        updatable = _updatable;
    }
}