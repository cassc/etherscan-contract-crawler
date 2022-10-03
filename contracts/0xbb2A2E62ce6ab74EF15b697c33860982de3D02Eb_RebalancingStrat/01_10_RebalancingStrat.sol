//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../utils/Constants.sol';

import '../../interfaces/IZunami.sol';
import "../../interfaces/IStrategy.sol";

contract RebalancingStrat is Ownable {
    using SafeERC20 for IERC20Metadata;

    enum WithdrawalType {
        Base,
        OneCoin
    }

    uint256 public constant PRICE_DENOMINATOR = 1e18;

    IZunami public zunami;
    IERC20Metadata[3] public tokens;

    uint256 public managementFees = 0;
    uint256 public minDepositAmount = 9975; // 99.75%

    uint256[4] public decimalsMultipliers;

    /**
     * @dev Throws if called by any account other than the Zunami
     */
    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(IERC20Metadata[3] memory _tokens) {
        tokens = _tokens;

        for (uint256 i; i < 3; i++) {
            decimalsMultipliers[i] = calcTokenDecimalsMultiplier(tokens[i]);
        }
    }

    function withdrawAll() external onlyZunami {
        transferAllTokensTo(address(zunami));
    }

    function transferAllTokensTo(address withdrawer) internal {
        uint256 tokenStratBalance;
        for (uint256 i = 0; i < 3; i++) {
            tokenStratBalance = tokens[i].balanceOf(address(this));
            if (tokenStratBalance > 0) {
                tokens[i].safeTransfer(withdrawer, tokenStratBalance);
            }
        }
    }

    /**
     * @dev Returns deposited amount in USD.
     * If deposit failed return zero
     * @return Returns deposited amount in USD.
     * @param amounts - amounts in stablecoins that user deposit
     */
    function deposit(uint256[3] memory amounts) external returns (uint256) {
        uint256 depositedAmount;
        for (uint256 i = 0; i < 3; i++) {
            if ( amounts[i] > 0) {
                depositedAmount += amounts[i] * decimalsMultipliers[i];
            }
        }

        return depositedAmount;
    }

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external virtual onlyZunami returns (bool) {

        require(userRatioOfCrvLps > 0 && userRatioOfCrvLps <= PRICE_DENOMINATOR, 'Wrong lp Ratio');
        require(withdrawalType == WithdrawalType.Base, 'Only base');

        transferPortionTokensTo(withdrawer, userRatioOfCrvLps);

        return true;
    }

    function transferPortionTokensTo(address withdrawer, uint256 userRatioOfCrvLps) internal {
        uint256 transferAmountOut;
        for (uint256 i = 0; i < 3; i++) {
            transferAmountOut = tokens[i].balanceOf(address(this)) * userRatioOfCrvLps / 1e18;
            if (transferAmountOut > 0) {
                tokens[i].safeTransfer(withdrawer, transferAmountOut);
            }
        }
    }

    function calcTokenDecimalsMultiplier(IERC20Metadata token) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= 18, 'Zunami: wrong token decimals');
        if (decimals == 18) return 1;
        return 10**(18 - decimals);
    }


    function autoCompound() public onlyZunami {
    }

    /**
     * @dev Returns total USD holdings in strategy.
     * @return Returns total USD holdings in strategy
     */
    function totalHoldings() public view virtual returns (uint256) {
        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += tokens[i].balanceOf(address(this)) * decimalsMultipliers[i];
        }
        return tokensHoldings;
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

    function withdrawStuckToken(IERC20Metadata _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    function withdrawStuckTokenTo(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner {
        require(_token != address(0), "TOKEN");
        require(_amount > 0, "AMOUNT");
        require(_to != address(0), "TO");

        IERC20Metadata(_token).safeTransfer(_to, _amount);
    }

    function updateMinDepositAmount(uint256 _minDepositAmount) public onlyOwner {
        require(_minDepositAmount > 0 && _minDepositAmount <= 10000, 'Wrong amount!');
        minDepositAmount = _minDepositAmount;
    }

    function claimManagementFees() external returns (uint256) {
        return 0;
    }
}