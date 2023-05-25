/**
 *Submitted for verification at Etherscan.io on 2023-04-01
*/

// File: IERC20.sol


pragma solidity >=0.7.0 <0.9.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// File: FincotekICO.sol


pragma solidity >=0.7.0 <0.9.0;


contract FincotekICO {

    address public owner;
    address public token;
    uint256 public tokenSupply = 50000000 ether;
    uint256 public minBuy = 0.01 ether;
    uint256 public maxBuy = 1 ether;
    uint256 public hardCap = 20 ether;
    uint256 public balance;
    mapping(address => uint256) public balanceOf;

    event SendToken(address indexed from, uint256 value);
    event Buy(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(owner == msg.sender, 'Caller is not owner');
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = _token;
    }

    function tokenOf(address _address) public view returns (uint256) {
        return _tokenValue(balanceOf[_address]);
    }

    function rate() public view returns (uint256) {
        return _rate(tokenSupply, hardCap);
    }

    function sendToken() external onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) == 0, 'Token sent');
        erc20.transferFrom(msg.sender, address(this), tokenSupply);
        emit SendToken(msg.sender, tokenSupply);
    }

    receive() external payable {
        uint256 value = balanceOf[msg.sender] + msg.value;
        require(value >= minBuy, 'Value is less than min buy');
        require(value <= maxBuy, 'Value is greater than max buy');
        require(address(this).balance <= hardCap, 'Balance is greater than hard cap');
        balance += msg.value;
        balanceOf[msg.sender] += msg.value;
        IERC20 erc20 = IERC20(token);
        erc20.transfer(address(msg.sender), _tokenValue(msg.value));
        emit Buy(msg.sender, msg.value);
    }

    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    function refund() external onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(owner, erc20.balanceOf(address(this)));
    }

    function _tokenValue(uint256 value) private view returns (uint256) {
        return (value * rate()) / 10 ** 18;
    }

    function _rate(uint256 value1, uint256 value2) private pure returns (uint256) {
        return (value1 * 10 ** 18) / value2;
    }
}