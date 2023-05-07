//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../utils/Constants.sol';

import '../../interfaces/IZunami.sol';

contract VaultAPSStrat is Ownable {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant PRICE_DENOMINATOR = 1e18;

    IZunami public zunami;
    IERC20Metadata token;

    uint256 public managementFees = 0;
    uint256 public minDepositAmount = 9975; // 99.75%

    /**
     * @dev Throws if called by any account other than the Zunami
     */
    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(IERC20Metadata _token) {
        token = _token;
    }

    function withdrawAll() external onlyZunami {
        transferAllTokensTo(address(zunami));
    }

    function transferAllTokensTo(address withdrawer) internal {
        uint256 tokenStratBalance = token.balanceOf(address(this));
        if (tokenStratBalance > 0) {
            token.safeTransfer(withdrawer, tokenStratBalance);
        }
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amount - amount in stablecoin that user deposit
     */
    function deposit(uint256 amount) external returns (uint256) {
        return amount;
    }

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256
    ) external virtual onlyZunami returns (bool) {
        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= PRICE_DENOMINATOR, 'Wrong lp Ratio');

        transferPortionTokensTo(withdrawer, userRatioOfCrvLps);

        return true;
    }

    function transferPortionTokensTo(address withdrawer, uint256 userRatioOfCrvLps) internal {
        uint256 transferAmountOut = (token.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;
        if (transferAmountOut > 0) {
            token.safeTransfer(withdrawer, transferAmountOut);
        }
    }

    function autoCompound() public onlyZunami {}

    /**
     * @dev Returns total USD holdings in strategy.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev disable renounceOwnership for safety
     */
    function renounceOwnership() public view override onlyOwner {
        revert('The strategy must have an owner');
    }

    /**
     * @dev dev set Zunami (main contract) address
     * @param zunamiAddr - address of main contract (Zunami)
     */
    function setZunami(address zunamiAddr) external onlyOwner {
        zunami = IZunami(zunamiAddr);
    }

    function updateMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        require(_minDepositAmount > 0 && _minDepositAmount <= 10000, 'Wrong amount!');
        minDepositAmount = _minDepositAmount;
    }

    function claimManagementFees() external returns (uint256) {
        return 0;
    }
}