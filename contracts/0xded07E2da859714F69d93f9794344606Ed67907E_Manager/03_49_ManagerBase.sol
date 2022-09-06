// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../interfaces/common/IWETH.sol";
import "../../interfaces/hub/IMuffinHub.sol";
import "../../interfaces/manager/IManagerBase.sol";
import "../../libraries/utils/SafeTransferLib.sol";

abstract contract ManagerBase is IManagerBase {
    address public immutable WETH9;
    address public immutable hub;

    constructor(address _hub, address _WETH9) {
        hub = _hub;
        WETH9 = _WETH9;
    }

    modifier fromHub() {
        require(msg.sender == hub);
        _;
    }

    /// @dev Transform an user address into account id
    function getAccRefId(address user) internal pure returns (uint256 accRefId) {
        accRefId = uint160(user);
        require(accRefId != 0, "ZERO_ACC_REF_ID");
    }

    function payHub(
        address token,
        address payer,
        uint256 amount
    ) internal {
        if (token == WETH9 && address(this).balance >= amount) {
            // pay with WETH9
            IWETH(WETH9).deposit{value: amount}(); // wrap only what is needed to pay
            IWETH(WETH9).transfer(hub, amount);
        } else {
            // pull payment
            SafeTransferLib.safeTransferFrom(token, payer, hub, amount);
        }
    }

    /*===============================================================
     *                          ACCOUNTS
     *==============================================================*/

    /// @dev Called by the hub contract
    function muffinDepositCallback(
        address token,
        uint256 amount,
        bytes calldata data
    ) external fromHub {
        if (amount > 0) payHub(token, abi.decode(data, (address)), amount);
    }

    /// @notice             Deposit tokens into hub's internal account
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function deposit(
        address recipient,
        address token,
        uint256 amount
    ) public payable {
        IMuffinHub(hub).deposit(address(this), getAccRefId(recipient), token, amount, abi.encode(msg.sender));
    }

    /// @notice             Withdraw tokens from hub's internal account to recipient
    /// @param recipient    Recipient of the withdrawn token
    /// @param token        Token address
    /// @param amount       Amount to withdraw
    function withdraw(
        address recipient,
        address token,
        uint256 amount
    ) public payable {
        IMuffinHub(hub).withdraw(recipient, getAccRefId(msg.sender), token, amount);
    }

    /// @notice             Deposit tokens into hub's internal account managed by other address
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function depositToExternal(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount
    ) external payable {
        IMuffinHub(hub).deposit(recipient, recipientAccRefId, token, amount, abi.encode(msg.sender));
    }

    /*===============================================================
     *                  ETH TRANSFER (FOR MULTICALL)
     *==============================================================*/

    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave WETH inside this
    /// contract accross transactions.
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable {
        uint256 balanceWETH = IWETH(WETH9).balanceOf(address(this));
        require(balanceWETH >= amountMinimum, "Insufficient WETH");

        if (balanceWETH > 0) {
            IWETH(WETH9).withdraw(balanceWETH);
            SafeTransferLib.safeTransferETH(recipient, balanceWETH);
        }
    }

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave ETH inside this
    /// contract accross transactions.
    function refundETH() external payable {
        if (address(this).balance > 0) SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    receive() external payable {
        require(msg.sender == WETH9);
    }
}