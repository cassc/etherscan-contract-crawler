// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721StakingLocker is IERC721Upgradeable {
    function lock(address, uint256[] memory) external;

    function unlock(address, uint256[] memory) external;

    function isLocked(uint256) external view returns (bool);
}