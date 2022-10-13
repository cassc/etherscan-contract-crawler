// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./interfaces/IStructs.sol";
import "./maps/CommunityAccessMap.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@artman325/community/contracts/interfaces/ICommunity.sol";

/*ICommunityRolesManagement, */
abstract contract RolesManagement is Initializable {
    // itrc' fraction that will send to person who has invited "buy and stake" person
    uint256 public invitedByFraction;

    address internal communityAddress;
    uint8 internal redeemRoleId;
    uint8 internal circulationRoleId;
    uint8 internal tariffRoleId;

    error MissingRole(address account, uint8 roleId);

    function __RolesManagement_init(IStructs.CommunitySettings calldata communitySettings) internal onlyInitializing {
        require(communitySettings.addr != address(0));

        invitedByFraction = communitySettings.invitedByFraction;
        communityAddress = communitySettings.addr;
        redeemRoleId = communitySettings.redeemRoleId;
        circulationRoleId = communitySettings.circulationRoleId;
        tariffRoleId = communitySettings.tariffRoleId;
    }

    /**
     * @param fraction fraction that will send to person which has invite person who staked
     */
    function _setCommission(uint256 fraction) internal {
        invitedByFraction = fraction;
    }

    function _invitedBy(address account) internal view returns (address inviter) {
        return CommunityAccessMap(communityAddress).invitedBy(account);
    }

    function _checkRole(uint8 roleId, address account) internal view virtual {
        if (!hasRole(roleId, account)) {
            revert MissingRole(account, roleId);
            // revert(
            //     string(
            //         abi.encodePacked(
            //             "AccessControl: account ",
            //             StringsUpgradeable.toHexString(uint160(account), 20),
            //             " is missing role ",
            //             StringsUpgradeable.toHexString(uint256(role), 32)
            //         )
            //     )
            // );
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     *
     */
    function hasRole(uint8 role, address account) public view returns (bool) {
        // external call to community contract
        uint8[] memory communityRoles = ICommunity(communityAddress).getRoles(account);

        for (uint256 i = 0; i < communityRoles.length; i++) {
            if (role == communityRoles[i]) {
                return true;
            }
        }

        return false;
    }
}