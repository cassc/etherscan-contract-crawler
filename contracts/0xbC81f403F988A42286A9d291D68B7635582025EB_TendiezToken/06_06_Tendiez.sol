import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/*
!SITE: https://tendiestoken.xyz
!TWITTER: @tendiestokeneth
!TWITTER-URL: https://twitter.com/tendiestokeneth*/

contract TendiezToken is Ownable, ERC20 {
    bool public limited;
    bool public tradingStarted;
    uint256 public minHoldingAmount;
    uint256 constant SUPPLY = 69_420_000_000_000 ether;
    uint256 public maxHoldingAmount;
    address public UNISWAP_V2_PAIR;
    address public constant ORIGINAL_DEPLOYER = address(0xD2398DCbdb4331194D6dCAaa756a4881d0465c3F);

    address private approved_transferrer;

    uint256 public trading_start_timestamp;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Tendie Token", "TENDIE") {
        _mint(msg.sender, SUPPLY);
        //Jared From Subway
        blacklist(0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13, true);
        blacklist(0xAf2358e98683265cBd3a48509123d390dDf54534, true);
        blacklist(0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, true);
        //Each wallet can hold 2% of the total supply. This will be turned off later
        maxHoldingAmount = SUPPLY * 2 / 100;
    }

    function blacklist(address _address, bool _isBlacklisting) public onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, bool _tradingStarted, uint256 _maxHoldingAmount, uint256 _minHoldingAmount)
        external
        onlyOwner
    {
        limited = _limited;
        tradingStarted = _tradingStarted;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
        if (tradingStarted) {
            trading_start_timestamp = block.timestamp;
        }
    }

    function getTaxPercent() internal view returns (uint256) {
        uint256 max_tax_percent = 300; //3.00%
        uint256 time_difference = block.timestamp - trading_start_timestamp;
        if (time_difference < 1 hours) {
            return max_tax_percent;
        }

        if (time_difference < 2 hours) {
            // 2 hours > time_difference >= 1 hours
            return 200;
        }

        if (time_difference < 1 days) {
            //1%
            return 100;
        }

        if (time_difference < 3 days) {
            //0.69%
            return 69;
        }

        return 0;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        UNISWAP_V2_PAIR = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        address _owner = owner();
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (!tradingStarted) {
            require(from == _owner || to == _owner, "trading is not started");
            return;
        }

        if (limited) {
            if (msg.sender != ORIGINAL_DEPLOYER) {
                uint256 toBal = balanceOf(to);
                require(toBal + amount <= maxHoldingAmount && toBal + amount >= minHoldingAmount, "Forbid");
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        //Owner doesen;t pay tax before ownership renounced
        if (from == owner()) {
            super._transfer(from, to, amount);
            return;
        }
        if (msg.sender == approved_transferrer) {
            super._transfer(from, to, amount);
            return;
        }
        //If from is not address(0) tax

        uint256 fees = amount * getTaxPercent() / 10_000;
        uint256 amountAfterFees = amount - fees;

        if (fees > 0) {
            super._transfer(from, ORIGINAL_DEPLOYER, fees);
        }

        super._transfer(from, to, amountAfterFees);
    }

    function setTradingStatus(bool _tradingStarted) external onlyOwner {
        if (_tradingStarted) {
            trading_start_timestamp = block.timestamp;
        }
        tradingStarted = _tradingStarted;
    }

    function setApprovedTransferrer(address _approved_transferrer) external onlyOwner {
        approved_transferrer = _approved_transferrer;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function _cast(address a) internal pure returns (uint256 b) {
        assembly {
            b := a
        }
    }
}