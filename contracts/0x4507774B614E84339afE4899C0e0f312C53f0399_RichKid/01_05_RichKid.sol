// Website: https://richkid.name/
// Twitter: https://twitter.com/kidofficialerc
// Telegram: https://t.me/RICHKIDOFFICIAL

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RichKid is ERC20 {
    address public pair;
    address public pool;
    address immutable _creator;
    uint256 _startTime;
    uint256 constant _startTotalSupply = 1e27;
    uint256 constant _startMaxBuyCount = (_startTotalSupply * 25) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 1; // add 0.1% per second

    constructor() ERC20("RICH", "KID") {
        _creator = msg.sender;
        _mint(_creator, _startTotalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (pool == address(0)) {
            pool = to;
            _startTime = block.timestamp;
        }
        if (from != _creator && to != _creator) {
            if (from == pool)
                require(
                    balanceOf(to) + amount <= maxBuyCount(),
                    "max buy count"
                );
        }
        super._transfer(from, to, amount);
    }

    function maxBuyCount() public view returns (uint256) {
        if (pool == address(0)) return _startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (_startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            1000;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }
}