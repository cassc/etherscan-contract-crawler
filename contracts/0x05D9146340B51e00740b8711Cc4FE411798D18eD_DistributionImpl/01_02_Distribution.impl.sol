// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./Distribution.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DistributionImpl is Distribution {

    using SafeMath for uint256;

    event Initialized(address token, address lp, uint amountPerBlock, uint distributableBlock);
    event Deposit(address lp, address token, uint amount, uint totalAmount);
    event RefixBlockAmount(address lp, address token, uint amountPerBlock);
    event Withdraw(address lp, address token, uint amount, uint totalAmount);

    event UpdateDistributionIndex(address target, address token, uint distributed, uint distributionIndex);
    event Distribute(address user, address target, address token, uint amount, uint currentIndex, uint userRewardSum);

    constructor() public Distribution() {}

    modifier onlyTreasury {
        require(msg.sender == treasury);
        _;
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    function version() public pure returns (string memory) {
        return "DistributionImpl20220921";
    }

    function estimateEndBlock() public view returns (uint) {
        return distributableBlock.add(totalAmount.sub(distributedAmount).ceilDiv(blockAmount));
    }

    function init(address _token, address _lp, uint _blockAmount, uint _blockNumber) public onlyTreasury {
        require(!isInitialized);
        isInitialized = true;

        require(_blockAmount != 0);
        require(_blockNumber > block.number);

        token = _token;
        lp = _lp;
        blockAmount = _blockAmount;
        distributableBlock = _blockNumber;
        distributedAmount = 0;

        emit Initialized(_token, _lp, _blockAmount, _blockNumber);
    }

    function depositToken(uint amount) public onlyTreasury {
        require(IERC20(token).transferFrom(treasury, address(this), amount));

        deposit(amount);
    }

    function deposit(uint amount) private {
        require(amount != 0);

        if (totalAmount != 0) {
            distributedAmount = distribution();
            distributableBlock = block.number;
        }
        totalAmount = totalAmount.add(amount);

        emit Deposit(lp, token, amount, totalAmount);
    }

    function refixBlockAmount(uint _blockAmount) public onlyTreasury {
        require(_blockAmount != 0);

        updateDistributionIndex();

        distributedAmount = distribution();
        blockAmount = _blockAmount;
        distributableBlock = block.number;

        emit RefixBlockAmount(lp, token, blockAmount);

    }

    function withdrawToken(uint amount) public onlyTreasury {
        require(amount != 0);
        uint distributed = distribution();
        require(distributed.add(amount) <= totalAmount);

        totalAmount = totalAmount.sub(amount);
        require(IERC20(token).transfer(treasury, amount));

        emit Withdraw(lp, token, amount, totalAmount);
    }

    function removeDistribution() public onlyTreasury {
        require(estimateEndBlock().add(7 days) < block.number);

        uint balance = 0;
        balance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(treasury, balance));
    }

    // ================================= Distribution =======================================

    function distribution() public view returns (uint){
        if(distributableBlock == 0 || distributableBlock > block.number) return distributedAmount;

        uint amount = distributedAmount.add(block.number.sub(distributableBlock).mul(blockAmount));

        return amount > totalAmount ? totalAmount : amount;
    }


    function getDistributionIndex() private view returns (uint) {
        uint distributed = distribution();

        if (distributed > lastDistributed) {
            uint thisDistributed = distributed.sub(lastDistributed);
            uint totalSupply = IERC20(lp).totalSupply();
            if (thisDistributed != 0 && totalSupply != 0) {
                return distributionIndex.add(thisDistributed.mul(10 ** 18).div(totalSupply));
            }
        }

        return distributionIndex;
    }

    function updateDistributionIndex() public {
        uint distributed = distribution();

        if (distributed > lastDistributed) {
            uint thisDistributed = distributed.sub(lastDistributed);
            uint totalSupply = IERC20(lp).totalSupply();

            lastDistributed = distributed;
            if (thisDistributed != 0 && totalSupply != 0) {
                distributionIndex = distributionIndex.add(thisDistributed.mul(10 ** 18).div(totalSupply));
            }

            emit UpdateDistributionIndex(lp, token, distributed, distributionIndex);
        }
    }

    function distribute(address user) public onlyTreasury nonReentrant {
        uint lastIndex = userLastIndex[user];
        uint currentIndex = getDistributionIndex();

        uint have = IERC20(lp).balanceOf(user);

        if (currentIndex > lastIndex) {
            userLastIndex[user] = currentIndex;

            if (have != 0) {
                uint amount = have.mul(currentIndex.sub(lastIndex)).div(10 ** 18);

                require(IERC20(token).transfer(user, amount));

                userRewardSum[user] = userRewardSum[user].add(amount);
                emit Distribute(user, lp, token, amount, currentIndex, userRewardSum[user]);
            }
        }
    }

    function () payable external { revert(); }
}