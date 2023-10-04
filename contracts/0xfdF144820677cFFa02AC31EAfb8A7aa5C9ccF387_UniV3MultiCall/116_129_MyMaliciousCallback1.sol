// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract MyMaliciousCallback1 {
    uint256 internal _vaultVictim;
    address internal _collToken;
    address internal _compartmentVictim;

    constructor(
        address vaultVictim,
        address collToken,
        address compartmentVictim
    ) {
        /* need to shift _vaultVictim by 4x hex to match storage layout f BaseCompartment such that
         * retrieving vaultAddr in BaseCompartment maps to _vaultVictim in this contract and access
         * control check in BaseCompartment (i.e., msg.sender != vaultAddr) could be bypassed
         */
        _vaultVictim = uint256(uint160(vaultVictim)) * 16 * 16 * 16 * 16;
        _collToken = collToken;
        _compartmentVictim = compartmentVictim;
    }

    function balanceOf(address) external returns (uint256) {
        /* Try hijacking control flow by tricking vault owner to call withdraw function with this purported
         * token contract and then use delegate call transferCollFromCompartment(...) and pretend msg.sender to
         * be the vault.
         */
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = _compartmentVictim.delegatecall(
            abi.encodeWithSignature(
                "transferCollFromCompartment(uint256,uint256,uint128,address,address,address)",
                1,
                1,
                1,
                address(this),
                _collToken,
                address(0)
            )
        );
        /* The delegate call is expected to fail because of mutex in _withdrawCheck()
         * Note: even if there wasn't a _withdrawCheck() then delegate call and access check could be
         * bypassed, then delegate call would operate on the contract state and balance of MyMaliciousCallback1,
         * NOT on balance of compartment, hence the compartment balance wouldn't be at risk
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