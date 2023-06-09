// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract pepegod is Ownable, ERC20 {
    using SafeMath for uint256;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    mapping(address => bool) public blacklists;
    address public uniswapV2Pair;


    constructor() ERC20("PepeGod", "PepeGod") {
        uint256 _totalSupplyss = 8900000000000000 * 10 ** 18;
        _mint(msg.sender, _totalSupplyss);

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        limited = true;
        maxHoldingAmount = _totalSupplyss.mul(2).div(100);
        minHoldingAmount = 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(blacklists[from] != true && blacklists[to] != true, "Blacklisted address");

        if (to == owner() || from == owner()) { return; }

        if(limited && from == uniswapV2Pair) {
            require(balanceOf(to) + amount <= maxHoldingAmount && balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }



    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function settblacklist(address[] memory accounts, bool _isBlacklisting) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklists[accounts[i]] = _isBlacklisting;
        }
    }


    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) external {
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

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) external {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount.mul(addresses.length);
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }
}