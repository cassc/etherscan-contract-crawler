// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// Parameters for ERC20Permit.permit call
struct ERC20PermitSignature {
    IERC20Permit token;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

library PermitHelper {
    function applyPermit(
        ERC20PermitSignature calldata p,
        address owner,
        address spender
    ) internal {
        p.token.permit(owner, spender, p.value, p.deadline, p.v, p.r, p.s);
    }

    function applyPermits(
        ERC20PermitSignature[] calldata permits,
        address owner,
        address spender
    ) internal {
        for (uint256 i = 0; i < permits.length; i++) {
            applyPermit(permits[i], owner, spender);
        }
    }
}