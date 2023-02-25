// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract WagmiNftStaking is Ownable, ERC1155Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant BLOCKS_PER_DAY = 6426;
    uint256 private PRECISION_FACTOR;

    // Whether it is initialized
    bool public isInitialized;
    uint256 public duration = 365; // 365 days

    // The block number when staking starts.
    uint256 public startBlock;
    // The block number when staking ends.
    uint256 public bonusEndBlock;
    // tokens created per block.
    uint256[2] public rewardsPerBlock;
    // The block number of the last pool update
    uint256 public lastRewardBlock;

    address public treasury = 0x64961Ffd0d84b2355eC2B5d35B0d8D8825A774dc;
    uint256 public performanceFee = 0.0064 ether;

    // The staked token
    IERC1155 public stakingNft;
    // The earned token
    address[2] public earnedToken;
    // Accrued token per share
    uint256[2] public accTokenPerShare;
    uint256 public oneTimeLimit = 40;
    bool public autoAdjustableForRewardRate = true;

    uint256 public totalStaked;
    uint256[2] private paidRewards;
    uint256[2] private shouldTotalPaid;

    struct UserInfo {
        uint256 amount; // number of staked NFTs
        uint256[] tokenIds; // staked tokenIds
        uint256[2] rewardDebt; // Reward debt
    }
    // Info of each user that stakes tokenIds

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256[] tokenIds);
    event Claim(address indexed user, uint256[2] amounts);
    event EmergencyWithdraw(address indexed user, uint256[] tokenIds);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardsPerBlock(uint256[2] rewardsPerBlock);
    event RewardsStop(uint256 blockNumber);
    event EndBlockUpdated(uint256 blockNumber);

    event ServiceInfoUpadted(address _addr, uint256 _fee);
    event DurationUpdated(uint256 _duration);
    event SetAutoAdjustableForRewardRate(bool status);

    constructor() {}

    /*
    * @notice Initialize the contract
    * @param _stakingNft: nft address to stake
    * @param _earnedToken: earned token addresses
    * @param _rewardsPerBlock: rewards per block (in earnedToken)
    */
    function initialize(IERC1155 _stakingNft, address[2] memory _earnedToken, uint256[2] memory _rewardsPerBlock)
        external
        onlyOwner
    {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingNft = _stakingNft;
        earnedToken = _earnedToken;
        rewardsPerBlock = _rewardsPerBlock;

        PRECISION_FACTOR = uint256(10 ** 20);
    }

    /*
    * @notice Deposit staked tokens and collect reward tokens (if any)
    * @param _amount: amount to withdraw (in earnedToken)
    */
    function deposit(uint256[] memory _tokenIds) external payable nonReentrant {
        require(startBlock > 0 && startBlock < block.number, "Staking hasn't started yet");
        require(_tokenIds.length > 0, "must add at least one tokenId");
        require(_tokenIds.length <= oneTimeLimit, "cannot exceed one-time limit");

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256[2] memory pending;
            for (uint256 i = 0; i < 2; i++) {
                pending[i] = (user.amount * accTokenPerShare[i]) / PRECISION_FACTOR - user.rewardDebt[i];
                if (pending[i] > 0) {
                    require(availableRewardTokens(i) >= pending[i], "Insufficient reward tokens");
                    _safeTokenTransfer(earnedToken[i], msg.sender, pending[i]);
                    paidRewards[i] += pending[i];
                }
            }
            if (pending[0] > 0 || pending[1] > 0) {
                emit Claim(msg.sender, pending);
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            stakingNft.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
            user.tokenIds.push(tokenId);
        }
        user.amount = user.amount + _tokenIds.length;
        user.rewardDebt[0] = (user.amount * accTokenPerShare[0]) / PRECISION_FACTOR;
        user.rewardDebt[1] = (user.amount * accTokenPerShare[1]) / PRECISION_FACTOR;

        totalStaked = totalStaked + _tokenIds.length;
        emit Deposit(msg.sender, _tokenIds);

        if (autoAdjustableForRewardRate) _updateRewardRate();
    }

    /*
    * @notice Withdraw staked tokenIds and collect reward tokens
    * @param _amount: number of tokenIds to unstake
    */
    function withdraw(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");
        require(_amount <= oneTimeLimit, "cannot exceed one-time limit");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _transferPerformanceFee();
        _updatePool();

        if (user.amount > 0) {
            uint256[2] memory pending;
            for (uint256 i = 0; i < 2; i++) {
                pending[i] = (user.amount * accTokenPerShare[i]) / PRECISION_FACTOR - user.rewardDebt[i];
                if (pending[i] > 0) {
                    require(availableRewardTokens(i) >= pending[i], "Insufficient reward tokens");
                    _safeTokenTransfer(earnedToken[i], msg.sender, pending[i]);
                    paidRewards[i] += pending[i];
                }
            }
            if (pending[0] > 0 || pending[1] > 0) {
                emit Claim(msg.sender, pending);
            }
        }

        uint256[] memory _tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds.pop();

            _tokenIds[i] = tokenId;
            stakingNft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }
        user.amount = user.amount - _amount;
        user.rewardDebt[0] = (user.amount * accTokenPerShare[0]) / PRECISION_FACTOR;
        user.rewardDebt[1] = (user.amount * accTokenPerShare[1]) / PRECISION_FACTOR;

        totalStaked = totalStaked - _amount;
        emit Withdraw(msg.sender, _tokenIds);

        if (autoAdjustableForRewardRate) _updateRewardRate();
    }

    function claimReward() external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256[2] memory pending;
        for (uint256 i = 0; i < 2; i++) {
            pending[i] = (user.amount * accTokenPerShare[i]) / PRECISION_FACTOR - user.rewardDebt[i];
            if (pending[i] > 0) {
                require(availableRewardTokens(i) >= pending[i], "Insufficient reward tokens");
                _safeTokenTransfer(earnedToken[i], msg.sender, pending[i]);
                paidRewards[i] += pending[i];
            }
        }

        user.rewardDebt[0] = (user.amount * accTokenPerShare[0]) / PRECISION_FACTOR;
        user.rewardDebt[1] = (user.amount * accTokenPerShare[1]) / PRECISION_FACTOR;
        emit Claim(msg.sender, pending);
    }

    /*
    * @notice Withdraw staked NFTs without caring about rewards
    * @dev Needs to be for emergency.
    */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        if (_amount > oneTimeLimit) _amount = oneTimeLimit;

        uint256[] memory _tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds.pop();

            _tokenIds[i] = tokenId;
            stakingNft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }
        user.amount = user.amount - _amount;
        user.rewardDebt[0] = (user.amount * accTokenPerShare[0]) / PRECISION_FACTOR;
        user.rewardDebt[1] = (user.amount * accTokenPerShare[1]) / PRECISION_FACTOR;
        totalStaked = totalStaked - _amount;

        emit EmergencyWithdraw(msg.sender, _tokenIds);
    }

    function stakedInfo(address _user) external view returns (uint256, uint256[] memory) {
        return (userInfo[_user].amount, userInfo[_user].tokenIds);
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens(uint256 _index) public view returns (uint256) {
        if (_index > 1) return 0;
        if(earnedToken[_index] == address(0x0)) {
            return address(this).balance;
        }
        return IERC20(earnedToken[_index]).balanceOf(address(this));
    }

    function insufficientRewards() external view returns (uint256, uint256) {
        uint256[2] memory adjustedShouldTotalPaid;
        for (uint256 i = 0; i < 2; i++) {
            adjustedShouldTotalPaid[i] = shouldTotalPaid[i];
            uint256 remainRewards = availableRewardTokens(i) + paidRewards[i];

            if (startBlock == 0) {
                adjustedShouldTotalPaid[i] += rewardsPerBlock[i] * duration * BLOCKS_PER_DAY;
            } else {
                uint256 remainBlocks = _getMultiplier(lastRewardBlock, bonusEndBlock);
                adjustedShouldTotalPaid[i] += rewardsPerBlock[i] * remainBlocks;
            }

            if (remainRewards >= adjustedShouldTotalPaid[i]) adjustedShouldTotalPaid[i] = remainRewards;
            adjustedShouldTotalPaid[i] -= remainRewards;
        }

        return (adjustedShouldTotalPaid[0], adjustedShouldTotalPaid[1]);
    }

    /*
    * @notice View function to see pending reward on frontend.
    * @param _user: user address
    * @return Pending reward for a given user
    */
    function pendingReward(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];

        uint256[2] memory adjustedTokenPerShare;
        for (uint256 i = 0; i < 2; i++) {
            adjustedTokenPerShare[i] = accTokenPerShare[i];
            if (block.number > lastRewardBlock && totalStaked != 0 && lastRewardBlock > 0) {
                uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
                uint256 rewards = multiplier * rewardsPerBlock[i];

                adjustedTokenPerShare[i] += (rewards * PRECISION_FACTOR) / totalStaked;
            }
        }

        return (
            (user.amount * adjustedTokenPerShare[0]) / PRECISION_FACTOR - user.rewardDebt[0],
            (user.amount * adjustedTokenPerShare[1]) / PRECISION_FACTOR - user.rewardDebt[1]
        );
    }

    /**
     * Admin Methods
     */
    function increaseEmissionRate(uint256 _amountA, uint256 _amountB) external payable onlyOwner {
        require(startBlock > 0, "pool is not started");
        require(bonusEndBlock > block.number, "pool was already finished");

        if (earnedToken[0] == address(0x0)) _amountA = msg.value;
        if (earnedToken[1] == address(0x0)) _amountB = msg.value;
        require(_amountA > 0 || _amountB > 0, "invalid amount");

        _updatePool();

        if (earnedToken[0] != address(0x0)) {
            IERC20(earnedToken[0]).safeTransferFrom(msg.sender, address(this), _amountA);
        }
        if (earnedToken[1] != address(0x0)) {
            IERC20(earnedToken[1]).safeTransferFrom(msg.sender, address(this), _amountB);
        }
        _updateRewardRate();
    }

    function _updateRewardRate() internal {
        if (bonusEndBlock <= block.number) return;

        bool _updated = false;
        uint256 remainBlocks = bonusEndBlock - block.number;
        for (uint256 i = 0; i < 2; i++) {
            uint256 remainRewards = availableRewardTokens(i) + paidRewards[i];
            if (remainRewards > shouldTotalPaid[i]) {
                remainRewards = remainRewards - shouldTotalPaid[i];
                rewardsPerBlock[i] = remainRewards / remainBlocks;
                _updated = true;
            }
        }

        if (_updated) {
            emit NewRewardsPerBlock(rewardsPerBlock);
        }
    }

    /*
    * @notice Withdraw reward token
    * @dev Only callable by owner. Needs to be for emergency.
    */
    function emergencyRewardWithdraw(uint256 _amount, uint256 _index) external onlyOwner {
        if (_index > 1) return;
        require(block.number > bonusEndBlock, "Pool is running");
        require(availableRewardTokens(_index) >= _amount, "Insufficient reward tokens");

        if (_amount == 0) _amount = availableRewardTokens(_index);
        _safeTokenTransfer(earnedToken[_index], msg.sender, _amount);
    }

    function startReward() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = block.number + 100;
        bonusEndBlock = startBlock + duration * BLOCKS_PER_DAY;
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        _updatePool();

        for (uint256 i = 0; i < 2; i++) {
            uint256 remainRewards = availableRewardTokens(i) + paidRewards[i];
            if (remainRewards > shouldTotalPaid[i]) {
                remainRewards -= shouldTotalPaid[i];
                _safeTokenTransfer(earnedToken[i], msg.sender, remainRewards);
            }
        }

        bonusEndBlock = block.number;
        emit RewardsStop(bonusEndBlock);
    }

    function updateEndBlock(uint256 _endBlock) external onlyOwner {
        require(startBlock > 0, "Pool is not started");
        require(bonusEndBlock > block.number, "Pool was already finished");
        require(_endBlock > block.number && _endBlock > startBlock, "Invalid end block");

        bonusEndBlock = _endBlock;
        emit EndBlockUpdated(_endBlock);
    }

    /*
    * @notice Update rewards per block
    * @dev Only callable by owner.
    * @param _rewardsPerBlock: the rewards per block
    */
    function updaterewardsPerBlock(uint256[2] memory _rewardsPerBlock) external onlyOwner {
        rewardsPerBlock = _rewardsPerBlock;
        emit NewRewardsPerBlock(_rewardsPerBlock);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(_duration >= 30, "lower limit reached");

        duration = _duration;
        if (startBlock > 0) {
            bonusEndBlock = startBlock + duration * BLOCKS_PER_DAY;
            require(bonusEndBlock > block.number, "invalid duration");
        }
        emit DurationUpdated(_duration);
    }

    function setAutoAdjustableForRewardRate(bool _status) external onlyOwner {
        autoAdjustableForRewardRate = _status;
        emit SetAutoAdjustableForRewardRate(_status);
    }

    function setServiceInfo(address _treasury, uint256 _fee) external {
        require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
        require(_treasury != address(0x0), "Invalid address");

        treasury = _treasury;
        performanceFee = _fee;
        emit ServiceInfoUpadted(_treasury, _fee);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _token) external onlyOwner {
        require(_token != earnedToken[0], "Cannot be reward token");
        require(_token != earnedToken[1], "Cannot be reward token");

        uint256 amount = address(this).balance;
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(amount);
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(address(msg.sender), amount);
        }

        emit AdminTokenRecovered(_token, amount);
    }

    function _safeTokenTransfer(address _token, address _to, uint256 _amount) internal {
        if (_token == address(0x0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /*
    * @notice Update reward variables of the given pool to be up-to-date.
    */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock || lastRewardBlock == 0) return;
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        for (uint256 i = 0; i < 2; i++) {
            uint256 _reward = multiplier * rewardsPerBlock[i];
            accTokenPerShare[i] += (_reward * PRECISION_FACTOR) / totalStaked;
            shouldTotalPaid[i] += _reward;
        }

        lastRewardBlock = block.number;
    }

    /*
    * @notice Return reward multiplier over the given _from to _to block.
    * @param _from: block to start
    * @param _to: block to finish
    */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, "should pay small gas to compound or harvest");

        payable(treasury).transfer(performanceFee);
        if (msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /**
     * onERC1155Received(address operator,address from,uint256 tokenId,uint256 amount,bytes data) → bytes4
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        require(msg.sender == address(stakingNft), "not enabled NFT");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        virtual
        override
        returns (bytes4)
    {
        require(msg.sender == address(stakingNft), "not enabled NFT");
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}
}