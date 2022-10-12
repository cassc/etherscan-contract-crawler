// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Factory} from "../interfaces/IArrakisV2Factory.sol";
import {IArrakisV2Beacon} from "../interfaces/IArrakisV2Beacon.sol";
import {
    ITransparentUpgradeableProxy
} from "../interfaces/ITransparentUpgradeableProxy.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// solhint-disable-next-line max-states-count
abstract contract ArrakisV2FactoryStorage is
    IArrakisV2Factory,
    OwnableUpgradeable /* XXXX DONT MODIFY ORDERING XXXX */
    // APPEND ADDITIONAL BASE WITH STATE VARS BELOW:
    // XXXX DONT MODIFY ORDERING XXXX
{
    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX

    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line const-name-snakecase
    string public constant version = "1.0.0";

    IArrakisV2Beacon public immutable arrakisV2Beacon;
    EnumerableSet.AddressSet internal _vaults;

    // APPPEND ADDITIONAL STATE VARS BELOW:

    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX

    // #region constructor.

    constructor(IArrakisV2Beacon arrakisV2Beacon_) {
        arrakisV2Beacon = arrakisV2Beacon_;
    }

    // #endregion constructor.

    function initialize(address _owner_) external initializer {
        _transferOwnership(_owner_);
        emit InitFactory(_owner_);
    }

    // #region admin set functions

    function upgradeVaults(address[] memory vaults_) external onlyOwner {
        for (uint256 i = 0; i < vaults_.length; i++) {
            ITransparentUpgradeableProxy(vaults_[i]).upgradeTo(
                arrakisV2Beacon.implementation()
            );
        }
    }

    function upgradeVaultsAndCall(
        address[] memory vaults_,
        bytes[] calldata datas_
    ) external onlyOwner {
        require(vaults_.length == datas_.length, "mismatching array length");
        for (uint256 i = 0; i < vaults_.length; i++) {
            ITransparentUpgradeableProxy(vaults_[i]).upgradeToAndCall(
                arrakisV2Beacon.implementation(),
                datas_[i]
            );
        }
    }

    function makeVaultsImmutable(address[] memory vaults_) external onlyOwner {
        for (uint256 i = 0; i < vaults_.length; i++) {
            ITransparentUpgradeableProxy(vaults_[i]).changeAdmin(address(1));
        }
    }

    // #endregion admin set functions

    // #region admin view call.

    function getProxyAdmin(address proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = proxy.staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    function getProxyImplementation(address proxy)
        public
        view
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = proxy.staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    // #endregion admin view call.
}