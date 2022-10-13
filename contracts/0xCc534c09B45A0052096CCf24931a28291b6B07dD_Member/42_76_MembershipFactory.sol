//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Membership.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/IProtocolDirectory.sol";
import "../interfaces/IWhitelist.sol";
import "../structs/MembershipPlansStruct.sol";
import "../libraries/Errors.sol";

//DEV
//

/**
 * @title MembershipFactory
 * This contract is responsible for deploying Membership contracts
 * on behalf of users within the ecosystem. This contract also contains
 * information to keep track of deployed contracts and versions/ status
 *
 */
contract MembershipFactory is
    IMembershipFactory,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev storing all addresses of membership plans
    address[] private membershipPlanAddresses;

    /// @dev Directory contract address
    address private directoryContract;

    /// @dev Variable to provide membershipId for user
    uint256 private membershipId;

    /// @dev Fixed cost for updatesPerYear
    uint256 private updatesPerYearCost;

    /// @dev Storing all membership factory states
    Membership[] private memberships;

    /// @dev storing all membership plans
    membershipPlan[] private membershipPlans;

    /// @dev  Mapping specific user to a membership plan id ; each user can have only one membership plan
    mapping(string => uint256) private UserToMembershipPlan;

    /// @dev Mapping specific plan to a membershipID
    mapping(uint256 => membershipPlan) private membershipIdtoPlan;

    /// @dev Mapping user to factory address of membership
    mapping(string => address) private UserToMembershipContract;

    /**
     * @dev event MembershipContractCreated
     *
     * @param membershipContractAddress address of the deployed membership contract
     * @param user address of the user the membership belongs to
     * @param uid string identifier of the user across the dApp
     * @param membershipCreatedDate uint256 timestamp of when the contract was deployed
     * @param membershipEndDate uint256 timestamp of when the membership expires
     * @param membershipId uint256 identifier of the specific membership the user got
     * @param updatesPerYear uint256 how many updates the user can use in a year
     * @param collectionAddress address of the nft membership contract if any or address(0)
     *
     */
    event MembershipContractCreated(
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
     * @param _directoryContract address of the protocol directory
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        directoryContract = _directoryContract;
        membershipId = 0;
        updatesPerYearCost = 3e17;
    }

    /**
     * @dev Function to return users membership contract address
     * @param _uid string identifier of a user across the dApp
     * @return address of the membership contract if exists for the _uid
     *
     */
    function getUserMembershipAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserToMembershipContract[_uid];
    }

    /**
     * @dev Function to createMembership by deploying membership contract for a specific member
     * @param uid string identifier of a user across the dApp
     * @param _membershipId uint256 id of the chosen membership plan
     * @param _walletAddress address of the user creating the membership
     *
     */
    function createMembership(
        string calldata uid,
        uint256 _membershipId,
        address _walletAddress
    ) external payable nonReentrant {
        membershipPlan memory _membershipPlan = membershipIdtoPlan[
            _membershipId
        ];
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        address _whitelistaddress = IProtocolDirectory(directoryContract)
            .getWhitelistContract();

        uint256 _createdDate = block.timestamp;
        uint256 _endedDate = block.timestamp +
            _membershipPlan.membershipDuration;
        bool _whitelistStatus = IWhitelist(_whitelistaddress)
            .checkIfAddressIsWhitelisted(_walletAddress);
        uint256 _updatesPerYear = _membershipPlan.updatesPerYear;
        if (_whitelistStatus == true) {
            _endedDate =
                block.timestamp +
                IWhitelist(_whitelistaddress).getWhitelistDuration();
            _updatesPerYear = IWhitelist(_whitelistaddress)
                .getWhitelistUpdatesPerYear();
        } else {
            if (msg.value != _membershipPlan.costOfMembership) {
                revert(Errors.MF_NEED_MORE_DOUGH);
            }
        }

        if (
            (IMember(IMemberAddress).checkIfUIDExists(_walletAddress) == false)
        ) {
            IMember(IMemberAddress).createMember(uid, _walletAddress);
        }
        if (UserToMembershipContract[uid] != address(0)) {
            revert(Errors.MF_HAS_MEMBERSHIP_CONTRACT);
        }
        if (!_membershipPlan.active) {
            revert(Errors.MF_INACTIVE_PLAN);
        }

        Membership _membership = new Membership(
            uid,
            directoryContract,
            _walletAddress,
            _createdDate,
            _endedDate,
            _membershipPlan.membershipId,
            _updatesPerYear,
            msg.value,
            _membershipPlan.nftCollection
        );
        memberships.push(_membership);
        UserToMembershipPlan[uid] = membershipId;
        UserToMembershipContract[uid] = address(_membership);
        membershipPlanAddresses.push(address(_membership));

        IMember(IMemberAddress).setIMembershipAddress(
            uid,
            address(_membership)
        );

        emit MembershipContractCreated(
            address(_membership),
            _walletAddress,
            uid,
            _createdDate,
            _endedDate,
            _membershipId,
            _updatesPerYear,
            address(0)
        );
        if (_whitelistStatus == false) {
            payable(IProtocolDirectory(directoryContract).getTransferPool())
                .transfer(msg.value);
        }
    }

    /**
     * @dev Function to create Membership for a member with supporting NFTs
     * @param uid string identifier of the user across the dApp
     * @param _contractAddress address of the NFT granting membership
     * @param _NFTType string type of NFT for granting membership i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the owned nft to verify ownership
     * @param _walletAddress address of the user creating a membership with their nft
     *
     */
    function createMembershipSupportingNFT(
        string calldata uid,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address _walletAddress
    ) external payable nonReentrant {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();

        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(uid, _walletAddress);
        }

        if (UserToMembershipContract[uid] != address(0)) {
            revert(Errors.MF_HAS_MEMBERSHIP_CONTRACT);
        }

        uint256 _amount = msg.value;

        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].nftCollection == _contractAddress) {
                IMember(IMemberAddress).checkIfWalletHasNFT(
                    _contractAddress,
                    _NFTType,
                    tokenId,
                    _walletAddress
                );

                membershipPlan memory _membershipPlan = membershipIdtoPlan[
                    membershipPlans[i].membershipId
                ];
                if (!_membershipPlan.active) {
                    revert(Errors.MF_INACTIVE_PLAN);
                }
                if (_amount != _membershipPlan.costOfMembership) {
                    revert(Errors.MF_NEED_MORE_DOUGH);
                }

                uint256 _createdDate = block.timestamp;
                uint256 _endedDate = block.timestamp +
                    _membershipPlan.membershipDuration;

                Membership _membership = new Membership(
                    uid,
                    directoryContract,
                    _walletAddress,
                    _createdDate,
                    _endedDate,
                    _membershipPlan.membershipId,
                    _membershipPlan.updatesPerYear,
                    _amount,
                    _membershipPlan.nftCollection
                );
                memberships.push(_membership);
                UserToMembershipPlan[uid] = _membershipPlan.membershipId;
                UserToMembershipContract[uid] = address(_membership);
                membershipPlanAddresses.push(address(_membership));
                payable(IProtocolDirectory(directoryContract).getTransferPool())
                    .transfer(_amount);
                emit MembershipContractCreated(
                    address(_membership),
                    _walletAddress,
                    uid,
                    _createdDate,
                    _endedDate,
                    _membershipPlan.membershipId,
                    _membershipPlan.updatesPerYear,
                    _contractAddress
                );
                break;
            }
        }
    }

    /**
     * @dev Function to create a membership plan with an NFT or without
     * If no collection provide address(0) for _collection
     * @param _duration uint256 value of how long the membership is valid
     * @param _updatesPerYear uint256 how many times in a year can the membership be updated
     * @param _cost uint256 cost in wei of the membership
     * @param _collection address of the NFT to create a membershipPlan or address(0)
     *
     */
    function createMembershipPlan(
        uint256 _duration,
        uint256 _updatesPerYear,
        uint256 _cost,
        address _collection
    ) external onlyOwner {
        if (_collection == address(0)) {
            membershipPlan memory _membershipPlan = membershipPlan(
                _duration,
                _cost,
                _updatesPerYear,
                address(0),
                ++membershipId,
                true
            );
            membershipIdtoPlan[membershipId] = _membershipPlan;
            membershipPlans.push(_membershipPlan);
        } else {
            membershipPlan memory _membershipPlan = membershipPlan(
                _duration,
                _cost,
                _updatesPerYear,
                _collection,
                ++membershipId,
                true
            );
            membershipIdtoPlan[membershipId] = _membershipPlan;
            membershipPlans.push(_membershipPlan);
        }
    }

    /**
     * @dev function to make membership plan active/inactive
     * @param _active bool representing if the membershipPlan can be used to create new contracts
     * @param _membershipId uint256 id of the membershipPlan to activate
     *
     */
    function setMembershipPlanActive(bool _active, uint256 _membershipId)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].membershipId == _membershipId) {
                membershipPlans[i].active = _active;
            }
        }
    }

    /**
     * @dev function to get active/inactive status of membershipplan
     * @param _membershipId uint256 id of a membershipPlan
     * @return isActive a bool describing its status
     *
     */
    function getMembershipPlanActive(uint256 _membershipId)
        external
        view
        returns (bool isActive)
    {
        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].membershipId == _membershipId) {
                isActive = membershipPlans[i].active;
            }
        }
    }

    /**
     * @dev function to get all membership plans
     * @return membershipPlan[] a list of all membershipPlans on the contract
     *
     */
    function getAllMembershipPlans()
        external
        view
        returns (membershipPlan[] memory)
    {
        return membershipPlans;
    }

    /**
     * @dev function to getCostOfMembershipPlan
     * @param _membershipId uint256 id of specific plan to retrieve
     * @return membershipPlan struct
     *
     */
    function getMembershipPlan(uint256 _membershipId)
        external
        view
        returns (membershipPlan memory)
    {
        return membershipIdtoPlan[_membershipId];
    }

    /**
     * @dev Function to get updates per year cost
     * @return uint256 cost of updating membership in wei
     *
     */
    function getUpdatesPerYearCost() external view returns (uint256) {
        return updatesPerYearCost;
    }

    /**
     * @dev Function to set new updates per year cost
     * @param _newCost uint256 in wei, how much updating the membership will be
     *
     */
    function setUpdatesPerYearCost(uint256 _newCost) external onlyOwner {
        updatesPerYearCost = _newCost;
    }

    /**
     * @dev Function to set new membership plan for user
     * @param _uid string identifing the user across the dApp
     * @param _membershipId uint256 id of the membership for the user
     *
     */
    function setUserForMembershipPlan(string memory _uid, uint256 _membershipId)
        external
    {
        UserToMembershipPlan[_uid] = _membershipId;
    }

    /**
     * @dev Function to transfer eth to specific pool
     *
     */
    function transferToPool() external payable {
        address transferPoolAddress = IProtocolDirectory(directoryContract)
            .getTransferPool();
        payable(transferPoolAddress).transfer(msg.value);
    }
}