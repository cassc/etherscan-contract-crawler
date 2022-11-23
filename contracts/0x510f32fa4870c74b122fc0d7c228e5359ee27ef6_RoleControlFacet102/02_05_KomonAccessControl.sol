//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";
import {IKomonAccessControl} from "IKomonAccessControl.sol";

/**
 * @title Komon AccessControl implementation
 */
abstract contract KomonAccessControl is IKomonAccessControl {
    function assetsToKomonAccount() public view returns (address) {
        return KomonAccessControlBaseStorage.layout()._assetsToKomonAccount;
    }

    function _setAssetstoKomonAccount(address account) internal {
        address oldAssetsAccount = KomonAccessControlBaseStorage
            .layout()
            ._assetsToKomonAccount;
        KomonAccessControlBaseStorage.layout()._assetsToKomonAccount = account;
        emit UpdatedAssetsToKomonAccount(oldAssetsAccount, account);
    }
}
