pragma solidity 0.8.16;
import {IInterestRateCredit} from "../interfaces/IInterestRateCredit.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Denominations} from "chainlink/Denominations.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library LineLib {
    using SafeERC20 for IERC20;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet WETH

    error EthSentWithERC20();
    error TransferFailed();
    error SendingEthFailed();
    error RefundEthFailed();

    error BadToken();

    event RefundIssued(address indexed recipient, uint256 value);

    enum STATUS {
        UNINITIALIZED,
        ACTIVE,
        LIQUIDATABLE,
        REPAID,
        INSOLVENT
    }

    /**
     * @notice - Send ETH or ERC20 token from this contract to an external contract
     * @param token - address of token to send out. Denominations.ETH for raw ETH
     * @param receiver - address to send tokens to
     * @param amount - amount of tokens to send
     */
    function sendOutTokenOrETH(address token, address receiver, uint256 amount) external returns (bool) {
        if (token == address(0)) {
            revert TransferFailed();
        }

        // both branches revert if call failed
        if (token != Denominations.ETH) {
            // ERC20
            IERC20(token).safeTransfer(receiver, amount);
        } else {
            // ETH
            bool success = _safeTransferFunds(receiver, amount);
            if (!success) {
                revert SendingEthFailed();
            }
        }
        return true;
    }

    /**
     * @notice - Receive ETH or ERC20 token at this contract from an external contract
     * @dev    - If the sender overpays, the difference will be refunded to the sender
     * @dev    - If the sender is unable to receive the refund, it will be diverted to the calling contract
     * @param token - address of token to receive. Denominations.ETH for raw ETH
     * @param sender - address that is sendingtokens/ETH
     * @param amount - amount of tokens to send
     */
    function receiveTokenOrETH(address token, address sender, uint256 amount) external returns (bool) {
        if (token == address(0)) {
            revert TransferFailed();
        }
        if (token != Denominations.ETH) {
            // ERC20
            if (msg.value != 0) {
                revert EthSentWithERC20();
            }
            IERC20(token).safeTransferFrom(sender, address(this), amount);
        } else {
            // ETH
            if (msg.value < amount) {
                revert TransferFailed();
            }

            if (msg.value > amount) {
                uint256 refund = msg.value - amount;

                if (_safeTransferFunds(msg.sender, refund)) {
                    emit RefundIssued(msg.sender, refund);
                }
            }
        }
        return true;
    }

    /**
     * @notice - Helper function to get current balance of this contract for ERC20 or ETH
     * @param token - address of token to check. Denominations.ETH for raw ETH
     */
    function getBalance(address token) external view returns (uint256) {
        if (token == address(0)) return 0;
        return token != Denominations.ETH ? IERC20(token).balanceOf(address(this)) : address(this).balance;
    }

    /**
     * @notice  - Helper function to safely transfer Eth using native call
     * @dev     - Errors should be handled in the calling function
     * @param recipient - address of the recipient
     * @param value - value to be sent (in wei)
     */
    function _safeTransferFunds(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = payable(recipient).call{value: value}("");
    }
}