//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;
import "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";

interface IGorjsDreamVortexCollection is IERC721Upgradeable{
    function burn(uint256[] calldata tokenIds) external;
}