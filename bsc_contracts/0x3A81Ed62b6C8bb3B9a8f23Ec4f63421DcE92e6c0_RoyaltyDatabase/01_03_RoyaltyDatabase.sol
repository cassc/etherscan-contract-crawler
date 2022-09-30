//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";

contract RoyaltyDatabase is Ownable {

    address payable public immutable royaltyRecipient;
    address payable public platformRecipient;
    
    constructor(address payable royalty, address payable platform) {
        royaltyRecipient = royalty;
        platformRecipient = platform;
    }

    function setPlatformRecipient(address payable platformRecipient_) external onlyOwner {
        platformRecipient = platformRecipient_;
    }

    function withdraw() external {
        _distribute(address(0));
    }

    function withdrawToken(address token) external {
        _distribute(token);
    }

    function withdrawTokens(address[] calldata tokens) external {
        uint len = tokens.length;
        for (uint i = 0; i < len;) {
            _distribute(tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _distribute(address token) internal {
        if (token == address(0)) {
            _send(royaltyRecipient, address(this).balance / 10);
            _send(platformRecipient, address(this).balance);
        } else {
            uint bal = IERC20(token).balanceOf(address(this));
            uint bal0 = bal / 10;
            uint bal1 = bal - bal0;
            _sendToken(token, royaltyRecipient, bal0);
            _sendToken(token, platformRecipient, bal1);
        }
    }

    function _sendToken(address token, address to, uint amount) internal {
        uint tokenBal = IERC20(token).balanceOf(address(this));
        if (amount > tokenBal) {
            amount = tokenBal;
        }
        if (amount == 0 || to == address(0)) {
            return;
        }
        IERC20(token).transfer(to, amount);
    }

    function _send(address payable to, uint amount) internal {
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        if (amount == 0 || to == address(0)) {
            return;
        }
        (bool s,) = to.call{value: amount}("");
        require(s, 'ETH TRNSFR FAIL');
    }

    receive() external payable {
        _distribute(address(0));
    }
}