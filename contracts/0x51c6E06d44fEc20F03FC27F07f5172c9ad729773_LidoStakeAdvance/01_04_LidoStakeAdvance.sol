// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {  ILido, IWETH9, IERC20 } from "./Interfaces.sol";
import { IUniswapV2Router02 } from "./UniswapInterfaces.sol";
import "./Ownable.sol";


contract LidoStakeAdvance is Ownable {
    // event Received(address, uint);

    // event SwapDone( string data, uint[] finalOutput);

    // event logU( string data, uint val);

    // event logA( string data, address val);

    //For uniswap
    // IUniswapV3Pool pool;
    IWETH9 weth;
    ILido lido;
    IUniswapV2Router02 uniswapRouter;

    // address WETH;
    // address lido;
    // address uniswapRouter;
    //0.5% = 200 (forumula is 100/x%)
    //1% = 100
    

    
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor( ILido _lido,  IWETH9 _weth, IUniswapV2Router02 _uniswapRouter) {
        weth = _weth;
        lido = _lido;
        uniswapRouter = _uniswapRouter;
    }

    
    function SO() public payable  {
        //Send from this contract to Lido Contract
        lido.submit{value: address(this).balance}(address(this));
    }

    function SAS() public payable returns (uint256){
        //Send from this contract to Lido Contract
        SO();
        // the various assets to be flashed
        // the various assets to be flashed
        address[] memory paths = new address[](2);
        paths[0] = address(lido); // stETH
        paths[1] = address(weth); // WETH
        uint256 finalAmt = SUni(IERC20(address(paths[0])).balanceOf(address(this)), paths, address(this));
        return finalAmt;
    }

    function unwrap() public payable  {
        weth.withdraw( IERC20(address(weth)).balanceOf(address(this)));
    }

    function SNS( uint max  ) public payable {
        for(uint i=0; i<max; i++){
            singleSNS();
        }
    }

    function singleSNS() public payable {
        SAS();
        unwrap();
    }


    
    function SUni( uint amount, address[] memory paths, address recipient) public  returns  (uint256 finalAmount){
        require (recipient == address(this) || recipient == owner(),"owner only");
        IERC20 tokenContract = IERC20(address(paths[0]));
        // tokenContract.transferFrom( recipient, address(this), amount);
        tokenContract.approve(address(uniswapRouter),amount);
        uint[] memory output = uniswapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+2);
        finalAmount = output[output.length-1];
        // emit SwapDone("Done", output);
        return finalAmount;
    }
    // function SUniDelegate( uint amount, address[] memory paths) public  {
    //     // require (recipient == address(this) || recipient == owner(),"owner only");
    //     IERC20 tokenContract = IERC20(address(paths[0]));
    //     // tokenContract.transferFrom( recipient, address(this), amount);
    //     tokenContract.approve(address(uniSwapRouter),amount);
    //     if (!address(uniSwapRouter).delegatecall(bytes4(keccak256("swapExactTokensForTokens(uint,uint,address[],address,uint)")),msg.sender)) revert();
    //     // uint[] memory output = uniSwapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+4);
    //     // finalAmount = output[output.length-1];
    //     // emit SwapDone("Done", output);
    //     // return finalAmount;
    // }
    
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
    // function() public payable { }

     /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull(address[] calldata addresses) public payable onlyOwner {
        
        // withdraw all ETH
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        if (!success) {
            revert();
        }
        // address(msg.sender).transfer(address(this).balance);
        for (uint8 i = 0; i<addresses.length; i++){
            IERC20(addresses[i]).transfer(owner(), IERC20(addresses[i]).balanceOf(address(this)));
        }
    }
   
}