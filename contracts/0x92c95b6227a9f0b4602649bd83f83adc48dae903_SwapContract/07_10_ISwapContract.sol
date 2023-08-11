// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IBurnableToken.sol";

interface ISwapContract {
    function BTCT_ADDR() external returns (address);

    function lpToken() external returns (IBurnableToken);

    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function collectSwapFeesForBTC(
        uint256 _incomingAmount,
        uint256 _minerFee,
        uint256 _rewardsAmount,
        address[] memory _spenders,
        uint256[] memory _swapAmounts
    ) external returns (bool);

    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bytes32 _txid
    ) external returns (bool);

    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external returns (bool);

    function recordUTXOSweepMinerFee(
        uint256 _minerFee,
        bytes32 _txid
    ) external returns (bool);

    function churn(
        address _newOwner,
        address[] memory _nodes,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold
    ) external returns (bool);

    function updateParams(
        address _sbBTCPool,
        address _buybackAddress,
        uint256 _withdrawalFeeBPS,
        uint256 _nodeRewardsRatio,
        uint256 _buybackRewardsRatio
    ) external returns (bool);

    function isTxUsed(bytes32 _txid) external view returns (bool);

    function getCurrentPriceLP() external view returns (uint256);

    function getFloatReserve(
        address _tokenA,
        address _tokenB
    ) external returns (uint256 reserveA, uint256 reserveB);

    function getActiveNodes() external view returns (address[] memory);

    function isNodeStake(address _user) external returns (bool);
}