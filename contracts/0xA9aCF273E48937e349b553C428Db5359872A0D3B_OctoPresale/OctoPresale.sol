/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.4;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract OctoPresale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public Octo;
    
    uint256 public constant salePrice = 0.000003 ether;
    uint256 public constant saleTime = 1 days;                  // 1 day
    uint256 public constant MaxAmount = 30 ether;               // ETH
    uint256 public constant limitAmount = 0.3 ether;            // ETH

    uint256 public totalAmount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimableTime;

    mapping(address => bool) public isClearing;
    mapping(address => uint256) userAmount;

    event PurchaseOcto(address account, uint256 amount, uint256 totalAmount);
    event HarvestOcto(address account, uint256 amountETH, uint256 purchaseAmount);
    event MigrateOcto(address account, uint256 totalAmount);

    constructor(address _Octo){
        require(_Octo != address(0),"invalid address!");
        Octo = _Octo;
    }

    function launch() public onlyOwner(){
        require(startTime == 0, "already started!");
        startTime = block.timestamp;
        endTime = startTime.add(saleTime);
        claimableTime = endTime.add(2 days);       // 48 hours
    }

    // buy Octo
    function purchase() external payable callerIsUser returns(bool) {
        require(block.timestamp>=startTime && block.timestamp<=endTime , "not sale time!");
        require(totalAmount.add(msg.value) <= MaxAmount,"exceeds max amount");
        require(userAmount[msg.sender].add(msg.value) <= limitAmount,"exceeds max amount you can buy");

        require(msg.value > 0,"invalid value!");
        if(userAmount[msg.sender] == 0){
            require(msg.value >= 0.1 ether,"too small");
        }
        userAmount[msg.sender] = userAmount[msg.sender].add(msg.value);
        totalAmount = totalAmount.add(msg.value);

        emit PurchaseOcto(msg.sender, msg.value, totalAmount);

        return true;
    }

    function claim() public returns(uint256) {
        require(claimableTime >0 , "not started!");
        require(block.timestamp > claimableTime, "not end!");
        require(userAmount[msg.sender] > 0 ,"invalid user!");
        require(isClearing[msg.sender] == false, "already claimed!");
        
        uint256 amount = userAmount[msg.sender];
        // caculate Octo amount
        uint256 OctoForUser = _calculateSaleQuote(amount);
        IERC20(Octo).safeTransfer(msg.sender,OctoForUser);
        isClearing[msg.sender] = true;
        emit HarvestOcto(msg.sender, amount, OctoForUser);
        return OctoForUser;
    }

    function finish() public returns (bool){
        require(endTime > 0,"not started!");
        require(endTime < block.timestamp, "not ended!");
        uint256 balance = address(this).balance;
        if(balance > 0){
            payable (owner()).transfer(balance);
        }
        return true;
    }

    function setOctoAddress(address _Octo) external onlyOwner() returns (bool) {
        Octo = _Octo;
        return true;
    }

    function userPurchaseInfo(address _user)
        external
        view
        returns (uint256, bool)
    {
        return (userAmount[_user], isClearing[_user]);
    }

    function _calculateSaleQuote(uint256 paymentAmount_) internal pure returns (uint256){
        return paymentAmount_.mul(1e18).div(salePrice);
    }

    // quote price 
    function calculateSaleQuote(uint256 paymentAmount_)
        external
        pure
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }

}