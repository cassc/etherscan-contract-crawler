/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract BEP20PayToken is Ownable{
    using SafeMath for uint256;

    struct SaleInfo {
        uint rAmountTotal;
        uint rAmount;
        uint rPrice;
    }
    SaleInfo[] public  salePerido;
    uint public currentPerido;
    uint public tokenIdoMax;

    struct RewardsLog { 
        address rSend;
        string rType;
        uint256 rValue;
        uint rTime;
    }
    mapping(address => RewardsLog[]) public  _rewardsLogList;
    struct TokenIdoLog {
        address rSend;
        uint rTime;
        uint rValue;
        uint rAmount;
    }
    mapping(address => TokenIdoLog[]) public  _tokenIdoLogList;
    uint private _pageSize = 10;

    address public tokenIdo;
    // address public lpRewardToken = 0x55333814c4b91021AFf58E6f2F7fD38ACA2919a8;
    address public lpRewardToken = 0x55d398326f99059fF775485246999027B3197955;
    address public recAddr;

    uint8 private _decimals;

    mapping(address => address) public inviter;
    struct Myteam {
        address rAddr;
        uint rValue;
        uint rAmount;
    }
    mapping(address=> Myteam[]) private myteam;
    mapping (address=> uint) public amountUserToken;

    event PayToken(address indexed token, address indexed sender, uint amount, uint orderid);

    event WithDrawalToken(address indexed token, address indexed sender, uint indexed amount);
    event WithDrawalTokenIdo(address indexed token, address indexed sender, uint indexed amount);

    constructor(){
        _decimals = 18;

        tokenIdoMax = 1000 * 10**_decimals;
        currentPerido = 1;
        salePerido.push(SaleInfo(100000 * 10**_decimals, 100000 * 10**_decimals, 2));
        salePerido.push(SaleInfo(150000 * 10**_decimals, 150000 * 10**_decimals, 4));
        salePerido.push(SaleInfo(200000 * 10**_decimals, 150000 * 10**_decimals, 6));
        recAddr = address(this);
    }

    function payToken(address token, uint amount, uint orderid) external returns(bool){

        require(0 < amount, 'Amount: must be > 0');

        address sender = _msgSender();

        if (token == lpRewardToken){
            uint amountToken = amount.mul(10).div(salePerido[currentPerido - 1].rPrice);
            require(amountUserToken[sender].add(amountToken) <= tokenIdoMax, 'Up to 1000 private placement');
            require(amountToken < salePerido[currentPerido - 1].rAmount, 'Insufficient number of private placements');
            amountUserToken[sender] = amountUserToken[sender].add(amountToken);
            salePerido[currentPerido - 1].rAmount = salePerido[currentPerido - 1].rAmount.sub(amountToken);
            _addTokenIdoLog(sender, amount, amountToken);
            if (inviter[sender] != address(0)){
                //更新团队数据
                uint myteamLength = myteam[inviter[sender]].length;
                for (uint i = 0; i < myteamLength; i++) {
                    if (myteam[inviter[sender]][i].rAddr == sender){
                        myteam[inviter[sender]][i].rValue = myteam[inviter[sender]][i].rValue.add(amount);
                        myteam[inviter[sender]][i].rAmount = myteam[inviter[sender]][i].rAmount.add(amountToken);
                    }
                }
                //转账
                uint amountReward = amount.mul(10).div(100);
                amount = amount.sub(amountReward);
                IERC20(token).transferFrom(sender, inviter[sender], amountReward);
                _addRewardsLog(sender, inviter[sender], amountReward);
            }
        }
        IERC20(token).transferFrom(sender, recAddr, amount);

        emit PayToken(token, sender, amount, orderid);

        return true;
    }

    function withDrawalToken(address token, address _address, uint amount) external onlyOwner returns(bool){

        IERC20(token).transfer(_address, amount);

        emit WithDrawalToken(token, _address, amount);

        return true;
    }

    function setRecAddr(address _addr) external onlyOwner {
        recAddr = _addr;
    }

    function bindInvite(address _address) external returns(bool){
        address sender = _msgSender();
        if (inviter[sender] == address(0) && _address != sender && inviter[_address] != sender){
            inviter[sender] = _address;
            myteam[_address].push(Myteam(sender, 0, 0));
        }
        
        return true;
    }

    function setTokenIdo(address _addr) external onlyOwner{
        tokenIdo = _addr;
    }

    function withDrawalTokenIdo() external returns(bool){

        address sender = _msgSender();

        IERC20(tokenIdo).transfer(sender, amountUserToken[sender]);
        amountUserToken[sender] = 0;

        emit WithDrawalTokenIdo(tokenIdo, sender, amountUserToken[sender]);

        return true;
    }

    function setPerido(uint _perido) external onlyOwner{
        require(_perido > 0 && _perido <= salePerido.length, 'Amount: must be > 0');
        currentPerido = _perido;
    }

    function setTokenIdoMax(uint _amount) external onlyOwner{
        require(_amount > 0, 'Amount: must be > 0');
        tokenIdoMax = _amount;
    }

    function _addTokenIdoLog(address _addr, uint _value, uint _amount) internal {
        _tokenIdoLogList[_addr].push(TokenIdoLog(_addr, block.timestamp, _value, _amount));
    }

    function getTokenIdoLog(uint page) public view returns (TokenIdoLog[] memory) {
         address sender = msg.sender;
        if(page * _pageSize >= _tokenIdoLogList[sender].length){
            return new TokenIdoLog[](0);
        }
        uint _start = page * _pageSize;
        uint _end = (page + 1) * _pageSize;
        if(_tokenIdoLogList[sender].length < _end){
            _end = _tokenIdoLogList[sender].length;
        }
        uint _len = _end - _start;
        TokenIdoLog[] memory _logs = new TokenIdoLog[](uint256(_len));
        for(uint i = 0; i < _len; i++) {
            _logs[i] = _tokenIdoLogList[sender][_start + i];
        }

        return _logs;
    }

    function _addRewardsLog(address _from, address _to, uint _amount) internal {
        _rewardsLogList[_to].push(RewardsLog(_from, 'USDT', _amount, block.timestamp));
    }

    function getRewardsLog(uint page) public view returns (RewardsLog[] memory) {
        address sender = msg.sender;
        if(page * _pageSize >= _rewardsLogList[sender].length){
            return new RewardsLog[](0);
        }
        uint _start = page * _pageSize;
        uint _end = (page + 1) * _pageSize;
        if(_rewardsLogList[sender].length < _end){
            _end = _rewardsLogList[sender].length;
        }
        uint _len = _end - _start;
        RewardsLog[] memory _logs = new RewardsLog[](uint256(_len));
        for(uint i = 0; i < _len; i++) {
            _logs[i] = _rewardsLogList[sender][_start + i];
        }

        return _logs;
    }

    function getMyteam(address _addr) public view returns (Myteam[] memory) {
        return myteam[_addr];
    }
}