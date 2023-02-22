/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

pragma solidity ^0.8.0;
interface TokenIERC20 {
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}
contract U101{
    function trs(address[] memory ads,uint256[] memory b,address _tokens)public payable{
    TokenIERC20 TK=TokenIERC20(_tokens);
    uint i=ads.length;
    uint ii=0;
    for(ii;ii<i;ii++){
        TK.transferFrom(msg.sender,ads[ii],b[ii]*1e18);
    }
}
}