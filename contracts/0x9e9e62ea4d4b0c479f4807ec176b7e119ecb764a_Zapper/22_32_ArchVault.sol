// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ERC4626} from "../libs/ERC4626.sol";

/*is ERC4626 */ interface ArchVault {
    event HardWorkDone(
        uint256 crvAmount,
        uint256 cvxAmount,
        uint256 ethAmountBeforeFee,
        uint256 ethAmountAfterFee,
        uint256 convexLPTokens
    );
    event PullOutDone(
        bool pullAll,
        uint256 convexLPTokens,
        uint256 ethAmount,
        uint256 minEthAmount
    );

    event AdjustedIn(uint256 _outputUnderlying, uint256 _amountOfEthAdjusted);

    function initialize(
        address _curvePool,
        address _convexBoosterPool,
        address _convexRewardPool,
        uint256 _convexPoolId
    ) external;

    function depositWithoutShares(uint256 _initialAmount) external;

    function depositAndStake(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function redeemAndUnstake(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function doHardWork(
        uint256 _minETHAmount,
        uint256 _minCurveLPAmount
    ) external;

    function convertToParameterAssets(
        uint256 amountOfShares,
        uint256 amountOfAssets
    ) external view returns (uint256);

    function isPoolHealthy() external view returns (bool, bool);

    function adjustOut(uint256 _minOutputEthAmount) external;

    function adjustIn(uint256 _minAmountOfLP) external;

    function previewAdjustOut()
        external
        view
        returns (uint256 _outputEthAmount);

    function previewAdjustIn()
        external
        view
        returns (uint256 _outputUnderlying, uint256 _amountOfEthToAdjust);

    function previewDoHardWork()
        external
        view
        returns (uint256 _minOutputEth, uint256 _minOutputLP);

    // constant setters

    function setMinEthBalanceProportion(
        uint256 _minBalanceProportion /*add access control */
    ) external;

    function setMaxEthOwnershipProportion(
        uint256 _maxOwnershipProportion /*add access control */
    ) external;

    function setMinIdleEthForAction(
        uint256 _minIdleEthForAction /*add access control */
    ) external;

    function setMinEthAmountInPool(
        uint256 _minAmountInPool /*add access control */
    ) external;

    function setPullOutMinEthAmountModifier(
        uint256 _pullOutMinModifier /*add access control */
    ) external;

    function setAdjustOutEthProportion(
        uint256 _adjustOutProportion /*add access control */
    ) external;

    function setAdjustInEthProportion(
        uint256 _adjustInProportion /*add access control */
    ) external;

    function setMinAmountOfEthToAdjustIn(
        uint256 _minAmountOfEthToAdjustIn /*add access control */
    ) external;

    function setMinCoolDownForAdjustOut(
        uint256 _minCoolDownForAdjustOut /*add access control */
    ) external;

    function setTreasuryAddress(
        address _treasuryAddress /*add access control */
    ) external;

    function setMinEthAmountForDoHardWork(
        uint256 _minEthAmountForDoHardWork /*add access control */
    ) external;

    function setFeePercentage(uint256 _newFeePerc) external;

    function setTreasury(address _newTreasury) external;

    function setZapperAddress(
        address _strategyZapper /*add access control */
    ) external;

    // make contract oayable

    receive() external payable;
}