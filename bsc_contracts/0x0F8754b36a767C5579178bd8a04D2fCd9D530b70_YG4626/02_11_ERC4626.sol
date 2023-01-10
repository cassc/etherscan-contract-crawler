// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.10 <0.9.0;

import "IERC20.sol";
import "IERC4626.sol";
import "ERC20Permit.sol";
import {Owned} from  "Owned.sol";

/// @notice Yagger ERC4646 tokenized vault implementation.
/// @author Kader https://github.com/aallamaa 

abstract contract ERC4626 is IERC4626, ERC20Permit, Owned {

    /* IMMUTABLES */

    /// @notice The underlying token the vault accepts.
    address public immutable asset;

    /// @notice The base unit of the underlying token and hence vault.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 internal immutable baseUnit;

    /// @dev deployment timestamp of the smart contract
    uint256 public immutable deployTS;

    /// @dev Funds used for yield generation
    uint256 public usedFunds;

    /// @notice Creates a new vault that accepts a specific underlying token.
    /// @param _asset The ERC20 compliant token the vault should accept.
    /// @param _name The name for the vault token.
    /// @param _symbol The symbol for the vault token.

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, IERC20(_asset).decimals()) {
        asset = _asset;
        deployTS = block.timestamp;
        baseUnit = 10**_decimals;
    }

    function _safeTransferFrom(address _owner, address _receiver, uint256 amount) internal returns (uint256 finalAmount) {
        uint256 initialBalance = IERC20(asset).balanceOf(_receiver);
        IERC20(asset).transferFrom(_owner, _receiver, amount);
        finalAmount = IERC20(asset).balanceOf(_receiver) - initialBalance;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    ///////////////////////////////////////////////////////////////*/

    /// @notice Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
    /// @return maxAssets max amount that can be deposited by caller
    function maxDeposit(address) public pure returns (uint256 maxAssets) {
        maxAssets = type(uint256).max;
    }
    
    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit 
    /// @notice at the current block, given current on-chain conditions.
    /// @param assets The amount of underlying assets to deposit
    /// @return shares The amount of the underlying asset.
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        shares = (assets * baseUnit) / assetsPerShare();
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint
    /// @notice at the current block, given current on-chain conditions.
    /// @param shares The amount of the shares.
    /// @return assets The amount of underlying assets to deposit
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        if (_totalSupply == 0) {return 0;}
        assets = (shares * assetsPerShare()) / baseUnit;

    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit 
    /// @notice at the current block, given current on-chain conditions.
    /// @param assets The amount of underlying assets to deposit
    /// @return shares The amount of the underlying asset.
    function previewDeposit(uint256 assets) external view virtual returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Deposit a specific amount of underlying assets.
    /// @param assets The amount of the underlying asset to deposit.
    /// @param receiver The address to receive shares corresponding to the deposit
    function _deposit(uint256 assets, address receiver) internal returns (uint256 shares) {
        uint256 exchangeRate_ = assetsPerShare();
        // Transfer in underlying tokens from the user.
        // Determine the real amount of underlying token received .
        uint256 realAssets = _safeTransferFrom(_msgSender(), address(this), assets);
        shares = (realAssets * baseUnit) / exchangeRate_;
        require((shares!=0), "ZERO_SHARES");
        // Determine the equivalent amount of shares and mint them.
        _mint(receiver, shares);
        // Should we state realUnderlyingAmount or underlyingAmount in the Deposit event
        emit Deposit(_msgSender(), receiver, realAssets, shares);
        // This will revert if the user does not have the amount specified.
        
    }

    /// @notice Deposit a specific amount of underlying assets.
    /// @param assets The amount of the underlying asset to deposit.
    /// @param receiver The address to receive shares corresponding to the deposit
    function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares) {
        return _deposit(assets, receiver);
    }    

    function depositWithPermit(uint256 assets, address receiver, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual returns (uint256 shares) {
        IERC2612Permit(asset).permit(_msgSender(), address(this), assets, deadline, v, r, s);
        return _deposit(assets, receiver);
    }


    /// @notice Returns Total number of underlying shares that caller can be mint..
    /// @return maxShares max amount that can be deposited by caller
    function maxMint(address) public pure returns (uint256 maxShares) {
        maxShares = type(uint256).max;
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint
    /// @notice at the current block, given current on-chain conditions.
    /// @param shares The amount of the shares.
    /// @return assets The amount of underlying assets to deposit
    function previewMint(uint256 shares) public view returns (uint256 assets) {
        assets = (shares * assetsPerShare()) / baseUnit;
    }

    /// @notice Deposit a specific amount of underlying assets.
    /// @param assets The amount of the underlying asset to deposit.
    /// @param receiver The address to receive shares corresponding to the deposit
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        uint256 targetAssets = previewMint(shares);
        uint256 exchangeRate_ = assetsPerShare();
        // Transfer in underlying assets from the user.
        // Determine the real amount of underlying token received .
        assets = _safeTransferFrom(_msgSender(), address(this), targetAssets);
        uint256 finalShares = (assets * baseUnit) / exchangeRate_;
        require((finalShares!=0), "ZERO_SHARES");
        // Determine the equivalent amount of shares and mint them.
        _mint(receiver, finalShares);
        // Should we state realUnderlyingAmount or underlyingAmount in the Deposit event
        emit Deposit(_msgSender(), receiver, assets, finalShares);
    }
    
    
    function maxWithdraw(address user) public view virtual returns (uint256 maxAssets) {
        return assetsOf(user);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        if (_totalSupply == 0) {return 0;}
        shares = (assets * baseUnit ) / assetsPerShare();
        // if (convertToAssets(shares) < assets) {
        //     shares += 1;
        // }
    }
    
    /// @notice Withdraw a specific amount of underlying assets.
    /// @param assets The amount of underlying assets to withdraw.
    /// @param receiver The address to receive underlying assets corresponding to the withdrawal.
    /// @param owner The address from which shares are withdrawn.
    function withdraw(uint256 assets, address receiver, address owner) external virtual returns (uint256 shares) {
        shares = previewWithdraw(assets);
        address caller = _msgSender();
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        // Determine the equivalent assets of shares and burn them.
        // This will revert if the user does not have enough shares.
        _burn(owner, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);
        require(totalAssets() >= assets, "funds are not availables (usedFunds)");
        IERC20(asset).transfer(receiver, assets);
    }

    function maxRedeem(address user) public view virtual returns (uint256 maxShares) {
        return _balances[user];
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Redeem a specific amount of shares for underlying tokens.
    /// @param shares The amount of shares to redeem for underlying tokens.
    /// @param receiver The address to receive underlying tokens corresponding to the withdrawal.
    /// @param owner The address from which shares are withdrawn.
    /// @return assets number of assets redeemed
    function redeem(uint256 shares, address receiver, address owner) external virtual returns (uint256 assets) {
        address caller = _msgSender();
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        // Determine the equivalent amount of underlying assets.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        // Withdraw from strategies if needed and transfer.
        require(totalAssets() >= assets, "funds are not availables (usedFunds)");
        // Burn the provided amount of shares.
        // This will revert if the user does not have enough shares.
        _burn(owner, shares);

        emit Withdraw(caller, receiver, owner, assets, shares);

        IERC20(asset).transfer(receiver, assets);
    }


    /*///////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/


    /// @notice Returns a user's Vault balance in underlying assets.
    /// @param depositor The user to get the underlying balance of.
    /// @return assets The user's Vault balance in underlying assets.
    function assetsOf(address depositor) public view returns (uint256 assets) {
        assets = (_balances[depositor] * assetsPerShare()) / baseUnit;
    }

    /// @notice Returns the amount of underlying asset a share can be redeemed for.
    /// @return assetsPerUnitShare The amount of underlying assets a share can be redeemed for.
    function assetsPerShare() public view returns (uint256 assetsPerUnitShare) {
        // Get the total supply of shares.
        uint256 shareSupply = _totalSupply;

        // If there are no shares in circulation, return an exchange rate of 1:1.
        if (shareSupply == 0) return baseUnit;

        // Calculate the exchange rate by dividing the total holdings by the share supply.
        assetsPerUnitShare = (totalAssets() * baseUnit) / shareSupply;
    }

    /// @notice Calculates the total amount of underlying asset the Vault holds.
    /// @return totalAssets The total amount of underlying asset the Vault holds.

    /// scenario 1: on repaie plus que ce qu'on a emprunté
    /// totalAssets = 100
    /// on emprunte 20
    /// totalAssets = 100 (balance = 80 + 20 usedFunds)

    /// avec les 20 on a généré 25
    /// totalAssets = 125 (balance = 105, usedFunds = 0)


    function totalAssets() public view virtual returns (uint256) {
        return usedFunds + IERC20(asset).balanceOf(address(this));
    }

    function addFunds(uint256 original_amount, uint256 repaid_amount) public onlyOwner returns (uint256 final_repaid_amount) {
        final_repaid_amount = _safeTransferFrom(_msgSender(), address(this), repaid_amount);
        usedFunds -= original_amount;
    }

    function removeFunds(uint256 amount) public onlyOwner {
        usedFunds += amount;
        IERC20(asset).transfer(_msgSender(), amount);
        //emit Withdraw(address(this), _msgSender(), amount);
    }

    function apy() external view returns (uint256 _apy, uint256 precision, uint256 duration) {
        // 31536000 is number of seconds in a year
        // APY = (1 + apy / precision ) ^ (31536000 / duration) * 100 - 100  
        precision = baseUnit;
        _apy = assetsPerShare() - precision;
        duration = (block.timestamp - deployTS);
    }

}