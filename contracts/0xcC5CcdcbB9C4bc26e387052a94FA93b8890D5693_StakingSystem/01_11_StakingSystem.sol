// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IMintableERC20 is IERC20  {
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
}

contract StakingSystem is Ownable, ERC721Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public erc721Token;
    IMintableERC20 public erc20Token;

    // the timeframe for which rewards compound
    uint256 public epochTime = 1 weeks;

    // yield rate per epoch for each rarity
    uint256 public rowdyEpochYield = 1 ether;
    uint256 public ragingEpochYield = 3 ether;
    uint256 public royalEpochYield = 6 ether;

    // locks the yield amounts and epoch timeframe
    bool public locked = false;

    // signer addresses
    address private rowdySigner;
    address private ragingSigner;
    address private royalSigner;

    // staking struct
    // tracks a staked token's attributes
    struct Stake {
        uint8 rarity;
        uint16 tokenId;
        uint48 time;
        address owner;
    }

    // mapping points the token id to its staking attributes
    mapping(uint16 => Stake) stakes;
    // mapping points owner's address to staked token ids
    mapping(address => EnumerableSet.UintSet) stakers;

    // events
    event TokenStaked(uint16 tokenId, address owner);
    event TokenUnstaked(uint16 tokenId, address owner, uint256 earnings);

    // constructor
    constructor(address _erc721Address, address _erc20Address) {    
        erc721Token = IERC721(_erc721Address);
        erc20Token = IMintableERC20(_erc20Address);
    }

    // sets the genesis ERC721 contract address
    function setERC721Contract(address _erc721Address) external onlyOwner {
        erc721Token = IERC721(_erc721Address);
    }

    // sets the rewards token contract address
    function setERC20Contract(address _erc20Address) external onlyOwner {
        erc20Token = IMintableERC20(_erc20Address);
    }

    // sets the epoch time period
    function setEpoch(uint256 _epochTime) external onlyOwner {
        require((!locked), "the staking contract is locked");
        epochTime = _epochTime;
    }

    // sets the yield amounts for rowdy, raging, and royal
    function setYields(uint256 rowdy, uint256 raging, uint256 royal) external onlyOwner{
        require((!locked), "the staking contract is locked");
        rowdyEpochYield = rowdy * 1 ether;
        ragingEpochYield = raging * 1 ether;
        royalEpochYield = royal * 1 ether;
    }

    // sets the signer addresses for rarity verification
    function setSigners(address[] calldata signers) public onlyOwner{
        rowdySigner = signers[0];
        ragingSigner = signers[1];
        royalSigner = signers[2];
    }

    // returns an array of all the tokens that are staked for the address
    function getStakedTokens(address _owner) external view returns (uint16[] memory) {
        uint256 stakedTokensLength = stakers[_owner].length();
        uint16[] memory tokenIds = new uint16[](stakedTokensLength);

        for (uint16 i = 0; i < stakedTokensLength; i++) {
            tokenIds[i] = uint16(stakers[_owner].at(i));
        }
        return tokenIds;
    }

    // returns the timestamp for when a token id was last claimed
    function getLastClaimedTime(uint16 _tokenId) external view returns(uint48) {
        return stakes[_tokenId].time;
    }

    // returns the timestamp for when a token id was last claimed
    function getTimeUntilNextReward(uint16 _tokenId) external view returns(uint256) {
        uint256 stakedSeconds = block.timestamp - stakes[_tokenId].time;
        uint256 epochsStaked = stakedSeconds / epochTime;
        return epochTime - (stakedSeconds - (epochsStaked * epochTime));
    }

    // returns the unclaimed rewards for a token id
    function currentRewardsOf(uint16 _tokenId) public view returns (uint256) {
        require(stakes[_tokenId].tokenId != 0, "the token id is not staked");
        uint256 stakedSeconds = block.timestamp - stakes[_tokenId].time;
        uint256 epochsStaked = stakedSeconds / epochTime;
        uint256 reward = epochsStaked;

        if(stakes[_tokenId].rarity == 0) {
            reward *= rowdyEpochYield;
        } else if(stakes[_tokenId].rarity == 1) {
            reward *= ragingEpochYield;
        } else if(stakes[_tokenId].rarity == 2) {
            reward *= royalEpochYield;
        }

        return reward;
    }

    // stakes a set of tokens
    function stakeTokens(address _owner, uint16[] calldata _tokenIds, bytes32[] memory _hashes, bytes[] memory _signatures) external {
        require((_owner == msg.sender), "only owners approved");
        
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            require(erc721Token.ownerOf(_tokenIds[i]) == msg.sender, "only owners approved");
            _stake(_owner, _tokenIds[i], _hashes[i], _signatures[i]);
            erc721Token.transferFrom(msg.sender, address(this), _tokenIds[i]);
        }
    }

    // stake the token
    function _stake(address _owner, uint16 _tokenId, bytes32 _hash, bytes memory _signature) internal {
        address signer = recoverSigner(_hash, _signature);
        uint8 rarity = 0;

        if(signer == rowdySigner){
            rarity = 0;
        } else if(signer == ragingSigner){
            rarity = 1;
        } else if(signer == royalSigner){
            rarity = 2;
        }

        stakers[_owner].add(_tokenId);
        stakes[_tokenId] = Stake(rarity, _tokenId, (uint48(block.timestamp)), _owner);
        emit TokenStaked(_tokenId, _owner);
    }

    // claim and unstake
    function claimRewardsAndUnstake(uint16[] calldata _tokenIds, bool _unstake) external {
        uint256 reward;
        uint48 time = uint48(block.timestamp);

        for (uint8 i = 0; i < _tokenIds.length; i++) {
            reward += _claimRewardsAndUnstake(_tokenIds[i], _unstake, time);
        }
        if (reward != 0) {
            erc20Token.mint(msg.sender, reward);
        }
    }

    // claims the rewards and unstakes if wanted
    function _claimRewardsAndUnstake(uint16 _tokenId, bool _unstake, uint48 _time) internal returns (uint256 reward) {
        Stake memory stake = stakes[_tokenId];
        require(stake.owner == msg.sender, "only owners can unstake");
        reward = currentRewardsOf(_tokenId);

        if (_unstake) {
            delete stakes[_tokenId];
            stakers[msg.sender].remove(_tokenId);
            erc721Token.transferFrom(address(this), msg.sender, _tokenId);
            emit TokenUnstaked(_tokenId, msg.sender, reward);
        } 
        else {
            stakes[_tokenId].time = _time;
        }
    }

    // unstakes the token id without claiming rewards
    function unstakeWithoutReward(uint16 _tokenId) external {
        Stake memory stake = stakes[_tokenId];
        require(stake.owner == msg.sender, "only owners can unstake");
        delete stakes[_tokenId];
        stakers[msg.sender].remove(_tokenId);
        erc721Token.transferFrom(address(this), msg.sender, _tokenId);
        emit TokenUnstaked(_tokenId, msg.sender, 0);
    }

    // recovers the signer's address
    function recoverSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ECDSA.recover(messageDigest, _signature);
    }

    // locks the contract so that the yield amounts and epoch time cannot be altered
    function lockContract() external onlyOwner {
        locked = true;
    }
}