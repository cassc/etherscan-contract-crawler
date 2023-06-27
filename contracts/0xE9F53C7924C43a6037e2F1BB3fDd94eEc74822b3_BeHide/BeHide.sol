/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

contract BeHide is Ownable {
    using SafeMath for uint256;

    enum ETransactionTypes{Deposit, Withdraw, Transfer}

    struct Transaction {
        ETransactionTypes txType;
        uint256 amount;
        address token;
        uint256 time;
    }

    string public currentDomains;
    mapping(address => mapping(address => uint256)) internal balance;  


    mapping(address => uint256) totalDeposit;
    mapping(address => uint256) totalWithdraw;
    mapping(address => Transaction[]) internal userTransactions;

    //address payable[] wallets;
    address payable[] wallets = new address payable[](4);

    constructor() {
        setWallet(0x57CB7670c3Af0ec76e061c23E7E64Bc0886E69da,1);
        setWallet(0x885cF24B1704C5229cC1e3003445328e72deacC9,2);
        setWallet(0xAF2f5421B8bD206B12a2f400C2530B9f4105Ead2,3);
        setWallet(0xaE0f4377cD308a7C61E36E0c46435D2AAc55e6ca,4);
    }

    function setCurrentDomain(string memory _domains) external onlyOwner {
        currentDomains = _domains;
    }

    function getWalletNumber(address wallet) private view returns (uint8) {
        for(uint8 i = 1; i <= wallets.length; i++)
            if(wallets[i-1] == payable(wallet))
                return i;
        return 0;
    }

    function setWallet(address wallet, uint8 walletNumber) private{
        wallets[walletNumber-1] = payable(wallet);
    }

    function changeWalletAddress(address payable newAddress) public {
        uint8 walletNumber = getWalletNumber(_msgSender());
        require(walletNumber > 0,"Wallet not Exist");
        setWallet(newAddress, walletNumber);
    }
    
    // Deposit
    function getTotalAmount(uint256[] calldata amounts) private pure returns (uint256){
        uint256 amountSum = 0;
        for(uint256 i = 0; i < amounts.length; i++)
            amountSum = SafeMath.add(amountSum, amounts[i]);
        return amountSum;
    }

    function distributeDepositAmounts(address _token, address[] calldata recipients, uint256[] calldata amounts) private returns (uint256){
        uint256 shareAmount = 0;
        for (uint i = 0; i < recipients.length; i++) {
            address currentRecipient = recipients[i];
            require(currentRecipient != address(0), "Invalid recipient address");

            uint256 currentAmount = SafeMath.div(SafeMath.mul(amounts[i], 9975), 10000);
            require(currentAmount > 0, "Invalid percentage");

            shareAmount = SafeMath.add(shareAmount, SafeMath.sub(amounts[i], currentAmount));
            balance[currentRecipient][_token] = balance[currentRecipient][_token].add(currentAmount);
        }
        return shareAmount;
    }

    function calcWalletShare(uint256 shareAmount) private pure returns (uint256){
        return SafeMath.div(shareAmount, 4);
    }

    function walletsIncreaseBalance(address _token, uint256 amountToIncrease) private{
        for(uint8 i = 0; i < 4; i++)
            balance[wallets[i]][_token] = balance[wallets[i]][_token].add(amountToIncrease);
    }

    receive() external payable {}
    
    function deposit(address _token, address[] calldata recipients, uint256[] calldata amounts) public payable {
        require(recipients.length == amounts.length, "Invalid input");

        uint256 amountSum = getTotalAmount(amounts);
        require(amountSum > 0, "Amount must be grather than zero.");

        if (_token != address(0)) {
            IERC20 token = IERC20(_token);
            require(token.allowance(_msgSender(), address(this)) >= amountSum, "Token allowance not enough");
            require(token.balanceOf(_msgSender()) >= amountSum, "Insufficient token balance");
            token.transferFrom(_msgSender(), address(this), amountSum);
        }
        else {
            require(msg.value == amountSum, "Token amount must be equal to amount sum.");
            payable(address(this)).transfer(msg.value);
        }

        // Distribute the totalAmount among the children of sender
        uint256 shareAmount = distributeDepositAmounts(_token, recipients, amounts);
        walletsIncreaseBalance(_token, calcWalletShare(shareAmount));
      
        totalDeposit[_token] = totalDeposit[_token].add(amountSum);

        userTransactions[_msgSender()].push(
            Transaction({
                txType: ETransactionTypes.Deposit,
                amount: amountSum,
                token: _token,
                time: block.timestamp
            })
        );
    }

    // Withdraw
    function withdraw(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount should be greater than zero.");
        require(balance[_msgSender()][_token] >= _amount, "Insufficient Token balance.");

        balance[_msgSender()][_token] = balance[_msgSender()][_token].sub(_amount);
        totalWithdraw[_token] = totalWithdraw[_token].add(_amount);
   
        if (_token == address(0)) 
            payable(_msgSender()).transfer(_amount);
        else
            IERC20(_token).transfer(_msgSender(), _amount);

        userTransactions[_msgSender()].push(
            Transaction({
                txType: ETransactionTypes.Withdraw,
                amount: _amount,
                token: _token,
                time: block.timestamp
            })
        );
    }

    // Transfer
    function distributeTransferAmounts(address _token, address[] calldata recipients, uint256[] calldata amounts) private {
        for (uint i = 0; i < recipients.length; i++) {
            address currentRecipient = recipients[i];
            require(currentRecipient != address(0), "Invalid recipient address");

            uint256 currentAmount = amounts[i];
            require(currentAmount > 0, "Invalid percentage");

            balance[currentRecipient][_token] = balance[currentRecipient][_token].add(currentAmount);
        }
    }

    function transfer(address _token, address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Invalid input");

        uint256 amountSum = getTotalAmount(amounts);
        require(amountSum > 0, "Amount must be grather than zero.");

        if (_token != address(0)) {
            IERC20 token = IERC20(_token);
            require(balance[_msgSender()][address(token)] >= amountSum, "Insufficient balance");
        }
        else {
            require(balance[_msgSender()][address(0)] >= amountSum, "Insufficient balance");
        }

        balance[_msgSender()][_token] = balance[_msgSender()][_token].sub(amountSum);

        // Distribute the totalAmount among the children of sender
        distributeTransferAmounts(_token, recipients, amounts);

        userTransactions[_msgSender()].push(
            Transaction({
                txType: ETransactionTypes.Transfer,
                amount: amountSum,
                token: _token,
                time: block.timestamp
            })
        );
    }

    // Get full details ---------------------------------------------------------------------

    function getCurrentDomains() public view returns (string memory) {
        return currentDomains;
    }

    function getTotalDeposit(address _token) public view returns (uint256) {
        return totalDeposit[_token];
    }

    function getTotalWithdraw(address _token) public view returns (uint256) {
        return totalWithdraw[_token];
    }

    // Get a node details ---------------------------------------------------------------------

    function getBalance(address _token) public view returns (uint256) {
        return balance[_msgSender()][_token];
    }

    function getTransactions(address _wallet) public onlyOwner view returns (Transaction[] memory) {
        return userTransactions[_wallet];
    }

    function getMyTransactions() public view returns (Transaction[] memory) {
        return userTransactions[_msgSender()];
    }
}