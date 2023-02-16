// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IUniswapV2Router.sol";

contract ChampionOptimizerLpFeeBatchV1 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public wNative;
    address public chamStaker;
    address public dfTreasury;
    address public coTreasury;

    // Fee constants
    uint public constant MAX_FEE = 1000;
    uint public chamStakerFee;
    uint public dfTreasuryFee;
    uint public coTreasuryFee;

    event NewChamStaker(address oldValue, address newValue);
    event NewDfTreasury(address oldValue, address newValue);
    event NewCoTreasury(address oldValue, address newValue);

    function initialize(
        address _wNative,
        address _chamStaker,
        address _dfTreasury,
        address _coTreasury,
        uint256 _chamStakerFee,
        uint256 _coTreasuryFee
    ) public initializer {
        __Ownable_init();
        wNative = IERC20Upgradeable(_wNative);

        chamStaker = _chamStaker;
        dfTreasury = _dfTreasury;
        coTreasury = _coTreasury;

        chamStakerFee = _chamStakerFee;
        coTreasuryFee = _coTreasuryFee;

        dfTreasuryFee = MAX_FEE - (_chamStakerFee + _coTreasuryFee);
    }

    // Main function. Divides profits.
    function harvest() public {
        uint256 wNativeBal = wNative.balanceOf(address(this));

        uint256 chamStakerAmount = (wNativeBal * chamStakerFee) / MAX_FEE;
        wNative.safeTransfer(chamStaker, chamStakerAmount);

        uint256 dfTreasuryAmount = (wNativeBal * dfTreasuryFee) / MAX_FEE;
        wNative.safeTransfer(dfTreasury, dfTreasuryAmount);

        uint256 coTreasuryAmount = (wNativeBal * coTreasuryFee) / MAX_FEE;
        wNative.safeTransfer(coTreasury, coTreasuryAmount);
    }

    // Manage the contract
    function setChamStaker(address _chamStaker) external onlyOwner {
        emit NewChamStaker(chamStaker, _chamStaker);
        chamStaker = _chamStaker;
    }

    function setCoTreasury(address _coTreasury) external onlyOwner {
        emit NewCoTreasury(coTreasury, _coTreasury);
        coTreasury = _coTreasury;
    }

    function setDfTreasury(address _dfTreasury) external onlyOwner {
        emit NewDfTreasury(dfTreasury, _dfTreasury);
        dfTreasury = _dfTreasury;
    }

    function setFees(
        uint256 _chamStakerFee,
        uint256 _coTreasuryFee
    ) public onlyOwner {
        require(
            MAX_FEE >= (_chamStakerFee + _coTreasuryFee),
            "ChampionOptimizerLpFeeBatchV1: FEE_TOO_HIGH"
        );
        chamStakerFee = _chamStakerFee;
        coTreasuryFee = _coTreasuryFee;
        dfTreasuryFee = MAX_FEE - (_chamStakerFee + _coTreasuryFee);
    }

    // Rescue locked funds sent by mistake
    function inCaseTokensGetStuck(
        address _token,
        address _recipient
    ) external onlyOwner {
        require(_token != address(wNative), "ChampionOptimizerLpFeeBatchV1: NATIVE_TOKEN");

        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(_recipient, amount);
    }

    receive() external payable {}
}