// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';
import {PermissionOperators} from '@kyber.network/utils-sc/contracts/PermissionOperators.sol';
import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';
import {IKyberGovernance} from '../interfaces/governance/IKyberGovernance.sol';
import {IRewardsDistributor} from '../interfaces/rewardDistribution/IRewardsDistributor.sol';


/**
    Internal contracts to participate in KyberDAO and claim rewards for Kyber
    Only accept external delegation, all reward will be transferred
*/
contract KyberInternalGovernance is PermissionOperators {
    using SafeERC20 for IERC20Ext;

    IERC20Ext public constant ETH_TOKEN_ADDRESS = IERC20Ext(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address payable public rewardRecipient;
    IKyberGovernance public governance;
    IRewardsDistributor public rewardDistributor;

    constructor(
        address _admin,
        address payable _rewardRecipient,
        IKyberGovernance _governance,
        IRewardsDistributor _rewardDistributor,
        address _operator
    ) PermissionAdmin(_admin) {
        require(_rewardRecipient != address(0), "invalid reward recipient");
        require(_governance != IKyberGovernance(0), "invalid kyber governance");
        require(_rewardDistributor != IRewardsDistributor(0), "invalid reward distributor");

        rewardRecipient = _rewardRecipient;
        governance = _governance;
        rewardDistributor = _rewardDistributor;

        if (_operator != address(0)) {
            // consistent with current design
            operators[_operator] = true;
            operatorsGroup.push(_operator);
            emit OperatorAdded(_operator, true);
        }
    }

    receive() external payable {}

    /**
    * @dev only operator can vote, given list of proposal ids
    *   and an option for each proposal
    */
    function vote(
        uint256[] calldata proposalIds,
        uint256[] calldata optionBitMasks
    )
        external onlyOperator
    {
        require(proposalIds.length == optionBitMasks.length, "invalid length");
        for(uint256 i = 0; i < proposalIds.length; i++) {
            governance.submitVote(proposalIds[i], optionBitMasks[i]);
        }
    }

    /**
    * @dev anyone can call to claim rewards for multiple epochs
    * @dev all eth will be sent back to rewardRecipient
    */
    function claimRewards(
        uint256 cycle,
        uint256 index,
        IERC20Ext[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32[] calldata merkleProof
    )
        external
        returns (uint256[] memory claimAmounts)
    {
        claimAmounts = rewardDistributor.claim(
            cycle, index, address(this), tokens, cumulativeAmounts, merkleProof
        );

        for(uint256 i = 0; i < tokens.length; i++) {
            uint256 bal = tokens[i] == ETH_TOKEN_ADDRESS ?
                address(this).balance : tokens[i].balanceOf(address(this));
            if (bal > 0) _transferToken(tokens[i], bal);
        }
    }

    function updateRewardRecipient(address payable _newRecipient)
        external onlyAdmin
    {
        require(_newRecipient != address(0), "invalid address");
        rewardRecipient = _newRecipient;
    }

    /**
    * @dev most likely unused, but put here for flexibility or in case a mistake in deployment 
    */
    function updateKyberContracts(
        IKyberGovernance _governance,
        IRewardsDistributor _rewardDistributor
    )
        external onlyAdmin
    {
        require(_governance != IKyberGovernance(0), "invalid kyber dao");
        require(_rewardDistributor != IRewardsDistributor(0), "invalid reward distributor");
        governance = _governance;
        rewardDistributor = _rewardDistributor;
    }

    /**
    * @dev allow withdraw funds of any tokens to rewardRecipient address
    */
    function withdrawFund(
        IERC20Ext[] calldata tokens,
        uint256[] calldata amounts
    ) external {
        require(tokens.length == amounts.length, "invalid length");
        for(uint256 i = 0; i < tokens.length; i++) {
            _transferToken(tokens[i], amounts[i]);
        }
    }

    function _transferToken(IERC20Ext token, uint256 amount) internal {
        if (token == ETH_TOKEN_ADDRESS) {
            (bool success, ) = rewardRecipient.call { value: amount }("");
            require(success, "transfer eth failed");
        } else {
            token.safeTransfer(rewardRecipient, amount);
        }
    }
}