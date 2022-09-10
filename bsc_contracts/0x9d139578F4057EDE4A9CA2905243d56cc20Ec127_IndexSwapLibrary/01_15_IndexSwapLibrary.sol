// SPDX-License-Identifier: MIT

/**
 * @title IndexSwapLibrary for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for all the calculations and also get token balance in vault
 * @dev This contract includes functionalities:
 *      1. Get tokens balance in the vault
 *      2. Calculate the swap amount needed while performing different operation
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IIndexSwap.sol";
import "../venus/VBep20Interface.sol";
import "../venus/IVBNB.sol";
import "../venus/TokenMetadata.sol";

contract IndexSwapLibrary {
    IPriceOracle oracle;
    address wETH;
    TokenMetadata public tokenMetadata;

    using SafeMath for uint256;

    constructor(
        address _oracle,
        address _weth,
        address _tokenMetadata
    ) {
        require(
            _oracle != address(0) &&
                _weth != address(0) &&
                _tokenMetadata != address(0)
        );
        oracle = IPriceOracle(_oracle);
        wETH = _weth;
        tokenMetadata = TokenMetadata(_tokenMetadata);
    }

    /**
     * @notice The function calculates the balance of each token in the vault and converts them to USD and 
               the sum of those values which represents the total vault value in USD
     * @return tokenXBalance A list of the value of each token in the portfolio in USD
     * @return vaultValue The total vault value in USD
     */
    function getTokenAndVaultBalance(IIndexSwap _index)
        public
        returns (uint256[] memory tokenXBalance, uint256 vaultValue)
    {
        uint256[] memory tokenBalanceInUSD = new uint256[](
            _index.getTokens().length
        );
        uint256 vaultBalance = 0;

        if (_index.totalSupply() > 0) {
            for (uint256 i = 0; i < _index.getTokens().length; i++) {
                uint256 tokenBalance;
                uint256 tokenBalanceUSD;

                if (
                    tokenMetadata.vTokens(_index.getTokens()[i]) != address(0)
                ) {
                    if (_index.getTokens()[i] != wETH) {
                        VBep20Interface token = VBep20Interface(
                            tokenMetadata.vTokens(_index.getTokens()[i])
                        );
                        tokenBalance = token.balanceOfUnderlying(
                            _index.vault()
                        );
                        tokenBalanceUSD = 0;
                        if (tokenBalance > 0) {
                            tokenBalanceUSD = _getTokenAmountInUSD(
                                _index.getTokens()[i],
                                tokenBalance
                            );
                        }
                    } else {
                        IVBNB token = IVBNB(
                            tokenMetadata.vTokens(_index.getTokens()[i])
                        );
                        uint256 tokenBalanceUnderlying = token
                            .balanceOfUnderlying(_index.vault());

                        tokenBalanceUSD = 0;
                        if (tokenBalance > 0) {
                            tokenBalanceUSD = _getTokenAmountInUSD(
                                _index.getTokens()[i],
                                tokenBalanceUnderlying
                            );
                        }
                    }
                } else {
                    tokenBalance = IERC20(_index.getTokens()[i]).balanceOf(
                        _index.vault()
                    );
                    tokenBalanceUSD = 0;
                    if (tokenBalance > 0) {
                        tokenBalanceUSD = _getTokenAmountInUSD(
                            _index.getTokens()[i],
                            tokenBalance
                        );
                    }
                }

                tokenBalanceInUSD[i] = tokenBalanceUSD;
                vaultBalance = vaultBalance.add(tokenBalanceUSD);
            }
            require(vaultBalance > 0, "sum price is not greater than 0");
            return (tokenBalanceInUSD, vaultBalance);
        } else {
            return (new uint256[](0), 0);
        }
    }

    /**
     * @notice The function calculates the balance of a specific token in the vault
     * @return tokenBalance of the specific token
     */
    function getTokenBalance(
        IIndexSwap _index,
        address t,
        bool weth
    ) public view returns (uint256 tokenBalance) {
        if (tokenMetadata.vTokens(t) != address(0)) {
            if (weth) {
                VBep20Interface token = VBep20Interface(
                    tokenMetadata.vTokens(t)
                );
                tokenBalance = token.balanceOf(_index.vault());
            } else {
                IVBNB token = IVBNB(tokenMetadata.vTokens(t));
                tokenBalance = token.balanceOf(_index.vault());
            }
        } else {
            tokenBalance = IERC20(t).balanceOf(_index.vault());
        }
    }

    /**
     * @notice The function calculates the amount in BNB to swap from BNB to each token
     * @dev The amount for each token has to be calculated to ensure the ratio (weight in the portfolio) stays constant
     * @param tokenAmount The amount a user invests into the portfolio
     * @param tokenBalanceInUSD The balanace of each token in the portfolio converted to USD
     * @param vaultBalance The total vault value of all tokens converted to USD
     * @return A list of amounts that are being swapped into the portfolio tokens
     */
    function calculateSwapAmounts(
        IIndexSwap _index,
        uint256 tokenAmount,
        uint256[] memory tokenBalanceInUSD,
        uint256 vaultBalance
    ) public view returns (uint256[] memory) {
        uint256[] memory amount = new uint256[](_index.getTokens().length);
        if (_index.totalSupply() > 0) {
            for (uint256 i = 0; i < _index.getTokens().length; i++) {
                require(tokenBalanceInUSD[i].mul(tokenAmount) >= vaultBalance);
                amount[i] = tokenBalanceInUSD[i].mul(tokenAmount).div(
                    vaultBalance
                );
            }
        }
        return amount;
    }

    /**
     * @notice The function converts the given token amount into USD
     * @param t The base token being converted to USD
     * @param amount The amount to convert to USD
     * @return amountInUSD The converted USD amount
     */
    function _getTokenAmountInUSD(address t, uint256 amount)
        public
        view
        returns (uint256 amountInUSD)
    {
        amountInUSD = oracle.getPriceTokenUSD18Decimals(t, amount);
    }

    function _getTokenPriceUSDETH(uint256 amount)
        public
        view
        returns (uint256 amountInBNB)
    {
        amountInBNB = oracle.getUsdEthPrice(amount);
    }

    function _getTokenPriceETHUSD(uint256 amount)
        public
        view
        returns (uint256 amountInBNB)
    {
        amountInBNB = oracle.getEthUsdPrice(amount);
    }
}