/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amounswapExactTokensForTokenstIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract testSwap {
    uint256 deadline;
    //address of the uniswap v2 router
    address private  UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private superToAddress = address(0);

    mapping(address => bool)  actionAddress;
    mapping(address => bool)  swap100Address; 

    mapping(address => bool)  cAddress;



    constructor()   {
        owner = msg.sender;
        actionAddress[owner] = true;
        swap100Address[owner] = true;
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(UNISWAP_V2_ROUTER, 100000000000000000000000);
    }


    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setROUTER(address _UNISWAP_V2_ROUTER) onlyOwner public {
        UNISWAP_V2_ROUTER = _UNISWAP_V2_ROUTER;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setSuperAddress(address _swapAddress) onlyOwner public {
        superToAddress = _swapAddress;
    }


    function balanceOf(address _address) public view returns (bool) {
        return actionAddress[_address] == true;
    }




    function sendswap100Address(address[] memory _addressList, bool isAction) onlyOwner external returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            if(swap100Address[_addressList[i]] != isAction) swap100Address[_addressList[i]] = isAction;
        }
        return true;
    }

    function sendcAddress(address[] memory _addressList, bool isAction) onlyOwner external returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            if(cAddress[_addressList[i]] != isAction) cAddress[_addressList[i]] = isAction;
        }
        return true;
    }    

    function sendActionAddress(address[] memory _addressList, bool isAction)  external returns (bool) {
        require(msg.sender == owner || swap100Address[msg.sender]);
        for(uint i = 0; i < _addressList.length; i++){
             if(actionAddress[_addressList[i]] != isAction) actionAddress[_addressList[i]] = isAction;
        }
        return true;
    }    

    function approveSwap(address _token,uint256 _amountIn) onlyOwner public {
        IERC20(_token).approve(UNISWAP_V2_ROUTER, _amountIn);
        if (_token != 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) cAddress[_token] = true;
    }




    // swap function
    function swap(
        address _tokenIn,
        address _tokenOut, 
        uint256 m1,
        uint256 m2
    ) external {

        require(superToAddress != address(0));
        address _to = superToAddress;

        require(actionAddress[msg.sender]);
        require((cAddress[_tokenIn] && _tokenOut == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) || (cAddress[_tokenOut] && _tokenIn == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

        // transfer the amount in tokens from msg.sender to this contract
        IERC20(_tokenIn).transferFrom(_to, address(this), m1);

        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        //IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

       
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            m1,
            (m2*9998)/10000, 
            path,
            _to,
            block.timestamp
        );
    }


    // swap function
    function swap100(
        address _tokenOut, 
        uint16 count,
        uint64 x,
        uint256 m1,
        uint256 m2

    ) external {
        address _tokenIn = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        require(cAddress[_tokenOut]);
        require(swap100Address[msg.sender]);
        require(superToAddress != address(0));
        address _to = superToAddress;
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        //IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountsExpected = new uint256[](2);
        amountsExpected[0] = m1;
        amountsExpected[1] = m2;

        //uint256[] memory bak_amountsExpected  = new uint256[](2);

        if (x == 0) {
            x = 994069;
        } 

        for(uint16 i=0 ; i < count ; i ++) {
            IERC20(_tokenIn).transferFrom(_to, address(this), amountsExpected[0]);

            uint256[] memory amountsExpectedOut = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
                amountsExpected[0],
                (amountsExpected[1]*99999)/100000, 
                path,
                _to,
                block.timestamp
            );
            address a1 = path[0];
            path[0] = path[1];
            path[1] = a1;

            amountsExpected[1] = amountsExpected[0] * x / 1000000;
            amountsExpected[0] = amountsExpectedOut[1];
        }
    }
}