// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    struct ResultBalance {
        bool success;
        uint256 balance;
    }

    function tryStaticAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) public view returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            call = calls[i];
            (result.success, result.returnData) = call.target.staticcall(
                call.callData
            );
            if (requireSuccess)
                require(
                    result.success,
                    "Multicall3: tryStaticAggregate failed"
                );
            unchecked {
                ++i;
            }
        }
    }

    function tryStaticCall(
        bool requireSuccess,
        Call calldata call
    ) public view returns (Result memory returnData) {
        (returnData.success, returnData.returnData) = call.target.staticcall(
            call.callData
        );
        if (requireSuccess)
            require(returnData.success, "Multicall3: tryStaticAggregate failed");
    }

    function tryAggregateBalanceOf(bool requireSuccess, address[] calldata targets, address[] calldata users) public view returns (ResultBalance[] memory returnBalances) {
        require(targets.length == users.length, "Multicall3: targets length is not equal to users length");
        uint256 length = targets.length;
        returnBalances = new ResultBalance[](length);
        for (uint256 i = 0; i < length; ) {
            ResultBalance memory result = returnBalances[i];
            IERC20 token = IERC20(targets[i]);
            try token.balanceOf(users[i]) returns (uint256 balance) {
                result.balance = balance;
                result.success = true;
            } catch {
                result.success = false;
                if (requireSuccess)
                    require(result.success, "Multicall3: tryAggregateBalanceOf failed");
            } 
            unchecked {
                ++i;
            }
        }
    }

    function aggregateBalance(address[] calldata users) public view returns (uint256[] memory balances) {
        uint256 length = users.length;
        balances = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            balances[i] = users[i].balance;
            unchecked {
                ++i;
            }
        }
    }
}