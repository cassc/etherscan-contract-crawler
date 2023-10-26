// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, FunctionLockedStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibERC20 } from "src/erc20/LibERC20.sol";

import { CannotAddNullDiscountToken, CannotAddNullSupportedExternalToken, CannotSupportExternalTokenWithMoreThan18Decimals } from "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { IEntityFacet } from "src/diamonds/nayms/interfaces/IEntityFacet.sol";
import { ISimplePolicyFacet } from "src/diamonds/nayms/interfaces/ISimplePolicyFacet.sol";
import { IMarketFacet } from "src/diamonds/nayms/interfaces/IMarketFacet.sol";
import { ITokenizedVaultFacet } from "src/diamonds/nayms/interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "src/diamonds/nayms/interfaces/ITokenizedVaultIOFacet.sol";

library LibAdmin {
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event SupportedTokenAdded(address indexed tokenAddress);
    event FunctionsLocked(bytes4[] functionSelectors);
    event FunctionsUnlocked(bytes4[] functionSelectors);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint8 old = s.maxDividendDenominations;
        require(_newMaxDividendDenominations > old, "_updateMaxDividendDenominations: cannot reduce");
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[_tokenId];
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        if (LibERC20.decimals(_tokenAddress) > 18) {
            revert CannotSupportExternalTokenWithMoreThan18Decimals();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.externalTokenSupported[_tokenAddress], "external token already added");
        require(s.objectTokenWrapperId[_tokenAddress] == bytes32(0), "cannot add participation token wrapper as external");

        string memory symbol = LibERC20.symbol(_tokenAddress);
        require(LibObject._tokenSymbolNotUsed(symbol), "token symbol already in use");

        s.externalTokenSupported[_tokenAddress] = true;
        bytes32 tokenId = LibHelpers._getIdForAddress(_tokenAddress);
        LibObject._createObject(tokenId);
        s.supportedExternalTokens.push(_tokenAddress);
        s.tokenSymbolObjectId[symbol] = tokenId;

        emit SupportedTokenAdded(_tokenAddress);
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }

    function _lockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = true;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsLocked(functionSelectors);
    }

    function _unlockFunction(bytes4 functionSelector) internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[functionSelector] = false;

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = functionSelector;
        emit FunctionsUnlocked(functionSelectors);
    }

    function _isFunctionLocked(bytes4 functionSelector) internal view returns (bool) {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        return s.locked[functionSelector];
    }

    function _lockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IEntityFacet.startTokenSale.selector] = true;
        s.locked[ISimplePolicyFacet.paySimpleClaim.selector] = true;
        s.locked[ISimplePolicyFacet.paySimplePremium.selector] = true;
        s.locked[ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector] = true;
        s.locked[IMarketFacet.cancelOffer.selector] = true;
        s.locked[IMarketFacet.executeLimitOffer.selector] = true;
        s.locked[ITokenizedVaultFacet.internalTransferFromEntity.selector] = true;
        s.locked[ITokenizedVaultFacet.payDividendFromEntity.selector] = true;
        s.locked[ITokenizedVaultFacet.internalBurn.selector] = true;
        s.locked[ITokenizedVaultFacet.wrapperInternalTransferFrom.selector] = true;
        s.locked[ITokenizedVaultFacet.withdrawDividend.selector] = true;
        s.locked[ITokenizedVaultFacet.withdrawAllDividends.selector] = true;
        s.locked[ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector] = true;
        s.locked[ITokenizedVaultIOFacet.externalDeposit.selector] = true;

        bytes4[] memory lockedFunctions = new bytes4[](14);
        lockedFunctions[0] = IEntityFacet.startTokenSale.selector;
        lockedFunctions[1] = ISimplePolicyFacet.paySimpleClaim.selector;
        lockedFunctions[2] = ISimplePolicyFacet.paySimplePremium.selector;
        lockedFunctions[3] = ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IMarketFacet.cancelOffer.selector;
        lockedFunctions[5] = IMarketFacet.executeLimitOffer.selector;
        lockedFunctions[6] = ITokenizedVaultFacet.internalTransferFromEntity.selector;
        lockedFunctions[7] = ITokenizedVaultFacet.payDividendFromEntity.selector;
        lockedFunctions[8] = ITokenizedVaultFacet.internalBurn.selector;
        lockedFunctions[9] = ITokenizedVaultFacet.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = ITokenizedVaultFacet.withdrawDividend.selector;
        lockedFunctions[11] = ITokenizedVaultFacet.withdrawAllDividends.selector;
        lockedFunctions[12] = ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = ITokenizedVaultIOFacet.externalDeposit.selector;

        emit FunctionsLocked(lockedFunctions);
    }

    function _unlockAllFundTransferFunctions() internal {
        FunctionLockedStorage storage s = LibAppStorage.functionLockStorage();
        s.locked[IEntityFacet.startTokenSale.selector] = false;
        s.locked[ISimplePolicyFacet.paySimpleClaim.selector] = false;
        s.locked[ISimplePolicyFacet.paySimplePremium.selector] = false;
        s.locked[ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector] = false;
        s.locked[IMarketFacet.cancelOffer.selector] = false;
        s.locked[IMarketFacet.executeLimitOffer.selector] = false;
        s.locked[ITokenizedVaultFacet.internalTransferFromEntity.selector] = false;
        s.locked[ITokenizedVaultFacet.payDividendFromEntity.selector] = false;
        s.locked[ITokenizedVaultFacet.internalBurn.selector] = false;
        s.locked[ITokenizedVaultFacet.wrapperInternalTransferFrom.selector] = false;
        s.locked[ITokenizedVaultFacet.withdrawDividend.selector] = false;
        s.locked[ITokenizedVaultFacet.withdrawAllDividends.selector] = false;
        s.locked[ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector] = false;
        s.locked[ITokenizedVaultIOFacet.externalDeposit.selector] = false;

        bytes4[] memory lockedFunctions = new bytes4[](14);
        lockedFunctions[0] = IEntityFacet.startTokenSale.selector;
        lockedFunctions[1] = ISimplePolicyFacet.paySimpleClaim.selector;
        lockedFunctions[2] = ISimplePolicyFacet.paySimplePremium.selector;
        lockedFunctions[3] = ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IMarketFacet.cancelOffer.selector;
        lockedFunctions[5] = IMarketFacet.executeLimitOffer.selector;
        lockedFunctions[6] = ITokenizedVaultFacet.internalTransferFromEntity.selector;
        lockedFunctions[7] = ITokenizedVaultFacet.payDividendFromEntity.selector;
        lockedFunctions[8] = ITokenizedVaultFacet.internalBurn.selector;
        lockedFunctions[9] = ITokenizedVaultFacet.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = ITokenizedVaultFacet.withdrawDividend.selector;
        lockedFunctions[11] = ITokenizedVaultFacet.withdrawAllDividends.selector;
        lockedFunctions[12] = ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = ITokenizedVaultIOFacet.externalDeposit.selector;

        emit FunctionsUnlocked(lockedFunctions);
    }
}