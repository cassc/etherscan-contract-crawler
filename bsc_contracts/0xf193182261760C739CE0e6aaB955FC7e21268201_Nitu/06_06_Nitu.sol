// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nitu is ERC20, Ownable {
    address public MINING_POOL = address(0);
    address public ADMIN_ADDRESS = 0x5f2192f495af8e4A102059379f46C596906690F2;
    uint256 public constant MAX_SUPPLY = 210000000 * 1e18;

    constructor() ERC20("NITU Token", "NITU") {
        transferOwnership(0x2B069a31A67b963e56f752081515E9307c6823B3);
    }

    function mint(uint256 amount) public {
        require(
            MINING_POOL != address(0),
            "Can not mining zero address"
        );
        require(ADMIN_ADDRESS == msg.sender, "You are not admin");
        require(amount + totalSupply() <= MAX_SUPPLY, "Limit mining token");
        _mint(MINING_POOL, amount);
    }

    function setMiningPool(address _address) public onlyOwner {
        MINING_POOL = _address;
    }

    function setAdminAddress(address _address) public onlyOwner {
        ADMIN_ADDRESS = _address;
    }

    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }
}