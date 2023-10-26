// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUXDRouter} from "./IUXDRouter.sol";
import {ErrZeroAddress} from "../common/Constants.sol";
import {IDepository} from "../integrations/IDepository.sol";

/// @title UXDRouter
/// @notice Routes transactions to implementation contracts to interact with various DEXes.
contract UXDRouter is Ownable, IUXDRouter {
    ///////////////////////////////////////////////////////////////
    ///                        Errors
    //////////////////////////////////////////////////////////////
    error NoDepositoryForMarket(address market);
    error RouterNotController(address caller);
    error Exists(
        address assetToken,
        address depository
    );
    error NotExists(address assetToken);
    error UnsupportedAsset(address depository, address asset);

    ///////////////////////////////////////////////////////////////
    ///                     Events
    ///////////////////////////////////////////////////////////////
    event DepositoryRegistered(
        address indexed assetToken,
        address indexed depository
    );
    event DepositoryUnregistered(
        address indexed assetToken,
        address indexed depository
    );

    /// @dev Mapping assetToken address => depository addresses[].
    mapping(address => address[]) private _depositoriesForAsset;

    /// @notice Sets the depository for a given token.
    /// @dev reverts if this depository address is already registered for the same asset.
    /// A depository can be registered multiple times for different assets.
    /// @param depository the depository contract address.
    /// @param assetToken the asset to register the depository for
    function registerDepository(address depository, address assetToken)
        external
        onlyOwner
    {
        address found = _checkDepositoriesForAsset(assetToken, depository);
        if (found != address(0)) {
            revert Exists(assetToken, depository);
        }
        if (!_depositorySupportsAsset(depository, assetToken)) {
            revert UnsupportedAsset(depository, assetToken);
        }
        _depositoriesForAsset[assetToken].push(depository);

        emit DepositoryRegistered(assetToken, depository);
    }

    /// @notice Unregisters a previously registered depository
    /// @param depository the depository address.
    /// @param assetToken the asset to unregister depository for
    function unregisterDepository(address depository, address assetToken)
        external
        onlyOwner
    {
        bool foundByAsset = false;
        address[] storage byAsset = _depositoriesForAsset[assetToken];
        if (byAsset.length == 0) {
            revert NotExists(assetToken);
        }
        for (uint256 i = 0; i < byAsset.length; i++) {
            if (byAsset[i] == depository) {
                foundByAsset = true;
                byAsset[i] = byAsset[byAsset.length - 1];
                byAsset.pop();
                break;
            }
        }
        if (!foundByAsset) {
            revert NotExists(assetToken);
        }

        emit DepositoryUnregistered(assetToken, depository);
    }

    /// @notice Returns the depository for a given market
    /// @dev This function reverts if a depository is not found for a given assetToken.
    /// This returns the default colalteral pair based on internal routing logic.
    /// This is currently set to return the first depository registered for a given assetToken.
    /// @param assetToken The assetToken to return the depository for
    /// @return depository the address of the depository for a given market.
    function findDepositoryForDeposit(address assetToken, uint256) external view returns (address) {
        return _firstDepositoryForAsset(assetToken);
    }

    function findDepositoryForRedeem(address assetToken, uint256) external view returns (address) {
        return _firstDepositoryForAsset(assetToken);
    }

    function depositoriesForAsset(address assetToken) external view returns (address[] memory) {
        return _depositoriesForAsset[assetToken];
    }

    function _firstDepositoryForAsset(address assetToken) internal view returns (address) {
       address[] storage depositories = _depositoriesForAsset[assetToken];
        if (depositories.length == 0) {
            revert NotExists(assetToken);
        }
        return depositories[0]; 
    }


    function _checkDepositoriesForAsset(
        address assetToken,
        address checkFor
    ) internal view returns (address) {
        address[] storage byAsset = _depositoriesForAsset[assetToken];
        for (uint256 i = 0; i < byAsset.length; i++) {
            if (byAsset[i] == checkFor) {
                return byAsset[i];
            }
        }
        return address(0);
    }

    function _depositorySupportsAsset(address depository, address asset) internal view returns (bool) {
        address[] memory supportedAssets = IDepository(depository).supportedAssets();
        uint assetLength = supportedAssets.length;
        for (uint256 i = 0; i < assetLength; i++) {
            if (supportedAssets[i] == asset) {
                return true;
            }
        }
        return false;
    }
}