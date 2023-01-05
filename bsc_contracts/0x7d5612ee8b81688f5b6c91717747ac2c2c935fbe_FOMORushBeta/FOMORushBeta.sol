/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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

// File: contracts/FOMOBeta.sol



pragma solidity ^0.8.6;



contract FOMORushBeta is Ownable {

    IERC20 public usdt;
    address public mainContract;
    address public nftContract;
    address public lastDeposit;

    // Game Settings
    uint256 public minDeposit = 5e6;
    uint256 public gameCycle;
    uint256 public gameOver;
    uint256 public players = 0;
    uint256 public newCycleGracePeriod = 300;
    uint256 public timerIncrement = 15;

    // Calculation variables
    uint256 private immutable percentageDivider = 1000;
    uint256 public winnerPercentage = 700;
    uint256 public mainContractFee = 50;
    uint256 public nftContractFee = 50;

    event FOMO(uint256 gameRound, uint256 playerCount, address playerAddress, uint256 timestamp, uint256 poolBalance, uint256 gameEndTime);

    constructor(
        address usdtAddr,
        address _mainContractAddr,
        address _nftContractAddr,
        uint256 startTime
    ) {
        usdt = IERC20(usdtAddr);
        mainContract = _mainContractAddr;
        nftContract = _nftContractAddr;
        gameOver = startTime;
        gameCycle = 1;
    }

    function joinFOMO(uint256 depositAmount) public {
        
        // Validate deposit amount
        require(depositAmount == minDeposit, "Below minimum amount.");

        // Player transfer token to this contract
        usdt.transferFrom(msg.sender, address(this), depositAmount);

        // Count Down = 0
        if (gameOver <= block.timestamp) {
            
            // No new player
            if (players == 1) {

                // Refund player from previous round
                usdt.transfer(lastDeposit, depositAmount);

            } else if (players > 1) {

                // Get current pool balance - deposit of new game cycle
                uint256 poolBalance = usdt.balanceOf(address(this)) - depositAmount;
                uint256 winnerReward = poolBalance * winnerPercentage / percentageDivider;
                usdt.transfer(lastDeposit, winnerReward);

            }

            // Start new game cycle
            gameOver = block.timestamp + newCycleGracePeriod;
            gameCycle++;
            // Reset player count
            players = 0;

        // FOMO is still going on...
        } else {
            // Increase count down timer
            gameOver += timerIncrement;
        }

        lastDeposit = msg.sender;
        players++;

        // Transfer 5% commission to main contract
        uint256 mainContractComm = depositAmount * mainContractFee / percentageDivider;
        usdt.transfer(mainContract, mainContractComm);

        // Transfer 5% commission to NFT contract
        uint256 nftContractComm = depositAmount * nftContractFee / percentageDivider;
        usdt.transfer(nftContract, nftContractComm);

        // Log FOMO records
        emit FOMO(gameCycle, players, msg.sender, block.timestamp, usdt.balanceOf(address(this)), gameOver);

    }

    function getGameCycle() public view returns(uint256){
        return gameCycle;
    }

    function getPlayers() public view returns(uint256){
        return players;
    }

    function getPoolBalance() public view returns(uint256){
        return usdt.balanceOf(address(this));
    }

    function getGameOverTime() public view returns(uint256){
        return gameOver;
    }

    function getTimeLeft() public view returns(uint256){
        if (gameOver <= block.timestamp) {
            return 0;
        } else {
            return gameOver - block.timestamp;
        }
    }

    function getCurrentWinner() public view returns(address){
        return lastDeposit;
    }

    function setMinDeposit(uint256 newAmount) external onlyOwner {
        minDeposit = newAmount;
    }

    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        newCycleGracePeriod = newGracePeriod;
    }

    function setTimerIncrement(uint256 newIncrement) external onlyOwner {
        timerIncrement = newIncrement;
    }

}