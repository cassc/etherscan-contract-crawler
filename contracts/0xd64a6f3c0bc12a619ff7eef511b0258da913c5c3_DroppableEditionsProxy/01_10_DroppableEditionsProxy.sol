// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC2309} from "../../../external/interface/IERC2309.sol";
import {DroppableEditionsStorage} from "./DroppableEditionsStorage.sol";
import {IDroppableEditionsFactory} from "./interface/IDroppableEditionsFactory.sol";
import {InitializedGovernable} from "../../../lib/InitializedGovernable.sol";
import {Pausable} from "../../../lib/Pausable.sol";
import {IDroppableEditionsLogicEvents} from "./interface/IDroppableEditionsLogic.sol";
import {IERC721Events} from "../../../external/interface/IERC721.sol";

/**
 * @title DroppableEditionsProxy
 * @author MirrorXYZ
 */
contract DroppableEditionsProxy is
    DroppableEditionsStorage,
    InitializedGovernable,
    Pausable,
    IDroppableEditionsLogicEvents,
    IERC721Events,
    IERC2309
{
    event Upgraded(address indexed implementation);

    event RenounceUpgrade(uint256 blockNumber);

    /// @notice IERC721Metadata
    string public name;
    string public symbol;

    constructor(
        address owner_,
        address governor_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, governor_) Pausable(true) {
        address logic = IDroppableEditionsFactory(msg.sender).logic();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }

        emit Upgraded(logic);

        proxyRegistry = proxyRegistry_;

        bytes memory nftMetaData;
        bytes memory adminData;

        (
            // NFT Metadata
            nftMetaData,
            // Edition Data
            allocation,
            quantity,
            price,
            // Admin data
            adminData
        ) = IDroppableEditionsFactory(msg.sender).parameters();

        (name, symbol, baseURI, contentHash) = abi.decode(
            nftMetaData,
            (string, string, string, bytes32)
        );

        (
            operator,
            merkleRoot,
            tributary,
            fundingRecipient,
            feePercentage,
            treasuryConfig
        ) = abi.decode(
            adminData,
            (address, bytes32, address, address, uint256, address)
        );
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

    // ============ Upgrade Methods ============

    /// @notice Get current logic
    function getLogic() external view returns (address logic) {
        assembly {
            logic := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @notice Allows governance to change the logic.
    function changeLogic(address newLogic) external onlyGovernance {
        require(upgradesAllowed, "cannot upgrade");

        // Store the newImplementation on implementation-slot
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newLogic)
        }

        emit Upgraded(newLogic);
    }

    /// @notice opt-out of upgrades
    function renounceUpgrades() external onlyGovernance {
        upgradesAllowed = false;

        emit RenounceUpgrade(block.number);
    }

    receive() external payable {}
}