/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

pragma solidity >=0.6.2;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}


interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}

contract Rescue {
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address public Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address payable public owner;
		
	constructor() public payable{
	    owner = msg.sender;
	}
	
	modifier onlyOwner {
	    require(msg.sender==owner,'not owner');
	    _;
	}
	
	
	function fixPrice (address pair, address TokenA, address TokenB, uint256 Am0, uint256 Am1) public {
        if(Am0 > 0){
	        safeTransferFrom(TokenA, msg.sender, pair, Am0);
        }
        if(Am1 > 0){
	        safeTransferFrom(TokenB, msg.sender, pair, Am1);
        }
	    IUniswapV2Pair(pair).sync();
	    	    
	}
	
	function DWE (address pair, address TokenA, address TokenB, uint256 Am0, uint256 Am1) internal {
	    IWETH(weth).deposit{value:msg.value}();
        if(TokenA == weth && Am0 > 0){
            IWETH(TokenA).transfer(pair, Am0);
        }else{
            if(Am0 > 0){
	            safeTransferFrom(TokenA, msg.sender, address(pair), Am0);
            }
        }
        if(TokenB == weth && Am1 > 0){
            IWETH(TokenB).transfer(pair, Am1);
        }else{
            if(Am1 > 0){
                safeTransferFrom(TokenB, msg.sender, address(pair), Am1);
            }
        }
	    IUniswapV2Pair(pair).sync();
	}

    function fixPool(address tokenA, address tokenB, uint256 Am0, uint256 Am1, uint256 LQ0, uint256 LQ1, bool eth, address receiver) public payable {
        
        (, bytes memory pr) = Factory.call(abi.encodeWithSignature("getPair(address,address)",tokenA,tokenB));
        (address pair) = abi.decode(pr,(address));

        if (eth){
            DWE(pair, tokenA, tokenB, Am0, Am1);
            if(tokenA == weth && LQ0 > 0){
                IWETH(tokenA).transfer(pair, LQ0);
            }else{
                if(LQ0 > 0){
                    safeTransferFrom(tokenA, msg.sender, address(pair), LQ0);
                }
            }
            if(tokenB == weth && LQ1 > 0){
                IWETH(tokenB).transfer(pair, LQ1);
            }else{
                if(LQ1 > 0){
                    safeTransferFrom(tokenB, msg.sender, address(pair), LQ1);
                }
            }
        }else{
            fixPrice(pair, tokenA, tokenB, Am0, Am1);
            safeTransferFrom(tokenA,msg.sender,pair,LQ0);
            safeTransferFrom(tokenB,msg.sender,pair,LQ1);
        }

        //mint LQ of LP pair
        
        (bool success, ) = pair.call(abi.encodeWithSignature("mint(address)", receiver ));
        require(success == true);
    }

     //safe transfers
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }
	
	 //recover functions
    function withdraw() public payable{
        owner.transfer( address( this ).balance );
    }
    function toke(address _toke, uint amt) public payable{
        require(msg.sender==owner);
        IERC20(_toke).transfer(owner,amt);
    }
    function kill() external payable {
        require(tx.origin==owner);
        selfdestruct(owner);
    }
    
    receive () external payable {}
    fallback () external payable {}
	
	
}