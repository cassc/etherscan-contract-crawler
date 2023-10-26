// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./ERC20Ubiquity.sol";

contract UbiquityAutoRedeem is ERC20Ubiquity {
    constructor(address _manager)
        ERC20Ubiquity(_manager, "Ubiquity Auto Redeem", "uAR")
    {} // solhint-disable-line no-empty-blocks

    /// @notice raise capital in form of uAR (only redeemable when uAD > 1$)
    /// @param amount the amount to be minted
    /// @dev you should be minter to call that function
    function raiseCapital(uint256 amount) external {
        address treasuryAddress = manager.treasuryAddress();
        mint(treasuryAddress, amount);
    }
}