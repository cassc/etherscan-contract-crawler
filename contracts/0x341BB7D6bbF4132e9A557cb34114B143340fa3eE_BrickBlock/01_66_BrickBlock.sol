// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;






// 
// ██████╗ ██████╗ ██╗ ██████╗██╗  ██╗    ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗    
// ██╔══██╗██╔══██╗██║██╔════╝██║ ██╔╝    ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝    
// ██████╔╝██████╔╝██║██║     █████╔╝     ██████╔╝██║     ██║   ██║██║     █████╔╝     
// ██╔══██╗██╔══██╗██║██║     ██╔═██╗     ██╔══██╗██║     ██║   ██║██║     ██╔═██╗     
// ██████╔╝██║  ██║██║╚██████╗██║  ██╗    ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗    
// ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝    
//                                                                                     
// Brick Block  - generated with HeyMint.xyz Launchpad - https://nft-launchpad.heymint.xyz
// 








import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IAddressRelay} from "./interfaces/IAddressRelay.sol";
import {BaseConfig} from "./libraries/HeyMintStorage.sol";

contract BrickBlock {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADDRESS_RELAY_SLOT =
        keccak256("heymint.launchpad.addressRelay");

    /**
     * @notice Initializes the child contract with the base implementation address and the configuration settings
     * @param _name The name of the NFT
     * @param _symbol The symbol of the NFT
     * @param _baseConfig Base configuration settings
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _addressRelay,
        address _implementation,
        BaseConfig memory _baseConfig
    ) {
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = _implementation;
        StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value = _addressRelay;
        IAddressRelay addressRelay = IAddressRelay(
            StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value
        );
        address implContract = addressRelay.fallbackImplAddress();
        (bool success, ) = implContract.delegatecall(
            abi.encodeWithSelector(0x35a825b0, _name, _symbol, _baseConfig)
        );
        require(success);
    }

    /**
     * @dev Delegates the current call to nftImplementation
     *
     * This function does not return to its internal call site - it will return directly to the external caller.
     */
    fallback() external payable {
        IAddressRelay addressRelay = IAddressRelay(
            StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value
        );
        address implContract = addressRelay.getImplAddress(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implContract,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}