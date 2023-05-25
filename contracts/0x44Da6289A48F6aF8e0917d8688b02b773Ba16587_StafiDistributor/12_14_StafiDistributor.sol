pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "../StafiBase.sol";
import "../interfaces/IStafiEther.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/reward/IStafiFeePool.sol";
import "../interfaces/reward/IStafiSuperNodeFeePool.sol";
import "../interfaces/reward/IStafiDistributor.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../types/ClaimType.sol";

// Distribute network validator priorityFees/withdrawals/slashs
contract StafiDistributor is StafiBase, IStafiEtherWithdrawer, IStafiDistributor {
    // Libs
    using SafeMath for uint256;

    event Claimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );
    event VoteProposal(bytes32 indexed proposalId, address voter);
    event ProposalExecuted(bytes32 indexed proposalId);
    event DistributeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSuperNodeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSlash(uint256 dealedHeight, uint256 slashAmount);
    event SetMerkleRoot(uint256 dealedEpoch, bytes32 merkleRoot);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    receive() external payable {}

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract("stafiDistributor", address(this))
        onlyLatestContract("stafiEther", msg.sender)
    {}

    // distribute withdrawals for node/platform, accept calls from stafiWithdraw
    function distributeWithdrawals() external payable override onlyLatestContract("stafiDistributor", address(this)) {
        require(msg.value > 0, "zero amount");

        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        stafiEther.depositEther{value: msg.value}();
    }

    // ------------ getter ------------

    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint("settings.node.deposit.amount");
    }

    function getMerkleDealedEpoch() public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.merkleRoot.dealedEpoch")));
    }

    function getTotalClaimedReward(address _account) public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.node.totalClaimedReward", _account)));
    }

    function getTotalClaimedDeposit(address _account) public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.node.totalClaimedDeposit", _account)));
    }

    function getMerkleRoot() public view returns (bytes32) {
        return getBytes32(keccak256(abi.encodePacked("stafiDistributor.merkleRoot")));
    }

    function getDistributeFeeDealedHeight() public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.distributeFee.dealedHeight")));
    }

    function getDistributeSuperNodeFeeDealedHeight() public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.distributeSuperNodeFee.dealedHeight")));
    }

    function getDistributeSlashDealedHeight() public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("stafiDistributor.distributeSlashAmount.dealedHeight")));
    }

    // ------------ settings ------------

    function updateMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyLatestContract("stafiDistributor", address(this)) onlySuperUser {
        setMerkleRoot(_merkleRoot);
    }

    // ------------ vote ------------

    // v1: platform = 10% node = 90%*(nodedeposit/32)+90%*(1- nodedeposit/32)*10%  user = 90%*(1- nodedeposit/32)*90%
    // v2: platform = 5%  node = 5% + (90% * nodedeposit/32) user = 90%*(1-nodedeposit/32)
    // distribute fee of feePool for user/node/platform
    function distributeFee(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount
    ) external onlyLatestContract("stafiDistributor", address(this)) onlyTrustedNode(msg.sender) {
        uint256 totalAmount = _userAmount.add(_nodeAmount).add(_platformAmount);
        require(totalAmount > 0, "zero amount");

        require(_dealedHeight > getDistributeFeeDealedHeight(), "height already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeFee", _dealedHeight, _userAmount, _nodeAmount, _platformAmount)
        );
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IStafiFeePool feePool = IStafiFeePool(getContractAddress("stafiFeePool"));
            IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
            IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));

            feePool.withdrawEther(address(this), totalAmount);

            uint256 nodeAndPlatformAmount = _nodeAmount.add(_platformAmount);

            if (_userAmount > 0) {
                stafiUserDeposit.recycleDistributorDeposit{value: _userAmount}();
            }
            if (nodeAndPlatformAmount > 0) {
                stafiEther.depositEther{value: nodeAndPlatformAmount}();
            }

            setDistributeFeeDealedHeight(_dealedHeight);

            _afterExecProposal(proposalId);

            emit DistributeFee(_dealedHeight, _userAmount, _nodeAmount, _platformAmount);
        }
    }

    // v1: platform = 10% node = 9%  user = 81%
    // v2: platform = 5%  node = 5%  user = 90%
    // distribute fee of superNode feePool for user/node/platform
    function distributeSuperNodeFee(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount
    ) external onlyLatestContract("stafiDistributor", address(this)) onlyTrustedNode(msg.sender) {
        uint256 totalAmount = _userAmount.add(_nodeAmount).add(_platformAmount);
        require(totalAmount > 0, "zero amount");

        require(_dealedHeight > getDistributeSuperNodeFeeDealedHeight(), "height already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeSuperNodeFee", _dealedHeight, _userAmount, _nodeAmount, _platformAmount)
        );
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IStafiFeePool feePool = IStafiFeePool(getContractAddress("stafiSuperNodeFeePool"));
            IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
            IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));

            feePool.withdrawEther(address(this), totalAmount);

            uint256 nodeAndPlatformAmount = _nodeAmount.add(_platformAmount);

            if (_userAmount > 0) {
                stafiUserDeposit.recycleDistributorDeposit{value: _userAmount}();
            }
            if (nodeAndPlatformAmount > 0) {
                stafiEther.depositEther{value: nodeAndPlatformAmount}();
            }

            setDistributeSuperNodeFeeDealedHeight(_dealedHeight);

            _afterExecProposal(proposalId);

            emit DistributeSuperNodeFee(_dealedHeight, _userAmount, _nodeAmount, _platformAmount);
        }
    }

    // distribute slash amount for user
    function distributeSlashAmount(
        uint256 _dealedHeight,
        uint256 _amount
    ) external onlyLatestContract("stafiDistributor", address(this)) onlyTrustedNode(msg.sender) {
        require(_amount > 0, "zero amount");

        require(_dealedHeight > getDistributeSlashDealedHeight(), "height already dealed");

        bytes32 proposalId = keccak256(abi.encodePacked("distributeSlashAmount", _dealedHeight, _amount));
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
            IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));

            stafiEther.withdrawEther(_amount);
            stafiUserDeposit.recycleDistributorDeposit{value: _amount}();
            setDistributeSlashDealedHeight(_dealedHeight);

            _afterExecProposal(proposalId);

            emit DistributeSlash(_dealedHeight, _amount);
        }
    }

    function setMerkleRoot(
        uint256 _dealedEpoch,
        bytes32 _merkleRoot
    ) external onlyLatestContract("stafiDistributor", address(this)) onlyTrustedNode(msg.sender) {
        uint256 predealedEpoch = getMerkleDealedEpoch();
        require(_dealedEpoch > predealedEpoch, "epoch already dealed");

        bytes32 proposalId = keccak256(abi.encodePacked("setMerkleRoot", _dealedEpoch, _merkleRoot));
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            setMerkleRoot(_merkleRoot);
            setMerkleDealedEpoch(_dealedEpoch);

            _afterExecProposal(proposalId);

            emit SetMerkleRoot(_dealedEpoch, _merkleRoot);
        }
    }

    // ----- node claim --------------

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external onlyLatestContract("stafiDistributor", address(this)) {
        uint256 claimableReward = _totalRewardAmount.sub(getTotalClaimedReward(_account));
        uint256 claimableDeposit = _totalExitDepositAmount.sub(getTotalClaimedDeposit(_account));

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
        require(MerkleProof.verify(_merkleProof, getMerkleRoot(), node), "invalid proof");

        uint256 willClaimAmount;
        if (_claimType == ClaimType.CLAIMREWARD) {
            require(claimableReward > 0, "no claimable reward");

            setTotalClaimedReward(_account, _totalRewardAmount);
            willClaimAmount = claimableReward;
        } else if (_claimType == ClaimType.CLAIMDEPOSIT) {
            require(claimableDeposit > 0, "no claimable deposit");

            setTotalClaimedDeposit(_account, _totalExitDepositAmount);
            willClaimAmount = claimableDeposit;
        } else if (_claimType == ClaimType.CLAIMTOTAL) {
            willClaimAmount = claimableReward.add(claimableDeposit);
            require(willClaimAmount > 0, "no claimable amount");

            setTotalClaimedReward(_account, _totalRewardAmount);
            setTotalClaimedDeposit(_account, _totalExitDepositAmount);
        } else {
            revert("unknown claimType");
        }

        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        stafiEther.withdrawEther(willClaimAmount);
        (bool success, ) = _account.call{value: willClaimAmount}("");
        require(success, "failed to claim ETH");

        emit Claimed(_index, _account, claimableReward, claimableDeposit, _claimType);
    }

    // --- helper ----

    function setTotalClaimedReward(address _account, uint256 _totalAmount) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.node.totalClaimedReward", _account)), _totalAmount);
    }

    function setTotalClaimedDeposit(address _account, uint256 _totalAmount) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.node.totalClaimedDeposit", _account)), _totalAmount);
    }

    function setMerkleDealedEpoch(uint256 _dealedEpoch) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.merkleRoot.dealedEpoch")), _dealedEpoch);
    }

    function setMerkleRoot(bytes32 _merkleRoot) internal {
        setBytes32(keccak256(abi.encodePacked("stafiDistributor.merkleRoot")), _merkleRoot);
    }

    function setDistributeFeeDealedHeight(uint256 _dealedHeight) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.distributeFee.dealedHeight")), _dealedHeight);
    }

    function setDistributeSuperNodeFeeDealedHeight(uint256 _dealedHeight) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.distributeSuperNodeFee.dealedHeight")), _dealedHeight);
    }

    function setDistributeSlashDealedHeight(uint256 _dealedHeight) internal {
        setUint(keccak256(abi.encodePacked("stafiDistributor.distributeSlashAmount.dealedHeight")), _dealedHeight);
    }

    function _voteProposal(bytes32 _proposalId) internal returns (bool) {
        // Get submission keys
        bytes32 proposalNodeKey = keccak256(
            abi.encodePacked("stafiDistributor.proposal.node.key", _proposalId, msg.sender)
        );
        bytes32 proposalKey = keccak256(abi.encodePacked("stafiDistributor.proposal.key", _proposalId));

        require(!getBool(proposalKey), "proposal already executed");

        // Check & update node submission status
        require(!getBool(proposalNodeKey), "duplicate vote");
        setBool(proposalNodeKey, true);

        // Increment submission count
        uint256 voteCount = getUint(proposalKey).add(1);
        setUint(proposalKey, voteCount);

        emit VoteProposal(_proposalId, msg.sender);

        // Check submission count & update network balances
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        uint256 threshold = stafiNetworkSettings.getNodeConsensusThreshold();
        if (calcBase.mul(voteCount) >= stafiNodeManager.getTrustedNodeCount().mul(threshold)) {
            return true;
        }
        return false;
    }

    function _afterExecProposal(bytes32 _proposalId) internal {
        bytes32 proposalKey = keccak256(abi.encodePacked("stafiDistributor.proposal.key", _proposalId));
        setBool(proposalKey, true);

        emit ProposalExecuted(_proposalId);
    }
}