// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IERC20.sol';

contract PapaFeeding is ReentrancyGuard, Ownable {
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // addresses
    address private reserveAddress;
    address private poolAddress;

    // contract variables
    bool public isPaused = false;
    bool public swapClosed = false;
    bool public claimClosed = false;

    IERC20 public papa;
    IUniswapV2Router02 public uniswapV2Router;

    // Stake struct
    struct Stake {
        uint256 amount;
        uint256 lockPeriod;
        uint256 lockTime;
        uint256 multiplier;
        bool claimed;
    }

    // Lock struct
    struct Lock {
        uint256 lockPeriod;
        uint256 multiplier;
    }

    // Campaign struct
    struct Campaign {
        address tokenAddress;
        bool active;
        uint256 totalAmount;
        uint256 maxAmount;
    }

    // user => stakes
    mapping (address => Stake[]) public stakes;
    // campaign => locks
    mapping (uint256 => Lock[]) public campaignLocks;
    
    // Campaigns
    Campaign[] public campaigns;

    event Feed(address indexed user, uint256 campaignId, uint256 amountIn, uint256 amountOutWithReward, uint256 lockPeriod, uint256 multiplier);
    event Claim(address indexed user, uint256 amount);

    /**
    * @dev Constructor
    * @param _papa Address of the Papa token
    * @param _reserveAddress Address of the reserve
    */
    constructor(address _papa, address _reserveAddress, address _poolAddress) {
        papa = IERC20(_papa);
        reserveAddress = _reserveAddress;
        poolAddress = _poolAddress;
        uniswapV2Router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }

    /**
    * @dev Modifier to check if the contract is paused
    */
    modifier notPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    /**
    * @dev Modifier to check if the swap is open
    */
    modifier swapOpen() {
        require(!swapClosed, "Swap is closed");
        _;
    }

    /**
    * @dev Modifier to check if the claim is open
    */
    modifier claimOpen() {
        require(!claimClosed, "Claim is closed");
        _;
    }

    /**
    * @dev Add a campaign
    * @param tokenAddress Address of the token
    * @param amount Amount of the token
    * @param active Boolean
    * @param locks uint256[] array
    * @param multipliers uint256[] array
    */
    function addCampaign(
        address tokenAddress,
        uint256 amount,
        bool active,
        uint256[] calldata locks,
        uint256[] calldata multipliers
    ) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(locks.length == multipliers.length, "Locks and multipliers length mismatch");
        // transfer the token amount to the contract
        papa.transferFrom(poolAddress, address(this), amount);
        // approve the max token amount for the uniswap router
        IERC20(tokenAddress).approve(address(uniswapV2Router), 2**256 - 1);
        // add the campaign
        Campaign memory campaign = Campaign(tokenAddress, active, 0, amount);
        campaigns.push(campaign);
        // add the locks
        for (uint256 i = 0; i < locks.length; i++) {
            campaignLocks[campaigns.length - 1].push(Lock(locks[i], multipliers[i]));
        }
    }

    /**
    * @dev Update a campaign
    * @param campaignId Id of the campaign
    * @param active Boolean
    */
    function updateCampaign(uint256 campaignId, bool active) external onlyOwner {
        campaigns[campaignId].active = active;
    }

    function closeCampaign(uint256 campaignId) external onlyOwner {
        uint256 amountLeft = campaigns[campaignId].maxAmount - campaigns[campaignId].totalAmount;
        // transfer the amount left to the reserve
        papa.transfer(reserveAddress, amountLeft);
        // set the campaign to inactive
        campaigns[campaignId].active = false;
    }

    /**
    * @dev Set the reserve address
    * @param _reserveAddress Address of the reserve
    */
    function setReserveAddress(address _reserveAddress) external onlyOwner {
        reserveAddress = _reserveAddress;
    }

    /**
    * @dev Set the pool address
    * @param _poolAddress Address of the pool
    */
    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
    }

    /**
    * @dev Set the isPaused variable
    * @param _isPaused Boolean
    */
    function setPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @dev Set the swapClosed variable
    * @param _swapClosed Boolean
     */
    function setSwapClosed(bool _swapClosed) external onlyOwner {
        swapClosed = _swapClosed;
    }

    /**
    * @dev Set the claimClosed variable
    * @param _claimClosed Boolean
    */
    function setClaimClosed(bool _claimClosed) external onlyOwner {
        claimClosed = _claimClosed;
    }

    /**
    * @dev Get the stakes of a user
    * @param _user Address of the user
    * @return Stake[] memory
    */
    function getStakes(address _user) external view returns (Stake[] memory) {
        return stakes[_user];
    }

    /**
    * @dev Swap ETH for Papa and stake the Papa amount
    * @param amountOutMin Minimum amount of Papa to receive
    * @param deadline Unix timestamp after which the transaction will revert
    */
    function swap(
        uint256 campaignId,
        uint256 lockId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external nonReentrant notPaused swapOpen
    {
        Campaign memory campaign = campaigns[campaignId];
        // check if the campaign is active
        require(campaign.active, "Campaign is not active");
        require(amountIn > 0, "Amount must be greater than 0");
        require(lockId < campaignLocks[campaignId].length, "Lock id does not exist");
        // transfer the token amount from the user to this contract
        IERC20(campaign.tokenAddress).transferFrom(msg.sender, address(this), amountIn);

        // get the lock
        Lock memory lock = campaignLocks[campaignId][lockId];
        
        // swap path
        address[] memory path = new address[](3);
        path[0] = campaign.tokenAddress;
        path[1] = WETH_ADDRESS;
        path[2] = address(papa);

        // make the swap
        uint[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
            amountIn, amountOutMin, path, reserveAddress, deadline
        );
        // get the amount of Papa received
        uint256 amountOut = amounts[amounts.length - 1];
        // calculate the amount with the reward
        uint256 amountOutWithReward = amountOut * lock.multiplier / 100;
        // check if the campaign max amount is reached
        require(campaign.totalAmount + amountOutWithReward <= campaign.maxAmount, "Campaign max amount reached");
        // update the campaign total amount
        campaigns[campaignId].totalAmount = campaign.totalAmount + amountOutWithReward;
        // stake the papa amount
        stakes[msg.sender].push(Stake(
            amountOutWithReward,
            lock.lockPeriod,
            block.timestamp,
            lock.multiplier,
            false
        ));
        // emit the event
        emit Feed(msg.sender, campaignId, amountIn, amountOutWithReward, lock.lockPeriod, lock.multiplier);
    }

    /**
    * @dev Claim the staked Papa amount
    * @param stakeId Stake ID
    */
    function claim(uint256 stakeId) external nonReentrant notPaused claimOpen {
        Stake memory stake = stakes[msg.sender][stakeId];
        require(!stake.claimed, "Stake already claimed");
        require(stake.lockTime + stake.lockPeriod <= block.timestamp, "Stake is still locked");
        stakes[msg.sender][stakeId].claimed = true;
        papa.transfer(msg.sender, stake.amount);
        emit Claim(msg.sender, block.timestamp);
    }

    /**
    * @dev Emergency function to withdraw the Papa amount
    */
    function emergency() external onlyOwner {
        papa.transfer(msg.sender, papa.balanceOf(address(this)));
    }

}