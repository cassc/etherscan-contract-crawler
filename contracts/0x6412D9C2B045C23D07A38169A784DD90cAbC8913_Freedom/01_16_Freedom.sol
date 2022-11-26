// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Freedom is ERC721URIStorage, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string public FreedomURI;
    IERC20 public platformToken;
    uint256 public nowSenatorCount;
    uint256 public maxSenatorCount;
    uint256 public maxNFTGroupCount;
    uint256 public nftPrice;
    uint256 public platformTax;
    address private platformAddress;

    struct Group {
        address creator;
        uint256 status;
        uint256 adminInviteAward;
        uint256 userInviteAward;
        uint256 joinPrice;
        mapping (address => bool) adminPermissions;
    }

    struct Senator {
        bool isSenator;
        uint256 communityMemberCount;
    }

    struct Pledge {
        uint256 amount;
        uint256 time;
    }

    struct PledgeRecord {
        address user;
        uint256 beginTime;
        uint256 endTime;
        uint256 amount;
    }

    mapping (address => Senator) public senatorInfo;
    mapping (uint256 => Group) public groupInfo;
    mapping (address => PledgeRecord[]) public pledgeRecordInfo;
    mapping (uint256 => uint256[]) public increaseGroupHotInfo;
    mapping (uint256 => uint256) public ntfGroupInfo;

    Pledge[] public pledgeInfo;

    event LogReceived(address, uint);
    event LogFallback(address, uint);

    constructor() ERC721("Freedom", "Freedom") {
        maxSenatorCount = 233;
        nftPrice = 10000000000000000000;
        platformToken = IERC20(0x0D7483A69b4189cC95570Dd56d51Cb5F7b366517);
        FreedomURI = "https://web-nft-dapp-test.bljcoco.com/dapp/prod/NFT?tokenId=";
        platformTax = 200;
        maxNFTGroupCount = 100;
        platformAddress = 0x03C90abdaed9e4C777615caC3b1ad7ede28D0106;
    }


    // Override Base URI
    function _baseURI() internal view override returns (string memory) {
        return FreedomURI;
    }


    function setURI (string memory _uri) public onlyOwner {
        FreedomURI = _uri;
    }


    function setSenator(address _address, bool _bool) public onlyOwner {
        require(nowSenatorCount <= nowSenatorCount, "Exceeding quantity limit");
        senatorInfo[_address].isSenator = _bool;
        if (_bool) {
            nowSenatorCount = nowSenatorCount + 1;
        } else {
            nowSenatorCount = nowSenatorCount - 1;
        }
    }


    function setPlatformToken (IERC20 _token) public onlyOwner {
        platformToken = _token;
    }


    function setPlatformAddress (address _platformAddress) public onlyOwner {
        platformAddress = _platformAddress;
    }


    function setMaxNFTGroupCount (uint256 _maxNFTGroupCount) public onlyOwner {
        maxNFTGroupCount = _maxNFTGroupCount;
    }

    function setPlatformTax (uint256 _platformTax) public onlyOwner {
        platformTax = _platformTax;
    }


    function addPledge (uint256 _amount, uint256 _time) public onlyOwner {
        pledgeInfo.push(
            Pledge({
                amount: _amount,
                time: _time
            })
        );
    }


    function editPledge (uint256 _index, uint256 _amount, uint256 _time) public onlyOwner {
        pledgeInfo[_index].amount = _amount;
        pledgeInfo[_index].time = _time;
    }


    function userPledge (uint256 _index) public {
        platformToken.safeTransferFrom(msg.sender, address(this), pledgeInfo[_index].amount);

        pledgeRecordInfo[msg.sender].push(
            PledgeRecord({
                user: msg.sender,
                beginTime: block.timestamp,
                endTime: block.timestamp + pledgeInfo[_index].time,
                amount: pledgeInfo[_index].amount
            })
        );
    }


    function userRedeem (uint256 _recordIndex) public {
        uint _endTime = pledgeRecordInfo[msg.sender][_recordIndex].endTime;
        require(block.timestamp > _endTime);
        platformToken.safeTransfer(msg.sender, pledgeRecordInfo[msg.sender][_recordIndex].amount);
    }


    function mintNFT () public returns (uint256) {
        platformToken.safeTransferFrom(msg.sender, address(this), nftPrice);

        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        return newItemId;
    }


    function createGroup (uint256 _groupId, uint256 _adminInviteAward, uint256 _userInviteAward, uint256 _joinPrice, uint256 _nftID) public {
        uint256 _userNFTBalance = balanceOf(msg.sender);

        require(_userNFTBalance > 0, "The user has no Freedom NFT");
        require(groupInfo[_groupId].status == 0, "Already Existed");
        require(_adminInviteAward <= 1000 && _userInviteAward <= 1000, "Numerical errors");
        require(_joinPrice > 0, "The price can't be 0");

        require(ownerOf(_nftID) == msg.sender, "You are not the owner");
        require(ntfGroupInfo[_nftID] < maxNFTGroupCount, "The number of groups exceeds the upper limit");

        ntfGroupInfo[_nftID] = ntfGroupInfo[_nftID] + 1;
    
        groupInfo[_groupId].status = 1;
        groupInfo[_groupId].creator = msg.sender;
        groupInfo[_groupId].adminInviteAward = _adminInviteAward;
        groupInfo[_groupId].userInviteAward = _userInviteAward;
        groupInfo[_groupId].joinPrice = _joinPrice;
    }


    function editGroup (uint256 _groupId, uint256 _adminInviteAward, uint256 _userInviteAward, uint256 _joinPrice) public {
        require(groupInfo[_groupId].status == 1, "Group ID does not exist");
        require(groupInfo[_groupId].creator == msg.sender, "You are not the creator");
        require(_adminInviteAward <= 1000 && _userInviteAward <= 1000, "Numerical errors");
        require(_joinPrice > 0, "The price can't be 0");

        groupInfo[_groupId].adminInviteAward = _adminInviteAward;
        groupInfo[_groupId].userInviteAward = _userInviteAward;
        groupInfo[_groupId].joinPrice = _joinPrice;
    }


    function setGroupAdminPermissions (uint256 _groupId, address _address, bool _permissions) public {
        require(groupInfo[_groupId].creator == msg.sender, "You are not the creator");

        groupInfo[_groupId].adminPermissions[_address] = _permissions;
    }


    function userJoinGroup (uint256 _groupId, address _invite) public {
        require(groupInfo[_groupId].status == 1, "Group ID does not exist");

        platformToken.safeTransferFrom(msg.sender, address(this), groupInfo[_groupId].joinPrice);

        uint256 _platformAmount = groupInfo[_groupId].joinPrice * platformTax / 1000;
        platformToken.safeTransfer(platformAddress, _platformAmount);

        if (_invite != address(0)) {

            uint256 _inviteAward;

            if (groupInfo[_groupId].adminPermissions[_invite]) {
                _inviteAward = (groupInfo[_groupId].joinPrice - _platformAmount) * groupInfo[_groupId].adminInviteAward / 1000;
            } else {
                _inviteAward = (groupInfo[_groupId].joinPrice - _platformAmount) * groupInfo[_groupId].userInviteAward / 1000;
            }

            uint256 _creatorAward = groupInfo[_groupId].joinPrice - _platformAmount - _inviteAward;
    
            platformToken.safeTransfer(_invite, _inviteAward);
            platformToken.safeTransfer(groupInfo[_groupId].creator, _creatorAward);
        } else {
            uint256 _creatorAward = groupInfo[_groupId].joinPrice - _platformAmount;
            platformToken.safeTransfer(groupInfo[_groupId].creator, _creatorAward);
        }
    }


    function userInviteJoinGroup (uint256 _groupId, address[] memory _userAddressList) public {
        require(groupInfo[_groupId].status == 1, "Group ID does not exist");

        uint256 _userCount = _userAddressList.length;
        uint256 _totalJoinPrice = groupInfo[_groupId].joinPrice * _userCount;
        platformToken.safeTransferFrom(msg.sender, address(this),_totalJoinPrice);

        uint256 _platformAmount = _totalJoinPrice * platformTax / 1000;
        platformToken.safeTransfer(platformAddress, _platformAmount);

        uint256 _inviteAward;
        address _invite = msg.sender;

        if (groupInfo[_groupId].adminPermissions[_invite]) {
            _inviteAward = (_totalJoinPrice - _platformAmount) * groupInfo[_groupId].adminInviteAward / 1000;
        } else {
            _inviteAward = (_totalJoinPrice - _platformAmount) * groupInfo[_groupId].userInviteAward / 1000;
        }

        uint256 _creatorAward = _totalJoinPrice - _platformAmount - _inviteAward;

        platformToken.safeTransfer(_invite, _inviteAward);
        platformToken.safeTransfer(groupInfo[_groupId].creator, _creatorAward);
    }


    function increaseGroupHot (uint256 _groupId, uint256 _amount) public {
        platformToken.safeTransferFrom(msg.sender, address(this), _amount);
        increaseGroupHotInfo[_groupId].push(_amount);
    }


    function operation(uint256 _amount, address _to) public onlyOwner {
        platformToken.safeTransfer(_to, _amount);
    }


    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }


    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
}