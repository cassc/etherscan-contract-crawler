// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract VIND is ERC20,Ownable {
    IRouter public router;
    address public uniswapV2Pair;
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    mapping(address => bool) public blacklists;
    mapping(address => bool) public excludeLimited;


    constructor() ERC20("Vin Diesel", "VIND") {
        _mint(msg.sender, 100000000000 * 10**18);

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        uniswapV2Pair = _pair;
        limited = true;
        maxHoldingAmount = 100000000 * 10**18;
        minHoldingAmount = 0;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10**18);
    }

    function _beforeTokenTransfer(address from,address to,uint256 amount) internal override virtual {
        if (blacklists[from] || blacklists[to]) {
            revert("Blacklisted address");
        }

        if (to == owner() || from == owner()) {
            return;
        }

        if (limited && from == uniswapV2Pair && !excludeLimited[to]) {
            require(balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function setLimited(bool _limited, uint256 _max, uint256 min) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _max;
        minHoldingAmount = min;
    }

    function setExcludeLimited(address _address, bool _excludeLimited) external onlyOwner {
        excludeLimited[_address] = _excludeLimited;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function settblacklist(address[] memory accounts, bool _isBlacklisting) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklists[accounts[i]] = _isBlacklisting;
        }
    }

    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) public {
        require(addresses.length < 801, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length, "Mismatch between Address and token count");

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum + amounts[i];
        }

        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) public {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount * addresses.length;
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }
}