// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4626, IERC20, ERC20, Math, SafeERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {OperableKeepable, Governable} from "src/common/OperableKeepable.sol";
import {IStrategy} from "src/interfaces/IStrategy.sol";
import {AuraRouter} from "src/compounder/AuraRouter.sol";
import {Errors} from "src/errors/Errors.sol";

contract AuraBaseCompounderVault is ERC4626, OperableKeepable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    event Rehypothecate(
        address indexed user, uint256 indexed shares, uint256 retention, uint256 treasury, uint256 vaultIncentive
    );

    uint256 public constant BASIS_POINTS = 1e12;

    // router contract
    AuraRouter public router;
    // strategy contract
    IStrategy public strategy;

    // rehypothecate retention
    uint256 public rehypothecateIncentive;

    // vault underlying asset
    IERC20 public underlying;

    constructor(address _asset, string memory _name, string memory _symbol)
        ERC4626(IERC20(_asset))
        ERC20(_name, _symbol)
        Governable(msg.sender)
    {
        if (_asset == address(0)) {
            revert Errors.ZeroAddress();
        }

        underlying = IERC20(_asset);
    }

    /**
     * @notice Sets the strategy contract for this contract.
     * @param _strategy The new strategy contract address.
     * @dev This function can only be called by the contract governor. Reverts if `_strategy` address is 0.
     */
    function setStrategy(address _strategy) external onlyGovernor {
        if (_strategy == address(0)) {
            revert Errors.ZeroAddress();
        }
        strategy = IStrategy(_strategy);
    }

    /**
     * @notice Sets the router contract for this contract.
     * @param _router The new router contract address.
     * @dev This function can only be called by the contract governor. Reverts if `_router` address is 0.
     */
    function setRouter(address _router) external onlyGovernor {
        if (_router == address(0)) {
            revert Errors.ZeroAddress();
        }
        router = AuraRouter(_router);
    }

    /**
     * @notice Sets the amount of LSD retained when rehyphotecating.
     * @param _incentive The % of the notional retained.
     * @dev This function can only be called by the contract governor and must be passed using the standard BASIS_POINTS.
     */
    function setRehypothecateIncentive(uint256 _incentive) external onlyGovernor {
        rehypothecateIncentive = _incentive;
    }

    /**
     * @dev See {IERC4626-deposit}.
     */
    function deposit(uint256 assets, address receiver) public override onlyOperator returns (uint256) {
        uint256 shares = previewDeposit(assets);
        _mint(receiver, shares);
        return shares;
    }

    /**
     * @notice Mints Vault shares to receiver.
     * @param _shares The amount of shares to mint.
     * @param _receiver The address to receive the minted assets.
     * @return shares minted
     */
    function mint(uint256 _shares, address _receiver) public override onlyOperator returns (uint256) {
        _mint(_receiver, _shares);
        return _shares;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(uint256 assets, address receiver, address owner) public override onlyOperator returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(uint256 shares, address receiver, address owner) public override onlyOperator returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @dev See {IERC4626-redeem}.
     */

    function totalAssets() public view override returns (uint256) {
        (, uint256 assets) = strategy.vaultsPosition();
        return assets - router.totalWithdrawRequestsLSD();
    }

    /**
     * @notice Burn Vault shares of account address.
     * @param _account Shares owner to be burned.
     * @param _shares Amount of shares to be burned.
     */
    function burn(address _account, uint256 _shares) public onlyOperator {
        _burn(_account, _shares);
    }

    /**
     * @notice Rehypothecate user shares charging a fee.
     * @param _assets The amount of assets to be rehypothecated.
     * @param _user msg.sender.
     */
    function rehypothecate(uint256 _assets, address _user) external onlyOperator returns (uint256, uint256, uint256) {
        uint256 shares = previewDeposit(_assets);

        _mint(address(router), shares);

        uint256 retention = shares.mulDiv(rehypothecateIncentive, BASIS_POINTS, Math.Rounding.Down);

        uint256 lsdShares = retention.mulDiv(2, 3, Math.Rounding.Down);

        uint256 strategyIncentive = previewRedeem(lsdShares);

        unchecked {
            uint256 treasuryIncentive = retention - lsdShares;
            emit Rehypothecate(_user, shares, retention, treasuryIncentive, strategyIncentive);
        }

        return (shares, retention, lsdShares);
    }
}