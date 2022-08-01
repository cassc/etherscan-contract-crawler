pragma solidity ^0.8.0;

import "./ERC20Taxed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HoneyToken is ERC20Taxed, Ownable {
    constructor (
        address[] memory intialAddress, 
        uint256[] memory initialWeights,
        uint256 baseWeight
    ) ERC20Taxed("SBU Honey", "BHNY", intialAddress, initialWeights, baseWeight) {
        // TODO: Change totalSupply: 38B : 38000000000 |38,000,000,000 | ether | 38000000000000000000000000000 wei
        _mint(msg.sender, 38000000000 * (10 ** uint256(decimals())));
        _setExcemption(msg.sender, true);
        for(uint256 i = 0; i < intialAddress.length; i++){
            _setExcemption(intialAddress[i], true);
        }
    }

    function setFeeContract(address newFeeContract) public onlyOwner {
        _setFeeContract(newFeeContract);
    }
    function setShield(bool _value) public onlyOwner {
        _setShield(_value);
    } 
    function setShieldList(uint160[] calldata _list, bool[] calldata _value) public onlyOwner {
        require(_list.length == _value.length, "List and Value length don't match");
        for(uint256 i = 0; i < _list.length; i++){
            _setShieldList(_list[i],  _value[i]);
        }
    }
    function setFeeExceptions(address[] calldata _list, bool[] calldata _value) public onlyOwner {
        require(_list.length == _value.length, "List and Value length don't match");
        for(uint256 i = 0; i < _list.length; i++){
            _setExcemption(_list[i], _value[i]);
        }
    }
}