// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface ICentaurSettlement {
    // event SettlementAdded(address indexed sender, address indexed _fromToken, uint _amountIn, address indexed _toToken, uint _amountOut);
    // event SettlementRemoved(address indexed sender, address indexed _fromToken, address indexed _toToken);
    struct Settlement {
        address fPool;
        uint amountIn;
        uint fPoolBaseTokenTargetAmount;
        uint fPoolBaseTokenBalance;
        uint fPoolLiquidityParameter;
        address tPool;
        uint maxAmountOut;
        uint tPoolBaseTokenTargetAmount;
        uint tPoolBaseTokenBalance;
        uint tPoolLiquidityParameter;
        address receiver;
        uint settlementTimestamp;
    }

    function factory() external pure returns (address);
    function settlementDuration() external pure returns (uint);

    function addSettlement(
        address _sender,
        Settlement memory _pendingSettlement
    ) external;
    function removeSettlement(address _sender, address _fPool, address _tPool) external;
    
    function getPendingSettlement(address _sender, address _pool) external view returns (Settlement memory);
    function hasPendingSettlement(address _sender, address _pool) external view returns (bool);

    function setSettlementDuration(uint) external;
}