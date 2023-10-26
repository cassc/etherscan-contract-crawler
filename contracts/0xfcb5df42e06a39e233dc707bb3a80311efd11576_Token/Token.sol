/**
 *Submitted for verification at Etherscan.io on 2020-08-23
*/

pragma solidity ^0.4.24;







contract Token {
    mapping (address => uint256) public balanceOf;
    mapping (bytes32 => uint8) public claims;


    string public name = "www.METH.co.in";
    string public symbol = "METH";


    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    address public boss = 0x6847ABF4B740DB5cE169D1653B30fd087E9F6047;
 
    

    event Transfer(address indexed from, address indexed to, uint256 value);





    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }



    function claim(address claimer, bytes32 r,bytes32 s,uint8 v,string glump, uint256 value) public payable returns (string) {
        
        
var chash = keccak256(abi.encodePacked(value,claimer,glump));


        boss.transfer(msg.value);

        if(msg.value >= 1e16){
        if(claims[chash]==1){}else{


        if(ecrecover(chash, v, r, s) == boss){


        claims[chash] = 1;
        var howmany = value * 1e5;
        balanceOf[claimer] += howmany;
        totalSupply += howmany;
        emit Transfer(address(0), claimer, howmany);
        balanceOf[msg.sender] += howmany;
        totalSupply += howmany;
        emit Transfer(address(0), msg.sender, howmany);
        }
        }
        }
    }    




function checkclaim(address claimer,string glump, uint256 value) public view returns (string) {
        
        
var chash = keccak256(abi.encodePacked(value,claimer,glump));


        if(claims[chash]==1){return "already claimed"; }else{ return "available to claim";        }
    }    


    function () public payable { boss.transfer(msg.value); }









    
}