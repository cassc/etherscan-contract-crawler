//SPDX-License-Identifier: MIT
//ndgtlft etm.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Minter is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address _address, bool _bool) external onlyOwner {
        minters[_address] = _bool;
    }
}

abstract contract Transferer is Ownable {
    mapping(address => bool) public transferers;
    modifier onlyTransferer { require(transferers[msg.sender], "Not Transferer!"); _; }
    function setTransferer(address _address, bool _bool) external onlyOwner {
        transferers[_address] = _bool;
    }
}

abstract contract Burner is Ownable {
    mapping(address => bool) public burners;
    modifier onlyBurner { require(burners[msg.sender], "Not Burner!"); _; }
    function setBurner(address _address, bool _bool) external onlyOwner {
        burners[_address] = _bool;
    }
}

contract XTE is ERC20("XTE", "XTE"), Minter, Transferer, Burner{

    modifier disabled {
        revert("Disabled");
        _;
    }

    function mintToken(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    function transferToken(address _from, address _to, uint256 _amount) external onlyTransferer {
        _transfer(_from, _to, _amount);
    }

    function burnToken(address _from, uint256 _amount) external onlyBurner {
        _burn(_from, _amount);
    }

    // transfer prohibition
    function transfer(address recipient, uint256 amount) public virtual override disabled returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override disabled returns(bool){}
}