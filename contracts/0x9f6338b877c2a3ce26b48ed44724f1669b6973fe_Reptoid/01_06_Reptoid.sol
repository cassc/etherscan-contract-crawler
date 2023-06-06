// https://vonnithepooh.xyz

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Reptoid is ERC20, Ownable {
    address public pool;
    uint256 _startTime;
    uint256 constant _startTotalSupply = 666999666999777e18;
    uint256 constant _startMaxWallet = _startTotalSupply / 1000;
    uint256 constant _addMaxWalletPerSec =
        (_startTotalSupply - _startMaxWallet) / 138000;

    constructor() ERC20("Reptoid", "TOID") {
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
            balanceOf(to) + amount <= this.maxWallet(to),
            "max wallet limit"
        );
        super._transfer(from, to, amount);
    }
}