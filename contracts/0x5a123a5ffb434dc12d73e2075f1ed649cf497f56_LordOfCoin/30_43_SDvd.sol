// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/ITreasury.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract SDvd is ERC20Snapshot, Ownable {

    using SafeMath for uint256;

    /// @notice Minter address. DVD-ETH Pool, DVD Pool.
    mapping(address => bool) public minters;
    /// @dev No fee address. SDVD-ETH Pool, DVD Pool.
    mapping(address => bool) public noFeeAddresses;
    /// @notice Lord of Coin
    address public controller;

    address public devTreasury;
    address public poolTreasury;
    address public tradingTreasury;

    /// @dev SDVD-ETH pair address
    address public pairAddress;
    /// @dev SDVD-ETH pair token
    IUniswapV2Pair pairToken;
    /// @dev Used to check LP removal
    uint256 lastPairTokenTotalSupply;

    constructor() public ERC20('Stock dvd.finance', 'SDVD') {
    }

    /* ========== Modifiers ========== */

    modifier onlyMinter {
        require(minters[msg.sender], 'Minter only');
        _;
    }

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(
        address _controller,
        address _pairAddress,
        address _sdvdEthPool,
        address _dvdPool,
        address _devTreasury,
        address _poolTreasury,
        address _tradingTreasury
    ) external onlyOwner {
        controller = _controller;

        // Create uniswap pair for SDVD-ETH pool
        pairAddress = _pairAddress;
        // Set pair token
        pairToken = IUniswapV2Pair(pairAddress);

        devTreasury = _devTreasury;
        poolTreasury = _poolTreasury;
        tradingTreasury = _tradingTreasury;

        // Add pools as SDVD minter
        _setMinter(_sdvdEthPool, true);
        _setMinter(_dvdPool, true);

        // Add no fees address
        _setNoFeeAddress(_sdvdEthPool, true);
        _setNoFeeAddress(_dvdPool, true);
        _setNoFeeAddress(devTreasury, true);
        _setNoFeeAddress(poolTreasury, true);
        _setNoFeeAddress(tradingTreasury, true);

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Minter Only ========== */

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    /* ========== Controller Only ========== */

    function snapshot() external onlyController returns (uint256) {
        return _snapshot();
    }

    /* ========== Public ========== */

    function syncPairTokenTotalSupply() public returns (bool isPairTokenBurned) {
        // Get LP token total supply
        uint256 pairTokenTotalSupply = pairToken.totalSupply();
        // If last total supply > current total supply,
        // It means LP token is burned by uniswap, which means someone removing liquidity
        isPairTokenBurned = lastPairTokenTotalSupply > pairTokenTotalSupply;
        // Save total supply
        lastPairTokenTotalSupply = pairTokenTotalSupply;
    }

    /* ========== Internal ========== */

    function _setMinter(address account, bool value) internal {
        minters[account] = value;
    }

    function _setNoFeeAddress(address account, bool value) internal {
        noFeeAddresses[account] = value;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        // Check uniswap liquidity removal
        _checkUniswapLiquidityRemoval(sender);

        if (noFeeAddresses[sender] || noFeeAddresses[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // 0.5% for dev
            uint256 devFee = amount.div(200);
            // 1% for farmers in pool
            uint256 poolFee = devFee.mul(2);
            // 1% to goes as sharing profit
            uint256 tradingFee = poolFee;

            // Get net amount
            uint256 net = amount
            .sub(devFee)
            .sub(poolFee)
            .sub(tradingFee);

            super._transfer(sender, recipient, net);
            super._transfer(sender, devTreasury, devFee);
            super._transfer(sender, poolTreasury, poolFee);
            super._transfer(sender, tradingTreasury, tradingFee);
        }
    }

    function _checkUniswapLiquidityRemoval(address sender) internal {
        bool isPairTokenBurned = syncPairTokenTotalSupply();

        // If from uniswap LP address
        if (sender == pairAddress) {
            // Check if liquidity removed
            require(isPairTokenBurned == false, 'LP removal disabled');
        }
    }

}