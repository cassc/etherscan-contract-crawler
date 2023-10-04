// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract MyMaliciousCallback2 {
    address internal _vaultVictim;
    address internal _withdrawToken;
    uint256 internal _withdrawAmount;

    constructor(
        address vaultVictim,
        address withdrawToken,
        uint256 withdrawAmount
    ) {
        _vaultVictim = vaultVictim;
        _withdrawToken = withdrawToken;
        _withdrawAmount = withdrawAmount;
    }

    function balanceOf(address) external returns (uint256) {
        // Try hijacking control flow by calling back into vault and trying to withdraw again
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = _vaultVictim.call(
            abi.encodeWithSignature(
                "withdraw(address,uint256)",
                _withdrawToken,
                _withdrawAmount
            )
        );
        /* The delegate call is expected to fail because of mutex in _withdrawCheck()
         * Note: even if there wasn't a _withdrawCheck() then delegate call and access check could be
         * bypassed, then delegate call would operate on the contract state and balance of MyMaliciousCallback1,
         * NOT on balance of vault, hence the vault balance wouldn't be at risk
         */
        if (!success) {
            // solhint-disable no-inline-assembly
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return 0;
    }

    // solhint-disable no-empty-blocks
    function transfer(address, uint256) external returns (bool) {}
}