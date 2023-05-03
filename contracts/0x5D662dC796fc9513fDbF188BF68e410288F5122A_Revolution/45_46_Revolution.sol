// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ERC1155Creator} from "./Manifold/ERC1155Creator.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ITokenEmitter} from "./ITokenEmitter.sol";
import {RevolutionStorageV1} from "./RevolutionInterfaces.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//TODO:
/*
1. get admin minting functionality working with manifold with delegetecall
2. build function to create a new mint for admins
3. build pricing structure
4. let people buy the mint
5. build queueing functionality
*/

contract Revolution is
    ReentrancyGuard,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    RevolutionStorageV1
{
    //TODO: test access control normally and across upgrading, make sure it still works in both cases
    
    address public constant revolutionTreasury =
        0x57dadF47646c7b4313AC9C6F71fAee1FB550391B; //collective safe
    uint16 public constant revolutionPercentFee = 500; //5%
    bytes32 public constant DROPPER_ROLE = keccak256("DROPPER_ROLE");

    //event for when a drop is created
    event DropCreated(
        address indexed tokenAddress,
        uint256 indexed dropId,
        string uri,
        uint256 dropEndTime,
        uint256 dropPrice,
        address creator
    );

    //event for when a purchase is made
    event DropPurchased(
        address indexed tokenAddress,
        uint256 indexed dropId,
        uint256 amount,
        address buyer
    );

    event RevolutionCreated(
        address indexed tokenAddress,
        address indexed daoAddress,
        DaoType daoType,
        uint256 daoSplit,
        uint256 governanceCreatorSplit
    );

    event GovernanceCreatorSplitChanged(
        uint16 oldSplit,
        uint16 newSplit
    );

    event DaoAddressChanged(
        address oldAddress,
        address newAddress,
        DaoType oldDaoType,
        DaoType newDaoType
    );

    event DaoSplitChanged(
        uint16 oldSplit,
        uint16 newSplit
    );

    function initialize(
        ERC1155Creator _tokenAddress,
        address _daoAddress,
        DaoType _daoType
    ) public initializer{
        __AccessControlEnumerable_init();

        tokenAddress = _tokenAddress;
        daoAddress = _daoAddress;
        daoType = _daoType;
        daoSplit = 5000;
        governanceCreatorSplit = 2000;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DROPPER_ROLE, msg.sender);

        emit RevolutionCreated(
            address(tokenAddress),
            daoAddress,
            daoType,
            daoSplit,
            governanceCreatorSplit
        );
    }

    //modifier for dropper role or admin role
    modifier onlyDropper() {
        require(
            hasRole(DROPPER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a dropper"
        );
        _;
    }

    // function callTokenContract(bytes memory _data)
    //     public
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    //     returns (bool success, bytes memory result)
    // {
    //     (success, result) = address(tokenAddress).delegatecall(_data);
    // }

    //function to create a new drop
    function createDrop(
        string memory uri,
        uint256 dropTime,
        uint256 dropPrice,
        address payable creator
    ) public onlyDropper returns (uint256) {
        require(bytes(uri).length > 0, "URI must not be empty");
        require(dropTime > 0, "Drop time must be greater than 0");
        require(creator != address(0x0), "Creator must not be 0x0");
        
        address[] memory receivers = new address[](1);
        receivers[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        string[] memory uris = new string[](1);
        uris[0] = uri;

        uint256 tokenId = tokenAddress.mintBaseNew(receivers, amounts, uris)[0];
        drops[tokenId] = Drop(
            dropTime + block.timestamp,
            dropPrice,
            creator,
            0
        );
        emit DropCreated(
            address(tokenAddress),
            tokenId,
            uri,
            dropTime + block.timestamp,
            dropPrice,
            creator
        );
        return tokenId;
    }

    //function to buy a drop
    function buyDrop(
        uint256 tokenId,
        uint256 amount,
        address to
    ) public nonReentrant payable {
        //require drop exists
        require(drops[tokenId].dropEndTime != 0, "Drop does not exist");
        require(
            msg.value == drops[tokenId].dropPrice * amount,
            "Incorrect amount sent"
        );
        //require current time to be less than drop time
        require(
            block.timestamp < drops[tokenId].dropEndTime,
            "Drop has already ended"
        );
        //require amount to be greater than 0
        require(amount > 0, "Amount must be greater than 0");

        if (to == address(0x0)) {
            to = msg.sender;
        }

        address[] memory receivers = new address[](1);
        receivers[0] = to;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        tokenAddress.mintBaseExisting(receivers, tokenIds, amounts);

        uint256 revolutionFee = (msg.value * revolutionPercentFee) / 10000;
        uint256 remainingAmount = msg.value - revolutionFee;
        uint256 daoAmount = (remainingAmount * daoSplit) / 10000;
        uint256 creatorAmount = remainingAmount - daoAmount;

        if (daoType == DaoType.REVOLUTION_VRGDA) {
            address[] memory vrgdaReceivers = new address[](2);
            vrgdaReceivers[0] = to;
            vrgdaReceivers[1] = drops[tokenId].creator;
            uint256[] memory vrgdaSplits = new uint256[](2);
            vrgdaSplits[0] = 100 - governanceCreatorSplit / 100;
            vrgdaSplits[1] = governanceCreatorSplit / 100;
            ITokenEmitter(daoAddress).buyToken{value: daoAmount}(
                vrgdaReceivers,
                vrgdaSplits
            );
        } else if (daoType == DaoType.SIMPLE_TREASURY) {
            (bool daoTransferSuccess, ) = daoAddress.call{value: daoAmount}("");
            require(daoTransferSuccess, "Transfer to DAO treasury failed.");
        }

        (bool revolutionTransferSuccess, ) = revolutionTreasury.call{value: revolutionFee}("");
        require(revolutionTransferSuccess, "Transfer to revolution treasury failed.");

        drops[tokenId].creator.transfer(creatorAmount);
        emit DropPurchased(address(tokenAddress), tokenId, amount, to);
    }

    function getDrop(uint256 tokenId) public view returns (Drop memory) {
        return drops[tokenId];
    }

    function getImplVersion() public pure returns (uint8) {
        return 1;
    }

    //function to set the dao address
    function setDaoAddress(address _daoAddress, DaoType _daoType)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit DaoAddressChanged(daoAddress, _daoAddress, daoType, _daoType);
        daoAddress = _daoAddress;
        daoType = _daoType;
    }

    //function to set dao split
    function setDaoSplit(uint16 _daoSplit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit DaoSplitChanged(daoSplit, _daoSplit);
        daoSplit = _daoSplit;
    }

    //function to set governance creator split
    function setGovernanceCreatorSplit(uint16 _governanceCreatorSplit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit GovernanceCreatorSplitChanged(
            governanceCreatorSplit,
            _governanceCreatorSplit
        );
        governanceCreatorSplit = _governanceCreatorSplit;
    }

    //function to add a new admin to the token contract
    function addTokenAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddress.approveAdmin(_admin);
    }

    //function to remove an admin from the token contract
    function removeTokenAdmin(address _admin)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress.revokeAdmin(_admin);
    }

    //function to transfer token ownership
    function transferTokenOwnership(address _newOwner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress.transferOwnership(_newOwner);
    }

    //function to send funds to an address
    function sendFunds(address payable _to, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _to.transfer(_amount);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}