import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
!TELEGRAM: https://t.me/HypeEntryPortal
!TWITTER: @HypeTokenEth
!TWITTER-URL: https://twitter.com/hypetokeneth
*/
contract HypeToken is Ownable, ERC20 {
    bool public limited;
    bool public tradingStarted;
    uint256 public minHoldingAmount;
    uint256 constant SUPPLY = 133_700_000_000_000 ether;
    uint256 public maxHoldingAmount;
    address public UNISWAP_V2_PAIR;
    address public constant ORIGINAL_DEPLOYER = address(0xB5bd56A7fed2fC0B331d08bbBdF0A09b83A59e0C);
    
    mapping(address => bool) public blacklists;

    constructor() ERC20("Hype", "HYPE") {
        _mint(msg.sender, SUPPLY);
        //Jared From Subway
        blacklist(0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13,true);
        blacklist(0xAf2358e98683265cBd3a48509123d390dDf54534,true);
        blacklist(0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, true);
        blacklist(0x4D521577f820525964C392352bB220482F1Aa63b,true);
        //Each wallet can hold 2% of the total supply. This will be turned off later
        maxHoldingAmount = SUPPLY * 2 / 100;
    }



    function blacklist(address _address, bool _isBlacklisting) public onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited,bool _tradingStarted, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        tradingStarted = _tradingStarted;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        UNISWAP_V2_PAIR = _uniswapV2Pair;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        address _owner = owner();
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (!tradingStarted) {
            require(from == _owner || to == _owner, "trading is not started");
            return;
        }

        if (limited) {
            if(msg.sender != ORIGINAL_DEPLOYER ) {
                require(balanceOf(to) + amount <= maxHoldingAmount && balanceOf(to) + amount >= minHoldingAmount, "Forbid");
            }
        }

    }

    function setTradingStatus(bool _tradingStarted) external onlyOwner {
        tradingStarted = _tradingStarted;
    }


    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}