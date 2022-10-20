// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

interface IGammaFarm {
    function deposit(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
    function unstake() external;
    function withdraw() external returns (uint256);
    function unstakeAndWithdraw() external returns (uint256);
    function claim() external;

    // --- View methods ---
    function getAccountLUSDAvailable(address _account) external view returns (uint256);
    function getAccountLUSDStaked(address _account) external view returns (uint256);
    function getAccountMALRewards(address _account) external view returns (uint256);

    // --- Emergency methods ---
    function emergencyWithdraw(bytes memory _tradeData) external;
    function emergencyRecover() external;

    // --- Owner methods ---
    function startNewEpoch(bytes memory _tradeData) external;
    function depositAsFarm(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
    function setMALBurnPercentage(uint16 _pct) external;
    function setDefaultTradeData(bytes memory _tradeData) external;

    // --- Events ---
    event EpochStarted(uint256 epoch, uint256 timestamp, uint256 totalLUSD);
    event LUSDGainLossReported(uint256 epoch, uint256 LUSDProfitFactor, uint256 LUSDGain, uint256 LUSDLoss);
}