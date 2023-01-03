/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

       
    //BNB to Token SWAP
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    //Add Liquidity non BNB
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;


}

interface IBEP20 {
   
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IPancakeFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract ZAP_LP_w_BNB {

    address public owner;

    address public router_address = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public factory_address = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address public token_A_Address;
    address public token_B_Address;

    address public LP_Address; 

    IBEP20 token_A_token;
    IBEP20 token_B_token;

    IBEP20 LP_token;


    IDEXRouter router;
    IPancakeFactory factory;


    //EVENTS
    event Deposit(address indexed from, uint256 indexed amount);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {

    //Router
    router = IDEXRouter(router_address);

    //Factory
    factory = IPancakeFactory(router_address);

    //Swapping Token
    token_A_token = IBEP20(token_A_Address);
    token_B_token = IBEP20(token_B_Address);

    //LP Token
    LP_token = IBEP20(LP_Address);

    //Owner
    owner = payable(msg.sender);

    }

    receive() external payable {
    emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function updateRouterAddress(address _newRouter) public onlyOwner {
        router_address = _newRouter; 

    }
    function updateFactoryAddress(address _newFactory) public onlyOwner {
        factory_address = _newFactory; 

    }



/////1  Deposit BNB  //ready

    function INITIATE(address  tokA, address tokB) public payable{
        
        require(msg.value > 0);
    
        emit Deposit(msg.sender, msg.value);


         
        uint256 contractBalanceNow = address(this).balance;


        //Buy tokA
        address[] memory tokApath = new address[](2);
        tokApath[0] = router.WETH();
        tokApath[1] = tokA;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 50 *  contractBalanceNow / 100 }
        (0, tokApath, address(this), block.timestamp);

        //Buy tokB
        address[] memory tokBpath = new address[](2);
        tokBpath[0] = router.WETH();
        tokBpath[1] = tokB;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 50 *  contractBalanceNow / 100 }
        (0, tokBpath, address(this), block.timestamp);



        
        uint256 tokenA_BalNow =      token_A_token.balanceOf(address(this));
        uint256 tokenB_BalNow =      token_B_token.balanceOf(address(this));
    

        token_A_token.approve(router_address, tokenA_BalNow);
        token_B_token.approve(router_address, tokenB_BalNow);

        router.addLiquidity( 
        
        token_A_Address,
        token_B_Address,
        tokenA_BalNow,
        tokenB_BalNow,
        0,
        0,
        owner,
        block.timestamp);

        
    //get LP Token address
    LP_token = IBEP20(factory.getPair(token_A_Address,token_B_Address));

        payable(msg.sender).transfer(address(this).balance);
        token_A_token.transfer(msg.sender, token_A_token.balanceOf(address(this)));
        token_B_token.transfer(msg.sender, token_B_token.balanceOf(address(this)));
        LP_token.transfer(msg.sender, LP_token.balanceOf(address(this)));

    }



}