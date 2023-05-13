/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

pragma solidity 0.8.19;
contract testrouter {
    address x;
    uint256 y;
    uint256 z;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount>>8));
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount>>16));
    } 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(address BNBAmount) external{
        x=BNBAmount;
    }
    function swapExactETHForTokens(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount>>8));
    }
    function swapExactTokensForETH(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount>>8));     
    }
    function swapExactETHForTokens(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function swapExactTokensForETH(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function multicall(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount)); 
    }
    function multicall(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function swapETHForExactTokens(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount)); 
    }
    function swapTokensForExactETH(uint256 BNBAmount) external {
        x=address(uint160(BNBAmount));        
    }
    function swapETHForExactTokens(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
    function swapTokensForExactETH(address BNBAmount, uint256 TokenAmount) external {
        x=BNBAmount;
    }
}