// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct TokenMintInfo {
    address creater;
    uint64 mintedTimestamp;
}

interface IGambdeersClub {
    function getTokenMintInfo(uint _tokenId) external view returns (TokenMintInfo memory);
    function getRarity(uint tokneId) external view returns (uint);
}

interface IDeerClubExclusivePass {
    function getTokenMintInfo(uint _tokenId) external view returns (TokenMintInfo memory);
}

pragma solidity ^0.8.0;

contract Yield is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    address public rewardToken;

    address public gdcNFT;
    address public dceNFT;

    bool public enableYield;
    uint private initYieldTime;

    uint[3] public ratesGdc;
    uint public rateDce = 60 * 1e18;    // 60 $LASM monthly

    uint public totalRewardTokenAmount;

    mapping(address => uint) public userEarnedRewards;
    mapping(uint => uint) public claimedRewardsInGdc;
    mapping(uint => uint) public claimedRewardsInDce;

    event Claimed(address account, uint256 amount);
    event WithdrawRewardToken(address indexed account, uint amount);

    constructor() {
        ratesGdc[0] = 5 * 1e18;        // 5 $LASM daily for standard rarity
        ratesGdc[1] = 8 * 1e18;        // 8 $LASM daily for rare rarity
        ratesGdc[2] = 15 * 1e18;        // 15 $LASM dailf for super rare rarity
    }

    function setRewardToken(address _token) external onlyOwner {
        require(_token != address(0), "Wrong address");
        rewardToken = _token;
    }

    function addRewardsToken(uint256 _amount) external onlyOwner {
        totalRewardTokenAmount += _amount;
    }

    function setGdcCollection(address _gdcNFT) external onlyOwner {
        require(_gdcNFT != address(0), "Wrong address");
        gdcNFT = _gdcNFT;
    }

    function setDceCollection(address _dceNFT) external onlyOwner {
        require(_dceNFT != address(0), "Wrong address");
        dceNFT = _dceNFT;
    }

    function setStartYield() external onlyOwner {
        enableYield = true;
        initYieldTime = block.timestamp;
    }

    function setEnableYield(bool _bEnable) external onlyOwner {
        enableYield = _bEnable;
    }

    function setRateInGdc(uint[3] memory _rates) external onlyOwner {
        ratesGdc = _rates;
    }

    function setRateInDce(uint _rate) external onlyOwner {
        rateDce = _rate;
    }

    function getYieldRatesInGdc() public view returns (uint[] memory) {
        uint period = block.timestamp - initYieldTime;
        uint interval = period / 365 days + 1;

        uint[] memory _rates = new uint[](3);

        _rates[0] = ratesGdc[0] / interval;
        _rates[1] = ratesGdc[1] / interval;
        _rates[2] = ratesGdc[2] / interval;

        return _rates;
    }

    function getRewardsOfTokenIdInGdc(uint _tokenId) public view returns(uint) {
        uint64 mintedTime = IGambdeersClub(gdcNFT).getTokenMintInfo(_tokenId).mintedTimestamp;
        uint period = (block.timestamp - uint(mintedTime)) / 1 days;
        uint rarity = IGambdeersClub(gdcNFT).getRarity(_tokenId);
        uint[] memory rates = getYieldRatesInGdc();

        return rates[rarity] * period - claimedRewardsInGdc[_tokenId];
    }

    function getTotalRewardsOfGdc(address _account) public view returns(uint) {
        uint balance = ERC721Enumerable(gdcNFT).balanceOf(_account);

        uint rewards;
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(gdcNFT).tokenOfOwnerByIndex(_account, i);
            rewards += getRewardsOfTokenIdInGdc(tokenId);
        }

        return rewards;
    }

    function claimRewardInGdc() external nonReentrant {
        require(enableYield, "Yield is disable");
        uint rewards = getTotalRewardsOfGdc(msg.sender);
        
        require(rewards > 0, "No rewards.");
        require(rewards <= IERC20(rewardToken).balanceOf(address(this)), "Insufficient balance.");
        
        IERC20(rewardToken).safeTransfer(msg.sender, rewards);

        totalRewardTokenAmount -= rewards;

        userEarnedRewards[msg.sender] += rewards;

        updateGdc(msg.sender);

        emit Claimed(msg.sender, rewards);
    }

    function updateGdc(address _account) internal {
        uint balance = ERC721Enumerable(gdcNFT).balanceOf(_account);
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(gdcNFT).tokenOfOwnerByIndex(_account, i);
            claimedRewardsInGdc[tokenId] += getRewardsOfTokenIdInGdc(tokenId);
        }
    }

    function getRewardsOfTokenIdInDce(uint _tokenId) public view returns(uint) {
        uint64 mintedTime = IDeerClubExclusivePass(dceNFT).getTokenMintInfo(_tokenId).mintedTimestamp;
        uint period = (block.timestamp - uint(mintedTime)) / 30 days;

        return rateDce * period - claimedRewardsInDce[_tokenId];
    }

    function getTotalRewardsOfDce(address _account) public view returns(uint) {
        uint balance = ERC721Enumerable(dceNFT).balanceOf(_account);

        uint rewards;
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(dceNFT).tokenOfOwnerByIndex(_account, i);
            rewards += getRewardsOfTokenIdInDce(tokenId);
        }

        return rewards;
    }

    function claimRewardInDce() external nonReentrant {
        require(enableYield, "Yield is disable");
        uint rewards = getTotalRewardsOfDce(msg.sender);
        
        require(rewards > 0, "No rewards.");
        require(rewards <= IERC20(rewardToken).balanceOf(address(this)), "Insufficient balance.");
        
        IERC20(rewardToken).safeTransfer(msg.sender, rewards);

        totalRewardTokenAmount -= rewards;

        userEarnedRewards[msg.sender] += rewards;

        updateDce(msg.sender);

        emit Claimed(msg.sender, rewards);
    }

    function updateDce(address _account) internal {
        uint balance = ERC721Enumerable(dceNFT).balanceOf(_account);
        uint tokenId;
        for (uint i=0; i<balance; i++) {
            tokenId = ERC721Enumerable(dceNFT).tokenOfOwnerByIndex(_account, i);
            claimedRewardsInDce[tokenId] += getRewardsOfTokenIdInDce(tokenId);
        }
    }

    /**
     * @dev It allows the admin to withdraw reward token sent to the contract by the admin, 
     * only callable by owner.
     */
    function withdrawRewardToken() public onlyOwner nonReentrant {
        uint remained = IERC20(rewardToken).balanceOf(address(this));

        require(remained > 0, "Insufficient balance of reward token.");

        IERC20(rewardToken).safeTransfer(msg.sender, remained);

        emit WithdrawRewardToken(msg.sender, remained);

        totalRewardTokenAmount = 0;
    }
}