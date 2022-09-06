// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import {IWETH} from '../interfaces/IWETH.sol';
import {IETHVault} from "../interfaces/IETHVault.sol";
import {IICHIVault} from "../interfaces/IICHIVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 @notice wrapper contract around ICHI vault with wETH being a base token. Allows users to deposit ETH instead of wETH
 */
contract ETHVault is ReentrancyGuard, IETHVault {

    // WETH address
    address public immutable override wETH;

    // Vault address
    address public immutable override vault;

    // Flag that indicates whether the vault is inverted or not
    bool private immutable isInverted;

    address constant NULL_ADDRESS = address(0);

    /**
     @notice creates an instance of ETHVault (wrapped around an existing ICHI vault)
     @param _wETH wETH address
     @param _vault underlying vault
     */
    constructor(
        address _wETH,
        address _vault
    ) {
        require(_wETH != NULL_ADDRESS && _vault != NULL_ADDRESS, "EV.constructor: zero address");

        wETH = _wETH;
        vault = _vault;

        bool _isInverted = _wETH == IICHIVault(_vault).token0();

        require(_isInverted || _wETH == IICHIVault(_vault).token1(), "EV.constructor: one of the tokens must be wETH");
        isInverted = _isInverted;
        IERC20(_wETH).approve(_vault, uint256(-1));

        emit DeployETHVault(
            msg.sender,
            _vault,
            _wETH,
            _isInverted
        );
    }

    /**
     @notice Distributes shares to depositor equal to the ETH value of his deposit multiplied by the ratio of total liquidity shares issued divided by the pool's AUM measured in ETH value. 
     @param to Address to which liquidity tokens are minted
     @param shares Quantity of liquidity tokens minted as a result of deposit
     */
    function depositETH(
        address to
    ) external payable override nonReentrant returns (uint256 shares) {
        require(msg.value > 0, "EV.depositETH: can't deposit 0");

        IWETH(wETH).deposit{ value: msg.value }();
        shares = isInverted ? IICHIVault(vault).deposit(msg.value, 0, to) : IICHIVault(vault).deposit(0, msg.value, to);
    }

}