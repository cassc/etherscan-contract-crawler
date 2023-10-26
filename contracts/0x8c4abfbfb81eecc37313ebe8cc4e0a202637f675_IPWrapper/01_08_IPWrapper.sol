// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/NFAiGatewayInterface.sol"; 

/**
* @title IPWrapper
* @dev This contract is a wrapper for the NFAiStakingLottery contract. It is used to make the NFAiStakingLottery contract compatible with the IP contract. 
*/
contract IPWrapper is NFAiGatewayInterface, Ownable {
    using SafeERC20 for IERC20;
    NFAiGatewayInterface public nFAiStakingLottery;
    
    constructor() {
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getRegisteredToken() external view override returns (address) {
        return nFAiStakingLottery.getRegisteredToken();
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getAllWinnerInfo() external view override returns (address[] memory, uint256[] memory) {
        return nFAiStakingLottery.getAllWinnerInfo();
    }
    
    /** 
    * @inheritdoc NFAiGatewayInterface
    */
    function getLastWinnerInfo() external view override returns (address, uint256, uint256) {
        return nFAiStakingLottery.getLastWinnerInfo();
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getStakerAmount(address user) external view override returns (uint256) {
        return nFAiStakingLottery.getStakerAmount(user);
    }                                  

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getMinimumStakeTime() external view override returns (uint256) {
        return nFAiStakingLottery.getMinimumStakeTime();
    }

    function getEligibility(address user) external view override returns (bool) {
        return nFAiStakingLottery.getEligibility(user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getTotalEligibleStaked() external  view returns (uint256) {
        return nFAiStakingLottery.getTotalEligibleStaked();
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getStakers() external view returns (address[] memory) {
        return nFAiStakingLottery.getStakers();
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getTotalStaked() external view  returns (uint256){
        return nFAiStakingLottery.getTotalStaked();
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getUserOdds(address user) external view override returns (uint256) {
        return nFAiStakingLottery.getUserOdds(user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function getStakerTime(address user) external view override returns (uint256) {
        return nFAiStakingLottery.getStakerTime(user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function stake(uint256 amount, address user) external override {
        if(msg.sender != user) {
            revert NotUser(msg.sender);
        }
        IERC20 token = IERC20(nFAiStakingLottery.getRegisteredToken());
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeIncreaseAllowance(address(nFAiStakingLottery), amount);
        nFAiStakingLottery.stake(amount, user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function unstake(address user) external override {
        if(msg.sender != user) {
            revert NotUser(msg.sender);
        }
        nFAiStakingLottery.unstake(user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function confirmParticipation(address user) external override {
        if(msg.sender != user) {
            revert NotUser(msg.sender);
        }
        nFAiStakingLottery.confirmParticipation(user);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function setMinimumStakeTime(uint256 _minutes) external override onlyOwner {
        nFAiStakingLottery.setMinimumStakeTime(_minutes);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function emergencyWithdraw(address ethTO, address ercTO, address tokenAdr) external override onlyOwner {
        nFAiStakingLottery.emergencyWithdraw(ethTO, ercTO, tokenAdr);
    }

    /**
    * @inheritdoc NFAiGatewayInterface
    */
    function draw(uint8 _drawingStrategy, uint256 _numberOfWinners) external override onlyOwner {
        nFAiStakingLottery.draw(_drawingStrategy, _numberOfWinners);
    }

    /**
    * @notice Set the NFAiStakingLotteryAddress
    * @param _nFAiStakingLottery Address of the NFAiStakingLottery contract
    */
    function setNFAiStakingLottery(address _nFAiStakingLottery) external onlyOwner {
        nFAiStakingLottery = NFAiGatewayInterface(_nFAiStakingLottery);
    }

    /** 
    * @inheritdoc NFAiGatewayInterface
    */
    function setInitializingFactors(
        bytes32 _keyHash, 
        uint64 subscriptionId, 
        uint32 _callbackGasLimit, 
        uint16 _minimumRequestConfirmations, 
        uint32 _numWords, 
        address _token
    ) external override onlyOwner {
        nFAiStakingLottery.setInitializingFactors(
            _keyHash, 
            subscriptionId, 
            _callbackGasLimit, 
            _minimumRequestConfirmations, 
            _numWords, 
            _token
        );
    }

   /** 
    * @inheritdoc NFAiGatewayInterface
    */
    function depositPrizeTokens(uint256 amount) external override onlyOwner {      
        IERC20 token = IERC20(nFAiStakingLottery.getRegisteredToken());
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeIncreaseAllowance(address(nFAiStakingLottery), amount);
        nFAiStakingLottery.depositPrizeTokens(amount);      
    }

   /** 
    * @inheritdoc NFAiGatewayInterface
    */
    function getPrizePool() external view override returns (uint256) {
        return nFAiStakingLottery.getPrizePool();
    }
}