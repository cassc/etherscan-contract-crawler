// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {OwnableUpgradeable} from "../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IWETH} from "../misc/interfaces/IWETH.sol";
import {IWETHGateway} from "./interfaces/IWETHGateway.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {Helpers} from "../protocol/libraries/helpers/Helpers.sol";
import {ReentrancyGuard} from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";

contract WETHGateway is ReentrancyGuard, IWETHGateway, OwnableUpgradeable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using SafeERC20 for IERC20;

    IWETH internal immutable WETH;

    address public immutable weth;
    address public immutable pool;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param _weth Address of the Wrapped Ether contract
     * @param _pool Address of the proxy pool of this contract
     **/
    constructor(address _weth, address _pool) {
        weth = _weth;
        pool = _pool;

        WETH = IWETH(weth);
    }

    function initialize() external initializer {
        __Ownable_init();

        WETH.approve(pool, type(uint256).max);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (xTokens)
     * is minted.
     * @param onBehalfOf address of the user who will receive the xTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function depositETH(address onBehalfOf, uint16 referralCode)
        external
        payable
        override
        nonReentrant
    {
        WETH.deposit{value: msg.value}();
        IPool(pool).supply(address(WETH), msg.value, onBehalfOf, referralCode);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param amount amount of pWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     */
    function withdrawETH(uint256 amount, address to)
        external
        override
        nonReentrant
    {
        IPToken pWETH = IPToken(
            IPool(pool).getReserveData(address(WETH)).xTokenAddress
        );
        uint256 userBalance = pWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        pWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        IPool(pool).withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
     * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
     * @param onBehalfOf the address for which msg.sender is repaying
     */
    function repayETH(uint256 amount, address onBehalfOf)
        external
        payable
        override
        nonReentrant
    {
        uint256 variableDebt = Helpers.getUserCurrentDebt(
            onBehalfOf,
            IPool(pool).getReserveData(address(WETH)).variableDebtTokenAddress
        );

        uint256 paybackAmount = variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }
        require(
            msg.value >= paybackAmount,
            "msg.value is less than repayment amount"
        );
        WETH.deposit{value: paybackAmount}();
        IPool(pool).repay(address(WETH), msg.value, onBehalfOf);

        // refund remaining dust eth
        if (msg.value > paybackAmount)
            _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    /**
     * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `Pool.borrow`.
     * @param amount the amount of ETH to borrow
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     */
    function borrowETH(uint256 amount, uint16 referralCode)
        external
        override
        nonReentrant
    {
        IPool(pool).borrow(address(WETH), amount, referralCode, msg.sender);
        WETH.withdraw(amount);
        _safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param amount amount of pWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     * @param deadline validity deadline of permit and so depositWithPermit signature
     * @param permitV V parameter of ERC712 permit sig
     * @param permitR R parameter of ERC712 permit sig
     * @param permitS S parameter of ERC712 permit sig
     */
    function withdrawETHWithPermit(
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external override nonReentrant {
        IPToken pWETH = IPToken(
            IPool(pool).getReserveData(address(WETH)).xTokenAddress
        );
        uint256 userBalance = pWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        // choosing to permit `amount`and not `amountToWithdraw`, easier for frontends, intregrators.
        pWETH.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );
        pWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        IPool(pool).withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit EmergencyTokenTransfer(token, to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount)
        external
        onlyOwner
    {
        _safeTransferETH(to, amount);
    }

    /**
     * @dev Get WETH address used by WETHGateway
     */
    function getWETHAddress() external view returns (address) {
        return address(WETH);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}