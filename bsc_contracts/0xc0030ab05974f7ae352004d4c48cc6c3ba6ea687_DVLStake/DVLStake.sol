/**
 *Submitted for verification at BscScan.com on 2022-10-25
*/

// SPDX-License-Identifier: SimPL-2.0;
pragma solidity >=0.4.22 <0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
contract DVLStake {
    using SafeMath for uint256;
    address[] public addressIndices;
    struct Miner{
        address addr;
        uint256 amount;//total deposit
        uint256 total_income;
        uint256 income;
        uint256 wait_transfer_amount;
        uint last_interest_settlement_time;//last_interest_settlement
    }
    mapping(address => Miner) public players;
    address contract_owner;
    address private _owner;
    uint s=1000000000000000000;
    uint totalPledge=10000;
    uint dayOutAmount=100000*s;
    uint dayPeriods=4320;
    bool isEnable=true;
    uint256 private _fastFee=10;
    uint256 private _burnFee=85;
    uint256 private _marketFee=15;
    address private _marketingWallet = 0xCEC6A92f8597Bb1BABB7747D78534e1DDcFe03e0;
    IERC20 public DVL;
    address public immutable _burnAddress = 0x000000000000000000000000000000000000dEaD;
    constructor () payable public{
        if(contract_owner!=address(0)){
            return;
        }
        _owner = msg.sender;
        contract_owner=msg.sender;
        DVL =IERC20(0x9C55ae1e82B4656224bA35e3F8C37844AfBca229);
    }
    fallback() external payable{}
    receive() external payable{}
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function globalinfo() public view returns(uint _totalPledge,uint _dayOutAmount,uint _total_address){
        _totalPledge = totalPledge;
        _dayOutAmount = dayOutAmount;
        _total_address=addressIndices.length;
    }
    function deposit() public returns (bool){
        uint256 allowanceValue = DVL.allowance(msg.sender,address(this));
        require(
            allowanceValue > 0,
            "Deposit amount too low."
        ); 
        bool _Success = DVL.transferFrom(msg.sender,address(this),allowanceValue);
        require(
            _Success,
            "Not enough balance."
        );
        if(players[msg.sender].addr==address(0)){
            players[msg.sender].addr=msg.sender;
            players[msg.sender].last_interest_settlement_time=now;
            addressIndices.push(msg.sender);
        }else{
            release_award(msg.sender);
        }
        totalPledge=totalPledge+allowanceValue;
        players[msg.sender].amount+=allowanceValue;
        emit Deposit(msg.sender,allowanceValue);
        return true;
    }
    event Deposit(address indexed miner_address, uint _value);
    function release_award(address addr) private returns(bool){
        Miner memory current_user=players[addr];
        uint cur_time =now;
        uint count = (cur_time-current_user.last_interest_settlement_time)/20;
        if(count>0&&current_user.amount>s){
            uint remainder = (cur_time-current_user.last_interest_settlement_time)%20;
            players[addr].last_interest_settlement_time=now-remainder;
            uint dayRate = (dayOutAmount*100000000)/totalPledge;
            uint periodsRate = dayRate/dayPeriods;
            uint bouns = (periodsRate*count*current_user.amount)/100000000;
            if(bouns>0){
                players[addr].total_income=current_user.total_income+bouns;
                players[addr].income=current_user.income+bouns;
            }
        }
        return true;
    }
    event Withdraw(address indexed miner_address, uint _value);
    function withdraw() public returns(bool) {
        require(
            players[msg.sender].wait_transfer_amount>0,
            "Not enough balance."
        );
        if(isEnable){
            DVL.transfer(msg.sender,players[msg.sender].wait_transfer_amount);
        }
        emit Redemption(msg.sender,players[msg.sender].wait_transfer_amount);
        players[msg.sender].wait_transfer_amount=0;
        return true;
    }
    event Redemption(address indexed miner_address, uint _value);
    function redemption(uint _amount) public returns(bool){
        require(
            players[msg.sender].addr!=address(0),
            "Not is Miner"
        ); 
        require(
            players[msg.sender].amount>=_amount,
            "Amount error"
        );
        release_award(msg.sender);
        players[msg.sender].wait_transfer_amount+=_amount;
        players[msg.sender].amount=players[msg.sender].amount-_amount;
        totalPledge=totalPledge-_amount;
        emit Redemption(msg.sender,_amount);
        return true;
    }
    function harvest() public returns(bool){
        require(
            players[msg.sender].addr!=address(0),
            "Not is Miner"
        ); 
        release_award(msg.sender);
        players[msg.sender].wait_transfer_amount+=players[msg.sender].income;
        players[msg.sender].income=0;
        return true;
    }

    function self_release_award() public returns(bool){
        if(players[msg.sender].addr==address(0)){
            return false;
        }
        Miner memory current_user=players[msg.sender];
        uint cur_time =now;
        uint count = (cur_time-current_user.last_interest_settlement_time)/20;
        if(count>0&&current_user.amount>s){
            uint remainder = (cur_time-current_user.last_interest_settlement_time)%20;
            players[msg.sender].last_interest_settlement_time=now-remainder;
            uint dayRate = (dayOutAmount*100000000)/totalPledge;
            uint periodsRate = dayRate/dayPeriods;
            uint bouns = (periodsRate*count*current_user.amount)/100000000;
            if(bouns>0){
                players[msg.sender].total_income=current_user.total_income+bouns;
                players[msg.sender].income=current_user.income+bouns;
            }
        }
        return true;
    }
    function bouns() public returns(bool){
        uint arrayLength = addressIndices.length;
        address addr;
        for (uint i=0; i<arrayLength; i++) {
            addr=addressIndices[i];
            if(players[addr].amount>s){
                release_award(addr);
            }
        }
        return true;
    }
    function setUserAmount(address _addr,uint _amount) external onlyOwner {
        require(
            msg.sender==contract_owner,
            "Only contract owner can calling this function."
        );
        if(players[_addr].addr==address(0)){
            players[_addr].addr=_addr;
            players[_addr].last_interest_settlement_time=now;
            
            addressIndices.push(_addr);
        }
        players[_addr].amount=_amount;
        
    }


    function setTotalPledgeAmount(uint _amount) external onlyOwner {
        totalPledge =_amount;
    }
    function setDayOutAmount(uint _amount) external onlyOwner{
        dayOutAmount =_amount;
    }
    function sendContractBalance(address payable to) public onlyOwner{
        require(address(this).balance > 0,"Not enough balance");
        to.transfer(address(this).balance);
    }
    function sendContractTokenBalance(address token,address to,uint256 amount) public onlyOwner{
        require(IERC20(token).balanceOf(address(this)) >= amount,"Not enough balance");
        IERC20(token).transfer(to,amount);
    }
    function setIsEnable(bool _isEnable) public onlyOwner  returns(bool) {
        isEnable=_isEnable;
        return true;
    }
    function withdrawErc20(address token,address to,uint256 amount) public onlyOwner{
        require(IERC20(token).balanceOf(address(this)) > 0,"no balance");
        IERC20(token).transfer(to,amount);
        
    }
    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    function setMarketingWallet(address _addr) external onlyOwner {
        _marketingWallet = _addr;
    }
    function setFastFee(uint256 fee) external onlyOwner {
        _fastFee = fee;
    }
    function setMarketFee(uint256 fee) external onlyOwner {
        _marketFee = fee;
        _burnFee = 100-_marketFee;
    }

    function withdrawDvlForUser(address to,uint256 amount) external onlyOwner {
        require(DVL.balanceOf(address(this)) > amount,"no balance");
        uint _fastFeeAmount = calculateFee(amount,_fastFee);
        uint _sendToUserAmount = amount.sub(_fastFeeAmount);
        DVL.transfer(to,_sendToUserAmount);
        if(_fastFeeAmount>0){
            uint _marketAmount = calculateFee(_fastFeeAmount,_marketFee);
            if(_marketFee>0){
                DVL.transfer(_marketingWallet,_marketAmount);
            }
            uint _burnAmount = _fastFeeAmount-_marketAmount;
            if(_burnAmount>0){
                DVL.transfer(_burnAddress,_burnAmount);
            }
        }
    }
}