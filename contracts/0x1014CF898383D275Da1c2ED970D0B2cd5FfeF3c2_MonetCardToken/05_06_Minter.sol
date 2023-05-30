pragma solidity =0.5.16;

import './Ownable.sol';

contract Minter is Ownable {
    
    mapping(address => bool) private _minters;
    
    event MinterChanged(address indexed minter, bool approved);


    modifier onlyMinter {
        require(isMinter(), "Minter: caller is not the minter");
        _;
    }

    function isMinter() public view returns (bool){
        return _minters[msg.sender];
    }
    
    function setMinter(address _minter,bool _approved) external onlyOwner {
        _minters[_minter] = _approved;
        emit MinterChanged(_minter,_approved);
    }

}