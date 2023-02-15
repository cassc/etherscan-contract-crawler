// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ShareToken.sol";
import "../interfaces/ISilo.sol";

/// @title ShareCollateralToken
/// @notice ERC20 compatible token representing collateral position in Silo
/// @custom:security-contact [email protected]
contract ShareCollateralToken is ShareToken {

    error SenderNotSolventAfterTransfer();
    error ShareTransferNotAllowed();

    /// @dev Token is always deployed for specific Silo and asset
    /// @param _name token name
    /// @param _symbol token symbol
    /// @param _silo Silo address for which tokens was deployed
    /// @param _asset asset for which this tokens was deployed
    constructor (
        string memory _name,
        string memory _symbol,
        address _silo,
        address _asset
    ) ERC20(_name, _symbol) ShareToken(_silo, _asset) {
        // all setup is done in parent contracts, nothing to do here
    }

    function _afterTokenTransfer(address _sender, address _recipient, uint256 _amount) internal override {
        ShareToken._afterTokenTransfer(_sender, _recipient, _amount);

        // if we minting or burning, Silo is responsible to check all necessary conditions
        // make sure that _sender is solvent after transfer
        if (_isTransfer(_sender, _recipient) && !silo.isSolvent(_sender)) {
            revert SenderNotSolventAfterTransfer();
        }

        // report mint or transfer
        _notifyAboutTransfer(_sender, _recipient, _amount);
    }

    function _beforeTokenTransfer(address _sender, address _recipient, uint256) internal view override {
        // if we minting or burning, Silo is responsible to check all necessary conditions
        if (!_isTransfer(_sender, _recipient)) {
            return;
        }

        // Silo forbids having debt and collateral position of the same asset in given Silo
        if (!silo.depositPossible(asset, _recipient)) revert ShareTransferNotAllowed();
    }
}