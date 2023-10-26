// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SFAStaking is IERC721Receiver {
    
    struct StakingData {
        uint256 tokenId;
        uint256 timestamp;
    }

    uint256 public maxSolarPass;
    uint256 public maxSolarHead;
    address public solarPass;
    uint8 public solarPassPayout;
    address public solarHead;
    uint8 public solarHeadPayout;
    address public sfaToken;
    uint32 public payoutPeriod;
    mapping(address => uint256) public solarPassStaked;
    mapping(address => uint256) public solarHeadStaked;
    mapping(address => StakingData[5]) public solarPassStakedData;
    mapping(address => StakingData[25]) public solarHeadStakedData;

    event SolarHeadStaked(address user, uint256 amount);
    event SolarPassStaked(address user, uint256 amount);
    event RewardsClaimed(address user, uint256 amount);
    event WithdrawalAll(address user);
    event WithdrawalSolarHead(address user);
    event WithdrawalSolarPass(address user);

    constructor(
        uint256 _maxSolarPass,
        uint256 _maxSolarHead,
        address _solarPass,
        uint8 _solarPassPayout,
        address _solarHead,
        uint8 _solarHeadPayout,
        address _sfaToken,
        uint32 _payoutPeriod
    ) {
        maxSolarPass = _maxSolarPass;
        maxSolarHead = _maxSolarHead;
        solarPass = _solarPass;
        solarPassPayout = _solarPassPayout;
        solarHead = _solarHead;
        solarHeadPayout = _solarHeadPayout;
        sfaToken = _sfaToken;
        payoutPeriod = _payoutPeriod;
    }


    /**
     * @notice views the staking state of a user
     * @param _user address of user whose state gets returned
     * @return uint256 amount of solar passes staked
     * @return uint256 amount of solar heads staked
     */
    function getStakedAmounts(address _user) external view returns(uint256, uint256) {
        uint256 userSolarPassesStaked = solarPassStaked[_user];
        uint256 userSolarHeadsStaked = solarHeadStaked[_user];
        return (userSolarPassesStaked, userSolarHeadsStaked);
    }


    /**
     * @notice stakes one solar head for msg.sender
     * @param _tokenId tokenId of solar head to be staked
     */
    function stakeSolarHead(uint256 _tokenId) external {
        uint256 amountStaked = solarHeadStaked[msg.sender];
        require(amountStaked + 1 <= maxSolarHead, "SFA Staking: staked amount exceeds limit");
        IERC721(solarHead).safeTransferFrom(msg.sender, address(this), _tokenId);
        solarHeadStaked[msg.sender] += 1;
        solarHeadStakedData[msg.sender][amountStaked] = StakingData(_tokenId, block.timestamp);
        emit SolarHeadStaked(msg.sender, 1);
    }

    /**
     * @notice stakes multiple solar heads at one time for msg.sender
     * @param _amount the amount of solar heads to stake
     * @param _tokenIds the tokenIds of the solar heads being staked
     */
    function batchStakeSolarHead(uint256 _amount, uint256[] calldata _tokenIds) external {
        uint256 amountStaked = solarHeadStaked[msg.sender];
        require(amountStaked + _amount <= maxSolarHead, "SFA Staking: staked amount exceeds limit");
        
        address _solarHead = solarHead;

        uint256 i = 0;
        while(i < _amount) {
            IERC721(_solarHead).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            solarHeadStaked[msg.sender] += 1;
            solarHeadStakedData[msg.sender][amountStaked + i] = StakingData(_tokenIds[i], block.timestamp);
            unchecked {
                ++i;
            }
        }
        emit SolarHeadStaked(msg.sender, _amount);
    }


    /**
     * @notice stakes one solar pass for msg.sender
     * @param _tokenId tokenId of solar pass to be staked
     */
    function stakeSolarPass(uint256 _tokenId) external {
        uint256 amountStaked = solarPassStaked[msg.sender];
        require(amountStaked + 1 <= maxSolarPass, "SFA Staking: staked amount exceeds limit");
        IERC721(solarPass).safeTransferFrom(msg.sender, address(this), _tokenId);
        solarPassStaked[msg.sender] += 1;
        solarPassStakedData[msg.sender][amountStaked] = StakingData(_tokenId, block.timestamp);
        emit SolarPassStaked(msg.sender, 1);
    }

     /**
     * @notice stakes multiple solar passes at one time for msg.sender
     * @param _amount the amount of solar passes to stake
     * @param _tokenIds the tokenIds of the solar passes being staked
     */
    function batchStakeSolarPass(uint256 _amount, uint256[] calldata _tokenIds) external {
        uint256 amountStaked = solarPassStaked[msg.sender];
        require(amountStaked + _amount <= maxSolarPass, "SFA Staking: staked amount exceeds limit");
        
        address _solarPass = solarPass;

        uint256 i = 0;
        while(i < _amount) {
            IERC721(_solarPass).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            solarPassStaked[msg.sender] += 1;
            solarPassStakedData[msg.sender][amountStaked + i] = StakingData(_tokenIds[i], block.timestamp);
            unchecked {
                ++i;
            }
        }
        emit SolarPassStaked(msg.sender, _amount);
    }

    /**
     * @notice allows msg.sender to claim SFA Token rewards, 
     * without having to withdraw their stakes NFTs
     */
    function claimRewards() external {
        uint256 solarHeadsStaked = solarHeadStaked[msg.sender];
        uint256 solarPassesStaked = solarPassStaked[msg.sender];

        uint256 tokensEarned;
        uint256 currTime = block.timestamp;
        uint32 _payoutPeriod = payoutPeriod;
        uint256 stakedTime;
        uint256 duration;

        uint256 i;
        while(i < solarHeadsStaked) {
            stakedTime = solarHeadStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 1 ether;
            solarHeadStakedData[msg.sender][i].timestamp = block.timestamp;
            unchecked {
                ++i;
            }
        }

        i = 0;
        while(i < solarPassesStaked) {
            stakedTime = solarPassStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 10 ether;
            solarPassStakedData[msg.sender][i].timestamp = block.timestamp;
            unchecked {
                ++i;
            }
        }

        IERC20(sfaToken).transfer(msg.sender, tokensEarned);
        emit RewardsClaimed(msg.sender, tokensEarned);
    }


     /**
     * @notice withdraws users staked NFTs. Additonally, claims
     * all SFA Token rewards for the user.
     */
    function withdraw() external {

        address _solarHead = solarHead;
        address _solarPass = solarPass;

        uint256 solarHeadsStaked = solarHeadStaked[msg.sender];
        uint256 solarPassesStaked = solarPassStaked[msg.sender];

        solarHeadStaked[msg.sender] = 0;
        solarPassStaked[msg.sender] = 0;

        uint256 tokensEarned;
        uint256 currTime = block.timestamp;
        uint32 _payoutPeriod = payoutPeriod;
        uint256 stakedTime;
        uint256 duration;

        uint256 i = 0;

        while(i < solarHeadsStaked) {
            stakedTime = solarHeadStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 1 ether;
            solarHeadStakedData[msg.sender][i].timestamp = 0;
            IERC721(_solarHead).safeTransferFrom(address(this), msg.sender, solarHeadStakedData[msg.sender][i].tokenId);
            unchecked {
                ++i;
            }
        }

        i = 0;
        while(i < solarPassesStaked) {
            stakedTime = solarPassStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 10 ether;
            solarPassStakedData[msg.sender][i].timestamp = 0;
            IERC721(_solarPass).safeTransferFrom(address(this), msg.sender, solarPassStakedData[msg.sender][i].tokenId);
            unchecked {
                ++i;
            }
        }

        IERC20(sfaToken).transfer(msg.sender, tokensEarned);
        emit WithdrawalAll(msg.sender);
    }

     /**
     * @notice withdraws users staked SolarHead. Additonally, claims
     * all SFA Token rewards for the user.
     */
    function withdrawSolarHead() external {

        address _solarHead = solarHead;

        uint256 solarHeadsStaked = solarHeadStaked[msg.sender];

        solarHeadStaked[msg.sender] = 0;

        uint256 tokensEarned;
        uint256 currTime = block.timestamp;
        uint32 _payoutPeriod = payoutPeriod;
        uint256 stakedTime;
        uint256 duration;

        uint256 i = 0;

        while(i < solarHeadsStaked) {
            stakedTime = solarHeadStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 1 ether;
            solarHeadStakedData[msg.sender][i].timestamp = 0;
            IERC721(_solarHead).safeTransferFrom(address(this), msg.sender, solarHeadStakedData[msg.sender][i].tokenId);
            unchecked {
                ++i;
            }
        }

        IERC20(sfaToken).transfer(msg.sender, tokensEarned);
        emit WithdrawalSolarHead(msg.sender);
    }

     /**
     * @notice withdraws users staked Solar Passes. Additonally, claims
     * all SFA Token rewards for the user.
     */
    function withdrawSolarPass() external {

        address _solarPass = solarPass;

        uint256 solarPassesStaked = solarPassStaked[msg.sender];

        solarPassStaked[msg.sender] = 0;

        uint256 tokensEarned;
        uint256 currTime = block.timestamp;
        uint32 _payoutPeriod = payoutPeriod;
        uint256 stakedTime;
        uint256 duration;

        uint256 i = 0;

        while(i < solarPassesStaked) {
            stakedTime = solarPassStakedData[msg.sender][i].timestamp;
            duration = currTime - stakedTime;
            tokensEarned += (duration / _payoutPeriod) * 10 ether;
            solarPassStakedData[msg.sender][i].timestamp = 0;
            IERC721(_solarPass).safeTransferFrom(address(this), msg.sender, solarPassStakedData[msg.sender][i].tokenId);
            unchecked {
                ++i;
            }
        }

        IERC20(sfaToken).transfer(msg.sender, tokensEarned);
        emit WithdrawalSolarPass(msg.sender);
    }

     /**
     * @notice required to allow this contract to recieve NFTs
     * in accordance of ERC721 token standard 
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}