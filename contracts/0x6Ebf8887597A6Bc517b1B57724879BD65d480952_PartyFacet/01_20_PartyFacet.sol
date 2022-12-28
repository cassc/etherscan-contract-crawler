// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPartyFacet} from "../interfaces/IPartyFacet.sol";
import {IERC20} from "../interfaces/IERC20.sol";

import {LibParty} from "../libraries/LibParty.sol";
import {LibSignatures} from "../libraries/LibSignatures.sol";
import {Modifiers, PartyInfo} from "../libraries/LibAppStorage.sol";

/// "Party manager is not kickable"
error OwnerNotKickable();
/// "Non-member user is not kickable"
error UserNotKickable();
/// "Manager user is not kickable. Need to remove role first"
error ManagerNotKickable();
/// "User needs invitation to join private party"
error NeedsInvitation();

/**
 * @title PartyFacet
 * @author PartyFinance
 * @notice Facet that contains the main actions to interact with a Party
 */
contract PartyFacet is Modifiers, IPartyFacet, IERC20 {
    /***************
    PARTY STATE GETTER
    ***************/
    // @inheritdoc IERC20
    function name() external view override returns (string memory) {
        return s.name;
    }

    // @inheritdoc IERC20
    function symbol() external view override returns (string memory) {
        return s.symbol;
    }

    // @inheritdoc IERC20
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    // @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        return s.totalSupply;
    }

    // @inheritdoc IERC20
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return s.balances[account];
    }

    // @inheritdoc IPartyState
    function denominationAsset() external view override returns (address) {
        return s.denominationAsset;
    }

    // @inheritdoc IPartyState
    function creator() external view override returns (address) {
        return s.creator;
    }

    // @inheritdoc IPartyState
    function members(address account) external view override returns (bool) {
        return s.members[account];
    }

    // @inheritdoc IPartyState
    function managers(address account) external view override returns (bool) {
        return s.managers[account];
    }

    // @inheritdoc IPartyState
    function getTokens() external view override returns (address[] memory) {
        return s.tokens;
    }

    // @inheritdoc IPartyState
    function partyInfo() external view override returns (PartyInfo memory) {
        return s.partyInfo;
    }

    // @inheritdoc IPartyState
    function closed() external view override returns (bool) {
        return s.closed;
    }

    /***************
    ACCESS ACTIONS
    ***************/
    // @inheritdoc IPartyCreatorActions
    function handleManager(address manager, bool setManager) external override {
        if (s.creator == address(0)) {
            // Patch for Facet upgrade
            require(s.managers[msg.sender], "Only Party Managers allowed");
            /// @dev Previously, parties didn't have the `creator` state, so for those parties the state will be zero address.
            s.creator = msg.sender;
        }
        require(s.creator == msg.sender, "Only Party Creator allowed");
        s.managers[manager] = setManager;
        // Emit Party managers change event
        emit PartyManagersChange(manager, setManager);
    }

    /***************
    PARTY ACTIONS
    ***************/
    // @inheritdoc IPartyActions
    function joinParty(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override notMember isAlive {
        // Handle request for private parties
        if (!s.partyInfo.isPublic) {
            if (!s.acceptedRequests[user]) {
                revert NeedsInvitation();
            }
            delete s.acceptedRequests[user];
        }

        // Add user as member
        s.members[user] = true;

        // Deposit, collect fees and mint party tokens
        (uint256 fee, uint256 mintedPT) = LibParty.mintPartyTokens(
            user,
            amount,
            allocation,
            approval
        );

        // Emit Join event
        emit Join(user, s.denominationAsset, amount, fee, mintedPT);
    }

    // @inheritdoc IPartyMemberActions
    function deposit(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override isAlive {
        require(s.members[user], "Only Party Members allowed");
        // Deposit, collect fees and mint party tokens
        (uint256 fee, uint256 mintedPT) = LibParty.mintPartyTokens(
            user,
            amount,
            allocation,
            approval
        );
        // Emit Deposit event
        emit Deposit(user, s.denominationAsset, amount, fee, mintedPT);
    }

    // @inheritdoc IPartyMemberActions
    function withdraw(
        uint256 amountPT,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyMember {
        // Withdraw, collect fees and burn party tokens
        LibParty.redeemPartyTokens(
            amountPT,
            msg.sender,
            allocation,
            approval,
            liquidate
        );
        // Emit Withdraw event
        emit Withdraw(msg.sender, amountPT);
    }

    // @inheritdoc IPartyManagerActions
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override onlyManager {
        // Swap token
        (uint256 soldAmount, uint256 boughtAmount, uint256 fee) = LibParty
            .swapToken(allocation, approval);

        // Emit SwapToken event
        emit SwapToken(
            msg.sender,
            address(allocation.sellTokens[0]),
            address(allocation.buyTokens[0]),
            soldAmount,
            boughtAmount,
            fee
        );
    }

    // @inheritdoc IPartyManagerActions
    function kickMember(
        address kickingMember,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyManager {
        if (kickingMember == msg.sender) revert OwnerNotKickable();
        if (!s.members[kickingMember]) revert UserNotKickable();
        if (s.managers[kickingMember]) revert ManagerNotKickable();
        // Get total PT from kicking member
        uint256 kickingMemberPT = s.balances[kickingMember];
        LibParty.redeemPartyTokens(
            kickingMemberPT,
            kickingMember,
            allocation,
            approval,
            liquidate
        );
        // Remove user as a member
        delete s.members[kickingMember];
        // Emit Kick event
        emit Kick(msg.sender, kickingMember, kickingMemberPT);
    }

    // @inheritdoc IPartyMemberActions
    function leaveParty(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyMember {
        // Get total PT from member
        uint256 leavingMemberPT = s.balances[msg.sender];
        LibParty.redeemPartyTokens(
            leavingMemberPT,
            msg.sender,
            allocation,
            approval,
            liquidate
        );
        // Remove user as a member
        delete s.members[msg.sender];
        // Emit Leave event
        emit Leave(msg.sender, leavingMemberPT);
    }

    // @inheritdoc IPartyCreatorActions
    function closeParty() external override onlyCreator isAlive {
        s.closed = true;
        // Emit Close event
        emit Close(msg.sender, s.totalSupply);
    }

    // @inheritdoc IPartyCreatorActions
    function editPartyInfo(
        PartyInfo memory _partyInfo
    ) external override onlyCreator {
        s.partyInfo = _partyInfo;
        emit PartyInfoEdit(
            _partyInfo.name,
            _partyInfo.bio,
            _partyInfo.img,
            _partyInfo.model,
            _partyInfo.purpose,
            _partyInfo.isPublic,
            _partyInfo.minDeposit,
            _partyInfo.maxDeposit
        );
    }
}