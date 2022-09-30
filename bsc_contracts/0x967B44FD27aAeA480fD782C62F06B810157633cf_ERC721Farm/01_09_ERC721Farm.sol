//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IFarmDeployer.sol";


contract ERC721Farm is Ownable, ReentrancyGuard, IERC721Farm{

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256[] tokenIds, uint256 rewards);
    event EmergencyWithdraw(address indexed user, uint256[] tokenIds);
    event NewStartBlock(uint256 startBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewMinimumLockTime(uint256 minimumLockTime);
    event NewUserStakeLimit(uint256 userStakeLimit);
    event Withdraw(address indexed user, uint256[] tokenIds, uint256 rewards);

    IERC721 public stakeToken;
    IERC20 public rewardToken;
    IFarmDeployer private farmDeployer;


    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public rewardPerBlock;
    uint256 public userStakeLimit;
    uint256 public minimumLockTime;
    uint256 public stakeTokenSupply = 0;
    uint256 public totalPendingReward = 0;
    uint256 public lastRewardTokenBalance = 0;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each user that stakes tokens (stakeToken)
    mapping(address => UserInfo) public userInfo;
    bool private initialized = false;

    struct UserInfo {
        uint256[] tokenIds; // List of token IDs
        uint256 rewardDebt; // Reward debt
        uint256 depositBlock; // Reward debt
    }

    /*
     * @notice Initialize the contract
     * @param _stakeToken: stake token address
     * @param _rewardToken: reward token address
     * @param _startBlock: start block
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _userStakeLimit: maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: minimum number of blocks user should wait after deposit to withdraw without fee
     * @param owner: admin address with ownership
     */
    function initialize(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address contractOwner
    ) external {
        require(!initialized, "Already initialized");
        require(_rewardPerBlock > 0, "Invalid reward per block");
        initialized = true;

        transferOwnership(contractOwner);
        farmDeployer = IFarmDeployer(IFarmDeployer721(msg.sender).farmDeployer());

        stakeToken = IERC721(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        rewardPerBlock = _rewardPerBlock;
        userStakeLimit = _userStakeLimit;
        minimumLockTime = _minimumLockTime;

        uint256 decimalsRewardToken = uint256(
            IERC20Metadata(_rewardToken).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(30 - decimalsRewardToken));
    }


    /*
     * @notice Deposit staked tokens on behalf of msg.sender and collect reward tokens (if any)
     * @param tokenIds: Array of token index IDs to deposit
     */
    function deposit(uint256[] calldata tokenIds) external {
        _deposit(tokenIds, address(msg.sender));
    }


    /*
     * @notice Deposit staked tokens on behalf account and collect reward tokens (if any)
     * @param tokenIds: Array of token index IDs to deposit
     * @param account: future owner of deposit
     */
    function depositOnBehalf(uint256[] calldata tokenIds, address account) external {
        _deposit(tokenIds, account);
    }


    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @dev Requires approval for all to be set
     * @param tokenIds: Array of token index IDs to deposit
     * @param account: Future owner of deposit
     */
    function _deposit (
        uint256[] calldata tokenIds,
        address account
    ) internal nonReentrant {
        _collectFee();
        require(block.number >= startBlock, "Pool is not active yet");
        require(block.number < getFinalBlockNumber(), "Pool has ended");
        require(stakeToken.isApprovedForAll(msg.sender, address(this)), "Not approved");

        UserInfo storage user = userInfo[account];
        uint256 amountOfTokens = user.tokenIds.length;

        if (userStakeLimit > 0) {
            require(
                tokenIds.length + amountOfTokens <= userStakeLimit,
                "User amount above limit"
            );
        }

        _updatePool();

        uint256 pending = 0;
        if (amountOfTokens > 0) {
            pending = amountOfTokens * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                rewardToken.transfer(account, pending);
            }
            totalPendingReward -= pending;
        }

        for(uint i = 0; i < tokenIds.length; i++) {
            require(stakeToken.ownerOf(tokenIds[i]) == msg.sender, "Not an owner");
            user.tokenIds.push(tokenIds[i]);
            stakeToken.transferFrom(
                address(msg.sender),
                address(this),
                tokenIds[i]
            );
        }

        stakeTokenSupply += tokenIds.length;

        user.rewardDebt = user.tokenIds.length * accTokenPerShare / PRECISION_FACTOR;
        user.depositBlock = block.number;
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Deposit(account, tokenIds, pending);
    }


    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @notice Withdrawal before minimum lock time is impossible
     * @param tokenIds: Array of token index IDs to withdraw
     */
    function withdraw(uint256[] calldata tokenIds) external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountOfTokens = user.tokenIds.length;
        require(amountOfTokens >= tokenIds.length, "Invalid IDs");

        uint256 earliestBlockToWithdrawWithoutFee = user.depositBlock + minimumLockTime;
        require(block.number >= earliestBlockToWithdrawWithoutFee, "Can't withdraw yet");

        _updatePool();

        uint256 pending = amountOfTokens * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;

        if (tokenIds.length > 0) {
            for(uint i = 0; i < tokenIds.length; i++){
                bool tokenTransferred = false;
                for(uint j = 0; j < user.tokenIds.length; j++){
                    if(tokenIds[i] == user.tokenIds[j]) {
                        user.tokenIds[j] = user.tokenIds[user.tokenIds.length - 1];
                        user.tokenIds.pop();
                        stakeToken.transferFrom(address(this), msg.sender, tokenIds[i]);
                        tokenTransferred = true;
                        break;
                    }
                }
                require(tokenTransferred, "Token not found");
            }
            stakeTokenSupply -= tokenIds.length;
        }

        if (pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
            totalPendingReward -= pending;
        }

        user.rewardDebt = user.tokenIds.length * accTokenPerShare / PRECISION_FACTOR;
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit Withdraw(msg.sender, tokenIds, pending);
    }


    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        _collectFee();
        UserInfo storage user = userInfo[msg.sender];

        uint256[] memory tokenArray = user.tokenIds;
        uint256 tokensAmount = tokenArray.length;
        uint256 pending = tokensAmount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        totalPendingReward -= pending;
        delete user.tokenIds;
        user.rewardDebt = 0;

        if(tokensAmount > 0){
            for(uint i = 0; i < tokenArray.length; i++) {
                stakeToken.transferFrom(
                    address(this),
                    address(msg.sender),
                    tokenArray[i]
                );
            }
            stakeTokenSupply -= tokensAmount;
        }
        lastRewardTokenBalance = rewardToken.balanceOf(address(this));

        emit EmergencyWithdraw(msg.sender, tokenArray);
    }


    /*
     * @notice Calculates the last block number according to available funds
     */
    function getFinalBlockNumber() public view returns (uint256) {
        uint256 contractBalance = rewardToken.balanceOf(address(this));
        uint256 firstBlock = stakeTokenSupply == 0 ? block.number : lastRewardBlock;
        return firstBlock + (contractBalance - totalPendingReward) / rewardPerBlock;
    }


    /*
     * @notice Allows Owner to withdraw ERC20 tokens from the contract
     * @param _tokenAddress: Address of ERC20 token contract
     * @param _tokenAmount: Amount of tokens to withdraw
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        _updatePool();

        if(_tokenAddress == address(rewardToken)){
            uint256 allowedAmount = rewardToken.balanceOf(address(this)) - totalPendingReward;
            require(_tokenAmount <= allowedAmount, "Over allowed amount");
        }

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }


    /*
     * @notice Sets start block of the pool
     * @param _startBlock: Number of start block
     */
    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(_startBlock >= block.number, "Can't set past block");
        require(startBlock >= block.number, "Staking has already started");
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;

        emit NewStartBlock(_startBlock);
    }


    /*
     * @notice Sets reward amount per block
     * @param _rewardPerBlock: Token amount to be distributed for each block
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        require(_rewardPerBlock != 0);
        rewardPerBlock = _rewardPerBlock;

        emit NewRewardPerBlock(_rewardPerBlock);
    }


    /*
     * @notice Sets maximum amount of tokens 1 user is able to stake. 0 for no limit
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     */
    function setUserStakeLimit(uint256 _userStakeLimit) public onlyOwner {
        require(_userStakeLimit != 0);
        userStakeLimit = _userStakeLimit;

        emit NewUserStakeLimit(_userStakeLimit);
    }


    /*
     * @notice Sets minimum amount of blocks that should pass before user can withdraw his deposit
     * @param _minimumLockTime: Number of blocks
     */
    function setMinimumLockTime(uint256 _minimumLockTime) public onlyOwner {
        require(_minimumLockTime <= farmDeployer.maxLockTime(),"Over max lock time");
        require(_minimumLockTime < minimumLockTime, "Can't increase");
        minimumLockTime = _minimumLockTime;

        emit NewMinimumLockTime(_minimumLockTime);
    }


    /*
     * @notice Sets farm variables
     * @param _startBlock: Number of start block
     * @param _rewardPerBlock: Token amount to be distributed for each block
     * @param _userStakeLimit: Maximum amount of tokens allowed to stake
     * @param _minimumLockTime: Number of blocks
     */
    function setFarmValues(
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime
    ) external onlyOwner {
        //start block
        if (startBlock != _startBlock) {
            setStartBlock(_startBlock);
        }

        //reward per block
        if (rewardPerBlock != _rewardPerBlock) {
            setRewardPerBlock(_rewardPerBlock);
        }

        //user stake limit
        if (userStakeLimit != _userStakeLimit) {
            setUserStakeLimit(_userStakeLimit);
        }

        //min lock time
        if (minimumLockTime != _minimumLockTime) {
            setMinimumLockTime(_minimumLockTime);
        }
    }


    /*
     * @notice View function to get deposited tokens array.
     * @param _user User address
     * @return tokenIds Deposited token IDs array
     */
    function getUserStakedTokenIds(address _user)
        external
        view
        returns(uint256[] memory tokenIds)
    {
        return userInfo[_user].tokenIds;
    }


    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.number > lastRewardBlock && stakeTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                cakeReward * PRECISION_FACTOR / stakeTokenSupply;
            return user.tokenIds.length * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return user.tokenIds.length * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        }
    }


    /*
     * @notice Updates pool variables
     */
    function _updatePool() private {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (stakeTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier * rewardPerBlock;
        totalPendingReward += cakeReward;
        accTokenPerShare = accTokenPerShare +
            cakeReward * PRECISION_FACTOR / stakeTokenSupply;
        lastRewardBlock = block.number;
    }


    /*
     * @notice Calculates number of blocks to pay reward for.
     * @param _from: Starting block
     * @param _to: Ending block
     * @return Number of blocks, that should be rewarded
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    )
    private
    view
    returns (uint256)
    {
        uint256 finalBlock = getFinalBlockNumber();
        if (_to <= finalBlock) {
            return _to - _from;
        } else if (_from >= finalBlock) {
            return 0;
        } else {
            return finalBlock - _from;
        }
    }


    /*
     * @notice Calculates reward token income and transfers specific fee amount.
     * @notice Fee share and fee receiver are specified on Deployer contract
     */
    function _collectFee() private {
        uint256 incomeFee = farmDeployer.incomeFee();
        if (incomeFee > 0) {
            uint256 rewardBalance = rewardToken.balanceOf(address(this));
            if(rewardBalance != lastRewardTokenBalance) {
                uint256 income = rewardBalance - lastRewardTokenBalance;
                uint256 feeAmount = income * incomeFee / 10_000;
                rewardToken.transfer(farmDeployer.feeReceiver(), feeAmount);
            }
        }
    }
}