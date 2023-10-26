// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {StringValue} from "./lib/StorageTypes.sol";
import {AddressValue} from "./lib/StorageTypes.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {LAYERROWNABLE_OWNER_SLOT, LAYERRTOKEN_NAME_SLOT, LAYERRTOKEN_SYMBOL_SLOT, LAYERRTOKEN_RENDERER_SLOT} from "./common/LayerrStorage.sol";

/**
 * @title LayerrProxy
 * @author 0xth0mas (Layerr)
 * @notice A proxy contract that serves as an interface for interacting with 
 *         Layerr tokens. At deployment it sets token properties and contract 
 *         ownership, initializes signers and mint extensions, and configures 
 *         royalties.
 */
contract LayerrProxy {

    /// @dev the implementation address for the proxy contract
    address immutable proxy;

    /// @dev this is included as a hint for block explorers
    bytes32 private constant PROXY_IMPLEMENTATION_REFERENCE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Thrown when a required initialization call fails
    error DeploymentFailed();

    /**
     * @notice Initializes the proxy contract
     * @param _proxy implementation address for the proxy contract
     * @param _name token contract name
     * @param _symbol token contract symbol
     * @param royaltyPct default royalty percentage in BPS
     * @param royaltyReceiver default royalty receiver
     * @param operatorFilterRegistry address of the operator filter registry to subscribe to
     * @param _extension minting extension to use with the token contract
     * @param _renderer renderer to use with the token contract
     * @param _signers array of allowed signers for the mint extension
     */
    constructor(
        address _proxy, 
        string memory _name, 
        string memory _symbol, 
        uint96 royaltyPct, 
        address royaltyReceiver, 
        address operatorFilterRegistry, 
        address _extension, 
        address _renderer, 
        address[] memory _signers
    ) {
        proxy = _proxy; 

        StringValue storage name;
        StringValue storage symbol;
        AddressValue storage renderer;
        AddressValue storage owner;
        AddressValue storage explorerProxy;
        /// @solidity memory-safe-assembly
        assembly {
            name.slot := LAYERRTOKEN_NAME_SLOT
            symbol.slot := LAYERRTOKEN_SYMBOL_SLOT
            renderer.slot := LAYERRTOKEN_RENDERER_SLOT
            owner.slot := LAYERROWNABLE_OWNER_SLOT
            explorerProxy.slot := PROXY_IMPLEMENTATION_REFERENCE
        } 
        name.value = _name;
        symbol.value = _symbol;
        renderer.value = _renderer;
        owner.value = tx.origin;
        explorerProxy.value = _proxy;

        uint256 signersLength = _signers.length;
        for(uint256 signerIndex;signerIndex < signersLength;) {
            ILayerrMinter(_extension).setContractAllowedSigner(_signers[signerIndex], true);
            unchecked {
                ++signerIndex;
            }
        }

        (bool success, ) = _proxy.delegatecall(abi.encodeWithSignature("setRoyalty(uint96,address)", royaltyPct, royaltyReceiver));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setOperatorFilter(address)", operatorFilterRegistry));
        //this item may fail if deploying a contract that does not use an operator filter

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setMintExtension(address,bool)", _extension, true));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("initialize()"));
        if(!success) revert DeploymentFailed();
    }

    fallback() external payable {
        address _proxy = proxy;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _proxy, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}