// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/IGlobalPool_R2.sol";
import "../interfaces/IinternetBond_R3.sol";

contract PolygonPool_R7 is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IGlobalPool_R2 {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    event IntermediaryClaimed(
        address[] stakers,
        uint256[] amounts,
        address intermediary, /* intermediary address which handle these funds */
        uint256 total /* total ether sent to intermediary */
    );

    event MaticClaimPending(address indexed claimer, uint256 amount);

    event ClaimsServed(
        address[] claimers,
        uint256[] amounts,
        uint256 missing /* total amount of claims still waiting to be served*/
    );

    event OperatorChanged(address indexed operator);
    event BondContractChanged(address indexed bondContract);
    event MinimumStakeChanged(uint256 minStake);
    event FeeCollectorChanged(address indexed feeCollector);
    event NotaryChanged(address indexed notary);
    event AnkrTokenAddressChanged(address indexed ankrToken);
    event ServeGasLeftChanged(uint256 gasLeft);

    mapping(address => uint256) private _pendingUserStakes;
    address[] private _pendingStakers;
    address private _operator;
    address private _notary;
    uint256 private _collectedFee;
    uint256 private _minimumStake;
    address private _bondContract;
    uint256 private _pendingGap;
    uint256[] private  _pendingClaimAmounts;
    address[] private _pendingClaimers;
    uint256 private _pendingMaticClaimGap;
    IERC20Upgradeable private _maticToken;
    IERC20Upgradeable private _ankrToken;
    address private _feeCollector;
    uint256 public ethUnstakeFee;
    uint256 private _SERVE_GAS_LEFT;

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(address operator, address maticToken, address ankrToken, address feeCollector) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _operator = operator;
        _notary = operator;
        _minimumStake = 1e18;
        _maticToken = IERC20Upgradeable(maticToken);
        _ankrToken = IERC20Upgradeable(ankrToken);
        _feeCollector = feeCollector;
    }

    function stake(uint256 amount) external override {
        _stake(msg.sender, amount, true);
    }

    function stakeAndClaimBonds(uint256 amount) external override {
        _stake(msg.sender, amount, true);
    }

    function stakeAndClaimCerts(uint256 amount) external override {
        _stake(msg.sender, amount, false);
        IinternetBond_R3(_bondContract).unlockSharesFor(msg.sender, amount);
    }

    function _stake(address staker, uint256 amount, bool isRebasing) internal nonReentrant {
        require(amount >= _minimumStake, "Value must be greater than min amount");
        require(_maticToken.transferFrom(staker, address(this), amount), "failed to receive MATIC");
        if (_pendingUserStakes[staker] == 0) {
            _pendingStakers.push(staker);
        }
        _pendingUserStakes[staker] = _pendingUserStakes[staker].add(amount);
        /* mint Internet Bonds for user */
        IinternetBond_R3(_bondContract).mintBonds(staker, amount);
        /* emit events */
        emit StakePending(staker, amount);
        emit StakePendingV2(staker, amount, isRebasing);
    }

    function getPendingStakes() public onlyOperator view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = new address[](_pendingStakers.length.sub(_pendingGap));
        uint256[] memory amounts = new uint256[](_pendingStakers.length.sub(_pendingGap));
        uint256 j = 0;
        for (uint256 i = _pendingGap; i < _pendingStakers.length; i++) {
            address staker = _pendingStakers[i];
            if (staker != address(0)) {
                addresses[j] = staker;
                amounts[j] = _pendingUserStakes[staker];
                j++;
            }
        }
        return (addresses, amounts);
    }

    function getRawPendingStakes() public onlyOperator view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = new address[](_pendingStakers.length);
        uint256[] memory amounts = new uint256[](_pendingStakers.length);
        for (uint256 i = 0; i < _pendingStakers.length; i++) {
            address staker = _pendingStakers[i];
            if (staker != address(0)) {
                addresses[i] = staker;
                amounts[i] = _pendingUserStakes[staker];
            }
        }
        return (addresses, amounts);
    }

    function claimToIntermediary(address payable intermediary, uint256 threshold) public onlyOperator {
        address[] memory stakers = new address[](_pendingStakers.length.sub(_pendingGap));
        uint256[] memory amounts = new uint256[](_pendingStakers.length.sub(_pendingGap));
        uint256 total = 0;
        uint256 j = 0;
        uint256 gaps = 0;
        uint256 i = 0;
        for (i = _pendingGap; i < _pendingStakers.length; i++) {
            /* if total exceeds threshold then we can't proceed stakes anymore (don't move this check to the end of scope) */
            if (total >= threshold) {
                break;
            }
            address staker = _pendingStakers[i];
            uint256 amount = _pendingUserStakes[staker];
            /* we might have gaps lets just skip them (we shrink them on full claim) */
            if (staker == address(0) || amount == 0) {
                gaps++;
                continue;
            }
            /* if stake amount with current total exceeds threshold then split it */
            if (total.add(amount) > threshold) {
                amount = threshold.sub(total);
            }
            stakers[j] = staker;
            amounts[j] = amount;
            total = total.add(amount);
            j++;
            /* lets release pending stakes only if amount is zero */
            _pendingUserStakes[staker] = _pendingUserStakes[staker].sub(amount);
            if (_pendingUserStakes[staker] == 0) {
                delete _pendingStakers[i];
                /* when we delete items from array we generate new gap, lets remember how many gaps we did to skip them in next claim */
                gaps++;
            }
        }
        _pendingGap = _pendingGap.add(gaps);
        /* claim funds to intermediary */
        require(_maticToken.transfer(intermediary, total), "matic not sent");
        /* decrease arrays */
        uint256 removeCells = stakers.length.sub(j);
        if (removeCells > 0) {
            assembly {mstore(stakers, sub(mload(stakers), removeCells))}
            assembly {mstore(amounts, sub(mload(amounts), removeCells))}
        }
        emit IntermediaryClaimed(stakers, amounts, intermediary, total);
    }

    function pendingStakesOf(address staker) public view returns (uint256) {
        return _pendingUserStakes[staker];
    }

    function pendingGap() public view returns (uint256) {
        return _pendingGap;
    }

    function calcPendingGap() public onlyOwner {
        uint256 gaps = 0;
        for (uint256 i = 0; i < _pendingStakers.length; i++) {
            address staker = _pendingStakers[i];
            if (staker != address(0)) {
                break;
            }
            gaps++;
        }
        _pendingGap = gaps;
    }

    function resetPendingGap() public onlyOwner {
        _pendingGap = 0;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
        emit OperatorChanged(operator);
    }

    function changeBondContract(address bondContract) public onlyOwner {
        _bondContract = bondContract;
        emit BondContractChanged(bondContract);
    }

    function pendingMaticClaimsOf(address claimer) external view returns (uint256) {
        uint256 claimsTotal;
        for (uint256 i = _pendingMaticClaimGap; i < _pendingClaimers.length; i++) {
            if (_pendingClaimers[i] == claimer) {
                claimsTotal += _pendingClaimAmounts[i];
            }
        }
        return claimsTotal;
    }

    function getPendingClaims() public onlyOperator view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = new address[](_pendingClaimers.length.sub(_pendingMaticClaimGap));
        uint256[] memory amounts = new uint256[](_pendingClaimers.length.sub(_pendingMaticClaimGap));
        uint256 j = 0;
        for (uint256 i = _pendingMaticClaimGap; i < _pendingClaimers.length; i++) {
            address claimer = _pendingClaimers[i];
            uint256 amount = _pendingClaimAmounts[i];
            if (claimer != address(0)) {
                addresses[j] = claimer;
                amounts[j] = amount;
                j++;
            }
        }
        return (addresses, amounts);
    }

    function getRawPendingClaims() public onlyOperator view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = new address[](_pendingClaimers.length);
        uint256[] memory amounts = new uint256[](_pendingClaimers.length);
        for (uint256 i = 0; i < _pendingClaimers.length; i++) {
            address claimer = _pendingClaimers[i];
            uint256 amount = _pendingClaimAmounts[i];
            if (claimer != address(0)) {
                addresses[i] = claimer;
                amounts[i] = amount;
            }
        }
        return (addresses, amounts);
    }

    function unstake(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) override external payable nonReentrant {
        _collectFee(msg.sender, fee, useBeforeBlock, signature);
        uint256 shares = IinternetBond_R3(_bondContract).balanceToShares(amount);
        _unstake(msg.sender, msg.sender, amount, shares, fee, true);
    }

    function unstakeBonds(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) override external payable nonReentrant {
        _collectFee(msg.sender, fee, useBeforeBlock, signature);
        uint256 shares = IinternetBond_R3(_bondContract).balanceToShares(amount);
        _unstake(msg.sender, msg.sender, amount, shares, fee, true);
    }

    function unstakeCerts(uint256 shares, uint256 fee, uint256 useBeforeBlock, bytes memory signature) override external payable nonReentrant {
        _collectFee(msg.sender, fee, useBeforeBlock, signature);
        uint256 amount = IinternetBond_R3(_bondContract).sharesToBalance(shares);
        IinternetBond_R3(_bondContract).lockSharesFor(msg.sender, shares);
        _unstake(msg.sender, msg.sender, amount, shares, fee, false);
    }

    function unstakeBondsFor(
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external payable nonReentrant {
        _collectFee(msg.sender, fee, useBeforeBlock, signature);
        uint256 shares = IinternetBond_R3(_bondContract).balanceToShares(amount);
        _unstake(
            msg.sender,
            recipient,
            amount,
            shares,
            fee,
            true
        );
    }

    function unstakeCertsFor(
        address recipient,
        uint256 shares,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external payable nonReentrant {
        _collectFee(msg.sender, fee, useBeforeBlock, signature);
        uint256 amount = IinternetBond_R3(_bondContract).sharesToBalance(shares);
        IinternetBond_R3(_bondContract).lockSharesFor(msg.sender, shares);
        _unstake(
            msg.sender,
            recipient,
            amount,
            shares,
            fee,
            false
        );
    }

    function _collectFee(address staker, uint256 fee, uint256 useBeforeBlock, bytes memory signature) internal {
        if (fee == 0 && useBeforeBlock == 0) {
            require(msg.value >= ethUnstakeFee, "PolygonPool: not enough ETH to pay fee");
            address payable wallet = payable(_feeCollector);
            require(wallet.send(msg.value), "PolygonPool: could not transfer unstake fee");
            emit EthFeeCollected(staker, msg.value);
        } else {
            require(block.number < useBeforeBlock, "PolygonPool: fee approval expired");
            require(
                _checkUnstakeAnkrFeeSignature(fee, useBeforeBlock, staker, signature),
                "PolygonPool: invalid unstake fee signature"
            );
            require(_ankrToken.transferFrom(staker, _feeCollector, fee), "PolygonPool: could not transfer unstake fee");
        }
    }

    function _unstake(
        address staker,
        address recipient,
        uint256 amount,
        uint256 shares,
        uint256 fee,
        bool isRebasing
    ) internal {
        require(amount > 0, "PolygonPool: cannot unstake 0");
        require(IERC20Upgradeable(_bondContract).balanceOf(staker) >= amount, "PolygonPool: cannot claim more than have on address");
        _pendingClaimers.push(recipient);
        _pendingClaimAmounts.push(amount);
        IinternetBond_R3(_bondContract).burnBonds(staker, recipient, amount);
        emit MaticClaimPending(recipient, amount);
        emit TokensBurned(staker, amount, shares, fee, isRebasing);
    }

    function serveClaims(uint256 amountToUse, address payable residueAddress, uint256 minThreshold) public onlyOperator payable {
        address[] memory claimers = new address[](_pendingClaimers.length.sub(_pendingMaticClaimGap));
        uint256[] memory amounts = new uint256[](_pendingClaimers.length.sub(_pendingMaticClaimGap));
        uint256 availableAmount = _maticToken.balanceOf(address(this));
        availableAmount = availableAmount.sub(_getTotalPendingStakes());
        require(amountToUse <= availableAmount, "not enough MATIC tokens to serve claims");
        if (amountToUse > 0) {
            availableAmount = amountToUse;
        }
        uint256 j = 0;
        uint256 gaps = 0;
        uint256 i = 0;
        for (i = _pendingMaticClaimGap; i < _pendingClaimers.length && gasleft() > _SERVE_GAS_LEFT; i++) {
            /* if the number of tokens left is less than threshold do not try to serve the claims */
            if (availableAmount < minThreshold) {
                break;
            }
            address claimer = _pendingClaimers[i];
            uint256 amount = _pendingClaimAmounts[i];
            /* we might have gaps lets just skip them (we shrink them on full claim) */
            if (claimer == address(0) || amount == 0) {
                gaps++;
                continue;
            }
            if (availableAmount < amount) {
                break;
            }
            claimers[j] = claimer;
            amounts[j] = amount;
            address payable wallet = payable(address(claimer));
            require(_maticToken.transfer(wallet, amount), "cannot send matic to claimer");
            availableAmount = availableAmount.sub(amount);
            j++;
            IinternetBond_R3(_bondContract).commitBurn(claimer, amount);
            delete _pendingClaimAmounts[i];
            delete _pendingClaimers[i];
            /* when we delete items from array we generate new gap, lets remember how many gaps we did to skip them in next claim */
            gaps++;
        }
        _pendingMaticClaimGap = _pendingMaticClaimGap.add(gaps);
        uint256 missing = 0;
        for (i = _pendingMaticClaimGap; i < _pendingClaimers.length; i++) {
            missing = missing.add(_pendingClaimAmounts[i]);
        }
        /* Send event with results */
        if (availableAmount > 0) {
            require(_maticToken.transfer(residueAddress, availableAmount), "cannot send matic to residue");
        }
        /* decrease arrays */
        uint256 removeCells = claimers.length.sub(j);
        if (removeCells > 0) {
            assembly {mstore(claimers, sub(mload(claimers), removeCells))}
            assembly {mstore(amounts, sub(mload(amounts), removeCells))}
        }
        emit ClaimsServed(claimers, amounts, missing);
    }

    function pendingClaimGap() public view returns (uint256) {
        return _pendingMaticClaimGap;
    }

    function calcPendingClaimGap() public onlyOwner {
        uint256 gaps = 0;
        for (uint256 i = 0; i < _pendingClaimers.length; i++) {
            address staker = _pendingClaimers[i];
            if (staker != address(0)) {
                break;
            }
            gaps++;
        }
        _pendingMaticClaimGap = gaps;
    }

    function resetPendingClaimGap() public onlyOwner {
        _pendingMaticClaimGap = 0;
    }

    function getMinimumStake() public view returns (uint256) {
        return _minimumStake;
    }

    function setMinimumStake(uint256 minStake) public onlyOperator {
        _minimumStake = minStake;
        emit MinimumStakeChanged(minStake);
    }

    function setFeeCollector(address feeCollector) public onlyOwner {
        _feeCollector = feeCollector;
        emit FeeCollectorChanged(feeCollector);
    }

    function setNotary(address notary) public onlyOwner {
        _notary = notary;
        emit NotaryChanged(notary);
    }

    function setAnkrTokenAddress(IERC20Upgradeable ankrToken) public onlyOwner {
        _ankrToken = ankrToken;
        emit AnkrTokenAddressChanged(address(ankrToken));
    }

    function setEthUnstakeFee(uint256 newValue) external onlyOperator {
        uint256 prevValue = ethUnstakeFee;
        ethUnstakeFee = newValue;
        emit EthUnstakeFeeChanged(prevValue, newValue);
    }

    function setServeGasLeft(uint256 gasLeft) external onlyOwner {
        _SERVE_GAS_LEFT = gasLeft;
        emit ServeGasLeftChanged(gasLeft);
    }

    function migrateDelayedBurn() external onlyOwner {
        for (uint256 i = _pendingMaticClaimGap; i < _pendingClaimers.length; i++) {
            address claimer = _pendingClaimers[i];
            uint256 amount = _pendingClaimAmounts[i];
            /* we might have gaps lets just skip them (we shrink them on full claim) */
            if (claimer == address(0) || amount == 0) {
                continue;
            }
            IinternetBond_R3(_bondContract).migrateBurnDelayed(claimer, amount);
        }
    }

    function _checkUnstakeAnkrFeeSignature(
        uint256 fee, uint256 useBeforeBlock, address staker, bytes memory signature
    ) public view returns (bool) {
        bytes32 payloadHash = keccak256(abi.encode(currentChain(), address(this), fee, useBeforeBlock, staker));
        return ECDSAUpgradeable.recover(payloadHash, signature) == _notary;
    }

    function currentChain() private view returns (uint256) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        return chain;
    }

    function _getTotalPendingStakes() internal view returns (uint256) {
        uint256 totalPendingStakeAmt;
        for (uint256 i = 0; i < _pendingStakers.length; i++) {
            address staker = _pendingStakers[i];
            if (staker != address(0)) {
                totalPendingStakeAmt = totalPendingStakeAmt.add(_pendingUserStakes[staker]);
            }
        }
        return totalPendingStakeAmt;
    }
}