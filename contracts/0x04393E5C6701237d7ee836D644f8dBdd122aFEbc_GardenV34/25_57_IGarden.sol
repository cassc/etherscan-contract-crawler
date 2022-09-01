// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';

import {IBabController} from './IBabController.sol';

/**
 * @title IEmergencyGarden
 */
interface IEmergencyGarden {
    /* ============ Write ============ */

    function wrap() external;
}

/**
 * @title IStrategyGarden
 */
interface IStrategyGarden {
    /* ============ Write ============ */

    function finalizeStrategy(
        uint256 _profits,
        int256 _returns,
        uint256 _burningAmount
    ) external;

    function allocateCapitalToStrategy(uint256 _capital) external;

    function expireCandidateStrategy() external;

    function addStrategy(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _stratParams,
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes calldata _opEncodedDatas
    ) external;

    function payKeeper(address payable _keeper, uint256 _fee) external;

    function updateStrategyRewards(
        address _strategy,
        uint256 _newTotalBABLAmount,
        uint256 _newCapitalReturned,
        uint256 _diffRewardsToSetAside,
        bool _addOrSubstractSetAside
    ) external;
}

/**
 * @title IAdminGarden
 */
interface IAdminGarden {
    /* ============ Write ============ */
    function initialize(
        address _reserveAsset,
        IBabController _controller,
        address _creator,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards
    ) external payable;

    function makeGardenPublic() external;

    function transferCreatorRights(address _newCreator, uint8 _index) external;

    function addExtraCreators(address[4] memory _newCreators) external;

    function setPublicRights(bool _publicStrategist, bool _publicStewards) external;

    function delegateVotes(address _token, address _address) external;

    function updateCreators(address _newCreator, address[4] memory _newCreators) external;

    function updateGardenParams(uint256[13] memory _newParams) external;

    function verifyGarden(uint256 _verifiedCategory) external;

    function resetHardlock(uint256 _hardlockStartsAt) external;
}

/**
 * @title IGarden
 */
interface ICoreGarden {
    /* ============ Constructor ============ */

    /* ============ View ============ */

    function privateGarden() external view returns (bool);

    function publicStrategists() external view returns (bool);

    function publicStewards() external view returns (bool);

    function controller() external view returns (IBabController);

    function creator() external view returns (address);

    function isGardenStrategy(address _strategy) external view returns (bool);

    function getContributor(address _contributor)
        external
        view
        returns (
            uint256 lastDepositAt,
            uint256 initialDepositAt,
            uint256 claimedAt,
            uint256 claimedBABL,
            uint256 claimedRewards,
            uint256 withdrawnSince,
            uint256 totalDeposits,
            uint256 nonce,
            uint256 lockedBalance
        );

    function reserveAsset() external view returns (address);

    function verifiedCategory() external view returns (uint256);

    function canMintNftAfter() external view returns (uint256);

    function customIntegrationsEnabled() external view returns (bool);

    function hardlockStartsAt() external view returns (uint256);

    function totalContributors() external view returns (uint256);

    function gardenInitializedAt() external view returns (uint256);

    function minContribution() external view returns (uint256);

    function depositHardlock() external view returns (uint256);

    function minLiquidityAsset() external view returns (uint256);

    function minStrategyDuration() external view returns (uint256);

    function maxStrategyDuration() external view returns (uint256);

    function reserveAssetRewardsSetAside() external view returns (uint256);

    function absoluteReturns() external view returns (int256);

    function totalStake() external view returns (uint256);

    function minVotesQuorum() external view returns (uint256);

    function minVoters() external view returns (uint256);

    function maxDepositLimit() external view returns (uint256);

    function strategyCooldownPeriod() external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function extraCreators(uint256 index) external view returns (address);

    function getFinalizedStrategies() external view returns (address[] memory);

    function getVotingPower(address _contributor) external view returns (uint256);

    function strategyMapping(address _strategy) external view returns (bool);

    function keeperDebt() external view returns (uint256);

    function totalKeeperFees() external view returns (uint256);

    function lastPricePerShare() external view returns (uint256);

    function lastPricePerShareTS() external view returns (uint256);

    function pricePerShareDecayRate() external view returns (uint256);

    function pricePerShareDelta() external view returns (uint256);

    function userLock(address _contributor) external view returns (uint256);

    /* ============ Write ============ */

    function deposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _referrer
    ) external payable;

    function depositBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        address _referrer,
        bytes memory signature
    ) external;

    function withdraw(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy
    ) external;

    function withdrawBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        bool _withPenalty,
        address _unwindStrategy,
        uint256 _pricePerShare,
        uint256 _strategyNAV,
        uint256 _fee,
        address _signer,
        bytes memory signature
    ) external;

    function claimReturns(address[] calldata _finalizedStrategies) external;

    function claimAndStakeReturns(uint256 _minAmountOut, address[] calldata _finalizedStrategies) external;

    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address signer,
        bytes memory signature
    ) external;

    function claimAndStakeRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external;

    function stakeBySig(
        uint256 _amountIn,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        address _signer,
        bytes memory _signature
    ) external;

    function claimNFT() external;

    function updateUserLock(
        address _contributor,
        uint256 _userLock,
        uint256 _balanceBefore
    ) external;
}

interface IERC20Metadata {
    function name() external view returns (string memory);
}

interface IGarden is ICoreGarden, IAdminGarden, IStrategyGarden, IEmergencyGarden, IERC20, IERC20Metadata, IERC1271 {
    struct Contributor {
        uint256 lastDepositAt;
        uint256 initialDepositAt;
        uint256 claimedAt;
        uint256 claimedBABL;
        uint256 claimedRewards;
        uint256 withdrawnSince;
        uint256 totalDeposits;
        uint256 nonce;
        uint256 lockedBalance;
    }
}