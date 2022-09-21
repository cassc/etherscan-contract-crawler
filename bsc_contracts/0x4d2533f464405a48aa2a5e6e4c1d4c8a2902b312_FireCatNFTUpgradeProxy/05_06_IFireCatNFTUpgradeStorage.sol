// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

/**
* @notice IFireCatNFTUpgradeStorage
*/
interface IFireCatNFTUpgradeStorage {
    function levelArray() external view returns (uint256[] memory);
    function stakeNumArray() external view returns (uint256[] memory);
    function payNumArray() external view returns (uint256[] memory);
    function levelUpPayToken() external view returns (address);
    function levelUpRequireStake(uint256 tokenLevel) external view returns (uint256);
    function levelUpRequirePay(uint256 tokenLevel) external view returns (uint256);
    function isStakeQualified(uint256 tokenId_, uint256 tokenLevel_) external returns (bool);

}