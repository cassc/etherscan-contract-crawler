// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { SafeMath } from './libraries/SafeMath.sol';

import { IERC20TokenGovernedProxy } from './interfaces/IERC20TokenGovernedProxy.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IGovernedERC20 } from './interfaces/IGovernedERC20.sol';
import { IOwnedERC20 } from './interfaces/IOwnedERC20.sol';
import { IERC20Token } from './interfaces/IERC20Token.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ERC20TokenGovernedProxy is IERC20TokenGovernedProxy, IGovernedProxy, NonReentrant {
    using SafeMath for uint256;

    IGovernedContract public impl;
    IGovernedContract public implementation; // only used for block explorers to detect contract as a proxy

    IGovernedProxy public spork_proxy;

    mapping(address => IGovernedContract) public upgrade_proposals;

    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(msg.sender == address(impl), 'Only calls from impl are allowed!');
        _;
    }

    constructor(IGovernedContract _impl) public {
        impl = _impl;
        implementation = _impl; // to allow block explorers to find the impl contract
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external onlyImpl {
        emit AirdropRewardsClaimed(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce,
            airdropServiceSignature
        );
    }

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) external onlyImpl {
        emit Transfer(from, to, value);
    }

    function emitApproval(
        address owner,
        address spender,
        uint256 value
    ) external onlyImpl {
        emit Approval(owner, spender, value);
    }

    // ERC20 standard functions
    //
    function name() external view returns (string memory _name) {
        _name = IERC20Token(address(uint160(address(impl)))).name();
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = IERC20Token(address(uint160(address(impl)))).symbol();
    }

    function decimals() external view returns (uint256 _decimals) {
        _decimals = IERC20Token(address(uint160(address(impl)))).decimals();
    }

    function balanceOf(address account) external view returns (uint256 _balance) {
        _balance = IGovernedERC20(address(uint160(address(impl)))).balanceOf(account);
    }

    function allowance(address owner, address spender) external view returns (uint256 _allowance) {
        _allowance = IGovernedERC20(address(uint160(address(impl)))).allowance(owner, spender);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = IGovernedERC20(address(uint160(address(impl)))).totalSupply();
    }

    function approve(address spender, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).approve(
            msg.sender,
            spender,
            value
        );
        emit Approval(msg.sender, spender, value);
    }

    function transfer(address to, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transferFrom(
            msg.sender,
            from,
            to,
            value
        );
        emit Transfer(from, to, value);
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            from,
            msg.sender
        );
        emit Approval(from, msg.sender, newApproveAmount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).increaseAllowance(
            msg.sender,
            spender,
            addedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result)
    {
        result = IGovernedERC20(address(uint160(address(impl)))).decreaseAllowance(
            msg.sender,
            spender,
            subtractedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    // OwnedERC20 functions
    //
    function mint(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).burn(recipient, amount);
    }

    // Governance functions
    //
    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImpl != impl, 'Already active!');
        require(_newImpl.proxy() == address(this), 'Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImpl,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImpl;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImpl, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(new_impl != impl, 'Already active!'); // in case it changes in the flight
        require(address(new_impl) != address(0), 'Not registered!');
        require(_proposal.isAccepted(), 'Not accepted!');

        IGovernedContract old_impl = impl;

        new_impl.migrate(old_impl);
        impl = new_impl;
        implementation = new_impl;
        old_impl.destroy(new_impl);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(new_impl, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl)
    {
        new_impl = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(address(new_impl) != address(0), 'Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function transferFrom(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function increaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function decreaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function transfer(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function approve(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'ERC20TokenGovernedProxy: delegatecall cannot be used'
            );
        }

        IGovernedContract impl_m = impl;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), impl_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}