// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineManagerBordeauxCityBondIntegration.sol";
import "../interfaces/IBordeauxCityBondIntegration.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract BordeauxCityBondIntegration is IWineManagerBordeauxCityBondIntegration
{
    address public override bordeauxCityBond;

    function _initializeBordeauxCityBond(
        address proxyAdmin_,
        address bordeauxCityBondCode_,
        uint256 BCBOutFee_,
        uint256 BCBFixedFee_,
        uint256 BCBFlexedFee_
    )
        internal
    {
        require(bordeauxCityBond == address(0), 'Contract is already initialized');
        bordeauxCityBond = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(bordeauxCityBond).initializeProxy(bordeauxCityBondCode_, proxyAdmin_, bytes(""));
        IBordeauxCityBondIntegration(bordeauxCityBond).initialize(address(this), BCBOutFee_, BCBFixedFee_, BCBFlexedFee_);
    }

}