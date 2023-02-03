// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FeesSplitter} from "./FeesSplitter.sol";
import {KeeperCompatibleInterface} from "../interfaces/KeeperCompatibleInterface.sol";
import {Epoch} from "../utils/Epoch.sol";

interface ICommunityFund {
    function release() external;

    function releasableAmount() external view returns (uint256);
}

/**
 * This is a keeper contract that splits the maha from the ecosystem fund into the various treasuries on a
 * monthly basis via a keeper.
 *
 * Currently deployed at: https://etherscan.io/address/0x5f7a88d09491b89f0e9a02e3cce3309ef1502ab8
 */
contract MAHASplitKeeper is Epoch, FeesSplitter, KeeperCompatibleInterface {
    IERC20 public maha;
    ICommunityFund public communityFund;

    constructor(
        address[] memory _accounts,
        uint32[] memory _percentAllocations,
        IERC20 _maha,
        ICommunityFund _fund,
        address _owner
    )
        FeesSplitter(_accounts, _percentAllocations)
        Epoch(86400 * 30, block.timestamp, 0)
    {
        maha = _maha;
        communityFund = _fund;

        _transferOwnership(_owner);
    }

    function releaseAndDistributeMAHA() public {
        communityFund.release();
        distributeERC20(maha);
    }

    function releasable() public view returns (uint256) {
        return communityFund.releasableAmount();
    }

    function distributeMAHA() public {
        distributeERC20(maha);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return (_callable(), "");
    }

    function performUpkeep(bytes calldata) external override checkEpoch {
        releaseAndDistributeMAHA();
    }
}