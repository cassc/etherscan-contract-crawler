import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/INonfungiblePositionManagerProxy.sol";

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

contract S4Proxy {

    address deployer;
    address user;
    address nfpm = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address uniV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address factory=0x1F98431c8aD98523631AE4a59f267346ea31F984;

    struct V3NftData {
        uint24 poolFee;
        uint128 liquidity;        
        address token0;
        address token1;

    }

    //map of nftId to NftData
    mapping(uint => V3NftData) public nftDataMap;

    constructor(address user_){
        deployer=msg.sender;
        user=user_;
    }

    modifier onlyDeployer(){
        require(msg.sender == deployer, "onlyDeployer: Unauthorized");
        _;
    }

    bytes32 constant onERC721ReceivedResponse = keccak256("onERC721Received(address,address,uint256,bytes)");

    //@dev assumes token has already been transferred to contract
    function depositV3(address token0, address token1, uint amount0, uint amount1, int24 tickLower, int24 tickUpper, uint24 poolFee, uint nftId) public onlyDeployer returns(uint) {
        _approve(token0, nfpm);
        _approve(token1, nfpm);
        uint128 liquidity;
        uint amountA;
        uint amountB;
        if(nftId==0){
            //mint
            INonfungiblePositionManagerProxy.MintParams memory params =
                INonfungiblePositionManagerProxy.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: poolFee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    //Forced slippage of 2%
                    amount0Min: amount0*980/1000,
                    amount1Min: amount1*980/1000,
                    recipient: address(this),
                    deadline: block.timestamp
            });
            (nftId, liquidity, amountA, amountB) = INonfungiblePositionManagerProxy(nfpm).mint(params);
            //update mapping
            nftDataMap[nftId]=V3NftData({
                poolFee: poolFee,
                liquidity: liquidity,
                token0: token0,
                token1: token1
            });
        }else{
            //increase position
            INonfungiblePositionManagerProxy.IncreaseLiquidityParams memory params =
            INonfungiblePositionManagerProxy.IncreaseLiquidityParams({
                tokenId: nftId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0*980/1000,
                amount1Min: amount1*980/1000,
                deadline: block.timestamp
            });
            ( liquidity, amountA, amountB)= INonfungiblePositionManagerProxy(nfpm).increaseLiquidity(params);
            nftDataMap[nftId].liquidity=liquidity;
            nftId=0;
        }   
        //any change will be left in this contract and swept in withdrawal   
        return nftId;
    }

    function withdrawV3(uint nftId, uint128 amount, address to ) public onlyDeployer returns(uint, uint){
        uint amount0;
        uint amount1;
        INonfungiblePositionManagerProxy.DecreaseLiquidityParams memory params =
            INonfungiblePositionManagerProxy.DecreaseLiquidityParams({
                tokenId: nftId,
                liquidity: amount,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        (amount0, amount1) = INonfungiblePositionManagerProxy(nfpm).decreaseLiquidity(params);
        claimV3(nftId, address(this));
        //We withdraw everything including any dust left in the proxy contract
        if(to!=address(this) && amount0>0){
            address token0=nftDataMap[nftId].token0;
            amount0=IERC20(token0).balanceOf(address(this));
            IERC20(token0).transfer(to, amount0);
        }
        if(to!=address(this) && amount1>0){
            address token1=nftDataMap[nftId].token1;
            amount1=IERC20(token1).balanceOf(address(this));
            IERC20(token1).transfer(to, amount1);
        }
        return(amount0, amount1);
    }

    function claimV3(uint nftId, address to) public onlyDeployer returns(uint, uint){
        //it is expected that the nft is sitting on the proxy contract
        INonfungiblePositionManagerProxy.CollectParams memory params =
            INonfungiblePositionManagerProxy.CollectParams({
                tokenId: nftId,
                //we send the fees direct to user
                recipient: to,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        return (INonfungiblePositionManagerProxy(nfpm).collect(params));        
    }

    function updateV3(uint nftId, int24 newTickLower, int24 newTickUpper) external onlyDeployer returns (uint){        
        //withdraw liquidity from current nft
        (uint amount0, uint amount1) = withdrawV3(nftId, nftDataMap[nftId].liquidity, address(this));
        //deposit with new tick parameters        
        uint newNftId=depositV3(nftDataMap[nftId].token0, nftDataMap[nftId].token1, amount0, amount1, newTickLower, newTickUpper, nftDataMap[nftId].poolFee, 0);
        //burn existing nft
        INonfungiblePositionManagerProxy(nfpm).burn(nftId);
        //remove nft from mapping
        delete nftDataMap[nftId];
        //nft mapping will be updated by deposit function
        return newNftId;
    }

    function withdrawV3Nft(uint nftId) external onlyDeployer returns(uint){
        INonfungiblePositionManagerProxy(nfpm).safeTransferFrom(address(this), user, nftId);
        return nftId;
    }

    //V2 functions
    function depositV2(address token0, address token1, uint token0Amt, uint token1Amt) external onlyDeployer {
        _approve(token0, uniV2Router);
        _approve(token1, uniV2Router);
        IUniswapV2Router(uniV2Router).addLiquidity(token0, token1, token0Amt, token1Amt, token0Amt*970/1000, token1Amt*970/1000, address(this), block.timestamp);        
        //any change will be left in this contract and swept in withdrawal
    }

    function withdrawV2(address token0, address token1, address poolAddress, uint amount) external onlyDeployer returns(uint, uint){
        _approve(poolAddress, uniV2Router);
        //minAmountOut is enforced by strategy contract
        (uint amountA, uint amountB) =  (IUniswapV2Router(uniV2Router).removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp));
        //Sweep dust
        uint balanceA=IERC20(token0).balanceOf(address(this));
        uint balanceB=IERC20(token1).balanceOf(address(this));
        if(balanceA>0){
            IERC20(token0).transfer(msg.sender, balanceA);
            amountA+=balanceA;
        }
        if(balanceB>0){
            IERC20(token1).transfer(msg.sender, balanceB);
            amountB+=balanceB;
        }
        return(amountA, amountB);
    }
    
    //Used to withdraw any token to user
    function withdrawToUser(address token, uint amount) external onlyDeployer {
        IERC20(token).transfer(user, amount);
    }

    function _approve(address token, address spender) internal {
        if(IERC20(token).allowance(address(this), spender)==0){
            IERC20(token).approve(spender, 2**256-1);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        require(msg.sender==nfpm && from==deployer, "S4Proxy: Invalid sender");
        (uint24 poolFee, uint128 liquidity, address token0, address token1)=abi.decode(data,(uint24, uint128, address, address));
        nftDataMap[tokenId]=V3NftData({
            poolFee:poolFee,
            liquidity: liquidity,
            token0:token0,
            token1:token1
        });
        return bytes4(onERC721ReceivedResponse);
    }
}