// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PercentageMath} from "../libs/PercentageMath.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

contract FeeCollector is IFeeCollector, Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using PercentageMath for uint256;
    IWETH public WETH;
    uint256 public treasuryPercentage;
    address public treasury;
    address public bendCollector;

    function initialize(
        IWETH _weth,
        address _treasury,
        address _bendCollector
    ) external initializer {
        __Ownable_init();
        WETH = _weth;
        treasury = _treasury;
        bendCollector = _bendCollector;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "FeeCollector: treasury can't be null"
        );
        treasury = _treasury;
    }

    function setBendCollector(address _bendCollector) external onlyOwner {
        require(
            _bendCollector != address(0),
            "FeeCollector: bendCollector can't be null"
        );
        bendCollector = _bendCollector;
    }

    function setTreasuryPercentage(uint256 _treasuryPercentage)
        external
        onlyOwner
    {
        require(
            _treasuryPercentage <= PercentageMath.PERCENTAGE_FACTOR,
            "FeeCollector: treasury percentage overflow"
        );
        treasuryPercentage = _treasuryPercentage;
    }

    function collect() external override {
        require(
            bendCollector != address(0),
            "FeeCollector: bendCollector can't be null"
        );
        require(treasury != address(0), "FeeCollector: treasury can't be null");

        uint256 _toDistribute = WETH.balanceOf(address(this));
        uint256 _toTreasury = _toDistribute.percentMul(treasuryPercentage);

        if (_toTreasury > 0) {
            IERC20Upgradeable(address(WETH)).safeTransfer(
                treasury,
                _toTreasury
            );
        }
        uint256 _toBendCollector = _toDistribute - _toTreasury;
        if (_toBendCollector > 0) {
            IERC20Upgradeable(address(WETH)).safeTransfer(
                bendCollector,
                _toBendCollector
            );
        }
    }
}