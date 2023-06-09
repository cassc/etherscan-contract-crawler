pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STBL is ERC20, Ownable {

    mapping (address => bool) public managers;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

    }

    function manageManagers(address[] memory _managers, bool[] memory _value) onlyOwner public {
        require(_managers.length == _value.length, "managers and value size doesn't equal");
        for(uint256 i = 0; i < _managers.length; ++i) {
            managers[_managers[i]] = _value[i];
        }
    }

    modifier onlyManager() {
        require(managers[msg.sender], "sender is not a manager");
        _;
    }

    function mint(address _receiver, uint256 _value) onlyManager public {
        ERC20._mint(_receiver, _value);
    }

    function burn(uint256 _value) public {
        ERC20._burn(msg.sender, _value);
    }
}