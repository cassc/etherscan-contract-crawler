// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2 ;

import "@openzeppelin/contracts//utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./DelegateInterface.sol";
import "./Adminable.sol";

contract RewardVault is DelegateInterface, Adminable, ReentrancyGuard {

    using TransferHelper for IERC20;

    event TrancheAdded (uint256 tranchId, uint64 startTime, uint64 endTime, uint64 expireTime, uint256 total, address provider, IERC20 token, uint128 ruleFlag);
    event TrancheUpdated (uint256 tranchId, uint64 startTime, uint64 endTime, uint64 expireTime, uint256 add);
    event RewardsRecycled (uint256 tranchId, uint256 share);
    event Claimed (uint256 tranchId, address account, uint256 share);
    event TaxFundWithdrawn (IERC20 token, uint256 share);
    event TrancheTreeSet (uint256 tranchId, uint256 unDistribute, uint256 distribute, uint256 tax, bytes32 merkleRoot);

    struct Tranche {
        bytes32 merkleRoot;
        uint64 startTime;
        uint64 endTime;
        uint64 expireTime;
        uint256 total;
        uint256 tax;
        uint256 unDistribute;
        uint256 recycled;
        uint256 claimed;
        address provider;
        IERC20 token;
    }

    mapping(uint256 => Tranche) public tranches;
    // Record of whether user claimed the reward.
    mapping(uint256 => mapping(address => bool)) public claimed;
    // Stored tax fund of all token.
    mapping(IERC20 => uint256) public taxFund;
    // Stored share of all token.
    mapping(IERC20 => uint) public totalShare;
    uint256 public trancheIdx;
    uint64 public defaultExpireDuration;
    address public distributor;

    address private constant _ZERO_ADDRESS = address(0);
    bytes32 private constant _INIT_MERKLE_ROOT = 0x0;
    bytes32 private constant _NO_MERKLE_ROOT = 0x0000000000000000000000000000000000000000000000000000000000000001;

    constructor (){}

    function initialize(address payable _admin, address _distributor, uint64 _defaultExpireDuration) public {
        require(_defaultExpireDuration > 0, "Incorrect inputs");
        admin = _admin;
        distributor = _distributor;
        defaultExpireDuration = _defaultExpireDuration;
    }

    /// @notice reward can supply by anyone.
    /// @dev If token has a tax rate, the actual received will be used.
    /// @param total Provide token amount.
    /// @param startTime The time of distribution rewards begins.
    /// @param endTime The time of distribution rewards ends.
    /// @param ruleFlag Flag corresponds to the rules of reward distribution.
    function newTranche(uint256 total, IERC20 token, uint64 startTime, uint64 endTime, uint128 ruleFlag) external payable {
        require(startTime > block.timestamp && endTime > startTime && total > 0 && ruleFlag > 0, "Incorrect inputs");
        uint256 _transferIn = transferIn(msg.sender, token, total);
        uint256 _trancheId = ++ trancheIdx;
        uint64 expireTime = endTime + defaultExpireDuration;
        tranches[_trancheId] = Tranche(_INIT_MERKLE_ROOT, startTime, endTime, expireTime, _transferIn, 0, 0, 0, 0, msg.sender, token);
        emit TrancheAdded(_trancheId, startTime, endTime, expireTime, _transferIn, msg.sender, token, ruleFlag);
    }

    /// @notice Only provider can update tranche info before the time start.
    /// @dev If token has a tax rate, the actual received will be used.
    /// @param startTime The time of distribution rewards begins.
    /// @param endTime The time of distribution rewards ends.
    /// @param add Added token amount.
    function updateTranche(uint256 _trancheId, uint64 startTime, uint64 endTime, uint256 add) external payable {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.provider == msg.sender, "No permission");
        require(block.timestamp < tranche.startTime, 'Already started');
        require(startTime > block.timestamp && endTime > startTime, 'Incorrect inputs');
        uint256 _transferIn;
        if (add > 0){
            _transferIn = transferIn(msg.sender, tranche.token, add);
            tranche.total = tranche.total + _transferIn;
        }
        tranche.startTime = startTime;
        tranche.endTime = endTime;
        tranche.expireTime = endTime + defaultExpireDuration;
        emit TrancheUpdated(_trancheId, startTime, endTime, tranche.expireTime, _transferIn);
    }

    /// @notice Only the reward provider can recycle the undistributed rewards and unclaimed rewards.
    function recyclingReward(uint256 _trancheId) external nonReentrant {
        (IERC20 token, uint share) = calRecycling(_trancheId);
        transferOut(msg.sender, token, share);
    }

    /// @notice Recycling the undistributed rewards for multiple tranches.
    /// @param _trancheIds to recycle, required to be sorted by distributing token addresses.
    function recyclingRewards(uint256[] calldata _trancheIds) external nonReentrant{
        uint256 len = _trancheIds.length;
        require(len > 0, "Incorrect inputs");
        IERC20 prevToken;
        uint256 prevShare;
        for (uint256 i = 0; i < len; i ++) {
            (IERC20 token, uint share) = calRecycling(_trancheIds[i]);
            if (prevToken != token && prevShare > 0){
                transferOut(msg.sender, prevToken, prevShare);
                prevShare = 0;
            }
            prevShare = prevShare + share;
            prevToken = token;
        }
        transferOut(msg.sender, prevToken, prevShare);
    }

    /// @notice Users can claim the reward.
    function claim(uint256 _trancheId, uint256 _share, bytes32[] calldata _merkleProof) external nonReentrant {
        IERC20 token = calClaim(_trancheId, _share, _merkleProof);
        transferOut(msg.sender, token, _share);
    }

    function claims(uint256[] calldata _trancheIds, uint256[] calldata _shares, bytes32[][] calldata _merkleProofs) external nonReentrant {
        uint256 len = _trancheIds.length;
        require(len > 0 && len == _shares.length && len == _merkleProofs.length, "Incorrect inputs");
        IERC20 prevToken;
        uint256 prevShare;
        for (uint256 i = 0; i < len; i ++) {
            IERC20 token = calClaim(_trancheIds[i], _shares[i], _merkleProofs[i]);
            if (prevToken != token && prevShare > 0){
                transferOut(msg.sender, prevToken, prevShare);
                prevShare = 0;
            }
            prevShare = prevShare + _shares[i];
            prevToken = token;
        }
        transferOut(msg.sender, prevToken, prevShare);
    }

    function verifyClaim(address account, uint256 _trancheId, uint256 _share, bytes32[] calldata _merkleProof) external view returns (bool valid) {
        return _verifyClaim(account, tranches[_trancheId].merkleRoot, _share, _merkleProof);
    }

    function setExpireDuration(uint64 _defaultExpireDuration) external onlyAdmin {
        require (_defaultExpireDuration > 0, "Incorrect inputs");
        defaultExpireDuration = _defaultExpireDuration;
    }

    function setDistributor(address _distributor) external onlyAdmin {
        distributor = _distributor;
    }

    /// @notice Only the distributor can set the tranche reward distribute info.
    /// @dev If the reward is not distributed for some reason, the merkle root will be set with 1.
    /// @param _undistributed The reward of not distributed.
    /// @param _distributed The reward of distributed.
    /// @param _tax tax fund to admin.
    /// @param _merkleRoot reward tree info.
    function setTrancheTree(uint256 _trancheId, uint256 _undistributed, uint256 _distributed, uint256 _tax, bytes32 _merkleRoot) external {
        require(msg.sender == distributor, "caller must be distributor");
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.endTime < block.timestamp, 'Not end');
        require(_undistributed + _distributed + _tax == tranche.total, 'Incorrect inputs');
        tranche.unDistribute = _undistributed;
        tranche.merkleRoot = _merkleRoot;
        tranche.tax = _tax;
        taxFund[tranche.token] = taxFund[tranche.token] + _tax;
        emit TrancheTreeSet(_trancheId, _undistributed, _distributed, _tax, _merkleRoot);
    }

    /// @notice Only admin can withdraw the tax fund.
    function withdrawTaxFund(IERC20 token, address payable receiver) external onlyAdmin {
        _withdrawTaxFund(token, receiver);
    }

    function withdrawTaxFunds(IERC20[] calldata tokens, address payable receiver) external onlyAdmin {
        uint len = tokens.length;
        for (uint256 i = 0; i < len; i ++) {
            _withdrawTaxFund(tokens[i], receiver);
        }
    }

    function calRecycling(uint256 _trancheId) private returns (IERC20 token, uint share) {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.provider == msg.sender, "No permission");
        require(tranche.merkleRoot != _INIT_MERKLE_ROOT, "Not start");
        uint recycling = tranche.unDistribute;
        uint distributed = tranche.total - tranche.unDistribute - tranche.tax;
        // can recycle expire
        if (block.timestamp >= tranche.expireTime && distributed > tranche.claimed){
            recycling = recycling + distributed - tranche.claimed;
        }
        recycling = recycling - tranche.recycled;
        require(recycling > 0, "Invalid amount");
        tranche.recycled = tranche.recycled + recycling;
        emit RewardsRecycled(_trancheId, recycling);
        return (tranche.token, recycling);
    }

    function calClaim(uint256 _trancheId, uint256 _share, bytes32[] memory _merkleProof) private returns(IERC20 token) {
        Tranche storage tranche = tranches[_trancheId];
        require(tranche.merkleRoot != _INIT_MERKLE_ROOT, "Not start");
        require(tranche.merkleRoot != _NO_MERKLE_ROOT, "No Reward");
        require(tranche.expireTime > block.timestamp, "Expired");
        require(!claimed[_trancheId][msg.sender], "Already claimed");
        require(_verifyClaim(msg.sender, tranche.merkleRoot, _share, _merkleProof), "Incorrect merkle proof");
        claimed[_trancheId][msg.sender] = true;
        tranche.claimed = tranche.claimed + _share;
        emit Claimed(_trancheId, msg.sender, _share);
        return tranche.token;
    }

    function _verifyClaim(address account, bytes32 root, uint256 _share, bytes32[] memory _merkleProof) private pure returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(account, _share));
        return MerkleProof.verify(_merkleProof, root, leaf);
    }

    function _withdrawTaxFund(IERC20 token, address payable receiver) private {
        uint withdrawable = taxFund[token];
        require(withdrawable > 0, "Not enough");
        delete taxFund[token];
        transferOut(receiver, token, withdrawable);
        emit TaxFundWithdrawn(token, withdrawable);
    }

    function transferIn(address from, IERC20 token, uint amount) private returns(uint share) {
        if (isNativeToken(token)) {
            require(msg.value == amount, "Not enough");
            share = amount;
        } else {
            uint beforeBalance = token.balanceOf(address(this));
            uint receivedAmount = token.safeTransferFrom(from, address(this), amount);
            share = amountToShare(receivedAmount, beforeBalance, totalShare[token]);
            require(share > 0, "Not enough");
            totalShare[token] = totalShare[token] + share;
        }
    }

    function transferOut(address to, IERC20 token, uint share) private {
        if (isNativeToken(token)) {
            (bool success,) = to.call{value : share}("");
            require(success);
        } else {
            uint _totalShare = totalShare[token];
            totalShare[token] = _totalShare - share;
            token.safeTransfer(to, shareToAmount(share, token.balanceOf(address(this)), _totalShare));
        }
    }

    function amountToShare(uint _amount, uint _reserve, uint _totalShare) private pure returns (uint share){
        share = _amount > 0 && _totalShare > 0 && _reserve > 0 ? _totalShare * _amount / _reserve : _amount;
    }

    function shareToAmount(uint _share, uint _reserve, uint _totalShare) private pure returns (uint amount){
        if (_share > 0 && _totalShare > 0 && _reserve > 0) {
            amount = _reserve * _share / _totalShare;
        }
    }

    function isNativeToken(IERC20 token) private pure returns (bool) {
        return (address(token) == _ZERO_ADDRESS);
    }

}