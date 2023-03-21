import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Icy is ERC20, Ownable {
    uint256 constant maxWalletStart = 5e16;
    uint256 constant addMaxWalletPerMinute = 85e16;
    uint256 public constant totalSupplyOnStart = 1e20;
    uint256 tradingStartTime;
    address public pool;

    constructor() ERC20("Icy", "IC") {
        _mint(msg.sender, totalSupplyOnStart);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function maxWallet() public view returns (uint256) {
        if (tradingStartTime == 0) return totalSupply();
        uint256 res = maxWalletStart +
            ((block.timestamp - tradingStartTime) * addMaxWalletPerMinute) /
            (1 minutes);
        if (res > totalSupply()) return totalSupply();
        return res;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // before start trading only owner can manipulate the token
        if (pool == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        // check max wallet
        if (to != pool)
            require(balanceOf(to) + amount <= maxWallet(), "wallet maximum");
    }

    function startTrade(address poolAddress) public onlyOwner {
        tradingStartTime = block.timestamp;
        pool = poolAddress;
    }
}