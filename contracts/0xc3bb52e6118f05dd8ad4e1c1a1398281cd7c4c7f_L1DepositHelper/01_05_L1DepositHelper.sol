// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {WETHInterface} from "../interfaces/WETHInterface.sol";
import {IL1ERC20Bridge} from "./interfaces/IL1ERC20Bridge.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title L1DepositHelper
/// @notice The L1 deposit helper for depositing tokens to L2 with a permit message
contract L1DepositHelper {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The L1 bridge contract
    IL1ERC20Bridge public immutable l1Bridge;

    /// @notice The WETH address
    address public immutable weth;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param _l1Bridge The L1 bridge
    /// @param _weth The WETH address
    constructor(address _l1Bridge, address _weth) {
        l1Bridge = IL1ERC20Bridge(_l1Bridge);
        weth = _weth;

        // Max approve WETH to the L1 bridge
        ERC20(_weth).safeApprove(_l1Bridge, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                             DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit an amount of the ERC20 to the senders balance on L2 using an EIP-2612 permit signature
    /// @param l1Token Address of the L1 ERC20 we are depositing
    /// @param l2Token Address of the L1 respective L2 ERC20
    /// @param amount Amount of the ERC20 to deposit
    /// @param l2Gas Gas limit required to complete the deposit on L2
    /// @param data Optional data to forward to L2
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with r and s
    /// @param r Must produce valid secp256k1 signature from the holder along with v and s
    /// @param s Must produce valid secp256k1 signature from the holder along with r and v
    function depositERC20WithPermit(
        address l1Token,
        address l2Token,
        uint256 amount,
        uint32 l2Gas,
        bytes calldata data,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Approve the tokens from the sender to this contract
        ERC20(l1Token).permit(msg.sender, address(this), amount, deadline, v, r, s);

        // Transfer the tokens from the sender to this contract
        ERC20(l1Token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve the tokens from this contract to the L1 bridge
        ERC20(l1Token).safeApprove(address(l1Bridge), amount);

        // Deposit the tokens to the senders balance on L2
        l1Bridge.depositERC20To(l1Token, l2Token, msg.sender, amount, l2Gas, data);
    }

    /// @notice Deposit an amount of ERC20 to a recipients balance on L2 using an EIP-2612 permit signature
    /// @param l1Token Address of the L1 ERC20 we are depositing
    /// @param l2Token Address of the L1 respective L2 ERC20
    /// @param to The recipient address on L2
    /// @param amount Amount of the ERC20 to deposit
    /// @param l2Gas Gas limit required to complete the deposit on L2
    /// @param data Optional data to forward to L2
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with r and s
    /// @param r Must produce valid secp256k1 signature from the holder along with v and s
    /// @param s Must produce valid secp256k1 signature from the holder along with r and v
    function depositERC20ToWithPermit(
        address l1Token,
        address l2Token,
        address to,
        uint256 amount,
        uint32 l2Gas,
        bytes calldata data,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Approve the tokens from the sender to this contract
        ERC20(l1Token).permit(msg.sender, address(this), amount, deadline, v, r, s);

        // Transfer the tokens from the sender to this contract
        ERC20(l1Token).safeTransferFrom(msg.sender, address(this), amount);

        // Approve the tokens from this contract to the L1 bridge
        ERC20(l1Token).safeApprove(address(l1Bridge), amount);

        // Deposit the tokens to the recipients balance on L2
        l1Bridge.depositERC20To(l1Token, l2Token, to, amount, l2Gas, data);
    }

    /// @notice Deposit an amount of ETH as WETH to the senders balance on L2
    /// @param l2Token Address of the L1 respective L2 ERC20
    /// @param l2Gas Gas limit required to complete the deposit on L2
    /// @param data Optional data to forward to L2
    function depositWETH(address l2Token, uint32 l2Gas, bytes calldata data) external payable {
        // Mint WETH
        WETHInterface(weth).deposit{value: msg.value}();

        // Deposit the tokens to the senders balance on L2
        l1Bridge.depositERC20To(weth, l2Token, msg.sender, msg.value, l2Gas, data);
    }

    /// @notice Deposit an amount of ETH as WETH to the senders balance on L2
    /// @param l2Token Address of the L1 respective L2 ERC20
    /// @param to The recipient address on L2
    /// @param l2Gas Gas limit required to complete the deposit on L2
    /// @param data Optional data to forward to L2
    function depositWETHTo(address l2Token, address to, uint32 l2Gas, bytes calldata data) external payable {
        // Mint WETH
        WETHInterface(weth).deposit{value: msg.value}();

        // Deposit the tokens to the recipients balance on L2
        l1Bridge.depositERC20To(weth, l2Token, to, msg.value, l2Gas, data);
    }
}