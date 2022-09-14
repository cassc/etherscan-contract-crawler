// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MAGToken is ERC20, Ownable , ERC20Burnable {

    mapping (address => bool ) public minter;

    address[] private minterList;
    
    constructor() ERC20("MAG1 Test", "MAG1T") {
        //add owner to minterList
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(minter[msg.sender], "Only-minter");
        _;
    }

    function mint(address to, uint256 amount) public onlyMinter{
        _mint(to, amount);
    }

    function addMinter(address _minterAddr) public onlyOwner{
        require(!minter[_minterAddr], "Is minter");
        minterList.push(_minterAddr);
        minter[_minterAddr] = true;
    }

    function removeMinter(address _minterAddr) public onlyOwner{
        require(minter[_minterAddr], "Not minter");
        minter[_minterAddr] = false;
        
        uint256 i = 0;
        address _minter;
        while (i < minterList.length) {
            _minter = minterList[i];
            if (!minter[_minter]) {
                minterList[i] = minterList[minterList.length - 1];
                delete minterList[minterList.length - 1];
                minterList.pop();
            } else {
                i++;
            }
        }
    }

    function getMinters() public view returns (address[] memory){
        return minterList;
    }
    
}