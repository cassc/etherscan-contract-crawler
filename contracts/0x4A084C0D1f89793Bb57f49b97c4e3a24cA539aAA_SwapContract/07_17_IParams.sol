// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

interface IParams {

    function minimumSwapAmountForWBTC() external view returns (uint256);
    function expirationTime() external view returns (uint256);
    function paraswapAddress() external view returns (address);
    function nodeRewardsRatio() external view returns (uint8);
    function depositFeesBPS() external view returns (uint8);
    function withdrawalFeeBPS() external view returns (uint8);
    function loopCount() external view returns (uint8);

    function setMinimumSwapAmountForWBTC(uint256 _minimumSwapAmountForWBTC) external;

    function setExpirationTime(uint256 _expirationTime) external;

    function setParaswapAddress(address _paraswapAddress) external;

    function setNodeRewardsRatio(uint8 _nodeRewardsRatio) external;

    function setWithdrawalFeeBPS(uint8 _withdrawalFeeBPS) external;

    function setDepositFeesBPS(uint8 _depositFeesBPS) external;

    function setLoopCount(uint8 _loopCount) external;
}