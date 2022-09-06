// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/FixedPointMath.sol";
import "./interfaces/ISingleAssetStake.sol";

// solhint-disable check-send-result
contract AutoCompoundingPicniqToken is ERC20 {
    using FixedPointMath for uint256;

    IERC20 private immutable _asset;
    ISingleAssetStake private _staking;

    uint8 private _mutex;

    constructor(address staking_)
        ERC20 ("Auto Compounding Picniq Token", "xSNACK") {
            _staking = ISingleAssetStake(staking_);
            _asset = IERC20(_staking.stakingToken());
            _asset.approve(address(_staking), type(uint256).max);

            _mutex = 1;
    }

    function asset() external view returns (address)
    {
        return address(_asset);
    }

    function totalAssets() public view returns (uint256)
    {
        return _staking.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256)
    {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256)
    {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256)
    {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256)
    {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view returns (uint256)
    {
        return convertToAssets(shares);
    }

    function maxDeposit(address) external pure returns (uint256)
    {
        return type(uint256).max;
    }

    function maxMint(address) external pure returns (uint256)
    {
        return type(uint256).max;
    }

    function maxWithdrawal(address owner) external view returns (uint256)
    {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedemption(address owner) external view returns (uint256)
    {
        return balanceOf(owner);
    }

    function deposit(uint256 assets, address receiver) external returns (uint256)
    {
        uint256 shares = previewDeposit(assets);

        _staking.getReward();
        
        require(shares != 0, "Zero shares");
        
        uint256 balance = _asset.balanceOf(address(this));

        _asset.transferFrom(msg.sender, address(this), assets);
        _staking.stake(assets + balance);
        _mint(receiver, shares);
        _approve(msg.sender, address(this), type(uint256).max);

        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    function withdraw(uint256 assets, address receiver, address owner) external runHarvest returns (uint256)
    {
        uint256 shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                _spendAllowance(owner, msg.sender, shares);
            }
        }

        _burn(owner, shares);
        _staking.withdraw(assets);
        _asset.transfer(receiver, assets);
        
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) external runHarvest returns (uint256)
    {
        uint256 assets = previewRedeem(shares);

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                _spendAllowance(owner, msg.sender, assets);
            }
        }

        require(assets != 0, "No assets");

        _burn(owner, shares);
        _staking.withdraw(assets);
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function mint(uint256 shares, address receiver) external returns (uint256)
    {
        uint256 assets = previewMint(shares);

        _staking.getReward();
        _asset.transferFrom(msg.sender, address(this), assets);

        uint256 balance = _asset.balanceOf(address(this));
        _staking.stake(balance);

        _mint(msg.sender, shares);
        _approve(msg.sender, address(this), type(uint256).max);

        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function harvest() external
    {
        _staking.getReward();
        uint256 balance = _asset.balanceOf(address(this));
        _staking.stake(balance);
    }

    modifier runHarvest()
    {
        _staking.getReward();
        uint256 balance = _asset.balanceOf(address(this));
        if (balance > 0) {
            _staking.stake(balance);
        }
        _;
    }

    modifier nonReentrant()
    {
        require(_mutex == 1, "Nonreentrant");

        _mutex = 2;
        _;
        _mutex = 1;
    }

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}