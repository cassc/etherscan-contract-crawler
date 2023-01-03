// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";

contract CryptoWorld is ERC20, ERC20Burnable, Ownable {
    uint256 public Max_Token;
    uint8 _decimals;

    address public constant ADVISOR_COMMITTEE =
        0xc6b1ca6de1E15b1dFAafD175463de78Ce9342A71;
    address public constant CWC_FOUNDATION_CHARITY =
        0x0151F4A36CeBd3b3591DBE8518Dc51669Ee084E7;
    address public constant EXCHANGE =
        0x008a2bc236F80db92e3DAf68a7d2B69cf6aE68f6;
    address public constant TEAM = 0x7C2069c6cD8F2C23BB25EFB14be4183f6ab60329;
    address public constant RESERVE =
        0xC014ac1Aa335EA372df69F3c6cEE46DcCaAEE9d1;
    address public constant COMMUNITY_MARKETING =
        0x63B2a17EEF217c7a08Edadab8f9C7DC4827677d5;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        _decimals = _decimal;
        uint256 decimalfactor = 10**uint256(_decimals);
        Max_Token = 5000000000 * decimalfactor;
        mint(ADVISOR_COMMITTEE, (500000000 * decimalfactor));
        mint(CWC_FOUNDATION_CHARITY, (500000000 * decimalfactor));
        mint(EXCHANGE, (1000000000 * decimalfactor));
        mint(TEAM, (500000000 * decimalfactor));
        mint(RESERVE, (500000000 * decimalfactor));
        mint(COMMUNITY_MARKETING, (500000000 * decimalfactor));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            Max_Token >= (totalSupply() + amount),
            "ERC20: Max Token limit exceeds"
        );
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}