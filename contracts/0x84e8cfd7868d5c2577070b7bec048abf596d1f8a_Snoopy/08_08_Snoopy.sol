pragma solidity ^0.8.20;
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract Snoopy is ERC20, Ownable {
    using SafeERC20 for IERC20;
    constructor(
        string memory _name, 
        string memory _symbol,
        uint256 _initialSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply * (10 ** 18) );
    }  
}