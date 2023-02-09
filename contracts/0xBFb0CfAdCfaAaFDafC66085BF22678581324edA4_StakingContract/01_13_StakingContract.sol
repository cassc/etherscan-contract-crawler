// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StakingContract is ERC20Burnable, Ownable {
    using strings for *;
    using SafeMath for uint256;

    // 5 tokens per day
    uint256 public EMISSIONS_RATE_BASE = 690000000000000;

    // 2 days
    uint256 public EVOLUTION_TIME = 86400 * 2;
    uint256 public MAX_LEVEL = 2;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public tomatoAddress;

    // Mapping of Tomato to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    // Use these for the weekly rewards
    mapping(uint256 => uint256) internal tokenIdToTimeStampOriginal;
    mapping(uint256 => uint256) internal tokenIdToClaimedStreaks;

    // Mapping of Tomato to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    // Mapping of staker to Tomato
    mapping(address => uint256[]) internal stakerToTokenIds;

    // Mapping of Tomato level
    mapping(uint256 => uint256) internal tokenIdToLevel;

    // Mapping of Tomato rarities (0 is unset, 1 is base, ... 5)
    mapping(uint256 => uint256) internal tokenIdToRarity;

    // Merkle root for rarity checking
    bytes32 public raritiesMerkleRoot;

    event Evolution(uint256 tokenId, uint256 level);
    event TokenStaked(address indexed staker, uint tokenId);

    constructor() ERC20("The Garden", "DEGENZ") {}

    function setTomatoAddress(address _tomatoAddress) public onlyOwner {
        tomatoAddress = _tomatoAddress;
        return;
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeById(uint256 tokenId, bytes32[] memory _proof, bytes32 _leafHash) public {
        require(MerkleProof.verify(_proof, raritiesMerkleRoot, _leafHash), "invalid proof");
        require(
            IERC721(tomatoAddress).ownerOf(tokenId) == msg.sender &&
                tokenIdToStaker[tokenId] == nullAddress,
            "Tomato must be stakable by you!"
        );

        IERC721(tomatoAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        stakerToTokenIds[msg.sender].push(tokenId);
        tokenIdToTimeStamp[tokenId] = block.timestamp;
        tokenIdToTimeStampOriginal[tokenId] = block.timestamp;
        tokenIdToStaker[tokenId] = msg.sender;
        tokenIdToRarity[tokenId] = extractRarity(_leafHash);

        emit TokenStaked(msg.sender, tokenId);
    }

    function extractRarity(bytes32 leafHash) public pure returns (uint256) {
        string memory stringLeaf = string(abi.encodePacked(leafHash));

        strings.slice memory s = stringLeaf.toSlice();
        strings.slice memory part;
        s.split(":".toSlice(), part);
        strings.slice memory rarity = s.split(":".toSlice(), part);
        string memory rarityS = rarity.toString();

        return uint256(strToUint(rarityS));
    }

    function getTokenEmissionMultiplier(uint256 tokenId) public view returns (uint256) {
        uint256 tokenRarity = tokenIdToRarity[tokenId];

        // If token is not at last evolution, do not earn tokens
        if (tokenIdToLevel[tokenId] < MAX_LEVEL) return 0;

        if (tokenRarity == 1) return 1;
        if (tokenRarity == 2) return 2;
        if (tokenRarity == 3) return 2;
        if (tokenRarity == 4) return 3;
        if (tokenRarity == 5) return 4;

        // Token has never been staked
        return 0;
    }

    function getTokenStreakRewardsAmount(uint256 tokenId) public view returns (uint256) {
        // require that token is staked
        if (tokenIdToStaker[tokenId] == nullAddress) return 0;

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStampOriginal[tokenId];
        uint256 _day = 86400;
        uint256 _streaks = tokenIdToClaimedStreaks[tokenId];

        if (secondsStaked < _day * 7) return 0;
        if (secondsStaked < _day * 14 && _streaks < 1) return (_day * 2 * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId));
        if (secondsStaked < _day * 21 && _streaks < 2) return (_day * 4 * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId));
        if (secondsStaked < _day * 28 && _streaks < 3) return (_day * 6 * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId));
        if (secondsStaked >= _day * 28 && _streaks < 4) return (_day * 8 * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId));

        return 0;
    }

    function getTokenStreakRewards(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Rewards are not claimable!"
        );

        _mint(msg.sender, getTokenStreakRewardsAmount(tokenId));
        tokenIdToClaimedStreaks[tokenId]++;
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one Tomato staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(tomatoAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId));

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
            tokenIdToClaimedStreaks[tokenId] = 0;
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(tomatoAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenIds[i]));

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
            tokenIdToClaimedStreaks[tokenIds[i]] = 0;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        _mint(
            msg.sender,
            ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId))
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenIds[i]));

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenIds[i]));
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        return secondsStaked * EMISSIONS_RATE_BASE * getTokenEmissionMultiplier(tokenId);
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function getStakingTime(uint256 tokenId) public view returns (uint256) {
        return tokenIdToTimeStamp[tokenId];
    }

    // Evolve functions
    function getTokenLevel(uint256 tokenId) public view returns (uint256) {
        return tokenIdToLevel[tokenId];
    }

    function evolveToken(uint256 tokenId) public returns (uint256) {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "You cannot evolve this Tomato!"
        );
        require(
            tokenIdToLevel[tokenId] < MAX_LEVEL,
            "Tomato at maximum level!"
        );
        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        require(
            secondsStaked > EVOLUTION_TIME * (getTokenLevel(tokenId) + 1),
            "Tomato needs more time to evolve!"
        );
        tokenIdToLevel[tokenId]++;
        emit Evolution(tokenId, tokenIdToLevel[tokenId]);

        // If at last evolution, reset seconds staked
        if (tokenIdToLevel[tokenId] >= MAX_LEVEL) tokenIdToTimeStamp[tokenId] = block.timestamp;

        return tokenIdToLevel[tokenId];
    }

    function strToUint(string memory _str) private pure returns(uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                revert("Error");
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        
        return res;
    }

    function setRaritiesMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        raritiesMerkleRoot = merkleRoot;
    }
}