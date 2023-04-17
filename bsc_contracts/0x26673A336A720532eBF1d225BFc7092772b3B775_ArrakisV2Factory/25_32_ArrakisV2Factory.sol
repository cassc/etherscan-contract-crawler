// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IArrakisV2} from "./interfaces/IArrakisV2.sol";
import {IArrakisV2Beacon} from "./interfaces/IArrakisV2Beacon.sol";
import {
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {
    BeaconProxy
} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {ArrakisV2FactoryStorage} from "./abstract/ArrakisV2FactoryStorage.sol";
import {InitializePayload} from "./structs/SArrakisV2.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {_getTokenOrder, _append} from "./functions/FArrakisV2Factory.sol";

/// @title ArrakisV2Factory factory for creating vault instances.
contract ArrakisV2Factory is ArrakisV2FactoryStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(IArrakisV2Beacon arrakisV2Beacon_)
        ArrakisV2FactoryStorage(arrakisV2Beacon_)
    {} // solhint-disable-line no-empty-blocks

    /// @notice Deploys an instance of Vault using BeaconProxy or TransparentProxy.
    /// @param params_ contains all data needed to create an instance of ArrakisV2 vault.
    /// @param isBeacon_ boolean, if true the instance will be BeaconProxy or TransparentProxy.
    /// @return vault the address of the Arrakis V2 vault instance created.
    function deployVault(InitializePayload calldata params_, bool isBeacon_)
        external
        returns (address vault)
    {
        vault = _preDeploy(params_, isBeacon_);
        _vaults.add(vault);
        emit VaultCreated(msg.sender, vault);
    }

    // #region public external view functions.

    /// @notice get Arrakis V2 standard token name for two corresponding tokens.
    /// @param token0_ address of the first token.
    /// @param token1_ address of the second token.
    /// @return name name of the arrakis V2 vault.
    function getTokenName(address token0_, address token1_)
        external
        view
        returns (string memory)
    {
        string memory symbol0 = IERC20Metadata(token0_).symbol();
        string memory symbol1 = IERC20Metadata(token1_).symbol();
        return _append("Arrakis Vault V2 ", symbol0, "/", symbol1);
    }

    /// @notice get a list of vaults created by this factory
    /// @param startIndex_ start index
    /// @param endIndex_ end index
    /// @return vaults list of all created vaults.
    function vaults(uint256 startIndex_, uint256 endIndex_)
        external
        view
        returns (address[] memory)
    {
        require(
            startIndex_ < endIndex_,
            "start index is equal or greater than end index."
        );
        require(
            endIndex_ <= numVaults(),
            "end index is greater than vaults array length"
        );
        address[] memory vs = new address[](endIndex_ - startIndex_);
        for (uint256 i = startIndex_; i < endIndex_; i++) {
            vs[i] = _vaults.at(i);
        }

        return vs;
    }

    /// @notice numVaults counts the total number of vaults in existence
    /// @return result total number of vaults deployed
    function numVaults() public view returns (uint256 result) {
        return _vaults.length();
    }

    // #endregion public external view functions.

    // #region internal functions

    function _preDeploy(InitializePayload calldata params_, bool isBeacon_)
        internal
        returns (address vault)
    {
        (address token0, address token1) = _getTokenOrder(
            params_.token0,
            params_.token1
        );

        string memory name = "Arrakis Vault V2";
        try this.getTokenName(token0, token1) returns (string memory result) {
            name = result;
        } catch {} // solhint-disable-line no-empty-blocks

        bytes memory data = abi.encodeWithSelector(
            IArrakisV2.initialize.selector,
            name,
            string(abi.encodePacked("RAKISv2-", _uint2str(numVaults() + 1))),
            params_
        );

        bytes32 salt = keccak256(
            abi.encodePacked(tx.origin, block.number, data)
        );

        vault = isBeacon_
            ? address(
                new BeaconProxy{salt: salt}(address(arrakisV2Beacon), data)
            )
            : address(
                new TransparentUpgradeableProxy{salt: salt}(
                    arrakisV2Beacon.implementation(),
                    address(this),
                    data
                )
            );
    }

    // #endregion internal functions

    // #region internal view functions

    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // #endregion internal view functions
}