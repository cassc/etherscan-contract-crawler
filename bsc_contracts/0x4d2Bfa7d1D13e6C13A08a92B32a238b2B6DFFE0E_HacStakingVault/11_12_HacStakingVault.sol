// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./RewardsToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HacStakingVault is IERC721Receiver, Ownable, ReentrancyGuard {

    struct vault {
        IERC721 nft;
        RewardsToken token;
        string name;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
        uint256 stakedTimestamp;
    }
    
    // Staker info
    struct Staker {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
        uint256 timeOfLastUpdate;
    }


    vault[] public VaultInfo;

    mapping(uint256 => mapping(uint256 => address)) public stakerAddress;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenRarity;
    mapping(address => mapping(uint256 => Staker)) public stakerInfo;

    uint256[7] public rewardRate;  

    bool public active;

    modifier isActive() {
        require(active == true, "staking vault is currently closed");
        _;
    }


    event MultiStake (uint256 indexed vaultId, uint256[] indexed tokenIds);
    event MultiUnstake (uint256 indexed vaultId, uint256[] indexed tokenIds);
    event RewardsClaimed (uint256 indexed vaultId, uint256 indexed amount);
    event NewVault (vault indexed _vaultInfo, uint256 indexed time);


        constructor() {
        rewardRate = [1 ether, 2 ether, 3 ether, 4 ether, 5 ether, 6 ether, 0];
        active = false;
    }

    //only owner functions

    function addVault(
        IERC721 _nft,
        RewardsToken _token,
        string calldata _name
    ) public onlyOwner {
        VaultInfo.push(
            vault({
                nft: _nft,
                token: _token,
                name: _name
            })
        );
        emit NewVault(vault(_nft, _token, _name), block.timestamp);
    }

    function setRate(uint256 _index, uint256 _rate) public onlyOwner {
        rewardRate[_index] = _rate;
    }

    function setRarity(uint24 _vaultId, uint256 _tokenId, uint256 _rarity) public onlyOwner {
        tokenRarity[_vaultId][_tokenId] = _rarity;
    }

    function setBatchRarity(uint24 _vaultId, uint256[] memory _tokenIds, uint256 _rarity) public onlyOwner() {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            tokenRarity[_vaultId][tokenId] = _rarity;
        }
    }

    function setActiveState(bool _state) public onlyOwner {
        active = _state;
    }

    //internal functions

    function _stake(uint256 _tokenId, uint256 _vaultId) internal {
        vault storage vaultid = VaultInfo[_vaultId];
        
        require(vaultid.nft.ownerOf(_tokenId) == msg.sender,"Not NFT owner");
        vaultid.nft.transferFrom(msg.sender, address(this), _tokenId);
        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId, block.timestamp);
        stakerInfo[msg.sender][_vaultId].stakedTokens.push(stakedToken);
        stakerInfo[msg.sender][_vaultId].amountStaked++;
        stakerAddress[_vaultId][_tokenId] = msg.sender; 
        stakerInfo[msg.sender][_vaultId].timeOfLastUpdate = block.timestamp;
      
    }

    function _unStake(uint256 _tokenId, uint256 _vaultId) internal {
        vault storage vaultid = VaultInfo[_vaultId];

        require(stakerInfo[msg.sender][_vaultId].amountStaked > 0, "No tokens staked");
        require(stakerAddress[_vaultId][_tokenId] == msg.sender, "Not NFT owner!");
        uint256 index = 0;
        for (uint256 i = 0; i < stakerInfo[msg.sender][_vaultId].stakedTokens.length; i++) {
        if (stakerInfo[msg.sender][_vaultId].stakedTokens[i].tokenId == _tokenId && stakerInfo[msg.sender][_vaultId].stakedTokens[i].staker != address(0)) {
                index = i;
                break;
            }
        }
        stakerInfo[msg.sender][_vaultId].stakedTokens[index].staker = address(0);
        stakerInfo[msg.sender][_vaultId].stakedTokens[index].stakedTimestamp = block.timestamp;
        stakerInfo[msg.sender][_vaultId].amountStaked--;
        stakerAddress[_vaultId][_tokenId] = address(0);
        vaultid.nft.transferFrom(address(this), msg.sender, _tokenId);
        stakerInfo[msg.sender][_vaultId].timeOfLastUpdate = block.timestamp;
    }
    

    function claimForVault(uint256 _vaultId) public {
       vault storage vaultid = VaultInfo[_vaultId];
        uint256 rewards = calculateRewards(msg.sender, _vaultId);
        require(rewards > 0, "You have no rewards to claim");
        stakerInfo[msg.sender][_vaultId].timeOfLastUpdate = block.timestamp;
        vaultid.token.mint(msg.sender, rewards);

       emit RewardsClaimed(_vaultId, rewards);
    }

    //external functions

    function stake(uint256 _vaultId, uint256[] calldata _tokenIds) external isActive nonReentrant {
        uint length = _tokenIds.length;
        uint i;

        for(i; i < length; ++i) {
            unchecked {
            _stake(_tokenIds[i], _vaultId);
            }
        }
        emit MultiStake(_vaultId, _tokenIds);
    }

    function unStake(uint256 _vaultId, uint256[] calldata _tokenIds) external isActive nonReentrant {
        uint256 length = _tokenIds.length;
        uint256 i;
        claimForVault(_vaultId);

        for(i; i < length; ++i) {
            unchecked {
            _unStake(_tokenIds[i], _vaultId);
            }

        }
        emit MultiUnstake(_vaultId, _tokenIds);
    }

    //read functions



    function calculateRewards(address _staker, uint256 _vaultId)
        internal
        returns (uint256 _rewards)
    {
        StakedToken[] memory staked = getStakedTokens(_staker, _vaultId);
        uint i;
        uint rewards;
        for (i; i< staked.length; ++i) {
           rewards += ((block.timestamp - stakerInfo[_staker][_vaultId].stakedTokens[i].stakedTimestamp) *
           rewardRate[tokenRarity[_vaultId][stakerInfo[_staker][_vaultId].stakedTokens[i].tokenId]]) / 86400;
           stakerInfo[_staker][_vaultId].stakedTokens[i].stakedTimestamp = block.timestamp;
        }
        return rewards;
    }


 function getStakedTokens(address _user, uint256 _vaultId) public view returns (StakedToken[] memory) {
        // Check if we know this user
        if (stakerInfo[_user][_vaultId].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](stakerInfo[_user][_vaultId].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakerInfo[_user][_vaultId].stakedTokens.length; j++) {
                if (stakerInfo[_user][_vaultId].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakerInfo[_user][_vaultId].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        else {
            return new StakedToken[](0);
        }
    }

    function getUserEarnedRewards(address _staker, uint256 _vaultId) public view returns (uint256) {
         StakedToken[] memory staked = getStakedTokens(_staker, _vaultId);
        uint i;
        uint rewards;
        for (i; i< staked.length; ++i) {
           rewards += ((block.timestamp - stakerInfo[_staker][_vaultId].stakedTokens[i].stakedTimestamp) *
           rewardRate[tokenRarity[_vaultId][stakerInfo[_staker][_vaultId].stakedTokens[i].tokenId]]) / 86400;
        }
        return rewards;
    }


    function getUserDailyEarning(address _user, uint256 _vaultId) public view returns (uint256) {
            uint256 earned;
        if (stakerInfo[_user][_vaultId].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](stakerInfo[_user][_vaultId].amountStaked);
            uint256 _index = 0;
            uint256 j = 0;

            for (j; j < stakerInfo[_user][_vaultId].stakedTokens.length; ++j) {
                if (stakerInfo[_user][_vaultId].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakerInfo[_user][_vaultId].stakedTokens[j];
                    _index++;
                }
            }
             for(uint256 i; i < _stakedTokens.length; ++i) {
                earned += (tokenRarity[_vaultId][_stakedTokens[i].tokenId] + 1);
             }
        }
             return earned;
    }

      function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}