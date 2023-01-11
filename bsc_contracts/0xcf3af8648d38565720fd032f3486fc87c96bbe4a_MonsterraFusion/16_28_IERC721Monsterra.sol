// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC721Monsterra is IERC721Upgradeable{

    function burnBatch(uint256[] calldata _listTokenID) external;
    
}