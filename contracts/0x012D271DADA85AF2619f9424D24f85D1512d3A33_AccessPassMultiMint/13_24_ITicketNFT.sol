// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @title Required interface for a TicketNFT compliant contract
* @author Oost & Voort, Inc
*/

interface ITicketNFT is IERC165 {

    /**
    * @dev The following are the stages of the contract in order:
    * PRE_AIRDROP: Before the airdrop has happened
    * TICKETS_REVEALED: when accessPassNFT has already set who the TicketWinners will be
    * AIRDROPPED_TICKETS: when the nfts have been airdropped
    * SET_REGISTRATION: when the _hasNotRegistered have been filled up
    * WINNERS_FROZEN: When the winners have been frozen from doing transfers
    * TRADING_ENABLED: When all trading has been enabled again
    */
    enum ContractStatus {
        PRE_AIRDROP,
        TICKETS_REVEALED,
        AIRDROPPED_TICKETS,
        SET_REGISTRATION,
        WINNERS_FROZEN,
        TRADING_ENABLED
    }

    /**
    * @dev emitted when the owner has changed the contract uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event ContractURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the owner changes the royalties
    * @param newRoyaltyAddress is the new royalty address that will receive the royalties.
    * @param newRoyalties is the new royalties set by the owner
    */
    event RoyaltiesSet(address newRoyaltyAddress, uint96 newRoyalties);

    /**
    * @dev emitted when the frozenPeriod has been set
    * @param oldTimestamp is the old timestamp for when the frozenPeriod was set
    * @param newTimestamp is the timestamp for when the frozenPeriod will now correspond as
    */
    event FrozenPeriodSet(uint256 oldTimestamp, uint256 newTimestamp);

    /**
    * @dev the following events must be done in order
    */

    /**
    * @dev emitted when the airdrop happens
    * @param winners is the ids of winners from AccessPassNFT. See AccessPassNFT's winners function for more information.
    */
    event TicketsAirdropped(uint16[] winners);

    /**
    * @dev emitted when the registration has been set
    * @param hasRegistered is an array boolean that represents if the onwer of that index has registered off-chain
    */
    event RegistrationSet(bool[] hasRegistered);

    /**
    * @dev emitted when a random number has been requested from VRF
    * @param requestId is the id sent back by VRF to keep track of the request
    */
    event RandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when a ticket winner has been selected
    * @param randomWord is used to determine the TicketWinner
    */
    event TicketWinnersSelected(uint256 randomWord);

    /**
    * @dev emitted when the trading for winners have been frozen
    * @param frozenTimestamp is until when trading for winning nfts have been frozen for
    */
    event TicketWinnersFrozen(uint256 frozenTimestamp);

    /**
    * @dev reverted with this error when the address being supplied is Zero Address
    * @param addressName is for whom the Zero Address is being set for
    */
    error ZeroAddress(string addressName);

    /**
    * @dev reverted with this error when a view function is being used to look for a nonExistent Token
    */
    error NonExistentToken();

    /**
    * @dev reverted with this error when a function is being called more than once
    */
    error CallingMoreThanOnce();

    /**
    * @dev reverted with this error when a variable has an incorrect value
    * @param variableName is the name of the variable with an incorrect value
    */
    error IncorrectValue(string variableName);

    /**
    * @dev reverted with this error when a string being supplied should not be empty
    * @param stringName is the name of the string being supplied with an empty value
    */
    error EmptyString(string stringName);

    /**
    * @dev reverted with this error when a function being called should not be called with the current Contract Status
    * @param currentStatus is the contract's current status
    * @param requiredStatus is the status the current must be in for the function to not revert
    */
    error IncorrectContractStatus(ContractStatus currentStatus, ContractStatus requiredStatus);

    /**
    * @dev reverted with this error when transferring a winningId during frozenPeriod
    * @param tokenId is the id being transferred
    * @param currentTimestamp is the current block's timestamp
    * @param requiredTimestamp is the timestamp the block must at least be in
    */
    error TransferringFrozenToken(uint256 tokenId, uint256 currentTimestamp, uint256 requiredTimestamp);

    /**
    * @notice airdrops to accessPassNFT winners
    * @param winners are accessPassNFT winners taken off-chain
    */
    function airdrop(
        uint16[] calldata winners
    ) external;

    /**
    * @notice requests a random word from VRF to be used for selecting a ticket winner
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 139_000 gas is used up solely
    * by fulfillRandomWords.
    */
    function requestRandomWord(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the contract uri
    * @param uri points to a json file that follows OpenSeas standard (see https://docs.opensea.io/docs/contract-level-metadata)
    */
    function setContractURI(string memory uri) external;

    /**
    * @notice sets the royalty fee for the second hand market selling
    * @param royaltyAddress is the recepient of royalty fees from second hand market.
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in a _royaltyFee/1000.
    * So to do 5% means supplying 50 since 50/1000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    */
    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyFee) external;

    /**
    * @notice sets the ids of the people who have not registered
    * @dev It is important to do this before requesting a random word. To make it cheaper gas-wise, sending an empty
    * array signifies that all token owners registered off-chain. An explanation of what the array of hasRegistered looks
    * like will follow:
    * if the owner of token id 0 has registered in the array it will show as true,
    * so [true, ...]
    * if the owner of token id 1 has not registered in the array it will show as false
    * so [true, false, ...]
    * and so on..
    * @param hasRegistered_ is an array of boolean that tells if the owner of the id has registered off-chain
    */
    function setRegistered(bool[] calldata hasRegistered_) external;

    /**
    * @notice sets the frozenPeriod for when trading winning token ids is disabled
    * @param frozenPeriod_ is a timestamp for when the ticket winners can start trading again
    */
    function setFrozenPeriod(uint256 frozenPeriod_) external;


    /**
    * @notice returns if the token id has registered or not
    * @param tokenId is the id of the token being queried
    */
    function hasRegistered(
        uint16 tokenId
    ) external view returns (bool);

    /**
    * @notice Returns if the address owns a winning nft
    * @param account is the queried address
    */
    function isAccountWinner(address account) external view returns (bool);

    /**
    * @notice returns the current contract status of the NFT
    */
    function contractStatus() external view returns (ContractStatus);

    /**
    * @notice returns the current supply of the NFT
    */
    function totalSupply() external view returns (uint256);
}