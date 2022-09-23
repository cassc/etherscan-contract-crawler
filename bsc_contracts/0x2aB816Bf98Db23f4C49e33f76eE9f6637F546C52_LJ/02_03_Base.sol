pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

    interface Erc20Token {//konwnsec//ERC20 接口
        function totalSupply() external view returns (uint256);
        function balanceOf(address _who) external view returns (uint256);
        function transfer(address _to, uint256 _value) external;
        function allowance(address _owner, address _spender) external view returns (uint256);
        function transferFrom(address _from, address _to, uint256 _value) external;
        function approve(address _spender, uint256 _value) external; 
        function burnFrom(address _from, uint256 _value) external; 
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        

    }
    
    
 
 

interface ERC721 {
    function mint(address _to,uint256 _tokenId ) external;
}


    
// 基类合约
    contract Base {
    using SafeMath for uint256;
              Erc20Token constant  internal _USDT = Erc20Token(0x55d398326f99059fF775485246999027B3197955);

 
        Erc20Token constant  internal _USDTAddr = Erc20Token(0x5f5bD6f8743A567BAa0313b54F82C20724f5cC5f);
        ERC721       internal   EOSSNFT = ERC721(0x163C140BE039b206b3B150532479142FA1895C65); 
        Erc20Token constant  internal _EOSAddr = Erc20Token(0x29769b1B99D5e46fA7dD3Ba46cf04aba27A1aE27);
        Erc20Token constant  internal _EOSLPAddr = Erc20Token(0x4173bbD124710F547E3D3CF545f8d90F22504B41);
        Erc20Token constant  internal _SEOSAddr = Erc20Token(0xFfF328b88c12C32731ABF193c2A4e0e2561C27dD);
        Erc20Token constant  internal _SEOSLPAddr = Erc20Token(0x6037b3a65992d11DB52A4bf4227f2E2578309beb);


// // 本地测试链
//         Erc20Token constant  internal _USDTAddr = Erc20Token(0x11343e19FAA20969921E7E5726ee2857F505897B);
//         ERC721       internal   EOSSNFT = ERC721(0x163C140BE039b206b3B150532479142FA1895C65); 
//         Erc20Token constant  internal _EOSAddr = Erc20Token(0x7f569bcCD70EC2314b33fF83c827FA255d17E361);
//         Erc20Token constant  internal _EOSLPAddr = Erc20Token(0x4173bbD124710F547E3D3CF545f8d90F22504B41);
//         Erc20Token constant  internal _SEOSAddr = Erc20Token(0x930033Ec33b578Dac7944fAB362e2839C03AeCaf);
//         Erc20Token constant  internal _SEOSLPAddr = Erc20Token(0x6037b3a65992d11DB52A4bf4227f2E2578309beb);




        uint256 public oneDay = 1000; 

        uint256 public _startTime;

        address public Uaddress; 

        address public _OPAddress;
    uint256 public    SupernodePrice = 2000000000000000000000;
    uint256 public    nodePrice      = 20000000000000000000000;
    mapping(uint256 => address) public IDtoToken; 
    mapping(uint256 => address) public IDtoTokenLP; 
        address  _owner;
        function FPT_Convert(uint256 value) internal pure returns(uint256) {
            return value.mul(1000000000000000000);
        }
    
      
        modifier onlyOwner() {
            require(msg.sender == _owner, "Permission denied"); _;
        }
        modifier isZeroAddr(address addr) {
            require(addr != address(0), "Cannot be a zero address"); _; 
        }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }


    function setUaddressship(address newaddress) public onlyOwner {
        require(newaddress != address(0));
        Uaddress = newaddress;
    }
    // 获取代币价格
    function Spire_Price(Erc20Token ERC20Address, Erc20Token LP) public view returns(uint256) {


                    // return  10000000;

        uint256 usdtBalance = _USDTAddr.balanceOf(address(LP));
        uint256 SpireBalance = ERC20Address.balanceOf(address(LP));
        if(usdtBalance == 0){
             return  0;
        }else{
            return  SpireBalance.mul(10000000).div(usdtBalance);
        }
    }

    function setTokenandLP(uint256 index,address LP ,address token) public onlyOwner  {
        IDtoToken[index] = token;
        IDtoTokenLP[index] = LP;
    }
 
    receive() external payable {}  
}