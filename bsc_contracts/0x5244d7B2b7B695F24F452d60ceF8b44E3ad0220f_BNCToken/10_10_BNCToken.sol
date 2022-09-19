// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../Wrap.sol";

contract BNCToken is ERC20, Ownable {
    address private constant address1 = 0x5CF7cF1aa87Bdc9D09C0e3160352f9F34C97BDd4;
    address private constant address2 = 0x12D2F94bEfF892D6938a8dc092568EDFF0ae5D86;
    address private constant address3 = 0x8Ed94aa1b8d1087B211C22f2ca5AC7c48B0a2D14;
    address private constant address4 = 0xAEe40be9e032e6B89A33386373Af5fB2C6C39963;
    uint256 private constant rate1 = 300;
    uint256 private constant rate2 = 100;
    uint256 private constant rate3 = 200;
    uint256 private constant rate4 = 200;

    IERC20 public immutable bth;
    Wrap public immutable wrap;
    IUniswapV2Router02 public immutable router;
    address public immutable pair0;
    address public immutable pair1;

    mapping(address => bool) private vips;

    constructor(
        address _router,
        address _bth,
        address _usdt,
        address _recipient
    ) ERC20("BNC ptotocol", "BNC") {
        _mint(_recipient, 42000 * 1e18);

        bth = IERC20(_bth);
        wrap = new Wrap(_bth);
        router = IUniswapV2Router02(_router);
        pair0 = IUniswapV2Factory(router.factory()).createPair(address(this), _bth);
        pair1 = IUniswapV2Factory(router.factory()).createPair(address(this), _usdt);

        vips[address(this)] = true;
        vips[address4] = true;
        vips[_recipient] = true;
        vips[0xf52d87bBF8191E3A3E5f970ff55593cf170c5FbC] = true;
    }

    function setVip(address vip, bool state) external onlyOwner {
        vips[vip] = state;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (vips[from] == true || vips[to] == true) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 balance = balanceOf(from);
        if (balance - amount < 1e15) {
            amount = balance - 1e15;
        }

        if (from != pair0 && from != pair1 && to != pair0 && to != pair1) {
            super._transfer(from, address4, (amount * rate4) / 10000);
            super._transfer(from, to, (amount * (10000 - rate4)) / 10000);
            return;
        }

        if (to == pair0 || to == pair1) {
            uint256 reserve = balanceOf(address(this));
            if (reserve >= 4e18) {
                _distributor(reserve);
            }
        }

        super._transfer(from, address(this), (amount * (rate1 + rate2)) / 10000);
        super._transfer(from, address3, (amount * rate3) / 10000);
        super._transfer(from, to, (amount * (10000 - rate1 - rate2 - rate3)) / 10000);
    }

    function _distributor(uint256 reserve) internal {
        if (allowance(address(this), address(router)) < reserve) {
            _approve(address(this), address(router), type(uint256).max);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(bth);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(reserve, 0, path, address(wrap), block.timestamp);

        wrap.withdraw();
        uint256 amount = bth.balanceOf(address(this)) - 1e15;
        if (amount >= 4e15) {
            bth.transfer(address1, (amount * rate1) / (rate1 + rate2));
            bth.transfer(address2, (amount * rate2) / (rate1 + rate2));
        }
    }
}