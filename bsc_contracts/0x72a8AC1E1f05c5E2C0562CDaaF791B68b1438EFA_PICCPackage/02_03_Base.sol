pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

    library SafeMath {//konwnsec//IERC20 接口
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0; 
            }
            uint256 c = a * b;
            assert(c / a == b);
            return c; 
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
            uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn't hold
            return c; 
        }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b; 
        }

        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            assert(c >= a);
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
            function mint(uint256 amount) external  returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        

    }
    
 

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
  
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}
    

    contract Base {
        using SafeMath for uint;


        Erc20Token constant internal _USDTIns = Erc20Token(0x55d398326f99059fF775485246999027B3197955); 
        Erc20Token constant internal _PICCIns = Erc20Token(0x63714C713bF14de1bF1CC9503a8b8Bae8071169A); 
        Erc20Token constant internal uniswapV2Pair = Erc20Token(0x45ef0b10E8bCf16d608cb306e00a9E53747d9DED); 

        address  _owner;
        address  _operator;

        function AMA_Convert(uint256 value) internal pure returns(uint256) {
            return value.mul(1000000000000000000);
        }
        
        modifier onlyOwner() {
            require(msg.sender == _owner, "Permission denied"); _;
        }
        modifier isZeroAddr(address addr) {
            require(addr != address(0), "Cannot be a zero address"); _; 
        }


        modifier only_operator() {
            require(msg.sender == _operator, "Permission denied"); _;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            require(newOwner != address(0));
            _owner = newOwner;
        }


        function transferOperatorship(address newOperator) public onlyOwner {
            require(newOperator != address(0));
            _operator = newOperator;
        }

        receive() external payable {}  
}