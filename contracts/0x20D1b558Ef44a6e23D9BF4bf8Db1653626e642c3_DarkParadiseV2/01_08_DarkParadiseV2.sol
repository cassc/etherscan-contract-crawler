//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import "./ERC1155Tradable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);

        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// Inheritance

// https://docs.synthetix.io/contracts/RewardsDistributionRecipient
contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;

    function notifyRewardAmount(
        uint256 rewardNotifyAmount,
        uint256 rewardTransferAmount
    ) external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Wrong caller");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }
}

contract TokenWrapper is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _stakingToken) public {
        stakingToken = IERC20(_stakingToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal nonReentrant {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }
}

interface IStratAccessNft {
    function getTotalUseCount(address _account, uint256 _id)
        external
        view
        returns (uint256);

    function getStratUseCount(
        address _account,
        uint256 _id,
        address _strategy
    ) external view returns (uint256);

    function startUsingNFT(address _account, uint256 _id) external;

    function endUsingNFT(address _account, uint256 _id) external;
}

contract DarkParadiseV2 is TokenWrapper, RewardsDistributionRecipient {
    IERC20 public rewardsToken;

    uint256 public DURATION = 1 seconds;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    //NFT
    IStratAccessNft public nft;

    // common, rare, unique ids considered in range on 1-111
    uint256 public constant rareMinId = 101;
    uint256 public constant uniqueId = 111;

    uint256 public minNFTId = 223;
    uint256 public maxNFTId = 444;

    uint256 public commonLimit = 3200 * 10**18;
    uint256 public rareLimit = 16500 * 10**18;
    uint256 public uniqueLimit = 30000 * 10**18;

    mapping(address => uint256) public usedNFT;

    event RewardAdded(uint256 rewardNotifyAmount, uint256 rewardTransferAmount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DurationChange(uint256 newDuration, uint256 oldDuration);
    event NFTSet(IStratAccessNft indexed newNFT);

    constructor(
        address _owner,
        address _rewardsToken,
        address _stakingToken,
        IStratAccessNft _nft
    ) public TokenWrapper(_stakingToken) Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        nft = _nft;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getLimit(address user) public view returns (uint256) {
        uint256 nftId = usedNFT[user];
        if (nftId == 0) return 0;

        uint256 effectiveId = ((nftId - 1) % 111) + 1;
        if (effectiveId < rareMinId) return commonLimit;
        if (effectiveId < uniqueId) return rareLimit;
        return uniqueLimit;
    }

    function setNFT(IStratAccessNft _nftAddress) public onlyOwner {
        nft = _nftAddress;
        emit NFTSet(_nftAddress);
    }

    function setDepositLimits(
        uint256 _common,
        uint256 _rare,
        uint256 _unique
    ) external onlyOwner {
        if (commonLimit != _common) commonLimit = _common;
        if (rareLimit != _rare) rareLimit = _rare;
        if (uniqueLimit != _unique) uniqueLimit = _unique;
    }

    function setMinMaxNFT(uint256 _min, uint256 _max) external onlyOwner {
        if (minNFTId != _min) minNFTId = _min;
        if (maxNFTId != _max) maxNFTId = _max;
    }

    function setDuration(uint256 newDuration) external onlyOwner {
        emit DurationChange(newDuration, DURATION);
        DURATION = newDuration;
    }

    function stake(uint256 amount, uint256 _nftId)
        public
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        require(_nftId >= minNFTId && _nftId <= maxNFTId, "Invalid nft");

        if (usedNFT[msg.sender] == 0) {
            usedNFT[msg.sender] = _nftId;
            nft.startUsingNFT(msg.sender, _nftId);
        }

        require(
            (amount + balanceOf(msg.sender)) <= getLimit(msg.sender),
            "Crossing limit"
        );

        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        //When a user withdraws their entire SDT from the strat, the strat stops using their NFT
        if (balanceOf(msg.sender) - amount == 0) {
            uint256 nftId = usedNFT[msg.sender];
            usedNFT[msg.sender] = 0;
            nft.endUsingNFT(msg.sender, nftId);
        }
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(
        uint256 rewardNotifyAmount,
        uint256 rewardTransferAmount
    ) external onlyRewardsDistribution updateReward(address(0)) {
        require(rewardNotifyAmount >= rewardTransferAmount, "!Notify Amount");
        if (block.timestamp >= periodFinish) {
            rewardRate = rewardNotifyAmount.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = rewardNotifyAmount.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);

        rewardsToken.safeTransferFrom(
            msg.sender,
            address(this),
            rewardTransferAmount
        );
        emit RewardAdded(rewardNotifyAmount, rewardTransferAmount);
    }
}