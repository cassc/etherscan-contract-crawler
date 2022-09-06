// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import './libraries/math/WadRayMath.sol';

import './interfaces/IOpenSkySettings.sol';
import './interfaces/IOpenSkyOToken.sol';
import './interfaces/IOpenSkyPool.sol';
import './interfaces/IOpenSkyIncentivesController.sol';
import './interfaces/IOpenSkyMoneyMarket.sol';

contract OpenSkyOToken is Context, ERC20Permit, ERC20Burnable, ERC721Holder, IOpenSkyOToken {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    IOpenSkySettings public immutable SETTINGS;

    address internal immutable _pool;
    uint256 internal immutable _reserveId;
    address internal immutable _underlyingAsset;

    uint8 private _decimals;

    modifier onlyPool() {
        require(_msgSender() == address(_pool), Errors.ACL_ONLY_POOL_CAN_CALL);
        _;
    }

    constructor(
        address pool,
        uint256 reserveId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address underlyingAsset,
        address settings
    ) ERC20(name, symbol) ERC20Permit(symbol) {
        _decimals = decimals;
        _pool = pool;
        _reserveId = reserveId;
        _underlyingAsset = underlyingAsset;
        SETTINGS = IOpenSkySettings(settings);
    }

    // The decimals of the token. Override ERC20
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _treasury() internal view returns (address) {
        return SETTINGS.daoVaultAddress();
    }

    function mint(
        address account,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.AMOUNT_SCALED_IS_ZERO);

        _mint(account, amountScaled);
        emit Mint(account, amount, index);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        uint256 previousBalance = super.balanceOf(account);
        uint256 previousTotalSupply = super.totalSupply();

        super._mint(account, amount);

        address incentiveControllerAddress = SETTINGS.incentiveControllerAddress();
        if (incentiveControllerAddress != address(0)) {
            IOpenSkyIncentivesController(incentiveControllerAddress).handleAction(
                account,
                previousBalance,
                previousTotalSupply
            );
        }
    }

    function burn(
        address account,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.AMOUNT_SCALED_IS_ZERO);

        _burn(account, amountScaled);
        emit Burn(account, amount, index);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        uint256 previousBalance = super.balanceOf(account);
        uint256 previousTotalSupply = super.totalSupply();

        super._burn(account, amount);

        address incentiveControllerAddress = SETTINGS.incentiveControllerAddress();
        if (incentiveControllerAddress != address(0)) {
            IOpenSkyIncentivesController(incentiveControllerAddress).handleAction(
                account,
                previousBalance,
                previousTotalSupply
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 index = IOpenSkyPool(_pool).getReserveNormalizedIncome(_reserveId);

        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.AMOUNT_SCALED_IS_ZERO);
        require(amountScaled <= type(uint128).max, Errors.AMOUNT_TRANSFER_OVERFLOW);

        uint256 previousSenderBalance = super.balanceOf(sender);
        uint256 previousRecipientBalance = super.balanceOf(recipient);

        super._transfer(sender, recipient, amountScaled);

        address incentiveControllerAddress = SETTINGS.incentiveControllerAddress();
        if (incentiveControllerAddress != address(0)) {
            uint256 currentTotalSupply = super.totalSupply();
            IOpenSkyIncentivesController(incentiveControllerAddress).handleAction(
                sender,
                previousSenderBalance,
                currentTotalSupply
            );
            if (sender != recipient) {
                IOpenSkyIncentivesController(incentiveControllerAddress).handleAction(
                    recipient,
                    previousRecipientBalance,
                    currentTotalSupply
                );
            }
        }
    }

    function mintToTreasury(uint256 amount, uint256 index) external override onlyPool {
        if (amount == 0) {
            return;
        }
        _mint(_treasury(), amount.rayDiv(index));
        emit MintToTreasury(_treasury(), amount, index);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // called only by pool
    function deposit(uint256 amount) external override onlyPool {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(_pool).getReserveData(_reserveId);

        if (reserve.isMoneyMarketOn) {
            (bool success, ) = address(reserve.moneyMarketAddress).delegatecall(
                abi.encodeWithSignature('depositCall(address,uint256)', _underlyingAsset, amount)
            );
            require(success, Errors.MONEY_MARKET_DELEGATE_CALL_ERROR);
        }
        emit Deposit(amount);
    }

    function withdraw(uint256 amount, address to) external override onlyPool {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(_pool).getReserveData(_reserveId);

        if (reserve.isMoneyMarketOn) {
            (bool success, ) = address(reserve.moneyMarketAddress).delegatecall(
                abi.encodeWithSignature('withdrawCall(address,uint256,address)', _underlyingAsset, amount, to)
            );
            require(success, Errors.MONEY_MARKET_DELEGATE_CALL_ERROR);
        } else {
            IERC20(_underlyingAsset).safeTransfer(to, amount);
        }
        emit Withdraw(amount);
    }

    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        uint256 index = IOpenSkyPool(_pool).getReserveNormalizedIncome(_reserveId);
        return super.balanceOf(account).rayMul(index);
    }

    function scaledBalanceOf(address account) external view override returns (uint256) {
        return super.balanceOf(account);
    }

    function principleBalanceOf(address account) external view override returns (uint256) {
        uint256 currentBalanceScaled = super.balanceOf(account);
        uint256 lastSupplyIndex = IOpenSkyPool(_pool).getReserveData(_reserveId).lastSupplyIndex;
        return currentBalanceScaled.rayMul(lastSupplyIndex);
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return currentSupplyScaled.rayMul(IOpenSkyPool(_pool).getReserveNormalizedIncome(_reserveId));
    }

    function scaledTotalSupply() external view virtual override returns (uint256) {
        return super.totalSupply();
    }

    function principleTotalSupply() external view virtual override returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();
        uint256 lastSupplyIndex = IOpenSkyPool(_pool).getReserveData(_reserveId).lastSupplyIndex;
        return currentSupplyScaled.rayMul(lastSupplyIndex);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
        return (super.balanceOf(user), super.totalSupply());
    }

    function claimERC20Rewards(address token) external override onlyPool {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(_pool).getReserveData(_reserveId);
        require(
            token != IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getMoneyMarketToken(_underlyingAsset) &&
                token != _underlyingAsset,
            Errors.RESERVE_TOKEN_CAN_NOT_BE_CLAIMED
        );
        IERC20(token).safeTransfer(_treasury(), IERC20(token).balanceOf(address(this)));
    }
}