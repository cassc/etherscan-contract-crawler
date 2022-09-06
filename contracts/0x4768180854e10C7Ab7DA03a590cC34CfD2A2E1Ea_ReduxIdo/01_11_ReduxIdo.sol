// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IPool.sol";
import "./Pool.sol";
import "./Validations.sol";

interface IStake {
    struct UserData {
        uint256 stakeToken;
        uint256 rewards;
        uint256 lastUpdateTime;
        uint256 stakingTime;
    }

    function users(address user) external view returns (UserData memory);
}

contract ReduxIdo is Pausable, Ownable {
    using SafeERC20 for IERC20;
    IPool private pool;
    address public stakingContract;

    event LogPoolCreated(address indexed poolOwner);
    event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);
    event LogWithdraw(address indexed participant, uint256 amount);

    constructor(address _stakingContract) {
        require(
            address(0) != address(_stakingContract),
            "zero address not accepted!"
        );
        stakingContract = _stakingContract;
    }

    function createPool(
        uint256 _hardCap,
        uint256 _startDateTime,
        uint256 _endDateTime,
        uint256 _status
    ) external onlyOwner _createPoolOnlyOnce returns (bool success) {
        IPool.PoolModel memory model = IPool.PoolModel({
            hardCap: _hardCap,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            status: IPool.PoolStatus(_status)
        });

        pool = new Pool(model);
        emit LogPoolCreated(_msgSender());
        success = true;
    }

    function addIDOInfo(
        address _investmentTokenAddress,
        uint256 _minAllocationPerUser,
        uint256 _maxAllocationPerUser
    ) external onlyOwner {
        pool.addIDOInfo(
            IPool.IDOInfo({
                investmentTokenAddress: _investmentTokenAddress,
                minAllocationPerUser: _minAllocationPerUser,
                maxAllocationPerUser: _maxAllocationPerUser
            })
        );
    }

    function updatePoolStatus(uint256 newStatus)
        external
        onlyOwner
        returns (bool success)
    {
        pool.updatePoolStatus(newStatus);
        emit LogPoolStatusChanged(_msgSender(), newStatus);
        success = true;
    }

    function getCompletePoolDetails()
        external
        view
        _poolIsCreated
        returns (IPool.CompletePoolDetails memory poolDetails)
    {
        poolDetails = pool.getCompletePoolDetails();
    }

    // Whitelisted accounts can invest in the Pool
    function participate(uint256 amount) external {
        require(
            IStake(stakingContract).users(msg.sender).stakeToken >= 500 ether,
            "User not staked required amount"
        );
        pool.deposit(msg.sender, amount);
    }

    function poolAddress() external view returns (address _pool) {
        _pool = address(pool);
    }

    function withdrawFunds(address fundsWallet) public onlyOwner {
        address investmentTokenAddress = pool.getInvestmentTokenAddress();
        uint256 totalRaisedAmount = IERC20(investmentTokenAddress).balanceOf(
            address(this)
        );
        require(totalRaisedAmount > 0, "Raised funds should be greater than 0");
        IERC20(investmentTokenAddress).safeTransfer(
            fundsWallet,
            totalRaisedAmount
        );
    }

    modifier _createPoolOnlyOnce() {
        require(address(pool) == address(0), "Pool already created!");
        _;
    }

    modifier _poolIsCreated() {
        require(address(pool) != address(0), "Pool not created yet!");
        _;
    }
}