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
function mint(address to, uint256 typeId, uint256 number) external;
}

    contract Base {
    using SafeMath for uint256;
        Erc20Token constant  internal _USDT = Erc20Token(0x55d398326f99059fF775485246999027B3197955);
        Erc20Token constant  internal _USDTAddr = Erc20Token(0x55d398326f99059fF775485246999027B3197955);
        ERC721 internal EOSSNFT = ERC721(0x55d398326f99059fF775485246999027B3197955); 
        Erc20Token constant  internal _EOSAddr = Erc20Token(0x56b6fB708fC5732DEC1Afc8D8556423A2EDcCbD6);
        Erc20Token constant  internal _EOSLPAddr = Erc20Token(0x06bd29bbbbEc61AFeb91B0e974Ac4482f2396e30);
        Erc20Token    internal _SEOSAddr = Erc20Token(0x58Afa1759fC752Eb9138455B2D32FfAD77062d6D);
        Erc20Token    internal _SEOSLPAddr = Erc20Token(0x58Afa1759fC752Eb9138455B2D32FfAD77062d6D);

   



        uint256 public oneDay = 86400; 
        

        uint256 public _startTime;

 
        address public _OPAddress;
        uint256 public SupernodePrice = 2000000000000000000000;
        uint256 public nodePrice      = 20000000000000000000000;
 


        uint256 public Tlilv = 98000;  


         address  _owner;
    
      
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
        address  _Powner = 0xdf6d4930bed6A88A8730fCE52f17d5c4E85723Cb;

     modifier only_Powner() {
            require(msg.sender == _Powner, "Permission denied"); _;
        }
   bool public openOW = true;

    function setopenOW() public onlyOwner {
        openOW = !openOW;
    }

    modifier only_openOW() {
        require(openOW, "only OW open"); _;
    }




    function transferPownership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        _Powner = newOwner;
    }


    function setlilv(uint256 newlilv )  public only_Powner only_openOW  {
        Tlilv = newlilv;   
     }
 
 
    // 获取代币价格
    function Spire_Price(Erc20Token ERC20Address, Erc20Token LP) public view returns(uint256) {

        uint256 usdtBalance = _USDTAddr.balanceOf(address(LP));
        uint256 SpireBalance = ERC20Address.balanceOf(address(LP));
        if(usdtBalance == 0){
             return  0;
        }else{
            return  SpireBalance.mul(10000000).div(usdtBalance);
        }
    }
 
 
    receive() external payable {}  
}