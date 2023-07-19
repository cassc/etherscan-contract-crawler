// https://twitter.com/NextTokenERC20
// https://NextToken.vip
// https://t.me/NextTokenPortal



// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NextToken is ERC20, Ownable {
    uint256 _startTime;
    address pool;
    uint256 public constant startTotalSupply = 1e30;
    uint256 constant _maxWalletPerSecond =
        (startTotalSupply / 100 - _startMaxBuy) / 900;
    uint256 constant _startMaxBuy = startTotalSupply / 1000;

    constructor() ERC20("Next Token", "ERC20") {
        _mint(msg.sender, startTotalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function maxBuy(address acc) external view returns (uint256) {
        if (acc == pool || acc == owner() || pool == address(0))
            return startTotalSupply;
        uint256 value = _startMaxBuy +
            (block.timestamp - _startTime) *
            _maxWalletPerSecond;
        if (value > startTotalSupply) return startTotalSupply;
        return value;
    }

    function maxBuyWitouthDecimals(
        address acc
    ) external view returns (uint256) {
        return this.maxBuy(acc) / (10 ** decimals());
    }

    function maxWalletPerSecond() external pure returns (uint256) {
        return _maxWalletPerSecond;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            pool != address(0) || from == owner() || to == owner(),
            "trading is not started"
        );
        require(
            balanceOf(to) + amount <= this.maxBuy(to) ||
                to == owner() ||
                from == owner(),
            "max wallet limit"
        );

        uint256 burnCount = (amount * 5) / 1000;
        if (pool == address(0)) burnCount = 0;
        if (burnCount > 0) {
            _burn(from, burnCount);
            amount -= burnCount;
        }

        super._transfer(from, to, amount);
    }

    function start(address poolAddress) external onlyOwner {
        _startTime = block.timestamp;
        pool = poolAddress;
    }
}