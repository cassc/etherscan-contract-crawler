/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    // constructor ()  { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }    
    function changeOwner(address _newOwner) external onlyOwner {
        emit OwnershipTransferred(_owner,_newOwner);
        _owner = _newOwner;
    }
}

interface ManagerWrap {
    function sendFee() external;
}

abstract contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;


    string  _name;
    string  _symbol;
    uint8  _decimals;
    uint  _totalSupply;

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) virtual internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal { }
}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract MyToken is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    // address public governance;
    // address public pendingGov;

    address private feeManager;

    mapping (address => bool) public blackList;
    mapping (address => bool) private _EXCLUDE;

    uint burnTax;
    uint feeTax;
    bool openManager;
    bool openFee;

    event NewPendingGov(address oldPendingGov, address newPendingGov);

    event NewGov(address oldGov, address newGov);

    event Log(string message);
    event LogBytes(bytes data);

    constructor (string memory name, string memory symbol, uint8 decimals) {
        _owner = msg.sender;
        //(MyToken, MTB, 18)
        burnTax = 15;
        feeTax = 35;
        openManager = true;
        openFee = true;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(msg.sender, 146800000000 * 10 ** 18);
        _EXCLUDE[msg.sender] = true;
        _EXCLUDE[feeManager] = true;
    }

    /** 
     * Add black account
     * @param _black black account
     */
    function addBlackList(address _black) public onlyOwner {
        blackList[_black] = true;
    }

    /** 
     * Remove black account
     * @param _black black account
     */
    function removeBlackList(address _black) public onlyOwner {
        blackList[_black] = false;
    }

    function addExclued(address _account) public onlyOwner {
        _EXCLUDE[_account] = true;
    }

    function removeExclued(address _account) public onlyOwner {
        _EXCLUDE[_account] = false;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal {
        super._beforeTokenTransfer(from, to, amount);
        require(!blackList[from], "MyToken: from is in black list");
        require(!blackList[to], "MyToken: to is in black list");
    }

    function setFeeStaus(bool _staus) public onlyOwner{
        openFee = _staus;
    }

    function setManagerStaus(bool _staus) public onlyOwner{
        openManager = _staus;
    }
    
    function setManager(address _aAddress) public onlyOwner{
        feeManager = _aAddress;
        _EXCLUDE[feeManager] = true;
    }

    function _transfer(address sender, address recipient, uint amount) override internal {
        if (_EXCLUDE[sender] || _EXCLUDE[recipient] || !openFee){
            super._transfer(sender, recipient, amount);
        }
        else{
            uint threshold = super.totalSupply().mul(9).div(10);
            uint blackHoleHold = super.balanceOf(address(0));
            
            if(blackHoleHold < threshold) {
                feeTax = 50;
            }else {
                feeTax = 35;
            }
            uint _fee = amount.mul(feeTax).div(1000);
            uint _destory = 0;
            if(blackHoleHold < threshold) {
                _destory = _fee.mul(burnTax).div(1000);
            }

            super._transfer(sender, recipient, amount.sub(_fee));
            
            if(_destory > 0) {
                super._burn(sender, _destory);
                super._transfer(sender, feeManager, _fee.sub(_destory));
            }else {
                super._transfer(sender, feeManager, _fee);
            }
            if (openManager && !Address.isContract(sender) && !Address.isContract(recipient)){
                ManagerWrap(feeManager).sendFee();
            }

        }
    }

    function burn(uint amount) public {
        super._burn(msg.sender, amount);
    }
}