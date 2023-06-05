// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./interfaces/GnosisSafe.sol";
import "./interfaces/RainbowRouter.sol";

/// @title Rainbow fee collector
/// @author Ghilia Weldesselasie - <[email protected]>
/// @dev Gnosis safe module that calls access controlled withdrawal functions on the Rainbow Router
/// @dev sweeper bot calls collectX()
///      -> safe.execTransactionFromModule()
///      -> RainbowRouter.withdrawX() (called by our Gnosis safe instance)
contract FeeCollector {

    /// the gnosis safe we execute withdrawals from
    GnosisSafe public immutable safe;

    /// @dev we use a bot to call our collect functions, that bot is designed as our caller
    address public caller;

    /// @dev address that receives the funds
    address public receiver;

    /// @dev address of the swap aggregator aka RainbowRouter
    address public router;

    /// @dev we don't want our caller's balance to go below this amount
    uint256 public minExpectedBalance;

    /// @dev modifier that ensures only the safe contract is allowed to call a specific method
    modifier onlySafe() {
        require(msg.sender == address(safe), "FC: CALLER_NOT_SAFE");
        _;
    }

    /// @dev modifier that ensures only the whitelisted caller is allowed to call a specific method
    modifier onlyCaller() {
        require(msg.sender == address(caller), "FC: CALLER_NOT_ALLOWED");
        _;
    }

    /// @param _receiver Address that will receive the withdrawn fees
    /// @param _router Rainbow Router instance address
    /// @param _safe Gnosis safe instance address
    constructor(address _caller, address _receiver, address _router, address _safe, uint256 _threshold) {
        caller = _caller;
        receiver = _receiver;
        router = _router;
        safe = GnosisSafe(_safe);
        minExpectedBalance = _threshold;
    }

    /// @dev Function for collecting ETH fees from the Rainbow Router, calling the RainbowRouter.withdrawETH function
    /// @dev only the caller addres is allowed to call this function
    /// @param amount Amount in wei we want to withdraw from the Rainbow Router
    function collectETHFees(uint256 amount) external onlyCaller {

        // if our bot's ETH balance is below the threshold, we have to top it up again using funds from the safe
        uint256 initialCallerBalance = caller.balance;

        // amount we top up the bot with, 0 unless minExpectedBalance > initialCallerBalance
        uint256 topUpAmount = 0;

        if (minExpectedBalance > initialCallerBalance) {
            uint256 delta = minExpectedBalance - initialCallerBalance;
            topUpAmount = amount <= delta ? amount : delta;

            require(
                safe.execTransactionFromModule(
                    router,
                    0,
                    abi.encodeWithSelector(
                        RainbowRouter.withdrawEth.selector,
                        caller,
                        topUpAmount
                    ),
                    GnosisSafe.Operation.CALL
                ),
                "FC: EW_FAILED"
            );
        }

        // if topUpAmount == amount, then amount - topUpAmount == 0
        // a transfer of 0 tokens would just waste gas so let's avoid it
        uint256 amountLeftToWithdraw = amount - topUpAmount;
        if (amountLeftToWithdraw > 0) {
            require(
                safe.execTransactionFromModule(
                    router,
                    0,
                    abi.encodeWithSelector(
                        RainbowRouter.withdrawEth.selector,
                        receiver,
                        amountLeftToWithdraw
                    ),
                    GnosisSafe.Operation.CALL
                ),
                "FC: EW_FAILED"
            );
        }

    }

    /// @dev Function for collecting fees in any token from the Rainbow Router, calling the RainbowRouter.withdrawToken function
    /// @dev only the caller addres is allowed to call this function
    /// @param token Address of token contract we want to withdraw from the Rainbow Router
    /// @param amount Amount in wei we want to withdraw from the Rainbow Router
    function collectTokenFees(address token, uint256 amount) external onlyCaller {
        require(
            safe.execTransactionFromModule(
                router,
                0,
                abi.encodeWithSelector(
                    RainbowRouter.withdrawToken.selector,
                    token,
                    receiver,
                    amount
                ),
                GnosisSafe.Operation.CALL
            ),
            "FC: TW_FAILED"
        );
    }

    /// @dev Function for updating the address we want to be able to call the collect functions
    ///      This update can only be performed by the safe, via a safe transaction
    /// @param newCaller Address of the new receiver
    function updateCaller(address newCaller) external onlySafe {
        caller = newCaller;
    }

    /// @dev Function for updating the address we want to forward collected fees to
    ///      This update can only be performed by the safe, via a safe transaction
    /// @param newReceiver Address of the new receiver
    function updateReceiver(address newReceiver) external onlySafe {
        receiver = newReceiver;
    }

    /// @dev Function for updating the Rainbow Router address
    ///      This update can only be performed by the safe, via a safe transaction
    /// @param newRouter Address of the new Rainbow Router contract
    function updateRouter(address newRouter) external onlySafe {
        router = newRouter;
    }

    /// @dev Function for updating the minimum expected balance that we don't want to go below
    ///      This update can only be performed by the safe
    /// @param newMinBalance new minimum balance amount
    function updateMinBalance(uint256 newMinBalance) external onlySafe {
        minExpectedBalance = newMinBalance;
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        uint256 length = data.length;
        results = new bytes[](length);
        bytes calldata call;
        bytes memory result;
        for (uint256 i = 0; i < length;) {
            bool success;
            call = data[i];
            (success, results[i]) = address(this).delegatecall(data[i]);
            result = results[i];
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            unchecked { ++i; }
        }
    }
}