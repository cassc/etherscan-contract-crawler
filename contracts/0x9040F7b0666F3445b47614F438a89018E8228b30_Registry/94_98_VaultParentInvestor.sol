// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { Registry } from '../registry/Registry.sol';
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

    modifier isInSync() {
        require(_inSync(), 'not synced');
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints,
        VaultRiskProfile _riskProfile,
        Registry _registry
    ) external {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        require(l.vaultId == 0, 'already initialized');

        l.vaultId = keccak256(
            abi.encodePacked(_registry.chainId(), address(this))
        );

        VaultBaseInternal.initialize(_registry, _manager, _riskProfile);
        VaultOwnershipInternal.initialize(
            _name,
            _symbol,
            _manager,
            _managerStreamingFeeBasisPoints,
            _managerPerformanceFeeBasisPoints,
            _registry.protocolTreasury()
        );
    }

    function getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) external view returns (uint fee) {
        return _getSendQuote(sigHash, chainId);
    }

    function getLzFeesMultiChain(
        bytes4 sigHash
    ) external view returns (uint[] memory lzFees, uint256 totalSendFee) {
        return _getSendQuoteMultiChain(sigHash, _allChildChains());
    }

    function childChains(uint index) public view returns (uint16) {
        return _childChains(index);
    }

    function children(uint16 chainId) public view returns (address) {
        return _children(chainId);
    }

    function allChildChains() public view returns (uint16[] memory) {
        return _allChildChains();
    }

    function totalValueAcrossAllChains() external view returns (uint value) {
        return _totalValueAcrossAllChains();
    }

    function inSync() external view returns (bool) {
        return _inSync();
    }

    function withdrawInProgress() external view returns (bool) {
        return _withdrawInProgress();
    }

    function deposit(
        uint tokenId,
        address asset,
        uint amount
    )
        external
        noBridgeInProgress
        noWithdrawInProgress
        isInSync
        whenNotPaused
        nonReentrant
    {
        _deposit(tokenId, asset, amount);
    }

    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    )
        external
        payable
        noWithdrawInProgress
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
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

    ///
    /// Internal
    ///

    function _deposit(uint tokenId, address asset, uint amount) internal {
        uint totalVaultValue = _totalValueAcrossAllChains();
        uint totalShares = _totalShares();
        if (totalShares > 0 && totalVaultValue == 0) {
            // This means all the shares issue are currently worthless
            // We can't issue anymore shares
            revert('vault closed');
        }
        uint depositValueInUSD = _registry().accountant().assetValue(
            asset,
            amount
        );
        // require(depositValueInUSD >= baseUnitPrice * 50, 'must deposit > 50 USD');
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        uint shares;
        uint currentUnitPrice;
        if (totalShares == 0) {
            shares = depositValueInUSD;
            // We should debate if the base unit of the vaults is to be 10**18 or 10**8.
            // 10**8 is the natural unit for USD (which is what the unitPrice is denominated in), but 10**18 gives us more precision when it comes to leveling fees.
            currentUnitPrice = _unitPrice(depositValueInUSD, shares);
        } else {
            shares = (depositValueInUSD * totalShares) / totalVaultValue;
            // Don't used unitPrice() because it will encorporate the deposited funds, but shares haven't been issue yet
            currentUnitPrice = _unitPrice(totalVaultValue, totalShares);
        }

        _updateActiveAsset(asset);
        _issueShares(
            tokenId,
            msg.sender,
            shares,
            currentUnitPrice,
            _registry().depositLockupTime()
        );
    }

    function _withdrawAll(uint tokenId, uint[] memory lzFees) internal {
        _levyFees(tokenId, _unitPrice());
        _withdrawMultiChain(tokenId, _holdings(tokenId).totalShares, lzFees);
    }

    function _withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) internal {
        require(msg.sender == _ownerOf(tokenId), 'not owner');

        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress = l.childChains.length;
        uint portion = (amount * 10 ** 18) / _totalShares();
        uint currentUnitPrice;

        // I don't really like smuggling this logic in here at this level
        // But it means that if a manager isn't charging a performanceFee then we don't need to call unitPrice()
        // Which means we don't need to sync.
        if (
            (_holdings(tokenId).performanceFee == 0 &&
                _managerPerformanceFee() == 0) || isSystemToken(tokenId)
        ) {
            currentUnitPrice = 0;
        } else {
            currentUnitPrice = _unitPrice();
        }
        _burnShares(tokenId, amount, currentUnitPrice);
        _withdraw(msg.sender, portion);
        _sendWithdrawRequestsToChildrenMultiChain(msg.sender, portion, lzFees);
    }

    ///
    /// Cross Chain Requests
    ///

    function requestTotalValueUpdateMultiChain(
        uint[] memory lzFees
    ) external payable noBridgeInProgress noWithdrawInProgress whenNotPaused {
        _requestTotalValueUpdateMultiChain(lzFees);
    }

    function _requestTotalValueUpdateMultiChain(uint[] memory lzFees) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;

        for (uint8 i = 0; i < l.childChains.length; i++) {
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
        address withdrawer,
        uint portion,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;

        for (uint8 i = 0; i < l.childChains.length; i++) {
            totalFees += lzFees[i];
            _sendWithdrawRequest(
                l.childChains[i],
                withdrawer,
                portion,
                lzFees[i]
            );
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    function _sendWithdrawRequest(
        uint16 dstChainId,
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
                withdrawer: withdrawer,
                portion: portion
            })
        );
    }
}