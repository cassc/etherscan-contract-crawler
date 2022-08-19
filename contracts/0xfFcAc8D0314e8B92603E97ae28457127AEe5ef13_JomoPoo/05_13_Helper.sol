pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Helper is Ownable {
    mapping(address=>bool) HelperMapping;

    constructor() {
       setHelper(msg.sender,true);
    }

    modifier onlyHelper() {
        _checkHelper();
        _;
    }
    function _checkHelper() internal view virtual {
        require(HelperMapping[msg.sender] == true, "Helper: caller is not the Helper");
    }

    function setHelper(address _address, bool _isHelper) public onlyOwner{
        HelperMapping[_address] = _isHelper;
    }

}