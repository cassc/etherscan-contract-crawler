// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../../storage/VaultStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StockWithdraw is VaultStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Function to update token balance and transfer them to the msg.sender.
    /// @param tokenAddress Address of the token.
    /// @param updatedBalance New token balance.
    /// @param shares Amount of shares to be burned.
    /// @param transferAmount Amount of token to be transferred.
    function updateAndTransferTokens(
        address tokenAddress,
        uint256 updatedBalance,
        uint256 shares,
        uint256 transferAmount
    ) internal {
        tokenBalances.setTokenBalance(
            tokenAddress,
            tokenBalances.getTokenBalance(tokenAddress).sub(updatedBalance)
        );
        _burn(msg.sender, shares);
        if (tokenAddress == eth) {
            address payable to = payable(msg.sender);
            // to.transfer replaced here
            (bool success, ) = to.call{value: transferAmount}("");
            require(success, "Transfer failed.");
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, transferAmount);
            if (isTimeLocked == true)
                vaultTokensUnlockedForUser[msg.sender] -= shares;
        }
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        public
        payable
        nonReentrant
    {
        addToAssetList(_tokenAddress);
        uint256 tokenCountDecimals;
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        address wEth = IAPContract(APContract).getWETH();
        if (_tokenAddress == eth) {
            uint256 tokenCount = (
                (_shares.mul(getVaultNAV())).div(totalSupply()).mul(1e18)
            ).div(tokenUSD);
            tokenCountDecimals = IHexUtils(
                IAPContract(APContract).stringUtils()
            ).fromDecimals(wEth, tokenCount);
        } else {
            uint256 tokenCount = (
                (_shares.mul(getVaultNAV())).div(totalSupply()).mul(1e18)
            ).div(tokenUSD);
            tokenCountDecimals = IHexUtils(
                IAPContract(APContract).stringUtils()
            ).fromDecimals(_tokenAddress, tokenCount);
        }
        if (
            tokenCountDecimals <= tokenBalances.getTokenBalance(_tokenAddress)
        ) {
            updateAndTransferTokens(
                _tokenAddress,
                tokenCountDecimals,
                _shares,
                tokenCountDecimals
            );
        } else revert("required asset not present in vault");
    }
}