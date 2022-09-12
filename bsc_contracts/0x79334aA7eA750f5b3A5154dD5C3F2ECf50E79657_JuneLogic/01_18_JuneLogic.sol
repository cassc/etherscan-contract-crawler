pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "./Manager.sol";

contract JuneLogic is OwnableUpgradeable, ERC20Upgradeable, Manager {
    using SafeMathUpgradeable for uint256;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint8 private _decimals;
    address private leftToken;
    address private rightToken;
    uint256 private PERCENTS_DIVIDER;

    uint256 private ratio;
    //marketing wallet
    address public MarketingWalletAddr;
    uint256 public WithdrawBurnFee;//%
    uint256 public DayMintAmount;//days mint
    uint256 public DayBurnAmount;//days burn
    address public WithdrawalAddr;
    address public MintAddr;
    bool public PairPaused;//is pair paused
    uint256 public sellMarketingRates;//sell:amount + (sellMarketingRates / 100 + amount)
    uint256 public buyMarketingRates;//buy:amount - (buyMarketingRates / 100 + amount)
    address public LiquidityAddr;//Liquidity wallet address
    uint256 public DividendMin;
    EnumerableMapUpgradeable.AddressToUintMap private DividendAdds;
    address  public SlippageAddr;
    uint256 public SlippageEachRate;

    event ev_PairPaused(bool paused);
    event ev_LiquidityAddr(address value);

    function initialize(address _fromTo, string memory _name, string memory _symbol, uint8 __decimals, uint256 initialSupply, address _MarketingWalletAddr, uint256 _DayMintAmount, uint256 _DayBurnAmount, uint256 _WithdrawBurnFee, address _WithdrawalAddr, address _MintAddr) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init(_name, _symbol);
        PERCENTS_DIVIDER = 10 ** 2;
        ratio = 10 ** 2;
        _decimals = __decimals;
        MarketingWalletAddr = _MarketingWalletAddr;
        WithdrawalAddr = _WithdrawalAddr;
        MintAddr = _MintAddr;
        DayMintAmount = _DayMintAmount * (10 ** uint(__decimals));
        DayBurnAmount = _DayBurnAmount * (10 ** uint(__decimals));
        WithdrawBurnFee = _WithdrawBurnFee;
        _mint(_fromTo, initialSupply * (10 ** uint(__decimals)));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function drawBalanceLocal(address _to, uint256 amount) public onlyDraw {
        uint256 tokenBalance = balanceOf(address(this));
        require(
            tokenBalance >= amount,
            "this Balance <= actionAount"
        );
        _transfer(address(this), _to, amount);
    }

    function setMarketingWallet(address _marketing) public onlyManager {
        MarketingWalletAddr = _marketing;
    }

    function Breed(address token, address _to, uint256 amount) public onlyManager {
        IERC20Upgradeable _token = IERC20Upgradeable(token);
        require(
            _token.balanceOf(address(this)) >= amount,
            "token Balance <= actionAount"
        );
        _token.transfer(_to, amount);
    }

    function setWithdrawalWallet(address addr) public onlyManager {
        WithdrawalAddr = addr;
    }

    function setMintWallet(address addr) public onlyManager {
        MintAddr = addr;
    }

    function setWithdrawBurnFee(uint256 _rate) public onlyWithdraw {
        WithdrawBurnFee = _rate;
    }

    function setDayMintAmount(uint256 _mintAmount) public onlyMint {
        DayMintAmount = _mintAmount;
    }

    function setDayBurnAmount(uint256 _burnAmount) public onlyBurn {
        DayBurnAmount = _burnAmount;
    }

    function setSlippageEachRate(uint256 value) public onlyManager {
        SlippageEachRate = value;
    }

    function setPairPaused(bool pause) public onlyManager {
        PairPaused = pause;
        emit ev_PairPaused(pause);
    }

    function setLiquidityAddr(address value) public onlyManager {
        LiquidityAddr = value;
        emit ev_LiquidityAddr(value);
    }

    function setSlippageAddr(address value) public onlyManager {
        SlippageAddr = value;
    }

    function setSellMarketingRates(uint256 value) public onlyManager {
        sellMarketingRates = value;
    }

    function setBuyMarketingRates(uint256 value) public onlyManager {
        buyMarketingRates = value;
    }

    function setDividendMin(uint256 value) public onlyManager {
        DividendMin = value;
    }

    function setDividendAdds(address[] memory value, bool _is) public onlyManager {
        for (uint i = 0; i < value.length; i++) {
            (bool isSave,uint256 _tmp) = EnumerableMapUpgradeable.tryGet(DividendAdds, value[i]);
            if (_is) {
                if (!isSave) {
                    EnumerableMapUpgradeable.set(DividendAdds, value[i], 0);
                }
            } else {
                if (isSave) {
                    EnumerableMapUpgradeable.remove(DividendAdds, value[i]);
                }
            }
        }
    }

    function IsDividend(address value) public view virtual returns (bool) {
        (bool isSave,uint256 _tmp) = EnumerableMapUpgradeable.tryGet(DividendAdds, value);
        return isSave;
    }

    function mintTo() public onlyMint {
        require(DayMintAmount > 0, "DayMintAmount<=0");
        require(MintAddr != address(0), "MintAddr address(0)");
        _mint(MintAddr, DayMintAmount);
    }

    function burnTo() public onlyBurn {
        require(DayBurnAmount > 0, "DayBurnAmount<=0");
        require(MintAddr != address(0), "MintAddr address(0)");
        _burn(MintAddr, DayBurnAmount);
    }

    function withdraw(address _to, uint256 _amount, uint256 _fee) public onlyWithdraw {
        require(
            balanceOf(WithdrawalAddr) >= _amount,
            "WithdrawalAddr<=actionAmount"
        );
        uint256 feeAmount = _fee.mul(WithdrawBurnFee).div(100);
        uint256 feeAmountMarket = _fee.sub(feeAmount);
        _burn(WithdrawalAddr, feeAmount);
        _transfer(WithdrawalAddr, MarketingWalletAddr, feeAmountMarket);
        _transfer(WithdrawalAddr, _to, _amount);
    }

    function Dividend() public onlyManager {
        IERC20Upgradeable LiquidityWallet = IERC20Upgradeable(LiquidityAddr);
        //realTime calc lp
        uint256 LpTotal = 0;
        for (uint i = 0; i < EnumerableMapUpgradeable.length(DividendAdds); i++) {
            (address _addr,uint256 _addrAm) = EnumerableMapUpgradeable.at(DividendAdds, i);
            LpTotal += LiquidityWallet.balanceOf(_addr);
        }
        uint256 DividendNum = balanceOf(SlippageAddr).mul(uint256(10) ** 28).div(LpTotal);
        for (uint i = 0; i < EnumerableMapUpgradeable.length(DividendAdds); i++) {
            (address _addr,uint256 _addrAm) = EnumerableMapUpgradeable.at(DividendAdds, i);
            uint256 userBalance = LiquidityWallet.balanceOf(_addr);
            uint256 userDividend = DividendNum.mul(userBalance).div(uint256(10) ** 28);
            //            uint256 currAmount = userDividend.mul(SlippageEachRate).div(PERCENTS_DIVIDER);
            uint256 currAmount = MathUpgradeable.mulDiv(userDividend, SlippageEachRate, PERCENTS_DIVIDER);
            if (currAmount > 0 && userBalance >= DividendMin && _addr != address(0)) {
                super._transfer(SlippageAddr, _addr, currAmount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 newAmount;
        uint256 marketingAmount;
        bool isBuy = LiquidityAddr == from;
        bool isSell = LiquidityAddr == to;
        if (isBuy) {
            require(!PairPaused, "pair: pair paused");
            marketingAmount = amount.mul(buyMarketingRates).div(100);
            newAmount = amount.sub(marketingAmount);
        } else if (isSell) {
            marketingAmount = amount.mul(sellMarketingRates).div(100);
            newAmount = amount.sub(marketingAmount);
            super._transfer(from, SlippageAddr, marketingAmount);
        } else {
            newAmount = amount;
        }
        super._transfer(from, to, newAmount);
    }
}