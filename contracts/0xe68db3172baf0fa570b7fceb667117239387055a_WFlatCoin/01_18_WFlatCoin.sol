// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./interfaces/IFlatCoin.sol";

contract WFlatCoin is ERC20Permit {
    uint256 internal constant WAD = 1e18;
    IFlatCoin public underlyingAsset;

    /**
     * @param _underlyingAsset address of the underlying asset to wrap
     */
    constructor(
        address _underlyingAsset
    ) ERC20Permit("Wrapped Flat Coin") ERC20("Wrapped Flat Coin", "wFC") {
        underlyingAsset = IFlatCoin(_underlyingAsset);
    }

    /**
     * @notice Exchanges FC to wFC
     * @param _fcAmount amount of FlatCoin to wrap in exchange for wFC
     * @dev Requirements:
     *  - msg.sender must approve at least `_fcAmount` FlatCoin to this
     *    contract.
     *  - msg.sender must have at least `_fcAmount` of FlatCoin.
     * User should first approve _fcAmount to the WFlatCoin contract
     * @return Amount of wFC user receives after wrap
     */
    function wrap(uint256 _fcAmount) external returns (uint256) {
        require(_fcAmount > 0, "zero amount");
        underlyingAsset.transferFrom(msg.sender, address(this), _fcAmount);
        uint256 wFCAmount = underlyingAsset.getSharesByAmount(_fcAmount);

        _mint(msg.sender, wFCAmount);
        return wFCAmount;
    }

    /**
     * @notice Exchanges wFC to FC
     * @param _wFCAmount amount of wFC to unwrap in exchange for FC
     * @dev Requirements:
     *  - `_wFCAmount` must be non-zero
     *  - msg.sender must have at least `_wFCAmount` wFC.
     * @return Amount of FlatCoin user receives after unwrap
     */
    function unwrap(uint256 _wFCAmount) external returns (uint256) {
        require(_wFCAmount > 0, "zero amount");
        _burn(msg.sender, _wFCAmount);

        uint256 FCAmount = underlyingAsset.getAmountByShares(_wFCAmount);
        underlyingAsset.transfer(msg.sender, FCAmount);
        return FCAmount;
    }

    /**
     * @notice Get amount of wFC for a given amount of FlatCoin
     * @param _fcAmount amount of FlatCoin
     * @return Amount of wFC for a given FlatCoin amount
     */
    function getWFCByFlatCoin(
        uint256 _fcAmount
    ) external view returns (uint256) {
        return underlyingAsset.getSharesByAmount(_fcAmount);
    }

    /**
     * @notice Get amount of FlatCoin for a given amount of WFC
     * @param _wFCAmount amount of WFC
     * @return Amount of FlatCoin for a given WFC amount
     */
    function getFlatCoinByWFC(
        uint256 _wFCAmount
    ) external view returns (uint256) {
        return underlyingAsset.getAmountByShares(_wFCAmount);
    }

    /**
     * @notice Get amount of FlatCoin for a one WFC
     * @return Amount of FlatCoin for 1 WFC
     */
    function FlatCoinPerToken() external view returns (uint256) {
        return underlyingAsset.getAmountByShares(WAD);
    }

    /**
     * @notice Get amount of WFC for a one FlatCoin
     * @return Amount of WFC for a 1 FlatCoin
     */
    function tokensPerFlatCoin() external view returns (uint256) {
        return underlyingAsset.getSharesByAmount(WAD);
    }
}