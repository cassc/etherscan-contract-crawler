/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract TokenStakingBrickInfinity is Context, Ownable, ReentrancyGuard {
    IERC20 public addressBrickInfinity;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _userStakingStartTime;
    uint256 private _totalSupply = 0;
    uint32 private _day = 86400;
    uint32 private _year = 31556926;
    uint256 public reclaimRestakeLockTime = _day;
    uint16 public annualPercentageRateAPR = 5;

    event UpdatedAPR(uint16, uint16);
    event StakedBrick(address, uint256);
    event ClaimedBrick(address, uint256);
    event ReStakedBrickRewards(address, uint256);
    event UnstakedBrick(address, uint256);
    event TotalBrickUpdated(uint256);
    event UserBrickUpdated(uint256);

    modifier checkReclaimRestakeLockTime(address account) {
        uint256 timePassed = block.timestamp - _userStakingStartTime[account];
        require(
            timePassed >= reclaimRestakeLockTime,
            "TokenStakingBrickInfinity: reclaim/restake within 24 hours"
        );
        _;
    }

    constructor(address _addressBrickInfinity) {
        addressBrickInfinity = IERC20(_addressBrickInfinity);
    }

    function stakeTokens(
        uint256 amount
    ) external checkReclaimRestakeLockTime(_msgSender()) {
        address from = _msgSender();
        if (_balances[from] > 0) {
            uint256 currentRewards = _restakeRewards(from);
            emit ReStakedBrickRewards(from, currentRewards);
        }
        _stakeTokens(from, amount);

        emit StakedBrick(from, amount);
        emit TotalBrickUpdated(totalSupply());
        emit UserBrickUpdated(balanceOf(from));
    }

    function _stakeTokens(address from, uint256 amount) private {
        address to = address(this);
        _balances[from] += amount;
        _totalSupply += amount;
        _userStakingStartTime[from] = block.timestamp;

        require(
            addressBrickInfinity.transferFrom(from, to, amount),
            "TokenStakingBrickInfinity: BrickInfinity transferFrom not succeeded"
        );
    }

    function restakeRewards()
        external
        checkReclaimRestakeLockTime(_msgSender())
        nonReentrant
    {
        address beneficiary = _msgSender();
        uint256 currentRewards = _restakeRewards(beneficiary);

        emit ReStakedBrickRewards(beneficiary, currentRewards);
        emit TotalBrickUpdated(totalSupply());
        emit UserBrickUpdated(balanceOf(beneficiary));
    }

    function _restakeRewards(address beneficiary) private returns (uint256) {
        require(
            _balances[beneficiary] > 0,
            "TokenStakingBrickInfinity: no BRICK stake amount exists for respective beneficiary"
        );
        uint256 currentRewards = _calculateClaimableRewards(beneficiary);
        require(
            currentRewards <= totalSupplyBrickRewards(),
            "TokenStakingBrickInfinity: BRICK rewards amount exceed contract balance"
        );
        _balances[beneficiary] += currentRewards;
        _totalSupply += currentRewards;
        _userStakingStartTime[beneficiary] = block.timestamp;

        return currentRewards;
    }

    function _calculateClaimableRewards(
        address beneficiary
    ) private view returns (uint256) {
        uint256 timePassed = block.timestamp -
            _userStakingStartTime[beneficiary];
        uint256 annualReward = (_balances[beneficiary] *
            annualPercentageRateAPR) / 100;
        uint256 currentReward = (annualReward * timePassed) / _year;

        return currentReward;
    }

    function claimRewards()
        external
        checkReclaimRestakeLockTime(_msgSender())
        nonReentrant
    {
        address beneficiary = _msgSender();
        uint256 claimableRewards = _claimRewards(beneficiary);

        emit ClaimedBrick(beneficiary, claimableRewards);
        emit TotalBrickUpdated(totalSupply());
        emit UserBrickUpdated(balanceOf(beneficiary));
    }

    function _claimRewards(address beneficiary) private returns (uint256) {
        require(
            _balances[beneficiary] > 0,
            "TokenStakingBrickInfinity: no BRICK stake amount exists for respective beneficiary"
        );
        uint256 currentRewards = _calculateClaimableRewards(beneficiary);
        require(
            currentRewards <= totalSupplyBrickRewards(),
            "TokenStakingBrickInfinity: BRICK rewards amount exceeds contract balance"
        );
        _userStakingStartTime[beneficiary] = block.timestamp;
        require(
            addressBrickInfinity.transfer(beneficiary, currentRewards),
            "TokenStakingBrickInfinity: BrickInfinity transfer not succeeded"
        );

        return currentRewards;
    }

    function viewUserBrickRewards(
        address beneficiary
    ) external view returns (uint256) {
        return _calculateClaimableRewards(beneficiary);
    }

    function unstakeTokens(uint256 amount) external nonReentrant {
        address to = _msgSender();
        require(
            _balances[to] > 0,
            "TokenStakingBrickInfinity: no BRICK stake amount exists for respective beneficiary"
        );
        require(
            amount <= _balances[to],
            "TokenStakingBrickInfinity: unstake amount exceeds balance"
        );

        uint256 currentRewards = 0;
        if (_calculateClaimableRewards(to) <= totalSupplyBrickRewards()) {
            currentRewards = _restakeRewards(to);
        }
        _unstakeTokens(to, amount + currentRewards);

        emit UnstakedBrick(to, amount + currentRewards);
        emit TotalBrickUpdated(totalSupply());
        emit UserBrickUpdated(balanceOf(to));
    }

    function _unstakeTokens(address to, uint256 amount) private {
        _balances[to] -= amount;
        _totalSupply -= amount;
        _userStakingStartTime[to] = block.timestamp;
        require(
            addressBrickInfinity.transfer(to, amount),
            "TokenStakingBrickInfinity: BrickInfinity transfer not succeeded"
        );
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyBrickRewards() public view returns (uint256) {
        return (addressBrickInfinity.balanceOf(address(this)) - _totalSupply);
    }

    function getCurrentTime() external view virtual returns (uint256) {
        return block.timestamp;
    }

    function changeBrickInfinityAddress(
        address newAddressBrickInfinity
    ) external onlyOwner returns (bool) {
        addressBrickInfinity = IERC20(newAddressBrickInfinity);

        return true;
    }

    function setAPR(uint16 newAPR) external onlyOwner {
        uint16 oldAPR = annualPercentageRateAPR;
        annualPercentageRateAPR = newAPR;

        emit UpdatedAPR(oldAPR, newAPR);
    }

    function name() external pure returns (string memory) {
        return "StakedBrickInfinity";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() external pure returns (string memory) {
        return "BRICK";
    }
}