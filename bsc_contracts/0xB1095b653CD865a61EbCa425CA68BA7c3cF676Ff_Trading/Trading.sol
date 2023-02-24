/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}



contract Trading is Ownable, ReentrancyGuard {
    IERC20 public busd;
    bytes32 private password; //callable from the dapp
    uint256 private timestamp; //for decryption of password

    constructor(IERC20 _busd) {
        busd = _busd;
    }

    struct Investment {
        uint256 amount;
        uint256 withdrawable;
        uint256 loss;
        uint256 profit;
        uint256 weekTimeperiod;
        uint256 timeperiod;
        bool invested;
    }
    struct Roi {
        uint256 per;
        bool pl;
        uint256 time;
    }
    Roi public roi; //return on the investment
    // mappings
    mapping(address => Investment) public userInvestment; //user information about the investment

    address[] investedAddresses;

    bool public withdrawOnAndOff;
    bool public deposit;
    uint256 public maxInvestment = 1000000 ether;
    uint256 public maxUserInvestment = 500 ether;
    uint256 public minInvestment = 50 ether;


  receive() external payable {} //contract can receive ethers from outside
  fallback() external payable {}

    // invest
    //check if deposit is enabled by owner
    // using password so, that this function is only callable from the dapp to verify it can only be callable on weekends
    // minimum Investment 50 busd
    // maximum Investment 500 busd
    // Can't invest of the amount in contract is greater than 1 milion
    // if user have any previous profit it will be withdrawn during new investment
    function invest(uint256 _amount, string memory _password) external nonReentrant {
        require(deposit, "Deposit is Currently off");
        bytes32 salt = keccak256(abi.encodePacked(timestamp, owner()));
        bytes32 __password = keccak256(abi.encodePacked(_password, salt));


        require(password == __password,

            // password == keccak256(abi.encodePacked(_password)),
            "Only Callable from DAPP and on weekends"
        );
        require(
            busd.balanceOf(address(this)) + _amount <= maxInvestment,
            "Maximum investment Limit reached. Please Wait"
        );
        require(
            _amount >= minInvestment,
            "Amount should be greator than Minimum investment Amount"
        );
        require(
            _amount <= maxUserInvestment,
            "Amount should be lessor equal to Mazimum User investment"
        );
        require(
            busd.allowance(msg.sender, address(this)) >= _amount,
            "insufficient Allowance"
        );

        bool temp;
        uint256 length = investedAddresses.length;
        // storing the address which are investing in the array
        for (uint256 i = 0; i < length; i++) {
            if (investedAddresses[i] == msg.sender) {
                temp = true;
                break;
            }
        }
        if (!temp) {
            investedAddresses.push(msg.sender);
        }

        if (userInvestment[msg.sender].profit > 0) {
            require(
                busd.balanceOf(address(this)) >=
                    ((userInvestment[msg.sender].amount *
                        userInvestment[msg.sender].profit) / 10000),
                "Insufficient Balance to withdraw previous profit Please contact admin"
            );
            busd.transfer(
                msg.sender,
                (userInvestment[msg.sender].amount *
                    userInvestment[msg.sender].profit) / 10000
            );
        }

        userInvestment[msg.sender] = Investment(
            userInvestment[msg.sender].amount +
                _amount -
                ((userInvestment[msg.sender].amount *
                    userInvestment[msg.sender].loss) / 10000),
            userInvestment[msg.sender].withdrawable +
                _amount -
                ((userInvestment[msg.sender].amount *
                    userInvestment[msg.sender].loss) / 10000),
            0,
            0,
            block.timestamp,
            block.timestamp,
            true
        );
        busd.transferFrom(msg.sender, address(this), _amount);
    }

    // monthly widthdraw
    // Can withdraw before a month
    // Can withdraw after a month
    // check if user have any loss and then enough amount to withdraw
    // Check if the contract have enough balance for user to withdraw
    // check if user's amount withdrawl is greater than min inevestment = 50 busd
    // user's previous profit or loss is calculated according to user's record and then transfer the withdrawable amount
    function monthlyWithdraw(uint256 _amount) external nonReentrant{
        require(_amount > 0, "amount should be greater than 0");
        require(
            userInvestment[msg.sender].timeperiod + 30 days < block.timestamp,
            "Can't widthdraw before a month"
        );
        require(
            userInvestment[msg.sender].withdrawable -
                ((userInvestment[msg.sender].amount *
                    userInvestment[msg.sender].loss) / 10000) >=
                _amount,
            "Don't have any balance to withdraw"
        );
        require(
            _amount <= busd.balanceOf(address(this)),
            "Don't have any balance in Contract Contact Admin"
        );

        Investment memory temp1;
        if (
            userInvestment[msg.sender].amount -
                ((userInvestment[msg.sender].amount *
                    userInvestment[msg.sender].loss) / 10000) -
                _amount >=
            minInvestment ||
            userInvestment[msg.sender].amount == _amount
        ) {
            temp1 = userInvestment[msg.sender];
            bool temp = userInvestment[msg.sender].amount == _amount;
            userInvestment[msg.sender] = Investment(
                temp
                    ? 0
                    : userInvestment[msg.sender].amount -
                        ((userInvestment[msg.sender].amount *
                            userInvestment[msg.sender].loss) / 10000) -
                        _amount,
                userInvestment[msg.sender].withdrawable -
                    ((userInvestment[msg.sender].amount *
                        userInvestment[msg.sender].loss) / 10000) -
                    _amount,
                0,
                0,
                userInvestment[msg.sender].weekTimeperiod,
                userInvestment[msg.sender].timeperiod,
                temp ? false : true
            );
        } else {
            revert(
                "Remaining Amount will be less than minInvestment, Withdraw full Amount"
            );
        }

        if (temp1.profit > 0) {
            require(
                busd.balanceOf(address(this)) >=
                    _amount + ((temp1.amount * temp1.profit) / 10000),
                "Insufficient Contract Balance to withdraw previous profit Please contact admin"
            );
            busd.transfer(
                msg.sender,
                (temp1.amount * temp1.profit) / 10000
            );
            // userInvestment[msg.sender].profit = 0;
        }
            busd.transfer(
                msg.sender,
                _amount - ((temp1.amount * temp1.loss) / 10000)
            ); 
        
    }

    // enter roi  __ profit or loss
    // per is percentage
    // pl if true it will be profit else it will be loss
    // Loss will be deducted from the total amount while in monthly widthdrawl

    function updateROIWeekly(uint256 _per, bool pl) external onlyOwner {
        if (pl) {
            uint256 length = investedAddresses.length;
            for (uint256 i = 0; i < length; i++) {
                if (userInvestment[investedAddresses[i]].invested) {
                    userInvestment[investedAddresses[i]].profit += _per;
                    userInvestment[investedAddresses[i]].weekTimeperiod = block
                        .timestamp;
                }

                roi = Roi(_per, pl, block.timestamp);
            }
        } else {
            // loss+=_per;
            uint256 length = investedAddresses.length;
            for (uint256 i = 0; i < length; i++) {
                if (userInvestment[investedAddresses[i]].invested) {
                    userInvestment[investedAddresses[i]].loss += _per;
                }
            }
            roi = Roi(_per, pl, block.timestamp);
        }
    }

    // weekly widthdraw
    // Can widthdraw within 30 days of investment
    // Can only be withdrawn if owner have set the withdraw status to true
    // Also check he contract balance if the withdrawl amount is available or not
    // user's profit is calculated and divided by 10000 so the profit in points can also be given
    // example: if your profit is 1000 set by the contract admin and then if divided by 10000 it actually will be 1000/10000 = 0.1 percent of the amount user's deposited
    function weeklyWithdraw() external nonReentrant {
        require(withdrawOnAndOff, "withdraw is off currently contact admin");
        require(userInvestment[msg.sender].invested, "You have not invested");

        uint256 temp = userInvestment[msg.sender].profit;
        require(
            busd.balanceOf(address(this)) >=
                (userInvestment[msg.sender].amount * temp) / 10000,
            "Insuffucient Contract Balance contact admin"
        );
        userInvestment[msg.sender].profit = 0;
        userInvestment[msg.sender].weekTimeperiod = block.timestamp;
        busd.transfer(
            msg.sender,
            (userInvestment[msg.sender].amount * temp) / 10000
        );
    }

    // Owner Withdraw Function to withdraw BUSD
    function withdraw(address _to, uint256 _amount) external onlyOwner {
        require(
            busd.balanceOf(address(this)) >= _amount,
            "Don't have enough available"
        );
        busd.transfer(_to, _amount);
    }

    // Owner can fund the contract with BUSD
    function fund(uint256 _amount) external onlyOwner {
        require(
            busd.balanceOf(owner()) >= _amount,
            "Don't have enough available"
        );
        require(
            busd.allowance(owner(), address(this)) >= _amount,
            "Don't have enough allowance"
        );
        busd.transferFrom(msg.sender, address(this), _amount);
    }
    //salt hashing for setting password
    function setPassword(string memory _password) external  onlyOwner{
     bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));
     bytes32 __password = keccak256(abi.encodePacked(_password, salt));
     timestamp = block.timestamp;
     password = __password;
  // store hashedPassword on the blockchain
}


    // If withdraw status is true user can claim weekly reward
    function toggleWithdrawOnAndOff(bool _val) external onlyOwner {
        withdrawOnAndOff = _val;
    }

    // If deposit status is true user can only invest

    function toggleDeposit(bool _val) external onlyOwner {
        deposit = _val;
    }

    function updateMaxInvestment(uint256 _maxInvestment) external onlyOwner {
        maxInvestment = _maxInvestment;
    }

    function updateMinInvestment(uint256 _minInvestment) external onlyOwner {
        minInvestment = _minInvestment;
    }

    function updateMaxUserInvestment(uint256 _maxUserInvestment)
        external
        onlyOwner
    {
        maxUserInvestment = _maxUserInvestment;
    }

    function updateBusdAddress(IERC20 _busd) external onlyOwner {
        busd = _busd;
    }

   
}