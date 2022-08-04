// SPDX-License-Identifier: CAL
pragma solidity 0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/factory/IFactory.sol";
import "./Vapour721A.sol";

contract Vapour721AFactory is IFactory {
    mapping(address => bool) private contracts;
    address private vmStateBuilder;

    
    constructor(address vmStateBuilder_){
        vmStateBuilder = vmStateBuilder_;
    }

    function _createChild(bytes calldata data_)
        internal
        returns (address child_)
    {
        ConstructorConfig memory config_ = abi.decode(
            data_,
            (ConstructorConfig)
        );
        child_ = address(new Vapour721A(config_));
    }

    /// @inheritdoc IFactory
    function createChild(bytes calldata data_)
        external
        virtual
        override
        returns (address)
    {
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Ensure the child at this address has not previously been deployed.
        require(!contracts[child_], "DUPLICATE_CHILD");
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// @inheritdoc IFactory
    function isChild(address maybeChild_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return contracts[maybeChild_];
    }

    /// Typed wrapper around IFactory.createChild.
    function createChildTyped(
        ConstructorConfig calldata constructorConfig_,
        address currency_,
        StateConfig memory vmStateConfig_
    ) external returns (Vapour721A child_) {
        child_ = Vapour721A(this.createChild(abi.encode(constructorConfig_)));
        Vapour721A(child_).initialize(InitializeConfig({
            currency: currency_,
            vmStateConfig: vmStateConfig_,
            vmStateBuilder: vmStateBuilder
        }));
    }
}