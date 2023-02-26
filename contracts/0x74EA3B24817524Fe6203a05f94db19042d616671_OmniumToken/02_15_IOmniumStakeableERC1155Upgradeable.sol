// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

interface IOmniumStakeableERC1155Upgradeable {
    function setTokenStakeCoeficient( uint256 _tokenId, uint256 _StakeCoeficient) external;
    function getTokenStakeCoeficient( uint256 _tokenId) external returns (uint256); 
}