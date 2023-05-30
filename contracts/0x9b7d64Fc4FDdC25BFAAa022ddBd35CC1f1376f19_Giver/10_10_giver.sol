// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract Giver is Ownable {

    address constant _token = 0x59fc0F9626e872bc89c71bAe90f40021F5A211A8;

    uint256 constant _BLOCKS_PER_READJUSTMENT = 24;
    uint256 constant _MINIMUM_TARGET = 2**16;
    uint256 constant _MAXIMUM_TARGET = 2**220;
    uint256 constant rewardAmount = 93*10**18;
    uint256 constant burnAmount = 30*10**18;
    uint256 constant targetEthBlocksPerDiffPeriod = _BLOCKS_PER_READJUSTMENT * 150;
    uint256 constant burnBlockStart = 17608710;

    uint256 public latestDifficultyPeriodStarted;
    uint256 public epochCount;
    uint256 public maximumDifficulty;


    uint256 public miningTarget;
    uint256 public tokensMinted;
    bytes32 public challengeNumber;

    mapping(bytes32 => bytes32) solutions;

    bool locked = false;
    bool public burningEnabled;


    event Mint(address indexed from, uint256 reward_amount, uint256 epochCount, bytes32 newChallengeNumber);

    constructor() {

        if(locked) revert();
        locked = true;

        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();
    }

    function _startNewMiningEpoch() internal {

      epochCount = epochCount+1;

      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }

      challengeNumber = blockhash(block.number - 1);

    }

    function _reAdjustDifficulty() internal {

        uint256 ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;

        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
          uint256 excess_block_pct = (targetEthBlocksPerDiffPeriod*100) /  ethBlocksSinceLastDifficultyPeriod;

          uint256 excess_block_pct_extra = (excess_block_pct-100);
          if (excess_block_pct_extra>1000) {excess_block_pct_extra=1000;}

          miningTarget = miningTarget-(miningTarget/2000)*excess_block_pct_extra;
        } else {
          uint256 shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod*100) / targetEthBlocksPerDiffPeriod;

          uint256 shortage_block_pct_extra = shortage_block_pct-100;
          if (shortage_block_pct_extra>1000) {shortage_block_pct_extra=1000;}

          miningTarget = miningTarget+(miningTarget/2000)*shortage_block_pct_extra;
        }


        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET)
        {
          miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET)
        {
          miningTarget = _MAXIMUM_TARGET;
        }

        if (block.number>burnBlockStart) {
          uint256 difficulty=_MAXIMUM_TARGET/miningTarget;
          if(difficulty>maximumDifficulty) {
            maximumDifficulty=difficulty;
            burningEnabled=false;
          }

          if(burningEnabled==false) {
            uint256 burningDifficulty = maximumDifficulty-(maximumDifficulty/100)*30;
            if(difficulty<burningDifficulty) {
              burningEnabled=true;
            }
          }
        }
    }

    function getChallengeNumber() external view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningTarget() external view returns (uint256) {
       return miningTarget;
    }

    function getMiningDifficulty() external view returns (uint256) {
        return _MAXIMUM_TARGET/miningTarget;
    }

    function getMiningReward() external pure returns (uint256) {
         return (rewardAmount);
    }

    function checkMintSolution(bytes32 challenge_number, uint256 testTarget, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) external view returns (bool success) {

        bytes memory prefix = "\x19Ethereum Signed Message:\n72";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, msg.sender, challenge_number));

        if (prefixedHashMessage!=msgHash) return false;

        address pow_addr = ecrecover(msgHash, v, r, s); 

        bytes32 digest=keccak256(abi.encodePacked(pow_addr,msg.sender,challenge_number));

        if(uint256(digest) > testTarget) return false;

        return true;
    }

    fallback () external payable {
        revert();
    }

    receive () external payable {
        revert();
    }

    function mint(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) external returns (bool success) {

        bytes memory prefix = "\x19Ethereum Signed Message:\n72";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, msg.sender,challengeNumber));

        if (prefixedHashMessage!=msgHash) revert('message must contain msg.sender');

        address pow_addr = ecrecover(msgHash, v, r, s); 

        bytes32 digest=keccak256(abi.encodePacked(pow_addr,msg.sender,challengeNumber));

        if(uint256(digest) > miningTarget) revert('high-hash');

        bytes32 solution = solutions[challengeNumber];
        if(solution != 0x0) revert('duplicate-solution');  //prevent the same answer from awarding twice

        tokensMinted = tokensMinted+rewardAmount;

        solutions[challengeNumber] = digest;

        uint256 contract_balance = IERC20(_token).balanceOf(address(this));
        require(rewardAmount<=contract_balance, "low-balance");

        IERC20(_token).transfer(msg.sender, rewardAmount);

        if(burningEnabled==true) {
          if(contract_balance-rewardAmount-burnAmount > 0) {
            ERC20Burnable(_token).burn(burnAmount);
          }
        }

        _startNewMiningEpoch();

        emit Mint(msg.sender, rewardAmount, epochCount, challengeNumber);

        return true;
    }

    function setMiningTarget(uint256 target) external onlyOwner {
      miningTarget=target;
    }

    function burnTokens(uint256 amount) external onlyOwner {
        ERC20Burnable(_token).burn(amount);
    }

    function transferERC20(address token, uint256 amount) external onlyOwner {
      IERC20(token).transfer(msg.sender, amount);
    }
}