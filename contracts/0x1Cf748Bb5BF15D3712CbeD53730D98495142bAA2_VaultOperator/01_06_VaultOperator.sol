// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Common} from "./libraries/Common.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";
import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";

contract VaultOperator is Ownable {
    IBribeVault public immutable bribeVault;
    IRewardDistributor public immutable rewardDistributor;
    address public operator;

    error NotAuthorized();
    error ZeroAddress();

    constructor(address _bribeVault, address _rewardDistributor) {
        bribeVault = IBribeVault(_bribeVault);
        rewardDistributor = IRewardDistributor(_rewardDistributor);

        // Default to the deployer
        operator = msg.sender;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotAuthorized();
        _;
    }

    /**
        @notice Set the operator
        @param  _operator  address  Operator address
     */
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert ZeroAddress();

        operator = _operator;
    }

    /**
        @notice Redirect transferBribes call to the bribeVault for approved operator
        @param  rewardIdentifiers  bytes32[]  List of rewardIdentifiers
     */
    function transferBribes(bytes32[] calldata rewardIdentifiers)
        external
        onlyOperator
    {
        bribeVault.transferBribes(rewardIdentifiers);
    }

    /**
        @notice Redirect updateRewardsMetadata call to the rewardDistributor for approved operator
        @param  distributions  Distribution[]  List of reward distribution details
     */
    function updateRewardsMetadata(Common.Distribution[] calldata distributions)
        external
        onlyOperator
    {
        rewardDistributor.updateRewardsMetadata(distributions);
    }
}