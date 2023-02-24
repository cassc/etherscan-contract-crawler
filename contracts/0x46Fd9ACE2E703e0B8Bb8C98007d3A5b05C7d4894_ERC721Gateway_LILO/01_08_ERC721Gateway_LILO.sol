// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "../ERC721Gateway.sol";
import "../interfaces/IERC721.sol";

contract ERC721Gateway_LILO is ERC721Gateway {

    constructor (address anyCallProxy, uint256 flag, address token) ERC721Gateway(anyCallProxy, flag, token) {}

    function _swapout(uint256 tokenId) internal override virtual returns (bool, bytes memory) {
        try IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId) {
            return (true, "");
        } catch {
            return (false, "");
        }
    }

    function _swapin(uint256 tokenId, address receiver, bytes memory extraMsg) internal override returns (bool) {
        try IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId) {
            return true;
        } catch {
            return false;
        }
    }
    
}