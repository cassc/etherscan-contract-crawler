//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILSR {
    // LSRMinter
    function msd() external view returns (address);

    function msdController() external view returns (address);

    function totalMint() external view returns (uint256);

    function mintCap() external view returns (uint256);

    function msdQuota() external view returns (uint256);

    // LSRCalculator

    function _setTaxIn(uint256 _fee) external;

    function _setTaxOut(uint256 _fee) external;

    function getAmountToBuy(uint256 _amountIn) external view returns (uint256);

    function getAmountToSell(uint256 _amountIn) external view returns (uint256);

    function mpr() external view returns (address);

    function msdDecimalScaler() external view returns (uint256);

    function mprDecimalScaler() external view returns (uint256);

    function taxIn() external view returns (uint256);

    function taxOut() external view returns (uint256);

    // LSRModelBase

    function _open() external;

    function _close() external;

    function _switchStrategy(address _strategy) external;

    function _withdrawReserves(address _recipient) external returns (uint256);

    function _claimRewards(address _treasury) external;

    function buyMsd(uint256 _amountIn) external;

    function buyMsd(address _recipient, uint256 _amountIn) external;

    function sellMsd(uint256 _amountIn) external;

    function sellMsd(address _recipient, uint256 _amountIn) external;

    function strategy() external view returns (address);

    function estimateReserves() external returns (uint256);

    function totalDeposits() external returns (uint256);

    function liquidity() external view returns (uint256);

    function mprQuota() external view returns (uint256);

    function mprOutstanding() external view returns (uint256 _availableQuota);

    function rewardsEarned() external returns (uint256);
}