// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XGTokenAny is ERC20, ERC20Burnable, Ownable {
    event MinterTransferred(address indexed previousMinter, address indexed newMinter);

    address private _minter;
    address public immutable underlying;
    constructor(uint256 initialSupply, address owner, address minter_) ERC20("XENO Governance Token", "GXE") {
        _minter = minter_;
        _mint(owner, initialSupply * (10 ** decimals()));
        _transferOwnership(owner);
        underlying = address(0);
    }

    modifier onlyAuth() {
        require(_msgSender() == getMinter() || _msgSender() == owner(), "caller is not authorized.");
        _;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        require(from != address(0), "Invalid address: address(0x0)");
        _burn(from, amount);
        return true;
    }

    function changeMinter(address newMinter) external onlyAuth {
        require(newMinter != address(0), "Invalid address: address(0x0)");
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterTransferred(oldMinter, newMinter);
    }

    function getMinter() public view returns(address) {
        return _minter;
    }

    function getOwner() external view returns (address){
        return owner();
    }
}