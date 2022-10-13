//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IMembershipFactory.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IBlacklist.sol";
import "./structs/MembershipStruct.sol";

import "./libraries/Errors.sol";

//DEV

/**
 * @title Membership Contract
 * @notice contract deployed 1:1 per User wanting a membership with Webacy
 * contains data and information for interacting within the suite of products onchain
 *
 */

contract Membership is IMembership, ReentrancyGuard {
    // Support multiple ERC20 tokens

    // Membership Information of a specific user
    mapping(string => MembershipStruct) private membershipInfoOfAddress;

    address private directoryAddress;

    /**
     * @dev membershipUpdated event
     * @param membershipContractAddress address of the membershipContract emitting event
     * @param user address of user associated with this membership
     * @param uid string identifier of user across dApp
     * @param membershipCreatedDate uint256 timestamp of the membership being created
     * @param membershipEndDate uint256 timestamp of the set time to expire membership
     * @param membershipId uint256 id of the type of membership purchased
     * @param updatesPerYear uint256 the number of updates a user may have within 1 year
     * @param collectionAddress address of NFT granting membership to a user
     *
     */
    event membershipUpdated(
        address membershipContractAddress,
        address user,
        string uid,
        uint256 membershipCreatedDate,
        uint256 membershipEndDate,
        uint256 membershipId,
        uint256 updatesPerYear,
        address collectionAddress
    );

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param uid string identifier of user across dApp
     * @param _directoryAddress address of protocol directory contract
     * @param _userAddress address of the user attached to this membership contract
     * @param _membershipStartDate uint256 beginning timestamp of the membership
     * @param _membershipEndedDate uint256 expiry timestamp of the membership
     * @param _membershipId uint256 id of the type of membership purchased
     * @param updatesPerYear uint256 number of times within a year the membership can be updated
     * @param _membershipPayedAmount uint256 cost of membership initally
     * @param nftCollection address of asset for granting membership
     *
     */
    constructor(
        string memory uid,
        address _directoryAddress,
        address _userAddress,
        uint256 _membershipStartDate,
        uint256 _membershipEndedDate,
        uint256 _membershipId,
        uint256 updatesPerYear,
        uint256 _membershipPayedAmount,
        address nftCollection
    ) {
        directoryAddress = _directoryAddress;
        address IMemberAddress = IProtocolDirectory(_directoryAddress)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(_userAddress) == false)) {
            IMember(IMemberAddress).createMember(uid, _userAddress);
        }

        MembershipStruct memory _membership = MembershipStruct(
            _userAddress,
            _membershipStartDate,
            _membershipEndedDate,
            _membershipPayedAmount,
            true,
            _membershipId,
            updatesPerYear,
            nftCollection,
            uid
        );
        membershipInfoOfAddress[uid] = _membership;
    }

    /**
     * @notice Function to return membership information of the user
     * @param _uid string identifier of user across dApp
     * @return MembershipStruct containing information of the specific user's membership
     *
     */
    function getMembership(string memory _uid)
        external
        view
        returns (MembershipStruct memory)
    {
        return membershipInfoOfAddress[_uid];
    }

    /**
     * @dev Function to check of membership is active for the user
     * @param _uid string identifier of user across dApp
     * @return bool boolean representing if the membership has expired
     *
     */
    function checkIfMembershipActive(string memory _uid)
        public
        view
        returns (bool)
    {
        return membershipInfoOfAddress[_uid].membershipEnded > block.timestamp;
    }

    /**
     * @dev renewmembership Function to renew membership of the user
     * @param _uid string identifier of the user renewing membership
     *
     *
     */
    function renewMembership(string memory _uid) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(_membership.membershipId);

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.payedAmount = msg.value;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @dev renewmembershipNFT - Function to renew membership for users that have NFTs
     * @param _contractAddress address of nft to approve renewing
     * @param _NFTType string type of NFT i.e. ERC20 | ERC1155 | ERC721
     * @param tokenId uint256 tokenId being protected
     * @param _uid string identifier of the user renewing membership
     *
     */
    function renewMembershipNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMemberAddress = IProtocolDirectory(directoryAddress)
            .getMemberContract();
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        IMember(IMemberAddress).checkIfWalletHasNFT(
            _contractAddress,
            _NFTType,
            tokenId,
            msg.sender
        );
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(_membership.membershipId);

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.payedAmount = msg.value;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @dev Function to top up updates
     * @param _uid string identifier of the user across the dApp
     *
     */
    function topUpUpdates(string memory _uid) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        uint256 _updateCost = IMembershipFactory(IMembershipFactoryAddress)
            .getUpdatesPerYearCost();

        if (msg.value < _updateCost) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.updatesPerYear = _membership.updatesPerYear + 1;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @notice changeMembershipPlan
     * Ability to change membership plan for a member given a membership ID and member UID.
     * It is a payable function given the membership cost for the membership plan.
     *
     * @param membershipId uint256 id of membership plan changing to
     * @param _uid string identifier of the user
     */
    function changeMembershipPlan(uint256 membershipId, string memory _uid)
        external
        payable
        nonReentrant
    {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(membershipId);
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];

        _membership.membershipId = _membershipPlan.membershipId;
        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;
        _membership.payedAmount = msg.value;

        IMembershipFactory(IMembershipFactoryAddress).setUserForMembershipPlan(
            _uid,
            _membershipPlan.membershipId
        );

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @notice changeMembershipPlanNFT - Function to change membership plan to an NFT based plan
     * @param membershipId uint256 id of the membershipPlan changing to
     * @param _contractAddress address of the NFT granting the membership
     * @param _NFTType string type of NFT i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the nft to verify ownership
     * @param _uid string identifier of the user across the dApp
     *
     */
    function changeMembershipPlanNFT(
        uint256 membershipId,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMemberAddress = IProtocolDirectory(directoryAddress)
            .getMemberContract();
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        IMember(IMemberAddress).checkIfWalletHasNFT(
            _contractAddress,
            _NFTType,
            tokenId,
            msg.sender
        );
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(membershipId);
        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];

        _membership.membershipId = _membershipPlan.membershipId;
        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;
        _membership.payedAmount = msg.value;

        IMembershipFactory(IMembershipFactoryAddress).setUserForMembershipPlan(
            _uid,
            _membershipPlan.membershipId
        );

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
    }

    /**
     * @notice redeemUpdate
     * @param _uid string identifier of the user across the dApp
     *
     * Function to claim that a membership has been updated
     */
    function redeemUpdate(string memory _uid) external {
        checkIfMembershipActive(_uid);
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        _membership.updatesPerYear = _membership.updatesPerYear - 1;

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }
}