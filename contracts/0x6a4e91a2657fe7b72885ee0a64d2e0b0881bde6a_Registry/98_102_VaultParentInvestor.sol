// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { Registry } from '../registry/Registry.sol';
import { Constants } from '../lib/Constants.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultParentInvestor is VaultParentInternal {
    using SafeERC20 for IERC20;

    event Deposit(
        address depositer,
        uint tokenId,
        address asset,
        uint amount,
        uint currentUnitPrice,
        uint shares
    );

    event WithdrawMultiChain(
        address withdrawer,
        uint tokenId,
        uint portion,
        uint currentUnitPrice,
        uint shares
    );

    modifier isInSync() {
        require(_inSync(), 'not synced');
        _;
    }

    function requestTotalValueUpdateMultiChain(
        uint[] memory lzFees
    ) external payable noBridgeInProgress noWithdrawInProgress whenNotPaused {
        _requestTotalValueUpdateMultiChain(lzFees);
    }

    function deposit(
        uint tokenId,
        address asset,
        uint amount
    ) external noBridgeInProgress isInSync whenNotPaused nonReentrant {
        _deposit(tokenId, asset, amount);
    }

    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external payable noBridgeInProgress whenNotPaused nonReentrant {
        _withdrawMultiChain(tokenId, amount, lzFees);
    }

    function withdrawAllMultiChain(
        uint tokenId,
        uint[] memory lzFees
    )
        external
        payable
        noWithdrawInProgress
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
        _withdrawAll(tokenId, lzFees);
    }

    function getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) external view returns (uint fee) {
        return _getLzFee(sigHash, chainId);
    }

    function getLzFeesMultiChain(
        bytes4 sigHash
    ) external view returns (uint[] memory lzFees, uint256 totalSendFee) {
        return _getLzFeesMultiChain(sigHash, _allChildChains());
    }

    function childChains(uint index) external view returns (uint16) {
        return _childChains(index);
    }

    function children(uint16 chainId) external view returns (address) {
        return _children(chainId);
    }

    function allChildChains() external view returns (uint16[] memory) {
        return _allChildChains();
    }

    function totalValueAcrossAllChains()
        external
        view
        returns (uint minValue, uint maxValue)
    {
        return _totalValueAcrossAllChains();
    }

    function inSync() external view returns (bool) {
        return _inSync();
    }

    function withdrawInProgress() external view returns (bool) {
        return _withdrawInProgress();
    }

    function requiresSyncForWithdraw(
        uint tokenId
    ) external view returns (bool) {
        return _requiresSyncForWithdraw(tokenId);
    }

    function requiresSyncForDeposit() external view returns (bool) {
        return _requiresSyncForDeposit();
    }

    // Returns the number of seconds until the totalValueSync expires
    function timeUntilExpiry() external view returns (uint) {
        return _timeUntilExpiry();
    }

    function holdingLocked(uint tokenId) external view returns (bool) {
        return _holdingLocked(tokenId);
    }

    ///
    /// Internal
    ///

    function _deposit(uint tokenId, address asset, uint amount) internal {
        require(_registry().depositAssets(asset), 'not deposit asset');
        require(
            _registry().allowedInvestors(msg.sender),
            'investor not allowed'
        );
        (, uint maxVaultValue) = _totalValueAcrossAllChains();
        uint totalShares = _totalShares();

        if (totalShares > 0 && maxVaultValue == 0) {
            // This means all the shares issue are currently worthless
            // We can't issue anymore shares
            revert('vault closed');
        }
        (uint depositValueInUSD, ) = _registry().accountant().assetValue(
            asset,
            amount
        );

        require(
            maxVaultValue + depositValueInUSD <= _registry().vaultValueCap(),
            'vault will exceed cap'
        );

        // if tokenId == 0 means were creating a new holding
        if (tokenId == 0) {
            require(
                depositValueInUSD >= _registry().minDepositAmount(),
                'min deposit not met'
            );
        }

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        _updateActiveAsset(asset);

        uint shares;
        uint currentUnitPrice;
        if (totalShares == 0) {
            shares = depositValueInUSD;
            // We should debate if the base unit of the vaults is to be 10**18 or 10**8.
            // 10**8 is the natural unit for USD (which is what the unitPrice is denominated in),
            // but 10**18 gives us more precision when it comes to leveling fees.
            currentUnitPrice = _unitPrice(depositValueInUSD, shares);
        } else {
            shares = (depositValueInUSD * totalShares) / maxVaultValue;
            // Don't used unitPrice() because it will encorporate the deposited funds, but shares haven't been issue yet
            currentUnitPrice = _unitPrice(maxVaultValue, totalShares);
        }

        uint issuedToTokenId = _issueShares(
            tokenId,
            msg.sender,
            shares,
            currentUnitPrice,
            _registry().depositLockupTime()
        );

        emit Deposit(
            msg.sender,
            issuedToTokenId,
            asset,
            amount,
            currentUnitPrice,
            shares
        );
        _registry().emitEvent();
    }

    function _withdrawAll(uint tokenId, uint[] memory lzFees) internal {
        (uint minPrice, ) = _unitPrice();
        _levyFees(tokenId, minPrice);
        _withdrawMultiChain(tokenId, _holdings(tokenId).totalShares, lzFees);
    }

    function _withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) internal {
        address owner = _ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == _registry().withdrawAutomator(),
            'not allowed'
        );

        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress = l.childChains.length;
        uint portion = (amount * Constants.PORTION_DIVISOR) / _totalShares();
        uint minUnitPrice;

        // If a Manager is not charging a performance fee we do not need the currentUnitPrice
        // To process a withdraw, because all withdraws are porpotional.
        // I don't really like smuggling this logic in here at this level
        // But it means that if a manager isn't charging a performanceFee then we don't have to impose a totalValueSync
        if (!_inSync() && !_requiresUnitPrice(tokenId)) {
            minUnitPrice = 0;
        } else {
            // This will revert if the vault is not in sync
            (minUnitPrice, ) = _unitPrice();
        }
        _burnShares(tokenId, amount, minUnitPrice);
        _withdraw(tokenId, owner, portion);
        _sendWithdrawRequestsToChildrenMultiChain(
            tokenId,
            owner,
            portion,
            lzFees
        );

        emit WithdrawMultiChain(owner, tokenId, portion, minUnitPrice, amount);
        _registry().emitEvent();
    }

    ///
    /// Cross Chain Requests
    ///

    function _requestTotalValueUpdateMultiChain(uint[] memory lzFees) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        uint totalFees;

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            uint16 childChainId = l.childChains[i];

            _registry().transport().sendValueUpdateRequest{ value: lzFees[i] }(
                ITransport.ValueUpdateRequest({
                    parentChainId: _registry().chainId(),
                    parentVault: address(this),
                    child: ITransport.ChildVault({
                        vault: l.children[childChainId],
                        chainId: childChainId
                    })
                })
            );
        }

        require(msg.value >= totalFees, 'insufficient fee sent');
    }

    function _sendWithdrawRequestsToChildrenMultiChain(
        uint tokenId,
        address withdrawer,
        uint portion,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            _sendWithdrawRequest(
                l.childChains[i],
                tokenId,
                withdrawer,
                portion,
                lzFees[i]
            );
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    function _sendWithdrawRequest(
        uint16 dstChainId,
        uint tokenId,
        address withdrawer,
        uint portion,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        _registry().transport().sendWithdrawRequest{ value: sendFee }(
            ITransport.WithdrawRequest({
                parentChainId: _registry().chainId(),
                parentVault: address(this),
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                tokenId: tokenId,
                withdrawer: withdrawer,
                portion: portion
            })
        );
    }

    function _requiresUnitPrice(uint tokenId) internal view returns (bool) {
        if (isSystemToken(tokenId)) {
            return false;
        }
        if (
            (_managerPerformanceFee() == 0 &&
                _holdings(tokenId).performanceFee == 0)
        ) {
            return false;
        }

        return true;
    }

    function _requiresSyncForWithdraw(
        uint tokenId
    ) internal view returns (bool) {
        if (!_hasActiveChildren() || !_requiresUnitPrice(tokenId)) {
            return false;
        }
        return true;
    }

    function _requiresSyncForDeposit() internal view returns (bool) {
        if (!_hasActiveChildren()) {
            return false;
        }
        return true;
    }
}