// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../components/SafeOwnableUpgradeable.sol";

/**
 * @notice  Vault collects fees
 */
contract Vault is Initializable, SafeOwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event TransferETH(address indexed to, uint256 amount);
    event TransferERC20Token(address indexed token, address indexed to, uint256 amount);

    function initialize() external initializer {
        __SafeOwnable_init();
    }

    /**
     * @notice  A helper method to transfer Ether to somewhere.
     *
     * @param   recipient   The receiver of the sent asset.
     * @param   value       The amount of asset to send.
     */
    function transferETH(address recipient, uint256 value) external onlyOwner {
        require(recipient != address(0), "recipient is zero address");
        require(value != 0, "transfer value is zero");
        AddressUpgradeable.sendValue(payable(recipient), value);
        emit TransferETH(recipient, value);
    }

    /**
     * @notice  A helper method to transfer ERC20 to somewhere.
     *
     * @param   recipient   The receiver of the sent asset.
     * @param   tokens      The address of to be sent ERC20 token.
     * @param   amounts     The amount of asset to send.
     */
    function transferERC20(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner {
        require(recipient != address(0), "recipient is zero address");
        require(tokens.length == amounts.length, "length mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Upgradeable(tokens[i]).safeTransfer(recipient, amounts[i]);
            emit TransferERC20Token(tokens[i], recipient, amounts[i]);
        }
    }

    /**
     * @notice  A helper method to transfer ERC20 to somewhere.
     *
     * @param   recipient   The receiver of the sent asset.
     * @param   tokens      The address of to be sent ERC20 token.
     */
    function transferAllERC20(address recipient, address[] memory tokens) external onlyOwner {
        require(recipient != address(0), "recipient is zero address");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
            IERC20Upgradeable(tokens[i]).safeTransfer(recipient, amount);
            emit TransferERC20Token(tokens[i], recipient, amount);
        }
    }

    bytes32[50] private __gap;
}