// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IArcada {
    function proxyMint(address to, uint256 amount) external;
}

interface IMTG {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract MTGStaking is Ownable, ReentrancyGuard {
    IArcada public Arcada;
    IMTG public MTG;

    uint256 public constant DAY = 24 * 60 * 60;
    uint256 public constant LOCKIN_PERIODS = 7 * DAY;

    uint256 public START;
    uint256 public GAMER_RATE = Math.ceilDiv(8 * 10 ** 18, DAY);
    uint256 public ROYAL_GAMER_RATE = Math.ceilDiv(24 * 10 ** 18, DAY);

    address public MTGAddress = 0x49907029e80dE1cBB3A46fD44247BF8BA8B5f12F;
    address public ArcadaAddress = 0x22d811658Dc32293fbB5680EC5df85Cc2B605dC7;
    bool public emergencyUnstakePaused = true;

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 lockInEndAt;
        uint256 stakedAt;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount);

    event Claimed(address owner, uint256 rewards);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {
        START = block.timestamp;
        MTG = IMTG(MTGAddress);
        Arcada = IArcada(ArcadaAddress);
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds
    )
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(_msgSender(), tokenIds[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId
    ) internal {
        require(
            MTG.ownerOf(_tokenId) == _msgSender(),
            "You must own the NFT."
        );
        uint256 lockInEndAt = block.timestamp + LOCKIN_PERIODS;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            lockInEndAt,
            block.timestamp
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        MTG.safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId);
    }

    // RESTAKE
    function batchClaim(
        uint256[] calldata tokenIds
    )
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _claim(_msgSender(), tokenIds[i]);
        }
    }

    function _claim(
        address _user,
        uint256 _tokenId
    ) internal {
        require(
            stakingRecords[_tokenId].tokenOwner == _msgSender(),
            "Token does not belong to you."
        );

        uint256 rewards = getPendingRewards(_tokenId);
        stakingRecords[_tokenId].stakedAt = block.timestamp;
        Arcada.proxyMint(_user, rewards);

        emit Staked(_user, _tokenId);
        emit Claimed(_user, rewards);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(_msgSender(), tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].lockInEndAt,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == _msgSender(),
            "Token does not belong to you."
        );

        uint256 rewards = getPendingRewards(_tokenId);
        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        MTG.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );
        Arcada.proxyMint(_user, rewards);

        emit Unstaked(_user, _tokenId);
        emit Claimed(_user, rewards);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256[] memory rewards = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < MTG.totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].lockInEndAt;
                rewards[counter] = getPendingRewards(tokenIds[counter]);
                counter++;
            }
        }
        return (tokenIds, expiries, rewards);
    }

    function getPendingRewards(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(stakingRecords[tokenId].stakedAt > START, "NFT is not staked.");
        if (tokenId <= 100) {
            return (block.timestamp - stakingRecords[tokenId].stakedAt) * ROYAL_GAMER_RATE;
        }
        return (block.timestamp - stakingRecords[tokenId].stakedAt) * GAMER_RATE;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // SETTER
    function setGamerRewardRate(uint256 rewardPerDay) external onlyOwner {
        GAMER_RATE = Math.ceilDiv(rewardPerDay, DAY);
    }

    function setRoyalGamerRewardRate(uint256 rewardPerDay) external onlyOwner {
        ROYAL_GAMER_RATE = Math.ceilDiv(rewardPerDay, DAY);
    }

    // MIGRATION ONLY.
    function setMTGNFTContract(address operator) external onlyOwner {
        MTG = IMTG(operator);
    }

    function setArcadaContract(address operator) external onlyOwner {
        Arcada = IArcada(operator);
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused)
        public
        onlyOwner
    {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        _unstake(msg.sender, tokenId);
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function emergencyUnstakeByOwner(uint256[] calldata tokenIds) external onlyOwner nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address user = stakingRecords[tokenId].tokenOwner;
            require(user != address(0x0), "Need owner exists.");
            delete stakingRecords[tokenId];
            numOfTokenStaked[user]--;
            MTG.safeTransferFrom(
                address(this),
                user,
                tokenId
            );
            emit EmergencyUnstake(user, tokenId);
        }
    }
}