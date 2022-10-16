//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/SwapCalldataUtils.sol";

contract TargetTokenHolder {
    using SafeERC20 for IERC20;
    using SwapCalldataUtils for bytes;

    address targetToken;

    constructor(address targetToken_) {
        targetToken = targetToken_;
    }

    // called for any calldata (see SAMPLE_CALLDATA in src/SwapCalldataParser.js)
    // thus emulating real-world pool/router behavior
    fallback (bytes calldata _input) external returns (bytes memory) {
        (uint256 amount, bool success) = _input.getAmount();
        if (success) {
            IERC20(targetToken).transferFrom(msg.sender, address(this), amount);
        }
    }

    function obtain(address _wrappedToken) external {
        IERC20 wrappedToken = IERC20(_wrappedToken);
        wrappedToken.transferFrom(
            msg.sender,
            address(this),
            wrappedToken.balanceOf(msg.sender)
        );
    }
}