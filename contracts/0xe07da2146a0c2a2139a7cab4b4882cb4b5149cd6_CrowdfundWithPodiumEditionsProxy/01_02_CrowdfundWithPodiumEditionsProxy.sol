// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {CrowdfundWithPodiumEditionsStorage} from "./CrowdfundWithPodiumEditionsStorage.sol";

interface ICrowdfundWithPodiumEditionsFactory {
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
            string memory name,
            string memory symbol,
            uint256 feePercentage,
            uint256 podiumDuration
        );
}

/**
 * @title CrowdfundWithPodiumEditionsProxy
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsProxy is
    CrowdfundWithPodiumEditionsStorage
{
    constructor(address treasuryConfig_, address payable operator_) {
        logic = ICrowdfundWithPodiumEditionsFactory(msg.sender).logic();
        editions = ICrowdfundWithPodiumEditionsFactory(msg.sender).editions();
        // Crowdfund-specific data.
        (
            fundingRecipient,
            fundingCap,
            operatorPercent,
            name,
            symbol,
            feePercentage,
            podiumDuration
        ) = ICrowdfundWithPodiumEditionsFactory(msg.sender).parameters();

        operator = operator_;
        treasuryConfig = treasuryConfig_;
        // Initialize mutable storage.
        status = Status.FUNDING;
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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