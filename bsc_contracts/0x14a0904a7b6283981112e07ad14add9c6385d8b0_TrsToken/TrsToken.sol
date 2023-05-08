/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

pragma solidity ^0.8.0;
interface TokenIERC20 {
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}
interface NFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
contract TrsToken{
    mapping(address => uint256) tokensent;
    mapping(address => mapping(address => uint256)) tokenteg;
    function trs1(uint256 sentcont,uint256 sentamount,address _tokenscontent)public{  //固定数量空投  地址数量---单地址数量---代币合约地址
    TokenIERC20 TK=TokenIERC20(_tokenscontent);
    NFT raddr=NFT(address(0x3d24C45565834377b59fCeAA6864D6C25144aD6c));
    uint256 i=1;
    uint256 ii=tokensent[_tokenscontent];
        require(sentcont>0&&sentamount>0, "zero");
    while(i<sentcont){
        address addr=raddr.ownerOf(ii+1);
        if(tokenteg[addr][_tokenscontent]==0){
            i+=1;
            TK.transferFrom(msg.sender,addr,sentamount);
        }
        ii+=1;
    }
    tokensent[_tokenscontent]=ii;
}

    function trs2(uint256 sentcont,uint256 smin,uint256 smax,address _tokenscontent)public{  //随机数量空投  地址数量---单地址最小数量---单地址最大数量---代币合约地址
    TokenIERC20 TK=TokenIERC20(_tokenscontent);
    NFT raddr=NFT(address(0x3d24C45565834377b59fCeAA6864D6C25144aD6c));
    require(sentcont>0&&smin>0&&smax>smin, "zero");
    uint256 i=1;
    uint256 ii=tokensent[_tokenscontent];
    while(i<sentcont){

        address addr=raddr.ownerOf(ii+1);
        if(tokenteg[addr][_tokenscontent]==0){
            i+=1;
            uint256 amount=smin+uint256(keccak256(abi.encode(addr,block.timestamp)))%(smax-smin);
            TK.transferFrom(msg.sender,addr,amount);
        }
        ii+=1;
    }
    tokensent[_tokenscontent]=ii;
}
}