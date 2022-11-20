// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../common/Storage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBettingAdmin {
    function getPool(uint256 poolId_) external view returns(Storage.Pool memory);
    function getPoolTeam(uint256 poolId_, uint256 teamId_) external view returns(Storage.Team memory);
    function getPoolTeams(uint256 poolId_) external view returns(Storage.Team[] memory);
    function erc20Contract() external view returns(IERC20Upgradeable);
    function signer() external view returns(address);
    function vaultContract() external view returns(address);
    function getTotalPools() external view returns(uint256);
    function betPlaced(address player_, uint256 poolId_, uint256 teamId_, uint256 amount_, uint256 commission_) external returns(bool);
    function payoutClaimed(address player_, uint256 poolId_, uint256 amount_) external returns (bool);
    function commissionClaimed(address player_, uint256 poolId_, uint256 amount_) external returns (bool);
    function refundClaimed(address player_, uint256 poolId_, uint256 amount_) external returns (bool);
}