// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modified `Auth.sol`, where the contract is its own `authority` there is no `target` to `canCall`.
/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    address public owner;

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(msg.sender, _owner);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        return canCall(user, functionSig) || user == owner;
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }

    function canCall(
        address user,
        bytes4 functionSig
    ) public view virtual returns (bool);
}