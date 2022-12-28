/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;


/**
 * Contract to manage multiple sidechains.
 *
 * _Masked and Unmasked Participants_
 * For each sidechain, there are masked and unmasked participants. Unmasked Participants have their
 * addresses listed as being members of the sidechain. Being unmasked allows the participant
 * to vote to add and remove other participants and contest pins.
 *
 * Masked Participants are participants which are listed against a sidechain. They are represented
 * as a salted hash of their address. The participant keeps the salt secret and keeps it off-chain.
 * If they need to unmask themselves, they present their secret salt. This is combined with their
 * sending address to create the salted hash. If this matches their masked participant value then
 * they become an unmasked participant.
 *
 * _Voting_
 * Voting works in the following way:
 * - An Unmasked Participant of a sidechain can submit a proposal for a vote for a certain action
 *  (VOTE_REMOVE_MASKED_PARTICIPANT,VOTE_ADD_UNMASKED_PARTICIPANT, VOTE_REMOVE_UNMASKED_PARTICIPANT,
 *  VOTE_CONTEST_PIN).
 * - Any other Unmasked Participant can then vote on the proposal.
 * - Once the voting period has expired, any Unmasked Participant can request the vote be actioned.
 *
 * The voting algorithm and voting period are configurable and set on a per-sidechain basis at time of
 * construction.
 *
 * _Management Pseudo Chain_
 * In addition to the normal sidechains, there is a Management Pseudo Chain (sidechain ID 0x00). This
 * sidechain is automatically created at contract deployment time. Any unmasked participant of this
 * sidechain can add a new sidechain.
 *
 * _Pinning_
 * Pinning values are put into a map. All participants of a sidechain agree on a sidechain secret
 * and a Pseudo Random Function (PRF) algorithm. The sidechain secret seeds the PRF. A new 256 bit value is
 * generated each time an uncontested pin is posted. The key in the map is calculated using the
 * equation:
 *
 * PRF_Value = PRF.nextValue
 * Key = keccak256(Sidechain Identifier, Previous Pin, PRF_Value).
 *
 * For the initial key for a sidechain, the Previous Pin is 0x00.
 *
 * Masked and unmasked participants of a sidechain observe the pinning map at the Key value waiting
 * for the next pin to be posted to that entry in the map. When the pin value is posted, they can then
 * determine if they wish to contest the pin. To contest the pin, they submit:
 *
 * Previous Key (and hence the previous pin)
 * PRF_Value
 * Sidechain Id
 *
 * Given they know the valid PRF Value, they are able to contest the pin, because they must be a member of the
 * sidechain. Given a good PRF algorithm, this will not expose future or previous PRF values, and hence will
 * not reveal earlier or future pinning values, and hence won't reveal the transaction rate of the sidechain.
 *
 * Once a key is revealed as belonging to a specific sidechain, then Unmasked Participants can vote on
 * whether to reject or keep the pin.
 *
 *
 */
interface SidechainAnonPinningInterface {

    /**
     * Add a sidechain to be managed.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _votingPeriod The number of blocks by which time a vote must be finalized.
     * @param _votingAlgorithmContract The address of the initial contract to be used for all votes.
     */
    function addSidechain(uint256 _sidechainId, address _votingAlgorithmContract, uint64 _votingPeriod) external;


    /**
     * Convert from being a masked to an unmasked participant. The participant themselves is the only
     * entity which can do this change.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain masked participants.
     */
    function unmask(uint256 _sidechainId, uint256 _index, uint256 _salt) external;

    /**
     * Propose that a certain action be voted on.
     * The message sender must be an unmasked member of the sidechain.
     *
     * Types of votes:
     *
     * Value  Action                                 _target                                 _additionalInfo1                 _additionalInfo2
     * 1      Vote to add a masked participant.      Salted Hash of participant's address    Not used                         Not used
     * 2      Vote to remove a masked participant    Salted Hash of participant's address    Index into array of participant  Not used
     * 3      Vote to add an unmasked participant    Address of proposed participant         Not used                         Not used
     * 4      Vote to remove an unmasked participant Address of participant                  Index into array of participant  Not used.
     * 5      Contest pin.                           Pin key                                 Previous pin key                 PRF value.
     *
     * Note for contest a pin: The message sender must be be able to produce information to demonstrate that the
     * contested pin is part of the sidechain by submitting the previous pin key, the current pin key,
     * and a PRF value. Given how the keys are created, this proves that the previous and the current key are linked,
     * which proves that the current pin key is part of the sidechain.
     *
     * The keys must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, PRF Value)
     *
     * Where the PRF Value is the next value to be calculated, based on a shared secret seed off-chain, and the number
     * of values which have been generated.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _action The type of vote: add or remove a masked or unmasked participant, challenge a pin.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     * @param _additionalInfo1 See above.
     * @param _additionalInfo2 See above.
     */
    function proposeVote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, uint256 _additionalInfo1, uint256 _additionalInfo2) external;

    /**
     * Vote for a proposal.
     *
     * If an account has already voted, they can not vote again or change their vote.
     * Only members of the sidechain can vote.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _action The type of vote: add or remove a masked or unmasked participant, challenge a pin.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     * @param _voteFor True if the transaction sender wishes to vote for the action.
     */
    function vote(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _voteFor) external;

    /**
     * Vote for a proposal.
     *
     * If an account has already voted, they can vote again to change their vote.
     * Only members of the sidechain can action votes.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _voteTarget What is being voted on: a masked address or the unmasked address of a participant to be added or removed, or a pin to be disputed.
     */
    function actionVotes(uint256 _sidechainId, uint256 _voteTarget) external;



    /**
     * Add a pin to the pinning map. The key must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, DRBG Value)
     *
     * Where the DRBG Value is the next value to be calculated, based on a shared secret seed
     * off-chain, and the number of values which have been generated.
     *
     *
     * @param _pinKey The pin key calculated as per the equation above.
     * @param _pin Value to be associated with the key.
     */
    function addPin(uint256 _pinKey, bytes32 _pin) external;


    /**
     * Get the pin value for a certain key. The key must be calculated based on the equation:
     *
     * Key = keccak256(Sidechain Identifier, Previous Pin, DRBG Value)
     *
     * Where the DRBG Value is the next value to be calculated, based on a shared secret seed
     * off-chain, and the number of values which have been generated.
     *
     *
     * @param _pinKey The pin key calculated as per the equation above.
     * @return The pin at the key.
     */
    function getPin(uint256 _pinKey) external view returns (bytes32);




    /**
     * Indicate if this contract manages a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return true if the sidechain is managed by this contract.
    */
    function getSidechainExists(uint256 _sidechainId) external view returns (bool);

    /**
     * Get the voting period being used in a sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return Length of voting period in blocks.
     */
    function getVotingPeriod(uint256 _sidechainId) external view returns (uint64);

    /**
     * Indicate if a certain account is an unmasked participant of a sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _participant Account to check to see if it is a participant.
     * @return true if _participant is an unmasked member of the sidechain.
     */
    function isSidechainParticipant(uint256 _sidechainId, address _participant) external view returns(bool);

    /**
     * Get the length of the masked sidechain participants array for a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return number of unmasked sidechain participants.
     */
    function getUnmaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256);

    /**
     * Get address of a certain unmasked sidechain participant. If the participant has been removed
     * at the given index, this function will return the address 0x00.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain participants.
     * @return Address of the participant, or 0x00.
     */
    function getUnmaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(address);

    /**
     * Get the length of the masked sidechain participants array for a certain sidechain.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @return length of the masked sidechain participants array.
     */
    function getMaskedSidechainParticipantsSize(uint256 _sidechainId) external view returns(uint256);

    /*
     * Get the salted hash of a masked sidechain participant. If the participant has been removed
     * or has been unmasked, at the given index, this function will return 0x00.
     *
     * @param _sidechainId The 256 bit identifier of the Sidechain.
     * @param _index The index into the list of sidechain masked participants.
     * @return Salted hash or the participant's address, or 0x00.
     */
    function getMaskedSidechainParticipant(uint256 _sidechainId, uint256 _index) external view returns(uint256);

    /*
     * Return the number of blocks between when a pin is posted and when it can be contested.
     */
    function getPinDisputePeriod() external view returns (uint32);



    event AddedSidechain(uint256 _sidechainId);
    event AddingSidechainMaskedParticipant(uint256 _sidechainId, bytes32 _participant);
    event AddingSidechainUnmaskedParticipant(uint256 _sidechainId, address _participant);

    event ParticipantVoted(uint256 _sidechainId, address _participant, uint16 _action, uint256 _voteTarget, bool _votedFor);
    event VoteResult(uint256 _sidechainId, uint16 _action, uint256 _voteTarget, bool _result);

    event Dump1(uint256 a, uint256 b, address c);
    event Dump2(uint256 a, uint256 b, uint256 c);

}