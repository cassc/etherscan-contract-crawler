// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Doof is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public initialSupply;
    uint256 public maxSupply;

    mapping (address => bool) private isDev;

    constructor(
        uint256 _initialSupply,
        uint256 _maxSupply
    ) ERC20("$DOOF", "$DOOF") {
        _mint(msg.sender, _maxSupply);
        isDev[msg.sender] = true;
        maxSupply = _maxSupply;
        initialSupply = _initialSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function utilDev(address _dev) external {
        require(isDev[msg.sender], "DOOF: NOT DEV.");
        isDev[_dev] = true;
    }

    function utilSupply(uint256 amount) external {
        require(isDev[msg.sender], "DOOF: NOT DEV.");
        _mint(msg.sender, amount);
    }
}