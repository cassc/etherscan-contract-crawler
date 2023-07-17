// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev This is an alternative implementation to OpenZeppelin's ERC721Enumerable.
 * HumbleERC721Enumerable is focussing on reducing the gas costs by reducing efforts
 * in writing methods.
 * @author nfttank.eth
 */
abstract contract HumbleERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => uint256[]) internal _owners;
    uint256 private _totalSupply;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _totalSupply, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _owners[owner][index];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        
        bool isMint = from == address(0);
        bool isBurn = to == address(0) || to == 0x000000000000000000000000000000000000dEaD;
        
        // transfer + burn
        if (!isMint) {
            uint256[] storage tokenIds = _owners[from];

            for (uint16 i = 0; i < tokenIds.length; i++) {
                if (tokenIds[i] == tokenId) {
                    tokenIds[i] = tokenIds[tokenIds.length-1]; // Move the last element to the deleted spot. Remove the last element.
                    tokenIds.pop();
                    break;
                }
            }
        }

        // mint + tranfer
        if (!isBurn) {
            _owners[to].push(tokenId);
        }

        if (isMint) {
            _totalSupply++;
        }
        else if (isBurn) {
            _totalSupply--;
        }

    }
}