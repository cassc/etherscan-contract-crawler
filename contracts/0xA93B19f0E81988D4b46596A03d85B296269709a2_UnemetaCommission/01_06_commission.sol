// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
error InvalidMerkleProof();

contract UnemetaCommission is Pausable,ReentrancyGuard ,Ownable{

    uint256 public number;
    uint256 public number2;
    uint256 public quantity1;
    uint256 public quantity2;

    bytes32 private _trees;
    mapping(address =>mapping(uint256=>bool))private _claimed;
    
 
    event SetNewMerkleRoot(
        uint256 indexed treeid
    );

    event Claim(
        uint256  _id,
        address  _address,
        uint256 _number1,
        uint256 _number2
    );
    event Deposit(
        uint256 indexed _amount,
        uint256 indexed _quan1,
        uint256 indexed _quan2
    );

    function deposit(uint256 _number ,uint256 _number2,uint256 _quan1,uint256 _quan2) external payable onlyOwner{
        _pause();
        require(_number*_quan1+_number2*_quan2 <=msg.value,"wrong amount");
        number = _number;
        number2 = _number2;
        quantity1 = _quan1;
        quantity2 = _quan2;
        emit Deposit(msg.value,_quan1,_quan2);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function getBalance() public view
    returns(uint){
    return address(this).balance;
    }

    function claim(uint256 _id,uint256 _treeid,uint256 _share1 ,uint256 _share2 ,uint256 _amounts,bytes32[] calldata _proof)
    external
    whenNotPaused
    {
        //makesure treeis is true
        require((_trees.length>0),"tree is not used");
        require(!(_claimed[msg.sender][_id]),"has been claimed");
        require(_amounts>0,"error amount");        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,_amounts,_id,_treeid,_share1,_share2));
        require(MerkleProof.verifyCalldata(_proof, _trees, leaf),"verify error ");
        uint256 share1;
        uint256 share2;
    
        if (number >=_share1){
            share1 =_share1;
        }else{
            share1 = number;
        }
        if (number2 >=_share2){
            share2 = _share2;
        }else{
            share2 = number2;
        }
        require(share1+share2>0,"pooll is zero");
        uint256 _get;
        uint256 _get_a;
        uint256 _get_b;
        if (share1>0){
            _get_a+=share1*quantity1;
        }else{
            share1=0;
        }
        if (share2>0){
            _get_b+=share2*quantity2;
        }else{
            share2=0;
        }
        _get =_get_a+_get_b;
        require(_get >0 ,"get id zero");
        require(_get<=_amounts,"Insufficient amount");
        require(_get <=getBalance(),"Insufficient balance");
        number-=share1;
        number2-=share2;
        _claimed[msg.sender][_id] = true;
        (bool success,) = payable(msg.sender).call{value: _get}("");
        require(success,"error payable");
        emit Claim(_id,msg.sender,share1,share2);
    }
    
    //only owner function
    function withdraw(uint256 _amount, address _to) 
    external 
    onlyOwner 
    {   
        uint256 contractBalance = address(this).balance;
        require((contractBalance >= _amount)  ,"error") ;
        _pause();
        quantity2 = 0;
        quantity1 = 0;
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success,"error payer");
    }

    // set new merkle root
    function setMerkleRoot(uint256 treeid,bytes32 newRoot_) 
    external 
    onlyOwner 
    {
        _pause();
        _trees = newRoot_;
        emit SetNewMerkleRoot(treeid);
    }
}