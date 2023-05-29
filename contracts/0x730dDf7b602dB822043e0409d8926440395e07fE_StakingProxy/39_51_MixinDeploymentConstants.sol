/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.5.9 <0.8.0;
pragma experimental ABIEncoderV2;

import "../../utils/0xUtils/IEtherToken.sol";
import "../interfaces/IGrgVault.sol";
import "../interfaces/IStaking.sol";
import "../../protocol/DragoRegistry/IDragoRegistry.sol";
import "../../rigoToken/RigoToken/RigoTokenFace.sol";


// solhint-disable separate-by-one-line-in-contract
abstract contract MixinDeploymentConstants is IStaking {

    // Mainnet GrgVault address
    address constant private GRG_VAULT_ADDRESS = address(0x0a33744eE5D57d6d69944213d8E6ad80d64Fdc58);

    // Ropsten GrgVault address
    // address constant private GRG_VAULT_ADDRESS = address(0x7fc6a07e4b7b859c80F949A2A7812e00C64b4264);
    
    // Mainnet DragoRegistry address
    address constant private DRAGO_REGISTRY_ADDRESS = address(0xdE6445484a8dcD9bf35fC95eb4E3990Cc358822e);
    
    // Ropsten DragoRegistry address
    // address constant private DRAGO_REGISTRY_ADDRESS = address(0x4e868D1dDF940316964eA7673E21bE6CBED8b30B);
    
    // Mainnet GRG Address
    address constant private GRG_ADDRESS = address(0x4FbB350052Bca5417566f188eB2EBCE5b19BC964);

    // Ropsten GRG Address
    // address constant private GRG_ADDRESS = address(0x6FA8590920c5966713b1a86916f7b0419411e474);

    /// @dev An overridable way to access the deployed grgVault.
    ///      Must be view to allow overrides to access state.
    /// @return grgVault The grgVault contract.
    function getGrgVault()
        public
        view
        virtual
        override
        returns (IGrgVault grgVault)
    {
        grgVault = IGrgVault(GRG_VAULT_ADDRESS);
        return grgVault;
    }
    
    /// @dev An overridable way to access the deployed dragoRegistry.
    ///      Must be view to allow overrides to access state.
    /// @return dragoRegistry The dragoRegistry contract.
    function getDragoRegistry()
        public
        view
        virtual
        override
        returns (IDragoRegistry dragoRegistry)
    {
        dragoRegistry = IDragoRegistry(DRAGO_REGISTRY_ADDRESS);
        return dragoRegistry;
    }
    
    /// @dev An overridable way to access the deployed GRG contract.
    ///      Must be view to allow overrides to access state.
    /// @return grgContract The GRG contract instance.
    function getGrgContract()
        public
        view
        virtual
        override
        returns (RigoTokenFace grgContract)
    {
        grgContract = RigoTokenFace(GRG_ADDRESS);
        return grgContract;
    }
}