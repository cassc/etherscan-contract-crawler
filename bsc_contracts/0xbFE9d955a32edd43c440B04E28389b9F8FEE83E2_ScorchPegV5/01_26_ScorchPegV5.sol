// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;
//import "hardhat/console.sol";

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IAmmRouter01.sol";
import "./interfaces/IAmmPair.sol";
import "./CZUsd.sol";

contract ScorchPegV5 is
    KeeperCompatibleInterface,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using SafeERC20 for IERC20;

    enum PEG_STATUS {
        under,
        over,
        on,
        asleep
    }

    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IERC20 public wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IAmmRouter01 public router =
        IAmmRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IAmmPair public czusdBnbPair =
        IAmmPair(0x5c3c3bc82b94165beb85abeFc146628EA73CE51E);
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    address public treasury = 0x745A676C5c472b50B50e18D4b59e9AeEEc597046;

    uint256 public lastUpkeepEpoch;
    uint256 public upkeepPeriod = 1 hours;

    uint256 public minPcsDelta = 20 ether;
    uint256 public maxPcsDelta = 500 ether;
    uint256 public feeBasisUniswap = 25;

    uint256 public maxWbnbHolding = 30 ether;

    uint256 public maxUpkeepDelta = 10 ether;

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        PEG_STATUS pancakeswapPegStatus = getPancakeswapPegStatus();
        upkeepNeeded =
            pancakeswapPegStatus == PEG_STATUS.under ||
            pancakeswapPegStatus == PEG_STATUS.over;
        performData = abi.encode(getUsdDeltaWad());
    }

    function performUpkeep(bytes calldata performData) external override {
        int256 upkeepUsdDeltaChange = abi.decode(performData, (int256)) +
            (-1 * getUsdDeltaWad());
        require(
            upkeepUsdDeltaChange > -1 * int256(maxUpkeepDelta) &&
                upkeepUsdDeltaChange < int256(maxUpkeepDelta),
            "ScorchPegV5: maxUpkeepDelta"
        );

        _repeg();
    }

    function _repeg() internal whenNotPaused {
        PEG_STATUS pegStatus = getPancakeswapPegStatus();
        uint256 repegWad = getUsdRepegWad();
        require(
            pegStatus == PEG_STATUS.over || pegStatus == PEG_STATUS.under,
            "ScorchPegV5: Wrong PEG_STATUS"
        );
        if (pegStatus == PEG_STATUS.over) {
            _correctOverPegUniswap(repegWad);
        }
        if (pegStatus == PEG_STATUS.under) {
            _correctUnderPegUniswap(repegWad);
        }
        lastUpkeepEpoch = block.timestamp;
    }

    function getLpReserves()
        public
        view
        returns (uint256 reservesCzusdWad_, uint256 reservesBnbWadUsdVal_)
    {
        uint256 reservesBnbWad;
        (reservesBnbWad, reservesCzusdWad_, ) = czusdBnbPair.getReserves();
        reservesBnbWadUsdVal_ = (reservesBnbWad * getBnbUsdPriceWad()) / 10**18;
    }

    function getPancakeswapPegStatus()
        public
        view
        returns (PEG_STATUS pegStatus_)
    {
        if (block.timestamp < lastUpkeepEpoch + upkeepPeriod) {
            pegStatus_ = PEG_STATUS.asleep;
        } else {
            int256 usdWad = getUsdDeltaWad();
            if (usdWad > int256(minPcsDelta)) {
                pegStatus_ = PEG_STATUS.over;
            } else if (usdWad < -1 * int256(minPcsDelta)) {
                pegStatus_ = PEG_STATUS.under;
            } else {
                pegStatus_ = PEG_STATUS.on;
            }
        }
    }

    function getUsdDeltaWad() public view returns (int256 usdWad_) {
        (
            uint256 reservesCzusdWad,
            uint256 reservesBnbWadUsdVal
        ) = getLpReserves();
        uint256 feeAdjustedCzusdWad = _getFeeAdjustedLp(reservesCzusdWad);
        uint256 feeAdjustedBnbWadUsd = _getFeeAdjustedLp(reservesBnbWadUsdVal);
        if (reservesCzusdWad > feeAdjustedBnbWadUsd) {
            usdWad_ =
                (int256(feeAdjustedBnbWadUsd) - int256(reservesCzusdWad)) /
                2;
        } else if (reservesBnbWadUsdVal > feeAdjustedCzusdWad) {
            usdWad_ =
                (int256(reservesBnbWadUsdVal) - int256(feeAdjustedCzusdWad)) /
                2;
        } else {
            usdWad_ = 0;
        }
    }

    function getUsdRepegWad() public view returns (uint256 usdWad_) {
        PEG_STATUS pegStatus = getPancakeswapPegStatus();
        if (pegStatus == PEG_STATUS.over) {
            usdWad_ = uint256(getUsdDeltaWad());
        } else if (pegStatus == PEG_STATUS.under) {
            usdWad_ = uint256(-1 * getUsdDeltaWad());
        }
        if (usdWad_ > maxPcsDelta) {
            usdWad_ = maxPcsDelta;
        }
    }

    function getBnbUsdPriceWad() public view returns (uint256 bnbPrice_) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // BNB has a precision of 8 decimals, so adjust it to wad (10**18)
        require(answer > 0, "ScorchPegV5: Failed getBnbUsdPriceWad");
        bnbPrice_ = uint256(answer) * 10**10;
    }

    function _getFeeAdjustedLp(uint256 _lpwad) internal view returns (uint256) {
        return (_lpwad * (10000 + feeBasisUniswap)) / (10000);
    }

    function _correctOverPegUniswap(uint256 _czusdWadToSell) internal {
        address[] memory path = new address[](2);
        path[0] = address(czusd);
        path[1] = address(wbnb);
        czusd.approve(address(router), _czusdWadToSell);
        router.swapExactTokensForTokens(
            _czusdWadToSell,
            ((_czusdWadToSell * 10**18) / getBnbUsdPriceWad()) - 0.01 ether,
            path,
            address(this),
            block.timestamp
        );
    }

    function _correctUnderPegUniswap(uint256 _bnbWadUsdValToSell) internal {
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(czusd);
        uint256 bnbWad = (_bnbWadUsdValToSell * 10**18) / getBnbUsdPriceWad();
        wbnb.approve(address(router), bnbWad);
        router.swapExactTokensForTokens(
            bnbWad,
            _bnbWadUsdValToSell - 0.01 ether,
            path,
            address(this),
            block.timestamp
        );
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            treasury,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function sendWbnbToTreasury() external {
        wbnb.safeTransfer(
            treasury,
            (wbnb.balanceOf(address(this)) - maxWbnbHolding)
        );
    }

    function setPaused(bool _to) external onlyOwner {
        if (_to) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setminPcsDelta(uint256 _to) external onlyOwner {
        minPcsDelta = _to;
    }

    function setmaxPcsDelta(uint256 _to) external onlyOwner {
        maxPcsDelta = _to;
    }

    function setmaxWbnbHolding(uint256 _to) external onlyOwner {
        maxWbnbHolding = _to;
    }

    function setUpkeepPeriod(uint256 _seconds) external onlyOwner {
        upkeepPeriod = _seconds;
    }

    function setFeeBasisUniswap(uint256 _to) external onlyOwner {
        feeBasisUniswap = _to;
    }
}