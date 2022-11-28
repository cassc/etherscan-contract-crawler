// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PerfuelStaking is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public prfAddress;

    uint256 public constant ROI_PERCENTAGE = 12; // 12%
    uint256 public constant TOTAL_PERCENTAGE = 100; // 100%
    uint256 public constant TOTAL_NUMBER_OF_DAYS = 365 days;
    uint256 public totalLiquidityProvided;

    struct DepositStruct {
        address investor;
        uint256 amountStaked;
        uint256 rewardAmount;
        uint256 stakedDate;
        uint256 releaseDate;
        bool isWithdrawn;
    }

    uint256 public currentDepositID;
    mapping(address=>uint256[]) public ownedDeposits;
    mapping(uint256=>DepositStruct) public depositData;
    uint256 public totalStaked;
    uint256 public totalWithdrawn;

    constructor(address _prfAddress) {
        require(
            _prfAddress!=address(0),
            "Invalid PRF Address"
        );
        prfAddress = _prfAddress;
    }

    function setPRFAddress(address _prfAddress) external onlyOwner{
        require(
            _prfAddress!=address(0),
            "Invalid PRF Address"
        );
        prfAddress = _prfAddress;
    }

    function invest(uint256 _amount) external {
        require(_amount>0,"Invalid amount");
        currentDepositID = currentDepositID.add(1);

        uint256 _id = currentDepositID;

        uint256 totalWithdrawal = _amount.mul(ROI_PERCENTAGE).div(TOTAL_PERCENTAGE).add(_amount);

        ownedDeposits[msg.sender].push(_id);

        depositData[_id] = DepositStruct({
            investor:msg.sender,
            amountStaked:_amount,
            rewardAmount:totalWithdrawal,
            stakedDate:block.timestamp,
            releaseDate:block.timestamp.add(TOTAL_NUMBER_OF_DAYS),
            isWithdrawn:false
        });

        totalStaked = totalStaked.add(_amount);
        IERC20(prfAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }


    function getTotalReward(address _investor) public view returns(uint256 totalReward) {
        uint256 length = ownedDeposits[_investor].length;
        for(uint256 i=0;i<length;i++){
            if(depositData[ownedDeposits[_investor][i]].releaseDate<=block.timestamp &&
             !depositData[ownedDeposits[_investor][i]].isWithdrawn){
                totalReward = totalReward.add(depositData[ownedDeposits[_investor][i]].rewardAmount);
            }
        }
    }

     function getSingleReward(uint256 _id) public view returns(uint256 totalReward) {
            if(depositData[_id].releaseDate<=block.timestamp &&
             !depositData[_id].isWithdrawn){
                totalReward = totalReward.add(depositData[_id].rewardAmount);
            }
    }

    function withdrawReward() external{
        address _investor = msg.sender;
        uint256 length = ownedDeposits[_investor].length;
        uint256 totalReward = 0;
        uint256 totalAmountStaked = 0;
        for(uint256 i=0;i<length;i++){
            if(depositData[ownedDeposits[_investor][i]].releaseDate<=block.timestamp &&
             !depositData[ownedDeposits[_investor][i]].isWithdrawn){
                depositData[ownedDeposits[_investor][i]].isWithdrawn = true; 
                totalReward = totalReward.add(depositData[ownedDeposits[_investor][i]].rewardAmount);
                totalAmountStaked = totalAmountStaked.add(depositData[ownedDeposits[_investor][i]].amountStaked);
            }
        }

        require(totalReward>0,"Cannot withdraw reward at the moment");
        require(totalReward<=getPRFBalance(),"Insufficient amount in the reward pool");

        if(totalReward.sub(totalAmountStaked)<=totalLiquidityProvided){
            totalLiquidityProvided = totalLiquidityProvided.sub(totalReward.sub(totalAmountStaked));
        }

        totalWithdrawn = totalWithdrawn.add(totalReward);
        IERC20(prfAddress).safeTransfer(msg.sender,totalReward);
    }

    function withdrawSingleReward(uint256 _id) external{
        require(depositData[_id].investor==msg.sender,"Invalid id");
        uint256 totalReward = 0;
        uint256 totalAmountStaked = 0;
            if(depositData[_id].releaseDate<=block.timestamp &&
             !depositData[_id].isWithdrawn){
                depositData[_id].isWithdrawn = true; 
                totalReward = totalReward.add(depositData[_id].rewardAmount);
                totalAmountStaked = totalAmountStaked.add(depositData[_id].amountStaked);
            }

        require(totalReward>0,"Cannot withdraw reward at the moment");
        require(totalReward<=getPRFBalance(),"Insufficient amount in the reward pool");
        
        if(totalReward.sub(totalAmountStaked)<=totalLiquidityProvided){
            totalLiquidityProvided = totalLiquidityProvided.sub(totalReward.sub(totalAmountStaked));
        }
        totalWithdrawn = totalWithdrawn.add(totalReward);
        IERC20(prfAddress).safeTransfer(msg.sender,totalReward);
    }

    function getPRFBalance() public view returns(uint256 totalPrfBalance){
        totalPrfBalance = IERC20(prfAddress).balanceOf(address(this));
    }

    function getPRFLiquidity() public view returns(uint256 totalPrfBalance){
        totalPrfBalance = totalLiquidityProvided;
    }

    function addLiquidity(uint256 _amount) external onlyOwner{
        require(_amount>0,"Invalid amount");
        totalLiquidityProvided = totalLiquidityProvided.add(_amount);
        IERC20(prfAddress).safeTransferFrom(msg.sender,address(this),_amount);
    }

    function removeLiquidity(uint256 _amount) external onlyOwner{
        require(_amount<=totalLiquidityProvided,"Insufficient liquidity");
        totalLiquidityProvided = totalLiquidityProvided.sub(_amount);
        IERC20(prfAddress).safeTransfer(msg.sender,_amount);
    }

    function getOwnedDeposits(address _investors) public view returns(uint256[] memory){
        return ownedDeposits[_investors];
    }

}