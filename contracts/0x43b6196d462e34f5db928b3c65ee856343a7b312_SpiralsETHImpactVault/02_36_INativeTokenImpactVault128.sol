// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import "src/vaults/ImpactVault128.sol";

abstract contract INativeTokenImpactVault128 is ImpactVault128 {
    function depositETH(address _receiver)
        external
        payable
        virtual
        whenNotPaused
        nonReentrant
    {
        if (msg.value == 0) {
            revert ZeroDeposit();
        }
        // Using SafeERC20Upgradeable
        // slither-disable-next-line unchecked-transfer
        uint256 amountToMint = _stake(msg.value);
        _mint(_receiver, amountToMint);

        emit Deposit(msg.value, amountToMint, _receiver);
    }

    function withdrawals(address)
        external
        view
        virtual
        returns (uint256, uint256);
}