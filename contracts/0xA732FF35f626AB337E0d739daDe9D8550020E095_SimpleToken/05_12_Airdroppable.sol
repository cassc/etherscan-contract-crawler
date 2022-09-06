//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @title Airdroppable
 * @author Javier Gonzalez
 * @notice Allows user to create an unlimited number of airdrops
 */
abstract contract Airdroppable {
    using BitMaps for BitMaps.BitMap;

    struct Airdrop {
        bytes32 merkleRoot;
        bool isComplete;
        uint256 claimPeriodEnds;
        BitMaps.BitMap claimed;
    }
    event NewAirdrop(uint256 index, bytes32 merkleRoot, uint256 claimPeriod);
    event Claimed(address claimant, uint256 amount);
    event AirdropComplete(uint256 index);
    event Sweep(address destination, uint256 amount);

    uint256 public numberOfAirdrops = 0;
    mapping(uint256 => Airdrop) airdrops;

    /**
     * @notice Creates a new airdrop if there is no other airdrop active.
     * @dev Does not verify if the contract has enough liquidity to fullfill the airdrop, this must be done off-chain.
     * @param _merkleRoot this must be calculated off chain and can be verified with the merkleProof
     * @param _timeLimit seconds until the airdrop can finish and be swept
     */
    function _newAirdrop(bytes32 _merkleRoot, uint256 _timeLimit)
        internal
        returns (uint256 airdropId)
    {
        airdropId = numberOfAirdrops;
        if (numberOfAirdrops > 0) {
            require(
                airdrops[numberOfAirdrops - 1].isComplete,
                "Airdrop currently active, creation failed"
            );
        }
        Airdrop storage _drop = airdrops[airdropId];
        _drop.merkleRoot = _merkleRoot;
        _drop.claimPeriodEnds = block.timestamp + _timeLimit;
        emit NewAirdrop(airdropId, _merkleRoot, _drop.claimPeriodEnds);
        numberOfAirdrops += 1;
    }

    function isClaimed(uint256 airdropIndex, uint256 claimIndex)
        public
        view
        returns (bool)
    {
        return airdrops[airdropIndex].claimed.get(claimIndex);
    }

    /**
     * @notice Sweep the tokens from airdrop to user. User needs to know the amount that is alloted to them.
     * @dev Uses merkle proofs to verify that the amount is equivalent to the user's claim
     * @param claimAmount this must be calculated off chain and can be verified with the merkleProof
     * @param merkleProof calculated using MerkleProof.js
     */
    function claimTokens(uint256 claimAmount, bytes32[] calldata merkleProof)
        external
    {
        uint256 airdropIndex = numberOfAirdrops - 1;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, claimAmount));
        (bool valid, uint256 claimIndex) = MerkleProof.verify(
            merkleProof,
            airdrops[airdropIndex].merkleRoot,
            leaf
        );
        require(valid, "Failed to verify proof");
        require(
            !isClaimed(airdropIndex, claimIndex),
            "Tokens already claimed for this airdrop"
        );
        airdrops[airdropIndex].claimed.set(claimIndex);

        emit Claimed(msg.sender, claimAmount);

        _sweep(msg.sender, claimAmount);
    }

    function getAirdropInfo(uint256 _index)
        public
        view
        returns (
            bytes32 root,
            uint256 claimPeriodEnds,
            bool isComplete
        )
    {
        root = airdrops[_index].merkleRoot;
        isComplete = airdrops[_index].isComplete;
        claimPeriodEnds = airdrops[_index].claimPeriodEnds;
    }

    /**
     * @notice Mark airdrop as completed which allows sweeping of the funds, and creating a new airdrop.
     * @dev Requires claimPeriod of airdrop to have finished
     */
    function _completeAirdrop() internal {
        require(numberOfAirdrops > 0, "No airdrops active");
        uint256 claimPeriodEnds = airdrops[numberOfAirdrops - 1]
            .claimPeriodEnds;
        require(
            block.timestamp > claimPeriodEnds,
            "Airdrop claim period still active"
        );
        airdrops[numberOfAirdrops - 1].isComplete = true;
        emit AirdropComplete(numberOfAirdrops - 1);
    }

    /**
     * @notice Sweeps leftover tokens from airdrop to a destination address
     * @dev Requires last airdrop to have finished
     * @param _destination to send funds to
     * @param _internalBalanceToSweep balance to send to destination from contract
     */
    function _sweepTokens(address _destination, uint256 _internalBalanceToSweep)
        internal
    {
        require(numberOfAirdrops > 0, "No airdrops active");
        require(
            airdrops[numberOfAirdrops - 1].isComplete,
            "Cannot sweep until airdrop is finished"
        );
        uint256 amountToSweep = _internalBalanceToSweep;
        _sweep(_destination, amountToSweep);
        emit Sweep(_destination, amountToSweep);
    }

    /**
     * @dev Makes the transfer function happen regardless of the standard we are using
     */
    function _sweep(address to, uint256 amount) internal virtual {}
}