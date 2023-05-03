//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC4906.sol";
contract ERC4906 is ERC165, IERC4906 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return( interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId) );
    }
}