/// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./ConstantsAF.sol";

abstract contract AFRoles is AccessControlEnumerable {
    modifier onlyEditor() {
        require(
            hasRole(ConstantsAF.EDITOR_ROLE, msg.sender),
            "Caller is not an editor"
        );
        _;
    }

    modifier onlyContract() {
        require(
            hasRole(ConstantsAF.CONTRACT_ROLE, msg.sender),
            "Caller is not a contract"
        );
        _;
    }

    function setRole(bytes32 role, address user) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ConstantsAF.ROLE_MANAGER_ROLE, msg.sender),
            "Caller is not admin nor role manager"
        );

        _setupRole(role, user);
    }
}