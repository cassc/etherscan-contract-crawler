// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Security/OnlyAuthorized.sol";
import "./interfaces/IOperable.sol";

contract Wos is ERC20, OnlyAuthorized, IOperable {
    address private oilWellAddress = address(0);
    address private specialOilWellAddress = address(0);
    address private wosPackagesAddress = address(0);

    constructor() ERC20("WOS", "WOS") {}

    function mint(uint256 amount) external onlyAuthorized {
        require(
            msg.sender == oilWellAddress ||
            msg.sender == specialOilWellAddress ||
            msg.sender == wosPackagesAddress,
            "only the well or markeplace can create wos"
        );
        _mint(msg.sender, amount);
    }

    function burn(uint amount) external onlyAuthorized {
        _burn(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function raise(uint256 amount) external view returns (uint256) {
        return amount * 10**decimals();
    }

    function setOilWellAddress(address oilWell) external onlyAuthorized {
        require(oilWell != address(0), "Address cannot be zero");
        require(
            oilWellAddress == address(0),
            "You can't change the address again"
        );
        oilWellAddress = oilWell;
    }

    function setSpecialOilWellAddress(address oilWell) external onlyAuthorized {
        require(oilWell != address(0), "Address cannot be zero");
        require(
            specialOilWellAddress == address(0),
            "You can't change the address again"
        );
        specialOilWellAddress = oilWell;
    }

    function setWosPackagesAddress(address addr) external onlyAuthorized {
        require(addr != address(0), "Address cannot be zero");
        require(
            wosPackagesAddress == address(0),
            "You can't change the address again"
        );
        wosPackagesAddress = addr;
    }
}