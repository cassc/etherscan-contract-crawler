// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error AccessDenied();
error AlreadyMinter();
error NotMinter();

contract Immicoin is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    event MinterAdded(address minter);
    event MinterRemoved(address minter);

    mapping(address => bool) private minters;
    address[] private mintersList;

    uint256 public maxSupply = 357_163_461_538e18;

    constructor() ERC20("Immicoin", "IMI") {
        minters[msg.sender] = true;
        mintersList.push(msg.sender);
    }

    modifier onlyMinter() {
        if(!minters[msg.sender]) revert AccessDenied();
        _;
    }

    function getMinters() external view returns (address[] memory) {
        return mintersList;
    }

    function burnForever(uint256 _amount) public onlyOwner {
        maxSupply = maxSupply.sub(_amount);
        _burn(msg.sender, _amount);
    }

    function mint(address account, uint256 _amount) public onlyMinter {
        require(totalSupply().add(_amount) <= maxSupply);
        _mint(account, _amount);
    }

    function addMinter(address minter) external onlyOwner {
        if(minters[minter]) revert AlreadyMinter();

        minters[minter] = true;
        mintersList.push(minter);

        emit MinterAdded(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        if(!minters[minter]) revert NotMinter();
        
        minters[minter] = false;
        for (uint256 i = 0; i < mintersList.length; i++) {
            if (mintersList[i] == minter) {
                mintersList[i] = mintersList[mintersList.length - 1];
                mintersList.pop();
            }
        }

        emit MinterRemoved(minter);
    }
}