// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {IERC721Renamable} from './IERC721Renamable.sol';

abstract contract ERC721Renamable is ERC721, Ownable, IERC721Renamable {
    string private _changeableName;

    constructor(string memory name_) {
        _changeableName = name_;
    }

    function setName(string calldata newName) external onlyOwner {
        _changeableName = newName;
    }

    /**
     * @dev See {ERC721-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _changeableName;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Renamable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}