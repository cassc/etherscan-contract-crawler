// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {CrowdfundWithEditionsStorage} from "./CrowdfundWithEditionsStorage.sol";
import {ERC20Storage} from "../../../external/ERC20Storage.sol";
import {IERC20Events} from "../../../external/interface/IERC20.sol";

interface ICrowdfundWithEditionsFactory {
    function mediaAddress() external returns (address);

    function logic() external returns (address);

    function editions() external returns (address);

    // ERC20 data.
    function parameters()
        external
        returns (
            address payable fundingRecipient,
            uint256 fundingCap,
            uint256 operatorPercent,
            uint256 feePercentage
        );
}

/**
 * @title CrowdfundWithEditionsProxy
 * @author MirrorXYZ
 */
contract CrowdfundWithEditionsProxy is
    CrowdfundWithEditionsStorage,
    ERC20Storage,
    IERC20Events
{
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address treasuryConfig_,
        address payable operator_,
        string memory name_,
        string memory symbol_
    ) ERC20Storage(name_, symbol_) {
        address logic = ICrowdfundWithEditionsFactory(msg.sender).logic();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }

        emit Upgraded(logic);

        editions = ICrowdfundWithEditionsFactory(msg.sender).editions();
        // Crowdfund-specific data.
        (
            fundingRecipient,
            fundingCap,
            operatorPercent,
            feePercentage
        ) = ICrowdfundWithEditionsFactory(msg.sender).parameters();

        operator = operator_;
        treasuryConfig = treasuryConfig_;
        // Initialize mutable storage.
        status = Status.FUNDING;
    }

    /// @notice Get current logic
    function logic() external view returns (address logic_) {
        assembly {
            logic_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}