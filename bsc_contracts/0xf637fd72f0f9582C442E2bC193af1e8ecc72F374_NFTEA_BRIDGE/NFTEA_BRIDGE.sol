/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
// Use this contract to remove maxTransactionLimit On Your NFTea.app Token

pragma solidity ^0.8.0;

interface IToken {

    function setIsTxLimitExempt(address holder, bool exempt) external;

    function setIsExcludedFromFee(address account, bool newValue) external;

    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newBuyBackTax) external;

    function setSellTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newBuyBackTax) external;

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newBuyBackShare) external;

    function setMaxTxAmount(uint256 maxTxAmount) external;

    function enableDisableWalletLimit(bool newValue) external;

    function transferOwnership(address newOwner) external;

    function setSwapAndLiquifyEnabled(bool _enabled) external;

    function setSwapAndLiquifyByLimitOnly(bool newValue) external;

    function changeRouterVersion(address newRouterAddress) external returns(address newPairAddress);

    function setWalletLimit(uint256 newLimit) external;

    function setNumTokensBeforeSwap(uint256 newLimit) external;

    function setoperations(address newAddress) external;

    function setcommunity(address newAddress) external;

    function setmarketing(address newAddress) external;

    function addMarketPair(address account) external;

}

contract NFTEA_BRIDGE {

    address public tokenAddress;
    mapping(address=>bool) public isAdmin;
    
    constructor() {
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only an admin can call this function");
        _;
    }

    function setTokenAddress(address token) public onlyAdmin{
        require(tokenAddress == address(0), 'token already set');
        tokenAddress = token;
    }

    function setAdmin(address _admin) public {
        require(isAdmin[msg.sender],'you are not an admin');
        isAdmin[_admin] = true;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external {
        require(holder!=0x3acd58d9cC879Bed0B0b5313466C9116176Bc242, 'error');
        require(holder!=0xb4668238Acf0314A7b4e153368e479fCd2E09831, 'error');
        IToken(tokenAddress).setIsTxLimitExempt(holder, exempt);
    }

    function setWalletLimit(uint256 newLimit) public onlyAdmin {
        IToken(tokenAddress).setWalletLimit(newLimit);
    }

    function setNumTokensBeforeSwap(uint256 newLimit) public onlyAdmin {
        IToken(tokenAddress).setNumTokensBeforeSwap(newLimit);
    }

    function setOperationsAddress(address newAddress) public onlyAdmin {
        IToken(tokenAddress).setoperations(newAddress);
    }

    function setCommunityAddress(address newAddress) public onlyAdmin {
        IToken(tokenAddress).setcommunity(newAddress);
    }

    function setMarketingAddress(address newAddress) public onlyAdmin {
        IToken(tokenAddress).setmarketing(newAddress);
    }

    function transferOwnership(address newOwner) public onlyAdmin {
        IToken(tokenAddress).transferOwnership(newOwner);
    }

    function setIsExcludedFromFee(address account, bool newValue) public onlyAdmin {
        IToken(tokenAddress).setIsExcludedFromFee(account, newValue);
    }

    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newBuyBackTax) public onlyAdmin {
        IToken(tokenAddress).setBuyTaxes(newLiquidityTax, newMarketingTax, newBuyBackTax);
    }

    function setSellTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newBuyBackTax) public onlyAdmin {
        IToken(tokenAddress).setSellTaxes(newLiquidityTax, newMarketingTax, newBuyBackTax);
    }

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newBuyBackShare) public onlyAdmin {
        IToken(tokenAddress).setDistributionSettings(newLiquidityShare, newMarketingShare, newBuyBackShare);
    }

    function setMaxTxAmount(uint256 maxTxAmount) public onlyAdmin {
        IToken(tokenAddress).setMaxTxAmount(maxTxAmount);
    }

    function enableDisableWalletLimit(bool newValue) public onlyAdmin {
        IToken(tokenAddress).enableDisableWalletLimit(newValue);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyAdmin {
        IToken(tokenAddress).setSwapAndLiquifyEnabled(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyAdmin {
        IToken(tokenAddress).setSwapAndLiquifyByLimitOnly(newValue);
    }

    function changeRouterVersion(address newRouterAddress) public onlyAdmin returns (address newPairAddress) {
        return IToken(tokenAddress).changeRouterVersion(newRouterAddress);
    }

    function addMarketPair(address account) public onlyAdmin {
        IToken(tokenAddress).addMarketPair(account);
    }
}