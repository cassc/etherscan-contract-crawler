// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../pool/IPool.sol";
import "../oracle/IOracleManager.sol";
import "../utils/Admin.sol";
import "./RouterStorage.sol";
import "../library/SafeMath.sol";
import "../library/SafeERC20.sol";

contract RouterImplementation is RouterStorage {

    using SafeMath for int256;

    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    IPool public immutable pool;

    IOracleManager public immutable oracleManager;

    event SetExecutor(address executor, bool isActive);

    event ErrorString(uint256 indexed index, string message);

    event LowLevelString(uint256 indexed index, bytes data);

    event CreateRequestTrade(
        uint256 indexed index,
        uint256 indexed timestamp,
        address indexed account,
        string symbolName,
        int256 tradeVolume,
        int256 priceLimit,
        uint256 executionFee
    );

    event ExecuteTrade(
        uint256 indexed index,
        uint256 indexed timestamp,
        address indexed account,
        string symbolName,
        int256 tradeVolume,
        int256 priceLimit,
        uint256 executionFee
    );

    event CancelTrade(
        uint256 indexed index,
        uint256 indexed timestamp,
        address indexed account,
        string symbolName,
        int256 tradeVolume,
        int256 priceLimit,
        uint256 executionFee
    );

    constructor(address _pool, address _oracleManager) {
        pool = IPool(_pool);
        oracleManager = IOracleManager(_oracleManager);
    }

    function setExecutor(address executor, bool isActive) external _onlyAdmin_ {
        isExecutor[executor] = isActive;
        emit SetExecutor(executor, isActive);
    }

    function setExecutionFee(uint256 newExecutionFee) external _onlyAdmin_ {
        executionFee = newExecutionFee;
    }

    function setMaxDelayTime(uint256 newMaxDelayTime) external _onlyAdmin_ {
        maxDelayTime = newMaxDelayTime;
    }

    function collectFees() external _onlyAdmin_ {
        if (unclaimedFee > 0) {
            unclaimedFee = 0;
            _transferOutETH(unclaimedFee, msg.sender);
        }
    }

    function requestTrade(
        string calldata symbolName,
        int256 tradeVolume,
        int256 priceLimit
    ) external payable {
        uint256 timestamp = block.timestamp;
        address account = msg.sender;
        uint256 executionFee_ = msg.value;
        require(
            executionFee_ >= executionFee,
            "router: insufficient executionFee"
        );

        tradeIndex++;
        requestTrades[tradeIndex] = RequestTrade(
            tradeIndex,
            timestamp,
            account,
            symbolName,
            tradeVolume,
            priceLimit,
            executionFee_
        );

        emit CreateRequestTrade(
            tradeIndex,
            timestamp,
            account,
            symbolName,
            tradeVolume,
            priceLimit,
            executionFee_
        );
    }

    function tryExecuteTrade(uint256 index, address executor) public {
        require(msg.sender == address(this), "router: should be internal call");

        RequestTrade memory request = requestTrades[index];

        require(
            request.timestamp + maxDelayTime >= block.timestamp,
            "router: request expired"
        );
        pool.trade(
            request.account,
            request.symbolName,
            request.tradeVolume,
            request.priceLimit
        );

        _transferOutETH(request.executionFee, executor);

        emit ExecuteTrade(
            request.index,
            request.timestamp,
            request.account,
            request.symbolName,
            request.tradeVolume,
            request.priceLimit,
            request.executionFee
        );
    }

    function tryCancelTrade(uint256 index) public {
        require(msg.sender == address(this), "router: should be internal call");

        RequestTrade memory request = requestTrades[index];

        unclaimedFee += request.executionFee;

        emit CancelTrade(
            request.index,
            request.timestamp,
            request.account,
            request.symbolName,
            request.tradeVolume,
            request.priceLimit,
            request.executionFee
        );
    }

    function executeTrade(
        uint256 endIndex,
        OracleSignature[] memory oracleSignatures
    ) external _reentryLock_ {
        uint256 startIndex = lastExecutedIndex + 1;
        if (endIndex > tradeIndex) endIndex = tradeIndex;
        require(startIndex <= endIndex, "router: invalid request index");

        address executor = msg.sender;
        require(isExecutor[executor], "router: executor only");

        RequestTrade memory request = requestTrades[endIndex];
        require(request.account != address(0), "router: request not exist");

        _updateOraclesWithTimestamp(request.timestamp, oracleSignatures);

        while (startIndex <= endIndex) {
            try this.tryExecuteTrade(startIndex, executor) {} catch Error(
                string memory reason
            ) {
                emit ErrorString(startIndex, reason);
                try this.tryCancelTrade(startIndex) {} catch {}
            } catch (bytes memory reason) {
                emit LowLevelString(startIndex, reason);
                try this.tryCancelTrade(startIndex) {} catch {}
            }

            delete requestTrades[startIndex];
            startIndex++;
        }
        lastExecutedIndex = endIndex;
    }

    function _updateOraclesWithTimestamp(
        uint256 requestTimestamp,
        OracleSignature[] memory oracleSignatures
    ) internal {
        for (uint256 i = 0; i < oracleSignatures.length; i++) {
            OracleSignature memory signature = oracleSignatures[i];
            if (
                oracleManager.timestamp(signature.oracleSymbolId) <
                requestTimestamp
            ) {
                require(
                    signature.timestamp == requestTimestamp,
                    "router: invalid oracle timestamp"
                );
                oracleManager.updateValue(
                    signature.oracleSymbolId,
                    signature.timestamp,
                    signature.value,
                    signature.v,
                    signature.r,
                    signature.s
                );
            }
        }
    }

    function _transferOutETH(uint256 amountOut, address receiver) internal {
        (bool success, ) = payable(receiver).call{value: amountOut}("");
        require(success, "router: send ETH fail");
    }
}