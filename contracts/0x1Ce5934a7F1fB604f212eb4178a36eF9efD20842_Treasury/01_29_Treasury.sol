// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GovernanceToken.sol";
import "../BustadToken.sol";
import "./ReleaseFund.sol";

contract Treasury is Ownable {
    ReleaseFund[] public releaseFunds;

    address public releaseFundMasterContract;
    BustadToken public bustadToken;
    GovernanceToken public governanceToken;

    uint256 public refundDelay;
    uint256 public withdrawDelay;
    uint256 public currentSnapshotId;
    address public currentReleaseFundContractAddress;
    uint256 public maxReleaseAmount;

    event Release(
        uint256 amount,
        uint256 snapshotId,
        uint256 refundDelay,
        uint256 withdrawDelay,
        address releaseFundContractAddress
    );

    constructor(
        address _releaseFundMasterContract,
        GovernanceToken _governanceToken,
        BustadToken _bustadToken,
        uint256 _refundDelay,
        uint256 _withdrawDelay,
        uint256 _maxReleaseAmout
    ) {
        releaseFundMasterContract = _releaseFundMasterContract;
        bustadToken = _bustadToken;
        governanceToken = _governanceToken;
        refundDelay = _refundDelay;
        withdrawDelay = _withdrawDelay;
        currentSnapshotId = 0;
        currentReleaseFundContractAddress = address(0);
        maxReleaseAmount = _maxReleaseAmout;
    }

    function release(uint256 amount) external onlyOwner {
        require(amount <= maxReleaseAmount, "Amount exceeded limit");
        require(
            amount <= bustadToken.balanceOf(address(this)),
            "Amount exceeded balance"
        );

        uint256 snapshotId = governanceToken.snapshot();

        address cloneAddress = Clones.cloneDeterministic(
            releaseFundMasterContract,
            bytes32(snapshotId)
        );

        ReleaseFund rFund = ReleaseFund(cloneAddress);

        uint256 withdrawAllowedAt = block.number + withdrawDelay;
        uint256 refundAllowedAt = block.number + refundDelay;

        rFund.init(
            snapshotId,
            governanceToken,
            bustadToken,
            refundAllowedAt,
            withdrawAllowedAt
        );

        currentSnapshotId = snapshotId;
        currentReleaseFundContractAddress = cloneAddress;

        bustadToken.transfer(cloneAddress, amount);

        releaseFunds.push(rFund);

        emit Release(
            amount,
            snapshotId,
            refundDelay,
            withdrawDelay,
            cloneAddress
        );
    }

    function getReleaseFundContractAddress(uint256 snapshopId)
        public
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                releaseFundMasterContract,
                bytes32(snapshopId)
            );
    }

    function getCurrentReleaseFundContractAddress()
        external
        view
        returns (address)
    {
        return currentReleaseFundContractAddress;
    }

    function setRefundTime(uint256 _refundDelay) external onlyOwner {
        refundDelay = _refundDelay;
    }

    function setWithdrawDelay(uint256 _withdrawDelay) external onlyOwner {
        withdrawDelay = _withdrawDelay;
    }

    function setMaxReleaseAmount(uint256 _maxReleaseAmount) external onlyOwner {
        maxReleaseAmount = _maxReleaseAmount;
    }

    function setReleaseFundMasterContract(address _releaseFundMasterContract) external onlyOwner {
        releaseFundMasterContract = _releaseFundMasterContract;
    }    

    function setBustadToken(BustadToken _bustadToken) external onlyOwner {
        bustadToken = _bustadToken;
    }

    function setGovernanceToken(GovernanceToken _governanceToken) external onlyOwner {
        governanceToken = _governanceToken;
    }    
}