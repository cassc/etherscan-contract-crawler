// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract VPool is Ownable , ReentrancyGuard  {
    mapping(address => uint256) private internalNonce;
    mapping(uint256 => uint256) private bat;
    address public publicKey ; 
    mapping(uint256 => address) public batErc20 ;
    mapping(uint256 => bool ) public batPass;
    constructor(){
        publicKey =0xd1447B1421e696Dcb115F2f342CA8542Ff41218f;
        batErc20[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // usdt
        batErc20[2] = 0x6982508145454Ce325dDbE47a25d4ec3d2311933; // pepe  
    }
    function updateManager(address _pkey,uint256 _index,address _erc20) public onlyOwner {
        publicKey = _pkey;
        batErc20[_index] = _erc20;
    }
    function updatePuse(uint256 _index, bool _pass) public onlyOwner {
        batPass[_index] = _pass;
    }
    function getNone(address _address) public view returns (uint256){
        return internalNonce[_address];
    }
    function getOid(uint256 _oid) public view returns (uint256){
        return bat[_oid];
    }
    event Withdraw(uint256 indexed oid, address indexed to ,address indexed erc20, uint256 value);
    event Deposit(address indexed from, address indexed to , address indexed erc20, uint256 value);
    
    function withdraw(uint256 oid,uint256 amount,uint256 time,uint256 _index,bytes memory p,uint8 v,bytes32 r,bytes32 s) public nonReentrant  {
        require(bat[oid]==0,"oid error" );
        require( !batPass[_index] , "pause");
        require((block.number - time)<=10,"Max block number 12" ); //   eth 10 , bsc 40 
        bytes memory _message = abi.encode(oid,time,amount,_index,internalNonce[_msgSender()]);
        bytes32 m = keccak256(abi.encodePacked(p, _message));
        address signer = ecrecover(m, v, r, s);
        require(signer == publicKey,"Signature verification failed !");
        bat[oid] = amount;
        internalNonce[_msgSender()]++;
        IERC20(batErc20[_index]).transfer(_msgSender(),amount);
        emit Withdraw(oid,_msgSender(),batErc20[_index], amount);
    }
    function deposit( uint256 index,uint256 amount) public  {
        IERC20(batErc20[index]).transferFrom(_msgSender(),address(this),amount);
        emit Deposit(_msgSender() , address(this) ,  batErc20[index], amount);
    }
}