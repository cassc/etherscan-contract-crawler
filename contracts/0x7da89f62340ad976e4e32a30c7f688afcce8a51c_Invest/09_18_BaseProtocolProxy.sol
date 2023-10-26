// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH9} from "../interfaces/IWETH9.sol";
import {Multicall} from "./Multicall.sol";
import {Permit} from "./Permit.sol";

/**
 * @title Handles payment and approve functions
 * @author Pino development team
 */
contract BaseProtocolProxy is Permit, Multicall, Ownable2Step {
    using SafeERC20 for IERC20;

    IWETH9 public immutable weth;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Thrown when the ETH transfer call is failed
     * @param _caller Address of the caller of the transaction
     * @param _recipient Address of the recipient receiving ETH
     */
    error FailedToSendEther(address _caller, address _recipient);

    /**
     * @notice Thrown when the amount of ETH to transfer is 0
     */
    error InvalidAmountToTransfer();

    /**
     * @notice Proxy contract constructor, sets permit2 and weth addresses
     * @param _permit2 Permit2 contract address
     * @param _weth WETH9 contract address
     */
    constructor(address _permit2, address _weth) payable Permit(_permit2) {
        weth = IWETH9(_weth);
    }

    receive() external payable {}

    /**
     * @notice Withdraws ETH and transfers to the recipient
     * @param _recipient Address of the destination receiving the fees
     */
    function withdrawAdmin(address _recipient) external onlyOwner {
        _sendETH(_recipient, address(this).balance);
    }

    /**
     * @notice Approves an ERC20 token to multiple spenders
     * @param _token ERC20 token address
     * @param _spenders The spender which spends the tokens (usually DeFi protocols)
     */
    function approveToken(IERC20 _token, address[] calldata _spenders) external payable {
        for (uint256 i = 0; i < _spenders.length;) {
            _token.forceApprove(_spenders[i], type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Wraps ETH to WETH
     * @param _proxyFeeInWei Fee of the proxy contract
     */
    function wrapETH(uint256 _proxyFeeInWei) external payable nonETHReuse {
        weth.deposit{value: msg.value - _proxyFeeInWei}();
    }

    /**
     * @notice Unwraps total amount of WETH9 to ETH and transfers the amount to the recipient
     * @param _recipient The destination address
     */
    function unwrapWETH9(address _recipient) external payable {
        uint256 balanceWETH = weth.balanceOf(address(this));

        if (balanceWETH > 0) {
            weth.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }

    /**
     * @notice Sweeps the total amount of tokens to inside the contract to the recipient
     * @param _token ERC20 token address
     * @param _recipient The destination address
     * @return amount Transferred amount of the token
     */
    function sweepToken(IERC20 _token, address _recipient) public payable returns (uint256 amount) {
        amount = _token.balanceOf(address(this));

        if (amount > 0) {
            _token.safeTransfer(_recipient, amount);
        }
    }

    /**
     * @notice Transfer ETH to the destination
     * @param _recipient The destination address
     * @param _amount Ether amount
     */
    function _sendETH(address _recipient, uint256 _amount) internal {
        if (_amount == 0) {
            revert InvalidAmountToTransfer();
        }

        (bool success,) = _recipient.call{value: _amount}("");

        if (!success) {
            revert FailedToSendEther(msg.sender, _recipient);
        }
    }
}