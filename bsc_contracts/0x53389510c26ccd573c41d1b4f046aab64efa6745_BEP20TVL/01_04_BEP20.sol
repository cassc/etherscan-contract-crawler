// SPDX-License-Identifier: MIT
// File: contracts/Ownable.sol

pragma solidity ^0.7.6;

import "./Math.sol";
import "./IFactory.sol";
import "./IRouter.sol";

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/SafeMath.sol

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
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
// File: contracts/IBEP20.sol



interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

contract BEP20TVL is Ownable, IBEP20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 public  dayRate = 60;
    uint256 public  BASE_RATIO = 10**18;
    uint256 public  SPY = (dayRate * BASE_RATIO) / 10000 / 1 days;
    uint256 public extraSupply;
    address public liquidity;


    mapping(string => uint256) public _rates;
    mapping(string => address) public _addrs;
    mapping(string => bool) public _switches;
    mapping(address => bool) public whites;
    mapping(address => bool) public pairs;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => bool) public rewardBlacklist;
    
    constructor() {
        _name = "Travel";
        _symbol = "TVL";
        _decimals = 18;

        _rates["_rewardLimit"] = 0;
        _rates["_buyBurn"] = 0;
        _rates["_buyLp"] = 0;
        _rates["_sellBurn"] = 0;
        _rates["_sellLp"] = 0;

        _addrs["_buyBurn"] = 0x000000000000000000000000000000000000dEaD;
        _addrs["_buyLp"] = address(this);
        _addrs["_sellBurn"] = 0x000000000000000000000000000000000000dEaD;
        _addrs["_sellLp"] = address(this);
        _addrs["_factory"] = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        _addrs["_router"] = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        _addrs["USDT"] = 0x55d398326f99059fF775485246999027B3197955;

        _switches["_canBuy"] = true;
        _switches["_canSell"] = true;
        whites[address(this)] = true;
        liquidity = IFactory(_addrs["_factory"]).createPair(_addrs["USDT"], address(this));
        setPairs(liquidity,true);

        setRewardBlacklist(liquidity, true);
        setRewardBlacklist(address(this), true);
        setRewardBlacklist(0x000000000000000000000000000000000000dEaD, true);
        setRewardBlacklist(address(0), true);
    }

    function setRewardBlacklist(address account, bool enable) public onlyOwner {
        rewardBlacklist[account] = enable;
    }

    function setConfig(string memory key, address add, uint rate) public onlyOwner returns (bool){
        _addrs[key] = add;
        _rates[key] = rate;
        return true;
    }

    function setPairs(address add, bool state) public onlyOwner returns (bool){
        pairs[add] = state;
        return true;
    }

    function setTradeStatus(bool canBuy, bool canSell) public onlyOwner returns (bool){
        _switches["_canBuy"] = canBuy;
        _switches["_canSell"] = canSell;
        return true;
    }

    function setDayRate(uint qua) public onlyOwner returns (bool){
        dayRate = qua;
        return true;
    }


    function setWhite(address add, bool status) public onlyOwner returns (bool){
        whites[add] = status;
        return true;
    }

    function isBuy(address sender, address recipient) private view returns (bool){
        return pairs[sender] && !whites[recipient];
    }

    function isSell(address sender, address recipient) private view returns (bool){
        return !whites[sender] && pairs[recipient];
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender,recipient,amount);
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        (uint burnAmount, uint lpAmount) =(0, 0);
        if (isBuy(sender, recipient))
        {
            require(_switches["_canBuy"] == true, "BEP20: buy from dex is closed");
            burnAmount = amount.div(1000).mul(_rates["_buyBurn"]);
            if (burnAmount > 0)
            {
                _balances[_addrs["_buyBurn"]] = _balances[_addrs["_buyBurn"]].add(burnAmount);
                emit Transfer(sender, _addrs["_buyBurn"], burnAmount);
            }
            
            lpAmount = amount.div(1000).mul(_rates["_buyLp"]);
            if (lpAmount > 0)
            {
                _balances[_addrs["_buyLp"]] = _balances[_addrs["_buyLp"]].add(lpAmount);
                emit Transfer(sender, _addrs["_buyLp"], lpAmount);
            }

        } else if (isSell(sender, recipient))
        {
            require(_switches["_canSell"] == true, "BEP20: sell to dex is closed");
            burnAmount = amount.div(1000).mul(_rates["_sellBurn"]);
            if (burnAmount > 0)
            {
                _balances[_addrs["_sellBurn"]] = _balances[_addrs["_sellBurn"]].add(burnAmount);
                emit Transfer(sender, _addrs["_sellBurn"], burnAmount);
            }

            lpAmount = amount.div(1000).mul(_rates["_sellLp"]);
            if (lpAmount > 0)
            {
                _balances[_addrs["_sellLp"]] = _balances[_addrs["_sellLp"]].add(lpAmount);
                emit Transfer(sender, _addrs["_sellLp"], lpAmount);
            }
        }

        uint leftAmount = amount.sub(burnAmount).sub(lpAmount);
        _balances[recipient] = _balances[recipient].add(leftAmount);
        
        emit Transfer(sender, recipient, leftAmount);
    }
    
    function lastTime() public view returns (uint256) {
        return  block.timestamp;
    }


    modifier calculateReward(address account) {
        if (account != address(0)) {
            uint256 reward = getReward(account);
            if (reward > 0 && _balances[account] >  _rates["_rewardLimit"]) {
                _balances[account] = _balances[account].add(reward);
                extraSupply = extraSupply.add(reward);
            }
            lastUpdateTime[account] = lastTime();
        }
        _;
    }

    function _beforeTokenTransfer(address from,address to, uint256 amount) internal virtual  calculateReward(from) calculateReward(to) {}

    function getReward(address account) public view returns (uint256) {
        if (lastUpdateTime[account] == 0 || rewardBlacklist[account] || _balances[account] <  _rates["_rewardLimit"]) {
            return 0;
        }
        return 
        _balances[account].mul(SPY).div(BASE_RATIO).mul(
            lastTime().sub(lastUpdateTime[account])
        );
    }


    //end of biz logics
    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
  */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() external view override returns (uint256) {
        //return _totalSupply;
        return _totalSupply.add(extraSupply);
    }

    /**
     * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) public view override returns (uint256) {
      //  return _balances[account];
       return _balances[account].add(getReward(account));
    }

    /**
     * @dev See {BEP20-transfer}.
   */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
   */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
   */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
   */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
   */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   */
    function mint(address _add, uint256 amount) public onlyOwner returns (bool) {
        _mint(_add, amount);
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

    function withdrawToken(address _token, address _add, uint _amount) external onlyOwner {
        IBEP20(_token).transfer(_add, _amount);
    }

    function withdraw(address payable _add, uint256 _amount) external onlyOwner {
        require(_add.send(_amount));
    }

}