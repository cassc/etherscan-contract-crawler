// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './BlueBerryErrors.sol';
import './interfaces/ISafeBox.sol';
import './interfaces/compound/ICErc20.sol';

contract SafeBox is
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    ISafeBox
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev address of cToken for underlying token
    ICErc20 public cToken;
    /// @dev address of underlying token
    IERC20Upgradeable public uToken;

    event Deposited(address indexed account, uint256 amount, uint256 cAmount);
    event Withdrawn(address indexed account, uint256 amount, uint256 cAmount);

    function initialize(
        ICErc20 _cToken,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        if (address(_cToken) == address(0)) revert ZERO_ADDRESS();
        IERC20Upgradeable _uToken = IERC20Upgradeable(_cToken.underlying());
        cToken = _cToken;
        uToken = _uToken;
        _uToken.safeApprove(address(_cToken), type(uint256).max);
    }

    function decimals() public view override returns (uint8) {
        return cToken.decimals();
    }

    /**
     * @notice Deposit underlying assets on Compound and issue share token
     * @param amount Underlying token amount to deposit
     * @return ctokenAmount cToken amount
     */
    function deposit(
        uint256 amount
    ) external override nonReentrant returns (uint256 ctokenAmount) {
        if (amount == 0) revert ZERO_AMOUNT();
        uint256 uBalanceBefore = uToken.balanceOf(address(this));
        uToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 uBalanceAfter = uToken.balanceOf(address(this));

        uint256 cBalanceBefore = cToken.balanceOf(address(this));
        if (cToken.mint(uBalanceAfter - uBalanceBefore) != 0)
            revert LEND_FAILED(amount);
        uint256 cBalanceAfter = cToken.balanceOf(address(this));

        ctokenAmount = cBalanceAfter - cBalanceBefore;
        _mint(msg.sender, ctokenAmount);

        emit Deposited(msg.sender, amount, ctokenAmount);
    }

    /**
     * @notice Withdraw underlying assets from Compound
     * @param cAmount Amount of cTokens to redeem
     * @return withdrawAmount Amount of underlying assets withdrawn
     */
    function withdraw(
        uint256 cAmount
    ) external override nonReentrant returns (uint256 withdrawAmount) {
        if (cAmount == 0) revert ZERO_AMOUNT();

        _burn(msg.sender, cAmount);

        uint256 uBalanceBefore = uToken.balanceOf(address(this));
        if (cToken.redeem(cAmount) != 0) revert REDEEM_FAILED(cAmount);
        uint256 uBalanceAfter = uToken.balanceOf(address(this));

        withdrawAmount = uBalanceAfter - uBalanceBefore;
        uToken.safeTransfer(msg.sender, withdrawAmount);

        emit Withdrawn(msg.sender, withdrawAmount, cAmount);
    }
}