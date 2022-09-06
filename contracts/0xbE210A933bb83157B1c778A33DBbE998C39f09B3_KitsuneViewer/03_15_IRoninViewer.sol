// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IRoninViewer{

    enum Phase{Init,Cat,Reserve,Claim,Ceremony} //Current launch phase
    function contractState() external view returns(uint roninCount, uint reserved, Phase phase, bool counting, uint time, bool paused, uint blockNumber);
    function myState(bytes32[] memory merkleProof) external view returns(uint myBalance, uint myReserved, uint cooldown, bool _canCatMint, bool _canReserve, uint blockNumber);
    function ronins(uint start_index, uint limit)  external view returns(uint[] memory);
    function myRonins(uint start_index, uint limit)  external view returns(uint[] memory);
}