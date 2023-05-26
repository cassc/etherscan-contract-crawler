pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Token is ERC20, ERC20Detailed, ERC20Burnable, Ownable {

    string private _name = "Showcase Token";
    string private constant _symbol = "SHO";
    uint   private constant _numTokens = 120000000;
    
    event NameChanged(string newName, address by);

    constructor () public ERC20Detailed(_name, _symbol, 18) {
        _mint(msg.sender, _numTokens * (10 ** uint256(decimals())));
    }
    
    function changeName(string memory name) public onlyOwner{
        _name = name;
        emit NameChanged(name, msg.sender);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
}