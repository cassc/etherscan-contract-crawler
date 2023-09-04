// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface Mintable {
   function mint(address to, uint256 amount) external;
   function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

contract CyberLionzStaking is AccessControl {
    bytes32 public ADMIN_ROLE = keccak256("ADMIN");
    using SafeMath for uint256;

    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    uint256 constant SECONDS_PER_DAY = 24*60*60;
    address rewardsTokenAddress;
    
    struct CollectionInfo {
        address collectionAddress;
        uint256 rewardPerDay;
        uint256 totalAmountStaked;
    }

    mapping(address => mapping(address => uint[])) addressToStakedTokens;
    mapping(address => mapping(uint => address)) contractTokenIdToOwner;
    mapping(address => mapping(uint => uint)) contractTokenIdToStakedTimestamp;

    CollectionInfo[] public collectionInfo;

    constructor(address _rewardsToken) {
        rewardsTokenAddress = _rewardsToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function setAdminRole(address admin) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(ADMIN_ROLE, admin);
    }

    function stake(uint256 _collectionID, uint256 _tokenID) external {
        _stake( _collectionID, _tokenID);
    }

    function _stake(
        uint256 _collectionID,
        uint256 _tokenID
    ) internal {
        CollectionInfo storage collection = collectionInfo[_collectionID];
        
        // Track original owner of token about to be staked
        contractTokenIdToOwner[collection.collectionAddress][_tokenID] = msg.sender;
        // Track time token was staked
        contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID] = block.timestamp;
        // Add to the list of tokens staked for this particular owner and contract
        addressToStakedTokens[collection.collectionAddress][msg.sender].push(_tokenID);

        collection.totalAmountStaked += 1;

        // transfer token into the custody of the contract
        IERC721(collection.collectionAddress).transferFrom(msg.sender, address(this), _tokenID);
    }

    function batchStake(uint256 _collectionID, uint256[] memory _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            _stake(_collectionID, _tokenIDs[i]);
        }
    }

    function batchUnstake(uint256 _collectionID, uint256[] memory _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; ++i) {
            _unstake(_collectionID, _tokenIDs[i]);
        }
    }

    function unstake(uint256 _collectionID, uint256 _tokenID) external {
        _unstake(_collectionID, _tokenID);
    }

    function _unstake(
        uint256 _collectionID,
        uint256 _tokenID
    ) internal {
        CollectionInfo storage collection = collectionInfo[_collectionID];

        require(contractTokenIdToOwner[collection.collectionAddress][_tokenID] == msg.sender,
            "token is not staked or sender does not own it"
        );

        _claimReward(msg.sender, _collectionID, _tokenID);

        // remove token ID from list of user's staked tokens
        _removeElement(addressToStakedTokens[collection.collectionAddress][msg.sender], _tokenID);
        // remove record of NFT token owner address
        delete contractTokenIdToOwner[collection.collectionAddress][_tokenID];
        // remove record of when the token was staked
        delete contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID];

        collection.totalAmountStaked -= 1;

        IERC721(collection.collectionAddress).transferFrom(address(this), msg.sender, _tokenID);
        
    }

    function totalClaimableReward(address _userAddress, uint256 _collectionID) public view returns(uint256) {
        uint256 payableAmount = 0;
        address collectionAddress = collectionInfo[_collectionID].collectionAddress;
        for (uint256 i; i < addressToStakedTokens[collectionAddress][_userAddress].length; i++) {
            uint256 _tokenId = addressToStakedTokens[collectionAddress][_userAddress][i];
            payableAmount += claimableReward(_userAddress, _collectionID, _tokenId);
        }
        return payableAmount;
    }

    function claimableReward(address _userAddress, uint256 _collectionID, uint256 _tokenID) public view returns(uint256) {
        CollectionInfo storage collection = collectionInfo[_collectionID];

        // check to see if token is currently staked
        if(contractTokenIdToOwner[collection.collectionAddress][_tokenID] != _userAddress)
          return 0;

        uint timeStaked = contractTokenIdToStakedTimestamp[collection.collectionAddress][_tokenID];
        uint256 payableAmount = (block.timestamp - timeStaked)
            .div(SECONDS_PER_DAY)
            .mul(collection.rewardPerDay);
        return payableAmount;
    }

    function _claimReward(address _userAddress, uint256 _collectionID,uint256 _tokenID) internal {
        uint256 payableAmount = claimableReward(_userAddress, _collectionID,_tokenID);
        Mintable(rewardsTokenAddress).mint(msg.sender,payableAmount);
    }

    function setCollection(address _collectionAddress, uint256 _rewardPerDay) public onlyRole(ADMIN_ROLE) {

        collectionInfo.push(
            CollectionInfo({collectionAddress: _collectionAddress, rewardPerDay: _rewardPerDay, totalAmountStaked: 0})
        );
    }

    function updateCollection(
        uint256 _collectionID,
        address _collectionAddress,
        uint256 _rewardPerDay
    ) public onlyRole(ADMIN_ROLE)  {
        CollectionInfo storage collection = collectionInfo[_collectionID];
        collection.collectionAddress = _collectionAddress;
        collection.rewardPerDay = _rewardPerDay;
    }

    function getUserStakedTokens(address _userAddress, uint256 _collectionID) external view returns(uint256[] memory){
        CollectionInfo storage collection = collectionInfo[_collectionID];
        return addressToStakedTokens[collection.collectionAddress][_userAddress];
    }

    function getTotalStakedItemsCount(uint256 _collectionID) external view returns (uint256) {
        CollectionInfo storage collection = collectionInfo[_collectionID];
        return collection.totalAmountStaked;
    }

    function onERC721Received( address, address, uint256) public pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }

    function _removeElement(uint256[] storage _array, uint256 _element) internal {

        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

}