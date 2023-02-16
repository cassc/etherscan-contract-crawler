// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IUniswapV2Router.sol";

contract ChampionOptimizerCeFeeBatchV1 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public wNative;
    address public dfTreasury;
    address public coTreasury;
    address public strategist;
    address public chamStaker;

    // Fee constants
    uint constant public MAX_FEE = 1000;
    uint public dfTreasuryFee;
    uint public coTreasuryFee;
    uint public strategistFee;
    uint public chamStakerFee;

    event NewDfTreasury(address oldValue, address newValue);
    event NewCoTreasury(address oldValue, address newValue);
    event NewStrategist(address oldValue, address newValue);
    event NewChamStaker(address oldValue, address newValue);

    function initialize(
        address _wNative,
        address _dfTreasury,
        address _coTreasury,  
        address _chamStaker,
        address _strategist,
        uint256 _coTreasuryFee,
        uint256 _chamStakerFee,
        uint256 _strategistFee  
    ) public initializer {
        __Ownable_init();
        wNative  = IERC20Upgradeable(_wNative);
        dfTreasury = _dfTreasury;
        coTreasury = _coTreasury;
        chamStaker = _chamStaker;
        strategist = _strategist;

        chamStakerFee = _chamStakerFee;
        strategistFee = _strategistFee;
        coTreasuryFee = _coTreasuryFee;
        dfTreasuryFee = MAX_FEE - (chamStakerFee + strategistFee + coTreasuryFee);
    }

    // Main function. Divides profits.
    function harvest() public {
        uint256 wNativeBal = wNative.balanceOf(address(this));

        uint256 coTreasuryAmount = wNativeBal * coTreasuryFee / MAX_FEE;
        wNative.safeTransfer(coTreasury, coTreasuryAmount);

        uint256 dfTreasuryAmount = wNativeBal * dfTreasuryFee / MAX_FEE;
        wNative.safeTransfer(dfTreasury, dfTreasuryAmount);

        uint256 chamStakerAmount = wNativeBal * chamStakerFee / MAX_FEE;
        wNative.safeTransfer(chamStaker, chamStakerAmount);

        uint256 strategistAmount = wNativeBal * strategistFee / MAX_FEE;
        wNative.safeTransfer(strategist, strategistAmount);
    }

    // Manage the contract
    function setDfTreasury(address _dfTreasury) external onlyOwner {
        emit NewDfTreasury(dfTreasury, _dfTreasury);
        dfTreasury = _dfTreasury;
    }

    function setCoTreasury(address _coTreasury) external onlyOwner {
        emit NewDfTreasury(coTreasury, _coTreasury);
        coTreasury = _coTreasury;
    }

    function setStrategist(address _strategist) external onlyOwner {
        emit NewStrategist(strategist, _strategist);
        strategist = _strategist;
    }

    function setChamStaker(address _chamStaker) external onlyOwner {
        emit NewChamStaker(chamStaker, _chamStaker);
        chamStaker = _chamStaker;
    }

    function setFees(
        uint256 _coTreasuryFee,
        uint256 _chamStakerFee,
        uint256 _strategistFee
    ) public onlyOwner {
        require(
            MAX_FEE >= (_chamStakerFee + _coTreasuryFee + _strategistFee),
            "CoFeeBatch: FEE_TOO_HIGH"
        );
        coTreasuryFee = _coTreasuryFee;
        chamStakerFee = _chamStakerFee;
        strategistFee = _strategistFee;
        dfTreasuryFee = MAX_FEE - (chamStakerFee + _coTreasuryFee + _strategistFee);
    }
    
    // Rescue locked funds sent by mistake
    function inCaseTokensGetStuck(address _token, address _recipient) external onlyOwner {
        require(_token != address(wNative), "CoFeeBatch: NATIVE_TOKEN");

        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(_recipient, amount);
    }

    receive() external payable {}
}