// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { IVaultParentManager } from './IVaultParentManager.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultOwnershipStorage } from '../vault-ownership/VaultOwnershipStorage.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultParentManager is VaultParentInternal, IVaultParentManager {
    using SafeERC20 for IERC20;

    modifier onlyManagerOrTransport() {
        require(
            msg.sender == _manager() ||
                msg.sender == address(_registry().transport()),
            'only manager or transport'
        );
        _;
    }

    function VAULT_PRECISION() external pure returns (uint) {
        return Constants.VAULT_PRECISION;
    }

    function unitPrice() external view returns (uint) {
        return _unitPrice();
    }

    function holdings(
        uint tokenId
    ) external view returns (VaultOwnershipStorage.Holding memory) {
        return _holdings(tokenId);
    }

    function bridgeInProgress() external view returns (bool) {
        return _bridgeInProgress();
    }

    function bridgeApprovedTo() external view returns (uint16) {
        return _bridgeApprovedTo();
    }

    function performanceFee(
        uint fee,
        uint discount,
        uint _totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) public pure returns (uint tokensOwed) {
        return
            _performanceFee(
                fee,
                discount,
                _totalShares,
                tokenPriceStart,
                tokenPriceFinish
            );
    }

    function streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint _totalShares,
        uint timeNow
    ) public pure returns (uint tokensOwed) {
        return _streamingFee(fee, discount, lastFeeTime, _totalShares, timeNow);
    }

    function calculateUnpaidFees(
        uint tokenId,
        uint currentUnitPrice
    ) public view returns (uint streamingFees, uint performanceFees) {
        return _calculateUnpaidFees(tokenId, currentUnitPrice);
    }

    function protocolFee(uint managerFees) public pure returns (uint) {
        return _protocolFee(managerFees);
    }

    function FEE_ANNOUNCE_WINDOW() external pure returns (uint) {
        return _FEE_ANNOUNCE_WINDOW;
    }

    function MAX_STREAMING_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_STREAMING_FEE_BASIS_POINTS;
    }

    function MAX_STREAMING_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_STREAMING_FEE_BASIS_POINTS_STEP;
    }

    function MAX_PERFORMANCE_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS;
    }

    function STEAMING_FEE_DURATION() external pure returns (uint) {
        return _STEAMING_FEE_DURATION;
    }

    function PROTOCOL_FEE_BASIS_POINTS() external pure returns (uint) {
        return _PROTOCOL_FEE_BASIS_POINTS;
    }

    function MANAGER_TOKEN_ID() external pure returns (uint) {
        return _MANAGER_TOKEN_ID;
    }

    function PROTOCOL_TOKEN_ID() external pure returns (uint) {
        return _PROTOCOL_TOKEN_ID;
    }

    function MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP;
    }

    function totalShares() external view returns (uint) {
        return _totalShares();
    }

    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    )
        external
        payable
        onlyManager
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        // check minAmountOut is within threshold
        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;

        IERC20(asset).safeApprove(address(_registry().transport()), amount);

        _registry().transport().bridgeAsset{ value: lzFee }(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this),
            asset,
            amount,
            minAmountOut
        );
    }

    function requestCreateChild(
        uint16 newChainId,
        uint lzFee
    ) external payable onlyManagerOrTransport whenNotPaused nonReentrant {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        require(msg.value >= lzFee, 'insufficient fee');

        require(!l.childCreationInProgress, 'sibling creation inprogress');
        require(l.children[newChainId] == address(0), 'sibling exists');
        require(newChainId != _registry().chainId(), 'not same chain');
        l.childCreationInProgress = true;
        ITransport.ChildVault[]
            memory existingChildren = new ITransport.ChildVault[](
                l.childChains.length
            );

        for (uint8 i = 0; i < l.childChains.length; i++) {
            existingChildren[i].chainId = l.childChains[i];
            existingChildren[i].vault = l.children[l.childChains[i]];
        }
        _registry().transport().sendVaultChildCreationRequest{ value: lzFee }(
            ITransport.VaultChildCreationRequest({
                parentVault: address(this),
                parentChainId: _registry().chainId(),
                newChainId: newChainId,
                manager: _manager(),
                riskProfile: _riskProfile(),
                children: existingChildren
            })
        );
    }

    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable onlyManager whenNotPaused nonReentrant {
        require(_registry().canChangeManager(), 'manager change disabled');
        require(newManager != address(0), 'invalid newManager');
        address oldManager = _manager();
        _changeManager(newManager);
        _transfer(oldManager, newManager, _MANAGER_TOKEN_ID);
        _sendChangeManagerRequestToChildren(newManager, lzFees);
    }

    function _sendChangeManagerRequestToChildren(
        address newManager,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            totalFees += lzFees[i];
            _sendChangeManagerRequest(l.childChains[i], newManager, lzFees[i]);
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    function _sendChangeManagerRequest(
        uint16 dstChainId,
        address newManager,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        _registry().transport().sendChangeManagerRequest{ value: sendFee }(
            ITransport.ChangeManagerRequest({
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                newManager: newManager
            })
        );
    }

    /// Fees

    function managerPerformanceFee() public view returns (uint) {
        return _managerPerformanceFee();
    }

    function managerStreamingFee() public view returns (uint) {
        return _managerStreamingFee();
    }

    function announcedManagerPerformanceFee() public view returns (uint) {
        return _announcedManagerPerformanceFee();
    }

    function announcedManagerStreamingFee() public view returns (uint) {
        return _announcedManagerStreamingFee();
    }

    function announcedFeeIncreaseTimestamp() public view returns (uint) {
        return _announcedFeeIncreaseTimestamp();
    }

    function announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) external onlyManager whenNotPaused {
        _announceFeeIncrease(newStreamingFee, newPerformanceFee);
    }

    function commitFeeIncrease() external onlyManager whenNotPaused {
        _commitFeeIncrease();
    }

    function renounceFeeIncrease() external onlyManager whenNotPaused {
        _renounceFeeIncrease();
    }

    /// Ownership

    function setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) external onlyManager whenNotPaused {
        _setDiscountForHolding(
            tokenId,
            streamingFeeDiscount,
            performanceFeeDiscount
        );
    }

    function levyFeesOnHoldings(
        uint[] memory tokenIds
    ) external onlyManager whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                block.timestamp >=
                    _holdings(tokenIds[i]).lastManagerFeeLevyTime + 24 hours,
                'already levied this period'
            );
            _levyFees(tokenIds[i], _unitPrice());
        }
    }

    function sendBridgeApproval(
        uint16 dstChainId,
        uint lzFee
    )
        external
        payable
        onlyManager
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        require(msg.value >= lzFee, 'insufficient fee');
        // If the bridge approval is cancelled the manager is block from initiating another for 1 hour
        // This protects users from being ddos'd and not being able to withdraw because the manager keeps applying a bridge lock
        require(
            l.lastBridgeCancellation + 1 hours < block.timestamp,
            'bridge approval timeout'
        );
        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;
        l.bridgeApprovedTo = dstChainId;

        _registry().transport().sendBridgeApproval{ value: lzFee }(
            ITransport.BridgeApprovalRequest({
                approvedChainId: dstChainId,
                approvedVault: dstVault
            })
        );
    }
}