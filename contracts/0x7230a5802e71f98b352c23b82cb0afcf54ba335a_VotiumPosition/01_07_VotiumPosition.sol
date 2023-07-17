// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISnapshotDelegationRegistry.sol";
import "../interfaces/convex/ILockedCvx.sol";
import "../interfaces/votium/IVotiumMerkleStash.sol";

contract VotiumPosition is Ownable {
    constructor() {
        _transferOwnership(msg.sender);
    }

    function setDelegate() external onlyOwner {
        bytes32 VotiumVoteDelegationId = 0x6376782e65746800000000000000000000000000000000000000000000000000;
        address DelegationRegistry = 0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;
        address votiumVoteProxyAddress = 0xde1E6A7ED0ad3F61D531a8a78E83CcDdbd6E0c49;
        ISnapshotDelegationRegistry(DelegationRegistry).setDelegate(
            VotiumVoteDelegationId,
            votiumVoteProxyAddress
        );
    }

    function lockCvx(uint256 _amount) external onlyOwner {
        address CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
        address VL_CVX = 0x72a19342e8F1838460eBFCCEf09F6585e32db86E;
        IERC20(CVX).approve(VL_CVX, _amount);
        ILockedCvx(VL_CVX).lock(address(this), _amount, 0);
    }

    function claimVotiumRewards(
        IVotiumMerkleStash.ClaimParam[] calldata claims
    ) external onlyOwner {
        IVotiumMerkleStash(0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A)
            .claimMulti(address(this), claims);
        // TODO convert reward tokens to eth
    }

    receive() external payable {}
}