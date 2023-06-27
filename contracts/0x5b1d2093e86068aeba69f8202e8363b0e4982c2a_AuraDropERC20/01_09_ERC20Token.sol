// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//   ______                                      ________                      __
//  /      \                                    /        |                    /  |
// /$$$$$$  | __    __   ______   ______        $$$$$$$$/  __    __   _______ $$ |____    ______   _______    ______    ______
// $$ |__$$ |/  |  /  | /      \ /      \       $$ |__    /  \  /  | /       |$$      \  /      \ /       \  /      \  /      \
// $$    $$ |$$ |  $$ |/$$$$$$  |$$$$$$  |      $$    |   $$  \/$$/ /$$$$$$$/ $$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$  |
// $$$$$$$$ |$$ |  $$ |$$ |  $$/ /    $$ |      $$$$$/     $$  $$<  $$ |      $$ |  $$ | /    $$ |$$ |  $$ |$$ |  $$ |$$    $$ |
// $$ |  $$ |$$ \__$$ |$$ |     /$$$$$$$ |      $$ |_____  /$$$$  \ $$ \_____ $$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \__$$ |$$$$$$$$/
// $$ |  $$ |$$    $$/ $$ |     $$    $$ |      $$       |/$$/ $$  |$$       |$$ |  $$ |$$    $$ |$$ |  $$ |$$    $$ |$$       |
// $$/   $$/  $$$$$$/  $$/       $$$$$$$/       $$$$$$$$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$ | $$$$$$$/
//                                                                                                          /  \__$$ |
//                                                                                                          $$    $$/
//                                                                                                           $$$$$$/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract AuraDropERC20 is Ownable, ERC20 {

    using StringsUpgradeable for uint256;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor(
        uint256 _totalSupply, 
        string memory _name, 
        string memory _symbol
        ) ERC20(
            _name,
            _symbol
        ) {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}