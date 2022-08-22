//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVenus.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IOracle.sol";
import "../refs/CoreRef.sol";

contract StrategyVenus is IStrategyVenus, ReentrancyGuard, Ownable, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public override lastEarnBlock;

    address public override wantAddress;
    address public override vTokenAddress;
    address[] public override markets;
    address public override uniRouterAddress;

    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public override earnedAddress;
    address public override distributionAddress;

    address[] public override earnedToWantPath;

    uint256 public override borrowRate;

    bool public override isComp;

    address public oracle;
    uint256 internal swapSlippage;

    constructor(
        address _core,
        address _wantAddress,
        address _vTokenAddress,
        address _uniRouterAddress,
        address _earnedAddress,
        address _distributionAddress,
        address[] memory _earnedToWantPath,
        bool _isComp,
        address _oracle,
        uint256 _swapSlippage
    ) public CoreRef(_core) {
        borrowRate = 585;
        wantAddress = _wantAddress;

        earnedToWantPath = _earnedToWantPath;

        earnedAddress = _earnedAddress;
        distributionAddress = _distributionAddress;
        vTokenAddress = _vTokenAddress;
        markets = [vTokenAddress];
        uniRouterAddress = _uniRouterAddress;

        isComp = _isComp;

        oracle = _oracle;
        swapSlippage = _swapSlippage;

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));

        IVenusDistribution(distributionAddress).enterMarkets(markets);
    }

    function _supply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).mint(_amount) == 0, "mint Err");
    }

    function _removeSupply(uint256 _amount) internal {
        require(IVToken(vTokenAddress).redeemUnderlying(_amount) == 0, "redeemUnderlying Err");
    }

    function _borrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).borrow(_amount) == 0, "borrow Err");
    }

    function _repayBorrow(uint256 _amount) internal {
        require(IVToken(vTokenAddress).repayBorrow(_amount) == 0, "repayBorrow Err");
    }

    function deposit(uint256 _wantAmt) public override nonReentrant whenNotPaused {
        (uint256 sup, uint256 brw, ) = updateBalance();

        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        _supply(wantLockedInHere());
    }

    function leverage(uint256 _amount) public override onlyTimelock {
        _leverage(_amount);
    }

    function _leverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, ) = updateBalance();

        require(brw.add(_amount).mul(1000).div(borrowRate) <= sup, "ltv too high");
        _borrow(_amount);
        _supply(wantLockedInHere());
    }

    function deleverage(uint256 _amount) public override onlyTimelock {
        _deleverage(_amount);
    }

    function deleverageAll(uint256 redeemFeeAmt) public override onlyTimelock {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        require(brw.add(redeemFeeAmt) <= sup.sub(supMin), "amount too big");
        _removeSupply(brw.add(redeemFeeAmt));
        _repayBorrow(brw);
        _supply(wantLockedInHere());
    }

    function _deleverage(uint256 _amount) internal {
        updateStrategy();
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();

        require(_amount <= sup.sub(supMin), "amount too big");
        require(_amount <= brw, "amount too big");

        _removeSupply(_amount);
        _repayBorrow(wantLockedInHere());
    }

    function setBorrowRate(uint256 _borrowRate) public override onlyTimelock {
        updateStrategy();
        borrowRate = _borrowRate;
        (uint256 sup, , uint256 supMin) = updateBalance();
        require(sup >= supMin, "supply should be greater than supply min");
    }

    function earn() public override whenNotPaused onlyTimelock {
        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }
        uint256 minReturnWant;

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        earnedAmt = wantLockedInHere();
        if (earnedAmt != 0) {
            _supply(earnedAmt);
        }

        lastEarnBlock = block.number;
    }

    function withdraw() public override onlyMultistrategy nonReentrant {
        _withdraw();

        if (isComp) {
            IVenusDistribution(distributionAddress).claimComp(address(this));
        } else {
            IVenusDistribution(distributionAddress).claimVenus(address(this));
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAddress != wantAddress && earnedAmt != 0) {
            uint256 minReturnWant = _calculateMinReturn(earnedAmt);
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokens(
                earnedAmt,
                minReturnWant,
                earnedToWantPath,
                address(this),
                now.add(600)
            );
        }

        uint256 wantBal = wantLockedInHere();
        IERC20(wantAddress).safeTransfer(msg.sender, wantBal);
    }

    function _withdraw() internal {
        (uint256 sup, uint256 brw, uint256 supMin) = updateBalance();
        uint256 _wantAmt = sup.sub(brw);
        uint256 delevAmtAvail = sup.sub(supMin);
        while (_wantAmt > delevAmtAvail) {
            if (delevAmtAvail > brw) {
                _deleverage(brw);
                (sup, brw, supMin) = updateBalance();
                delevAmtAvail = sup.sub(supMin);
                break;
            } else {
                _deleverage(delevAmtAvail);
            }
            (sup, brw, supMin) = updateBalance();
            delevAmtAvail = sup.sub(supMin);
        }

        if (_wantAmt > delevAmtAvail) {
            _wantAmt = delevAmtAvail;
        }

        _removeSupply(_wantAmt);
    }

    function _pause() internal override {
        super._pause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(uniRouterAddress, 0);
        IERC20(wantAddress).safeApprove(vTokenAddress, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(uniRouterAddress, uint256(-1));
        IERC20(wantAddress).safeApprove(vTokenAddress, uint256(-1));
    }

    function calculateMinReturn(uint256 _amount) external view returns (uint256 minReturn) {
        minReturn = _calculateMinReturn(_amount);
    }

    function _calculateMinReturn(uint256 amount) internal view returns (uint256 minReturn) {
        uint256 oraclePrice = IOracle(oracle).getLatestPrice(earnedAddress);
        uint256 total = amount.mul(oraclePrice).div(1e18);
        minReturn = total.mul(100 - swapSlippage).div(100);
    }

    function setSlippage(uint256 _swapSlippage) public onlyGovernor {
        require(_swapSlippage < 10, "Slippage value is too big");
        swapSlippage = _swapSlippage;
    }

    function setOracle(address _oracle) public onlyGovernor {
        oracle = _oracle;
    }

    function updateBalance()
        public
        view
        override
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        )
    {
        (uint256 errCode, uint256 _sup, uint256 _brw, uint256 exchangeRate) = IVToken(vTokenAddress).getAccountSnapshot(
            address(this)
        );
        require(errCode == 0, "Venus ErrCode");
        sup = _sup.mul(exchangeRate).div(1e18);
        brw = _brw;
        supMin = brw.mul(1000).div(borrowRate);
    }

    function wantLockedTotal() public view returns (uint256) {
        (uint256 sup, uint256 brw, ) = updateBalance();
        return wantLockedInHere().add(sup).sub(brw);
    }

    function wantLockedInHere() public view override returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public override onlyTimelock {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        require(_token != vTokenAddress, "!safe");

        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() public override {
        require(IVToken(vTokenAddress).accrueInterest() == 0);
    }
}