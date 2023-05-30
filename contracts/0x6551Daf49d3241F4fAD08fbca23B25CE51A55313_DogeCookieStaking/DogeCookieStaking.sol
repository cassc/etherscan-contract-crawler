/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    // Set original owner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract DogeCookieStaking is Ownable {
    struct StakingOption {
        uint256 minUnlockPeriod;
        uint256 minStakingAmount;
        uint256 apy;
        bool accepting;
    }

    struct Staking {
        uint256 amount;
        uint256 unlockTime;
        uint256 optionIndex;
        bool isActive;
    }

    mapping(address => Staking[]) public stakings;
    mapping(address => uint256) public totalStakings;
    mapping(address => uint256) public rewards;

    IERC20 public token;
    StakingOption[] public stakingOptions;

    uint256 public totalAllowance = 0;
    uint256 public totalAvailable = 0;
    uint256 public totalStaked = 0;

    constructor() {
        token = IERC20(0x21D5AF064600f06F45B05A68FddC2464A5dDaF87);

        stakingOptions.push(
            StakingOption(5 * 2630000, 100000 * 1000000000, 15, true)
        );
        stakingOptions.push(
            StakingOption(10 * 2630000, 100000 * 1000000000, 30, true)
        );
        stakingOptions.push(
            StakingOption(12 * 2630000, 100000 * 1000000000, 35, true)
        );

        stakingOptions.push(
            StakingOption(5 * 2630000, 500000 * 1000000000, 20, true)
        );
        stakingOptions.push(
            StakingOption(10 * 2630000, 500000 * 1000000000, 40, true)
        );
        stakingOptions.push(
            StakingOption(12 * 2630000, 500000 * 1000000000, 50, true)
        );
        totalAvailable = 1000000000 * 1000000000;
    }

    function addStakingOption(
        uint256 minUnlockPeriod,
        uint256 apy,
        uint256 minStakingAmount
    ) external onlyOwner {
        stakingOptions.push(
            StakingOption(minUnlockPeriod, minStakingAmount, apy, true)
        );
    }

    function modifyStaking(uint256 index, bool value) external onlyOwner {
        stakingOptions[index].accepting = value;
    }

    function stake(uint256 amount, uint256 optionIndex) external {
        require(optionIndex < stakingOptions.length, "Invalid option index");
        StakingOption storage option = stakingOptions[optionIndex];
        require(amount >= option.minStakingAmount);
        require(option.accepting, "Not Active");
        uint256 issuing = (amount * option.apy) / 100;
        require(
            (totalAvailable - totalAllowance) >= issuing,
            "Not enough tokens to stake"
        );
        totalStakings[msg.sender]++;
        // Transfer tokens from the user to the contract
        token.transferFrom(msg.sender, address(this), amount);
        totalAllowance += issuing;
        totalStaked += amount;
        // Add a new staking for the user
        stakings[msg.sender].push(
            Staking(
                amount,
                block.timestamp + stakingOptions[optionIndex].minUnlockPeriod,
                optionIndex,
                true
            )
        );
    }

    function unstake(uint256 stakingIndex) external {
        require(
            stakingIndex < stakings[msg.sender].length,
            "Invalid staking index"
        );
        Staking storage staking = stakings[msg.sender][stakingIndex];
        require(staking.isActive, "Staking is not active");
        require(
            block.timestamp >= staking.unlockTime,
            "Minimum unlock period not completed"
        );

        // Calculate the rewards based on the staking period, APY, and staked amount
        //staking period in days rounded down to floor value
        uint256 reward = (staking.amount *
            stakingOptions[staking.optionIndex].apy) / 100;

        // Update the user's rewards
        rewards[msg.sender] += reward;

        totalAllowance -= reward;
        totalAvailable -= reward;
        totalStaked -= staking.amount;

        // Deactivate the staking
        staking.isActive = false;

        // Transfer the staked tokens and rewards back to the user
        token.transfer(msg.sender, staking.amount + reward);
    }

    function withDrawTokens() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function updateAvailable(uint256 _available) external onlyOwner {
        totalAvailable = _available;
    }

    function withdrawNativeToken() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}