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

interface IERC1155Extended is IERC1155 {
    function totalSupply() external view returns (uint256);
}

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
    // The block number of the last pool update
    uint256 public lastRewardBlock;

    address public treasury = 0x64961Ffd0d84b2355eC2B5d35B0d8D8825A774dc;
    uint256 public performanceFee = 0.00089 ether;

    // The staked token
    IERC1155 public stakingNft;
    // The earned token
    address[2] public earnedToken;
    uint256 public oneTimeLimit = 30;
    uint256 public stakingUserLimit = 50;

    uint256 public totalStaked;
    uint256[2] public paidRewards;
    uint256[2] public totalRewardShares;

    struct UserInfo {
        uint256 amount; // number of staked NFTs
        uint256[] tokenIds; // staked tokenIds
        mapping(uint256 => uint256) indexOfTokenId;
    }

    // Info of each user that stakes tokenIds
    mapping(address => UserInfo) private userInfo;
    mapping(uint256 => uint256[2]) private claimedAmountsForNft;

    event Deposit(address indexed user, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256[] tokenIds);
    event Claim(address indexed user, uint256[2] amounts);
    event EmergencyWithdraw(address indexed user, uint256[] tokenIds);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event RewardsStop(uint256 blockNumber);
    event EndBlockUpdated(uint256 blockNumber);

    event SetUserLimit(uint256 limit);
    event ServiceInfoUpadted(address addr, uint256 fee);

    constructor() {}

    /**
     * @notice Initialize the contract
     * @param _stakingNft: nft address to stake
     * @param _earnedToken: earned token addresses
     */
    function initialize(IERC1155 _stakingNft, address[2] memory _earnedToken) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingNft = _stakingNft;
        earnedToken = _earnedToken;
        PRECISION_FACTOR = uint256(10 ** 20);
    }

    /**
     * @notice Deposit staked NFTs and collect reward tokens (if any)
     * @param _tokenIds: tokenIds to deposit
     */
    function deposit(uint256[] memory _tokenIds) external payable nonReentrant {
        require(startBlock > 0 && startBlock < block.number, "Staking hasn't started yet");
        require(_tokenIds.length > 0, "must add at least one tokenId");
        require(_tokenIds.length <= oneTimeLimit, "cannot exceed one-time limit");
        require(userInfo[msg.sender].amount + _tokenIds.length <= stakingUserLimit, "cannot exceed staking limit");

        _transferPerformanceFee();
        _updatePool();

        UserInfo storage user = userInfo[msg.sender];
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            stakingNft.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
            user.tokenIds.push(tokenId);
            user.indexOfTokenId[tokenId] = user.tokenIds.length;
        }
        user.amount = user.amount + _tokenIds.length;
        totalStaked = totalStaked + _tokenIds.length;
        emit Deposit(msg.sender, _tokenIds);

        uint256[2] memory pending = _processPendingReward();
        if (pending[0] > 0 || pending[1] > 0) {
            emit Claim(msg.sender, pending);
        }
    }

    /**
     * @notice Withdraw staked NFTs and collect reward tokens
     * @param _tokenIds: tokenIds to unstake
     */
    function withdraw(uint256[] memory _tokenIds) external payable nonReentrant {
        require(_tokenIds.length > 0, "Amount should be greator than 0");
        require(_tokenIds.length <= oneTimeLimit, "cannot exceed one-time limit");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _tokenIds.length, "Amount to withdraw too high");

        _transferPerformanceFee();
        _updatePool();

        if (user.amount > 0) {
            uint256[2] memory pending = _processPendingReward();
            if (pending[0] > 0 || pending[1] > 0) {
                emit Claim(msg.sender, pending);
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 index = user.indexOfTokenId[_tokenId];
            require(index > 0, "You did not stake this item");

            uint256 tokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds[index - 1] = tokenId;
            user.tokenIds.pop();

            user.indexOfTokenId[tokenId] = index;
            user.indexOfTokenId[_tokenId] = 0;

            stakingNft.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
        }
        user.amount = user.amount - _tokenIds.length;
        totalStaked = totalStaked - _tokenIds.length;

        emit Withdraw(msg.sender, _tokenIds);
    }

    /**
     * @notice claim pending rewards for staked NFTs
     */
    function claimReward() external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256[2] memory pending = _processPendingReward();
        emit Claim(msg.sender, pending);
    }

    function _processPendingReward() internal returns (uint256[2] memory pending) {
        UserInfo storage user = userInfo[msg.sender];
        for (uint256 i = 0; i < user.tokenIds.length; i++) {
            uint256 tokenId = user.tokenIds[i];
            pending[0] += (totalRewardShares[0] - claimedAmountsForNft[tokenId][0]);
            pending[1] += (totalRewardShares[1] - claimedAmountsForNft[tokenId][1]);
            claimedAmountsForNft[tokenId][0] = totalRewardShares[0];
            claimedAmountsForNft[tokenId][1] = totalRewardShares[1];
        }
        _safeTokenTransfer(earnedToken[0], msg.sender, pending[0]);
        _safeTokenTransfer(earnedToken[1], msg.sender, pending[1]);

        paidRewards[0] += pending[0];
        paidRewards[1] += pending[1];
    }

    /**
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
            user.indexOfTokenId[tokenId] = 0;

            _tokenIds[i] = tokenId;
            stakingNft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        }
        user.amount = user.amount - _amount;
        totalStaked = totalStaked - _amount;

        emit EmergencyWithdraw(msg.sender, _tokenIds);
    }

    /**
     * @notice returns staked tokenIds and the number of user's staked tokenIds.
     */
    function stakedInfo(address _user) external view returns (uint256, uint256[] memory) {
        return (userInfo[_user].amount, userInfo[_user].tokenIds);
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens(uint256 _index) public view returns (uint256) {
        if (_index > 1) return 0;
        if (earnedToken[_index] == address(0x0)) {
            return address(this).balance;
        }
        return IERC20(earnedToken[_index]).balanceOf(address(this));
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _tokenId: user address
     * @return Pending rewards for a given tokenId
     */
    function pendingReward(uint256 _tokenId) external view returns (uint256, uint256) {
        uint256[2] memory tmpAllocations;
        uint256 totalSupply = IERC1155Extended(address(stakingNft)).totalSupply();
        for (uint256 i = 0; i < 2; i++) {
            uint256 _reward = availableRewardTokens(i);
            if (_reward + paidRewards[i] > totalRewardShares[i] * totalSupply) {
                _reward = _reward + paidRewards[i] - totalRewardShares[i] * totalSupply;
            } else {
                _reward = 0;
            }

            tmpAllocations[i] = totalRewardShares[i] + _reward / totalSupply;
        }

        return (
            tmpAllocations[0] - claimedAmountsForNft[_tokenId][0],
            tmpAllocations[1] - claimedAmountsForNft[_tokenId][1]
        );
    }

    /**
     * @notice Withdraw reward token
     * @param _amount: the token amount to withdraw
     * @param _index: the token index
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

    function updateUserLimit(uint256 _userLimit) external onlyOwner {
        stakingUserLimit = _userLimit;
        emit SetUserLimit(_userLimit);
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
        require(_token != earnedToken[0] && _token != earnedToken[1], "Cannot be reward token");

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

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        uint256 totalSupply = IERC1155Extended(address(stakingNft)).totalSupply();
        for (uint256 i = 0; i < 2; i++) {
            uint256 _reward = availableRewardTokens(i);
            if (_reward + paidRewards[i] > totalRewardShares[i] * totalSupply) {
                _reward = _reward + paidRewards[i] - totalRewardShares[i] * totalSupply;
            } else {
                _reward = 0;
            }

            totalRewardShares[i] += _reward / totalSupply;
        }

        lastRewardBlock = block.number;
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, "should pay small gas to call this method");

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