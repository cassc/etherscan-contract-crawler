// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface BurnFunction {
    function BurnInVariaNFT(address burnTokenAddress, uint256 burnValue) external;
}

contract InVariaStaking is Ownable, ReentrancyGuard,ERC1155Holder {
    BurnFunction public InVariaNFTBurn;
    IERC1155 public InVariaNFT;
    IERC20 public USDC;

    address public constant WithDrawAddress = 0xAcB683ba69202c5ae6a3B9b9b191075295b1c41C;
    address public constant inVaria = 0x502818ec5767570F7fdEe5a568443dc792c4496b;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    struct StakingInfo {
        uint256 stakeNFTamount;
        uint256 leftToUnstakeNFTamount;
        uint256 staketime;
        uint256 unstaketime;
        bool isUnstake;
    }

    struct BurningInfo {
        uint256 burnableNFTamount;
        uint256 leftToBurnNFTamount;
        uint256 locktime;
        bool isBurn;
    }

    struct NftBalance {
        uint256 stakingAmount;
        uint256 burnableAmount;
    }

    mapping(address => StakingInfo[]) public stakingInfo;
    mapping(address => BurningInfo[]) public burningInfo;
    mapping(address => NftBalance) public nftBalance;
    mapping(address => uint256) public ClaimAmount;

    uint256 private AprByMin = 240 * 1e6 wei;
    uint256 private BurnReturn = 2000 * 1e6 wei;
    uint256 public YearInSeconds = 31536000;

    event stakeInfo(address indexed user,uint256 stakeTime , uint256 amount , uint256 burnTime);
    event unStakeInfo(address indexed user,uint256 unstakeTime,uint256 amount);
    event WithDraw(address indexed user,uint256 withdrawTime,uint256 amount);
    event burn(address indexed user,uint256 amount,uint256 burntime);

    constructor() {
        InVariaNFT = IERC1155(inVaria);
        InVariaNFTBurn = BurnFunction(inVaria);
        USDC = IERC20(usdc);
    }

    function USDC_Balance() public view returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    // only Owner

    function withDrawUSDC(uint256 bal) external onlyOwner {
        USDC.transfer(WithDrawAddress, bal * 1e6);
    }

    //execute function
    function InputUSDC(uint256 balance) external {
        USDC.transferFrom(msg.sender, address(this), balance * 1e6);
    }

    function stakeNFT(uint256 bal) external {
        require(InVariaNFT.balanceOf(msg.sender, 1) >= bal, "Invalid input balance");
        require(bal > 0, "Can't stake zero");

        InVariaNFT.safeTransferFrom(msg.sender, address(this), 1, bal, "");

        uint256 startTime = block.timestamp;
        stakingInfo[msg.sender].push(StakingInfo(bal, bal, startTime, startTime, false));
        nftBalance[msg.sender].stakingAmount += bal;
        updateBurningInfo(bal, startTime + YearInSeconds, msg.sender, nftBalance[msg.sender]);

        emit stakeInfo(msg.sender,block.timestamp , bal , startTime + YearInSeconds);
    }

    function updateBurningInfo(uint256 bal, uint256 locktime,
        address stakingAddress, NftBalance storage customerBalance) internal {
        if (customerBalance.burnableAmount == 0) {
            burningInfo[stakingAddress].push(BurningInfo(bal, bal, locktime, false));
            customerBalance.burnableAmount = bal;
        } else if (customerBalance.stakingAmount >
            customerBalance.burnableAmount) {
            uint256 burnableBalance =
                customerBalance.stakingAmount -
                customerBalance.burnableAmount;
            burningInfo[stakingAddress].push(BurningInfo(burnableBalance, burnableBalance, locktime, false));
            customerBalance.burnableAmount += burnableBalance;
        }
    }

    function unStake(uint256 unstakeAmount) external nonReentrant {
        require(nftBalance[msg.sender].stakingAmount >= unstakeAmount, "You don't have enough staking NFTs");
        uint256 leftToUnstakeAmount = unstakeAmount;
        uint256 unstakeTime = block.timestamp;

        ClaimAmount[msg.sender] += StakingReward_Balance(msg.sender);
        for (uint256 i = 0; i < stakingInfo[msg.sender].length; i++) {
            if (stakingInfo[msg.sender][i].isUnstake) continue;
            if (leftToUnstakeAmount == 0) break;

            StakingInfo storage stakeRecord = stakingInfo[msg.sender][i];
            if (leftToUnstakeAmount >= stakeRecord.leftToUnstakeNFTamount) {
                leftToUnstakeAmount -= stakeRecord.leftToUnstakeNFTamount;
                stakeRecord.leftToUnstakeNFTamount = 0;
                stakeRecord.isUnstake = true;
            } else {
                stakeRecord.leftToUnstakeNFTamount -= leftToUnstakeAmount;
                leftToUnstakeAmount = 0;
            }
            stakeRecord.unstaketime = unstakeTime;
        }

        emit unStakeInfo(msg.sender,block.timestamp,unstakeAmount);

        nftBalance[msg.sender].stakingAmount -= unstakeAmount;
        InVariaNFT.safeTransferFrom(address(this), msg.sender, 1, unstakeAmount, "");
    }

    function withDraw() external nonReentrant {
        uint256 claimAmount = CheckClaimValue(msg.sender);
        require(claimAmount > 0, "You can't claim");
        uint256 updateStakingTime = block.timestamp;

        for (uint256 i = 0; i < stakingInfo[msg.sender].length; i++) {
            if (!stakingInfo[msg.sender][i].isUnstake) {
                stakingInfo[msg.sender][i].unstaketime = updateStakingTime;
            }
        }

        ClaimAmount[msg.sender] = 0;
        USDC.transfer(msg.sender, claimAmount);

        emit WithDraw(msg.sender,block.timestamp,claimAmount);
    }

    function BurnNFT(uint256 burnAmount) external {
        require(InVariaNFT.balanceOf(msg.sender, 1) >= burnAmount, "Invalid input balance");
        uint256 leftToBurnAmount = burnAmount;

        for (uint256 i = 0; i < burningInfo[msg.sender].length; i++) {
            if (leftToBurnAmount == 0) break;
            BurningInfo storage burnRecord = burningInfo[msg.sender][i];
            require(block.timestamp > (burnRecord.locktime), "Unlock time is coming soon");
            if (burnRecord.isBurn) continue;

            if (leftToBurnAmount >= burnRecord.leftToBurnNFTamount) {
                leftToBurnAmount -= burnRecord.leftToBurnNFTamount;
                burnRecord.leftToBurnNFTamount = 0;
                burnRecord.isBurn = true;
            } else {
                burnRecord.leftToBurnNFTamount -= leftToBurnAmount;
                leftToBurnAmount = 0;
            }
        }

        nftBalance[msg.sender].burnableAmount -= burnAmount;
        InVariaNFTBurn.BurnInVariaNFT(msg.sender, burnAmount);
        USDC.transfer(msg.sender, BurnReturn * burnAmount);

        emit burn(msg.sender,burnAmount,block.timestamp);
    }

    function StakingReward_Balance(address stakingAddress)
        public
        view
        returns (uint256)
    {
        uint256 balance = 0;

        for (uint256 i = 0; i < stakingInfo[stakingAddress].length; i++) {
            StakingInfo memory stakeRecord = stakingInfo[stakingAddress][i];
            if (stakeRecord.isUnstake) continue;

            balance += stakeRecord.leftToUnstakeNFTamount *
                (block.timestamp - stakeRecord.unstaketime) *
                (AprByMin / YearInSeconds);
        }

        return balance;
    }

    function CheckClaimValue(address user) public view returns (uint256) {
        uint256 claimAmount = StakingReward_Balance(user) + ClaimAmount[user];
        return claimAmount;
    }

    function BurnNftInfo(address user)public view returns(uint256){

        uint256 Burnable = 0;
        for (uint256 i = 0; i < burningInfo[user].length; i++) {

            if(burningInfo[user][i].locktime <= block.timestamp){
                Burnable += burningInfo[user][i].leftToBurnNFTamount;
            }

        }

        return Burnable;
    }
}