// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/ISafeHook.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

abstract contract SafeHook is ERC165Upgradeable, ISafeHook {
     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // return
        //     interfaceId == type(ISafeHook).interfaceId ||
        //     super.supportsInterface(interfaceId);
        return interfaceId == type(ISafeHook).interfaceId;
    }

    function executeHook(address from, address to, uint256 tokenId) external virtual override returns(bool success);

}