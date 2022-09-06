// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import './../BaconCoin/BaconCoin3.sol';
import './../PoolStakingRewards/PoolStakingRewards0.sol';
import './../PoolCore/Pool10.sol';


import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract PoolStaking4 is Initializable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    uint256 constant PER_BLOCK_DECAY_18_DECIMALS = 999999775700000000;
    uint256 constant PER_BLOCK_DECAY_INVERSE = 1000000224300050310;
    uint256 constant DENOM = 224337829e21;
    uint256 constant GUARDIAN_REWARD = 39e18;
    uint256 constant DAO_REWARD = 18e18;
    uint256 constant COMMUNITY_REWARD = 50e18;
    uint256 constant COMMUNITY_REWARD_BONUS = 100e18;

    uint256 stakeAfterBlock;
    address guardianAddress;
    address daoAddress;
    address baconCoinAddress;
    address[] poolAddresses;

    uint256[] updateEventBlockNumber;
    uint256[] updateEventNewAmountStaked;
    uint256 updateEventCount;
    uint256 currentStakedAmount;

    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public userLastDistribution;

    uint256 oneYearBlock;

    struct UnstakeRecord {
        uint256 endBlock;
        uint256 amount;
    }

    // PoolStaking2 storage
    uint256 unstakingLockupBlockDelta;
    mapping(address => UnstakeRecord) userToUnstake;
    uint256 pendingWithdrawalAmount;

    //PoolStaking3 storage for nonReentrant modifier
    //modifier and variables could not be imported via inheratance given upgradability rules
    mapping(address => bool) isApprovedPool;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    //PoolStaking4 storage
    address newStakingContract;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    // TODO: maybe this should just be a normal setter like the rest in this block...
    function setUnstakingLockupBlockDelta(uint256 _unstakingLockupBlockDelta) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        unstakingLockupBlockDelta = _unstakingLockupBlockDelta;
    }

    function setOneYearBlock(uint256 _oneYearBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        oneYearBlock = _oneYearBlock;
    }

    function setstakeAfterBlock(uint256 _stakeAfterBlock) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        stakeAfterBlock = _stakeAfterBlock;
    }

    // To be called after baconCoin0 is deployed
    function setBaconAddress(address _baconCoinAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        baconCoinAddress = _baconCoinAddress;
    }

    // To be called after baconCoin0 is deployed
    function setDAOAddress(address _DAOAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        userLastDistribution[_DAOAddress] =  userLastDistribution[daoAddress];
        daoAddress = _DAOAddress;
    }

    function setGuardianAddress(address _guardianAddress) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        userLastDistribution[_guardianAddress] =  userLastDistribution[guardianAddress];
        guardianAddress = _guardianAddress;
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 4;
    }

    function getContractInfo() public view returns (uint256, uint256, address, address, address, address  [] memory, uint256, uint256, uint256) {
        return (
            stakeAfterBlock,
            oneYearBlock,
            guardianAddress,
            daoAddress,
            baconCoinAddress,
            poolAddresses,
            updateEventCount,
            currentStakedAmount,
            pendingWithdrawalAmount
        );
    }

    function getPendingWithdrawInfo(address _holderAddress) public view returns(uint256, uint256, uint256) {
        return (
            userToUnstake[_holderAddress].endBlock,
            userToUnstake[_holderAddress].amount,
            pendingWithdrawalAmount
        );
    }

    function getUserLastDistributed(address wallet) public view returns (uint256) {
        return (userLastDistribution[wallet]);
    }

    /*****************************************************
    *       Staking FUNCTIONS
    ******************************************************/

    function decayExponent(uint256 exponent) public pure returns (uint256) {
        //18 decimals
        if (exponent == 0) {
            return 1e18;
        }

        uint256 answer = PER_BLOCK_DECAY_18_DECIMALS;
        for (uint256 i = 0; i < exponent-1; i++) {
            answer = answer.mul(1e18).div(PER_BLOCK_DECAY_INVERSE);
        }

        return answer;
    }

    function calcBaconBetweenEvents(uint256 blockX, uint256 blockY) public view returns (uint256) {
        //bacon per block after first year is
        //y=50(1-0.000000224337829000)^{x}
        //where x is number of blocks over 15651074

        //Bacon accumulated between two blocksover first year is:
        //S(x,y) = S(y) - S(x) = (A1(1-r^y) / (1-r)) - (A1(1-r^x) / (1-r))
        //where A1 = 50 and r = 0.9999997757

        //1 year block subtracted from block numbers passed in since formula only cares about change in time since that point
        blockX = blockX.sub(oneYearBlock);
        blockY = blockY.sub(oneYearBlock);

        uint256 SyNumer = 1e18;
        uint256 SxNumer = 1e18;

        SyNumer = SyNumer.sub(decayExponent(blockY)).mul(COMMUNITY_REWARD);
        SxNumer = SxNumer.sub(decayExponent(blockX)).mul(COMMUNITY_REWARD);

        uint256 Sy = SyNumer.mul(1e18).div(DENOM);
        uint256 Sx = SxNumer.mul(1e18).div(DENOM);

        return Sy.sub(Sx);
    }


    /**
    *   @dev function distribute accepts a wallet address and transfers the BaconCoin accrued to their wallet since the user's Last Distribution
    */
    function distribute(address wallet) public returns (uint256) {
        // Forward to the new staking contract
        return PoolStakingRewards0(newStakingContract).massHarvest(wallet);
    }


    function checkStaked(address wallet) public view returns (uint256) {
        return PoolStakingRewards0(newStakingContract).getCurrentBalance(wallet);
    }

    /**
    *   @dev Function unstake begins the process of withdrawing staked value. After a timeout, 
    *   the amount will be available to withdraw. If you calling account already has an unstake pending
    *   the new amount will be added to the pending amount and the timeout will reset.
    */
    function unstake(uint256 amount) public nonReentrant returns (uint256) {
        PoolStakingRewards0(newStakingContract).unstakeForWallet(msg.sender, amount);
        return 0;
    }

    /**  
    *   @dev Function withdraw moves tokens that were unstaked by the caller to the caller's wallet
    */
    function withdraw(uint256 amount) public returns (uint256) {
        // Disabled for new staking
        return 0;
    }

    function getEvents() public view returns (uint256  [] memory, uint256  [] memory) {
        return (updateEventBlockNumber, updateEventNewAmountStaked);
    }

    function transferMintRights(address newMinter) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");
        BaconCoin3(baconCoinAddress).setStakingContract(newMinter);
    }

    function setNewStakingContract(address newContract) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");
        newStakingContract = newContract;
    }

    function transferAllStakes(address stakingCore, address[] memory recepients, uint256[] memory amounts, uint256 length) public {
        require(msg.sender == guardianAddress, "PoolStaking: unapproved sender");

        for (uint256 i = 0; i < length; i++) {
            Pool10(poolAddresses[0]).transfer(stakingCore, amounts[i]); 
            PoolStakingRewards0(newStakingContract).stake(recepients[i], amounts[i]);
        }
    }

}