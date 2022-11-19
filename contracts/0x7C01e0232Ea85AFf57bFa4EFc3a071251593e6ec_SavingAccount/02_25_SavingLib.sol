// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IGlobalConfig.sol";
import "./Utils.sol";

library SavingLib {
    using SafeERC20 for IERC20;

    /**
     * Receive the amount of token from msg.sender
     * @param _amount amount of token
     * @param _token token address
     */
    function collectAssets(uint256 _amount, address _token) public {
        if (Utils._isETH(_token)) {
            require(msg.value == _amount, "The amount is not sent from address.");
        } else {
            //When only tokens received, msg.value must be 0
            require(msg.value == 0, "msg.value must be 0 when receiving tokens");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     * Send the amount of token to an address
     * @param _amount amount of token
     * @param _token token address
     */
    function sendAssets(uint256 _amount, address _token) public {
        if (Utils._isETH(_token)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }
}