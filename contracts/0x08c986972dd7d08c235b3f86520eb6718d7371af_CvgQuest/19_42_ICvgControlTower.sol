// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IERC20Mintable.sol";
import "./ICvg.sol";
import "./IBondDepository.sol";
import "./IBondCalculator.sol";
import "./IBondStruct.sol";
import "./ITAssetStruct.sol";
import "./ICvgOracle.sol";
import "./IVotingPowerEscrow.sol";
import "./ICvgRewards.sol";
import "./ILockingPositionManager.sol";
import "./ILockingPositionDelegate.sol";
import "./IGaugeController.sol";
import "./ITokeManager.sol";
import "./ITokeRewards.sol";
import "./ICvgTokeStaking.sol";
import "./ITokeStaker.sol";
import "./ITAssetStaking.sol";
import "./IYsDistributor.sol";
import "./ITAssetBlackHole.sol";
import "./IBondPositionManager.sol";
import "./ISwapperFactory.sol";
import "./IStakingPositionManager.sol";
import "./IStakingViewer.sol";
import "./IStakingLogo.sol";
import "./IBondLogo.sol";
import "./ILockingLogo.sol";
import "./ILockingPositionService.sol";

interface ICvgControlTower {
    function cvgToken() external view returns (ICvg);

    function cvgOracle() external view returns (ICvgOracle);

    function bondCalculator() external view returns (IBondCalculator);

    function gaugeController() external view returns (IGaugeController);

    function cvgCycle() external view returns (uint128);

    function votingPowerEscrow() external view returns (IVotingPowerEscrow);

    function allBaseBonds(uint256 index) external view returns (address);

    function allBaseAggregators(uint256 index) external view returns (address);

    function allBaseTAssetStakings(uint256 index) external view returns (address);

    function treasuryDao() external view returns (address);

    function treasuryStaking() external view returns (address);

    function treasuryBonds() external view returns (address);

    function insertNewBond(address _newClone, uint256 _version) external;

    function insertNewTAssetStaking(address _newClone, uint256 _version) external;

    function insertNewAggregator(address _newClone, uint256 _version) external;

    function cvgRewards() external view returns (ICvgRewards);

    function tokeStaker() external view returns (ITokeStaker);

    function cvgTokeStaking() external view returns (ICvgTokeStaking);

    function lockingPositionManager() external view returns (ILockingPositionManager);

    function lockingPositionService() external view returns (ILockingPositionService);

    function lockingPositionDelegate() external view returns (ILockingPositionDelegate);

    function tokeManager() external view returns (ITokeManager);

    function tokeRewards() external view returns (ITokeRewards);

    function toke() external view returns (IERC20Metadata);

    function cvgToke() external view returns (IERC20Mintable);

    function poolCvgToke() external view returns (address);

    function getTAssetStakingContract(uint256 index) external view returns (address);

    function isTAssetStaking(address contractAddress) external view returns (bool);

    function isStakingContract(address contractAddress) external view returns (bool);

    function getTAssetStakingLength() external view returns (uint256);

    function ysDistributor() external view returns (IYsDistributor);

    function tAssetBlackHole() external view returns (ITAssetBlackHole);

    function isBond(address account) external view returns (bool);

    function bondPositionManager() external view returns (IBondPositionManager);

    function stakingPositionManager() external view returns (IStakingPositionManager);

    function stakingLogo() external view returns (IStakingLogo);

    function bondLogo() external view returns (IBondLogo);

    function lockingLogo() external view returns (ILockingLogo);

    function cvgUtilities() external view returns (address);

    function swapperFactory() external view returns (ISwapperFactory);
}