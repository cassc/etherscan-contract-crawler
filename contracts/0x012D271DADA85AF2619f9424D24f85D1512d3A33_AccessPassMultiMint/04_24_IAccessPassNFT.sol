// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../TicketNFT.sol";
import "./IVerifiedSlot.sol";

/**
* @title Required interface for an AccessPassNFT compliant contract
* @author Oost & Voort, Inc
*/

interface IAccessPassNFT is IERC165, IVerifiedSlot {
    /**
    * @dev The following are the stages of the contract in order:
    * NO_MINTING: Minting is not yet allowed
    * PRIVATE_MINTING: Only people in the mint whitelist can mint
    * PUBLIC_MINTING: Everyone can mint
    * END_MINTING: When everything's been minted already
    * TIERS_RANDOMIZED: When a random number has been set for the tiers
    * TIERS_REVEALED: When the final token metadata has been uploaded to IPFS
    * TICKETS_RANDOMIZED: When a random number has been set for the tickets airdrop
    */
    enum ContractStatus {
        NO_MINTING,
        PRIVATE_MINTING,
        PUBLIC_MINTING,
        END_MINTING,
        TIERS_RANDOMIZED,
        TIERS_REVEALED,
        TICKETS_RANDOMIZED
    }

    /**
    * @dev Minting types are explained below:
    * PRIVATE_MINT: minted using the private mint function
    * PUBLIC_MINT: minted using the public mint function
    */
    enum MintingType {PRIVATE_MINT, PUBLIC_MINT}

    /**
    * @dev The on-chain property of the nft that is determined by a random number
    */
    enum Tier {BRONZE, SILVER, GOLD}

    /**
    * @dev emitted when the owner has set the private minting timestamp
    * @param oldTimestamp is for what the timestamp used to be
    * @param newTimestamp is the new value
    */
    event PrivateMintingTimestampSet(uint256 oldTimestamp, uint256 newTimestamp);


    /**
    * @dev emitted when the owner has set the public minting timestamp
    * @param oldTimestamp is for what the timestamp used to be
    * @param newTimestamp is the new value
    */
    event PublicMintingTimestampSet(uint256 oldTimestamp, uint256 newTimestamp);

    /**
    * @dev emitted when the owner has changed the max number of nfts a public user can mint
    * @param oldMaxPublicMintable is the old value for the maximum a public account can mint
    * @param newMaxPublicMintable is the new value for the maximum a public account can mint
    */
    event MaxPublicMintableSet(uint16 oldMaxPublicMintable, uint16 newMaxPublicMintable);


    /**
    * @dev emitted when the owner changes the treasury
    * @param oldTreasury is the old value for the treasury
    * @param newTreasury is the new value for the treasury
    */
    event TreasurySet(address oldTreasury, address newTreasury);

    /**
    * @dev emitted when the owner changes the minting price
    * @param oldPrice is the price the minting was set as
    * @param newPrice is the new price minting will cost as
    */
    event PriceSet(uint256 oldPrice, uint256 newPrice);

    /**
    * @dev emitted when the owner changes the royalties
    * @param newRoyalties is the new royalties set by the owner
    */
    event RoyaltyFeesSet(uint96 newRoyalties);

    /**
    * @dev emitted when the owner has changed the contract uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event ContractURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the owner has changed the unrevealed uri
    * @param oldURI is the uri it was set as before
    * @param newURI is the uri it is now set in
    */
    event UnrevealedURISet(string oldURI, string newURI);

    /**
    * @dev emitted when the TicketNFT has been set
    * @param oldTicketNFT is the old TicketNFT it was pointing to
    * @param newTicketNFT is the TicketNFT it is now pointing to
    */
    event TicketNFTSet(TicketNFT oldTicketNFT, TicketNFT newTicketNFT);

    /**
    * @dev emitted when the treasury has been paid in ETH
    * @param account is the account that paid the treasury
    * @param amount is how much ETH the account sent to the treasury
    */
    event TreasuryPaid(address indexed account, uint256 amount);

    /**
    * @dev the following events must be done in order
    */

    /**
    * @dev emitted when the owner has requested a random word from VRF to set the tiers of each NFT
    * @param requestId is the id set by VRF
    */
    event TiersRandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when VRF has used fulfillRandomness to set the random number
    * @param randomWord is the randomWord given back in a callback by VRF
    */
    event TiersRandomized(uint256 randomWord);

    /**
    * @dev emitted when the owner has put the final token metadata uri for the nfts
    */
    event TiersRevealed();

    /**
    * @dev emitted when the owner has requested a random word from VRF to set who will be airdropped TicketNFTs
    * @param requestId is the id set by VRF
    */
    event TicketsRandomWordRequested(uint256 requestId);

    /**
    * @dev emitted when VRF has used fulfillRandomness to set the random number
    * @param randomWord is the randomWord given back in a callback by VRF
    */
    event TicketsRandomized(uint256 randomWord);

    /**
    * @dev reverted with this error when the address being supplied is Zero Address
    * @param addressName is for whom the Zero Address is being set for
    */
    error ZeroAddress(string addressName);

    /**
    * @dev reverted with this error when a view function is asking for a Zero Address' information
    */
    error ZeroAddressQuery();

    /**
    * @dev reverted with this error when a view function is being used to look for a nonExistent Token
    */
    error NonExistentToken();

    /**
    * @dev reverted with this error when a function is being called more than once
    */
    error CallingMoreThanOnce();

    /**
    * @dev reverted with this error when a function should no longer be called
    */
    error CanNoLongerCall();

    /**
    * @dev reverted with this error when a variable being supplied is valued 0
    * @param variableName is the name of the variable being supplied with 0
    */
    error IsZero(string variableName);

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
    * @dev reverted with this error when an account that has won is trying to transfer his or her last AccessPassNFT
    * during WINNERS_FROZEN in TicketNFT
    * @param account is the address trying to transfer
    * @param currentTimestamp is the current block's timestamp
    * @param requiredTimestamp is the timestamp the block must at least be in
    */
    error TransferringFrozenAccount(address account, uint256 currentTimestamp, uint256 requiredTimestamp);

    /********************** EXTERNAL ********************************/

    /**
    * @notice private mints for people in the whitelist
    * @param verifiedSlot is a signed message by the whitelist signer that presents how many the minter can mint
    */
    function privateMint(VerifiedSlot calldata verifiedSlot) external payable;

    /*
    * @notice public mints for anyone
    */
    function publicMint() external payable;

    /**
    * @notice Randomize the NFT. This requests a random Chainlink value, which causes the tier of each nft id to be known.
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 29_000 is used up solely by
    * fulfillRandomWords
    */
    function randomizeTiers(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the base URI for the token metadata
    * @dev This can only happen once after the generation of the token metadata in unison with the winners function.
    * @param revealedURI must end in a '/' (slash), because the tokenURI expects it to end in a slash.
    */
    function revealTiers(string memory revealedURI) external;

    /**
    * @notice Randomize the tickets. This requests a random Chainlink value, which causes the winners to be known.
    * @dev See https://docs.chain.link/docs/vrf-contracts/#configurations for Chainlink VRF documentation
    * @param subscriptionId The chainlink subscription id that pays for the call to Chainlink, needs to be setup with ChainLink beforehand
    * @param gasLane The maximum gas price you are willing to pay for a Chainlink VRF request in wei
    * @param callbackGasLimit How much gas to use for the callback request. Approximately 31_000 gas is used up
    * solely by fulfillRandomWords.
    */
    function randomizeTickets(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external;

    /**
    * @notice sets the whitelist signer
    * @dev immediately do this after deploying the contract
    * @param whiteListSigner_ is the signer address for verifying the minting slots
    */
    function setWhitelistSigner(address whiteListSigner_) external;

    /**
    * @notice sets the ticketNFT
    * @dev set this before selecting the TicketWinners in TicketNFT
    * @param ticketNFT_ is the TicketNFT that selects the ticketWinners
    */
    function setTicketNFT(TicketNFT ticketNFT_) external;

    /**
    * @notice sets the recipient of the eth from public and private minting and the royalty fees
    * @dev setRoyaltyFee right after setting the treasury
    * @param treasury_ could be an EOA or a gnosis contract that receives eth and royalty fees
    */
    function setTreasury(address payable treasury_) external;

    /**
    * @notice sets the royalty fee for the second hand market selling
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in a _royaltyFee/10_000.
    * So to do 5% means supplying 500 since 500/10_000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    */
    function setRoyaltyFee(uint96 royaltyFee) external;

    /**
    * @notice sets the price of minting. the amount is sent to the treasury right after the minting
    * @param price_ is expressed in wei
    */
    function setPrice(uint256 price_) external;

    /**
    * @notice sets the contract uri
    * @param contractURI_ points to a json file that follows OpenSeas standard (see https://docs.opensea.io/docs/contract-level-metadata)
    */
    function setContractURI(string memory contractURI_) external;

    /**
    * @notice sets the unrevealedURI
    * @param unrevealedURI_ points to a json file with the placeholder image inside
    */
    function setUnrevealedURI(string memory unrevealedURI_) external;

    /**
    * @notice sets the private minting timestamp
    * @param privateMintingTimestamp_ is when private minting is enabled. Setting this to zero disables all minting
    */
    function setPrivateMintingTimestamp(uint256 privateMintingTimestamp_) external;

    /**
    * @notice sets the public minting timestamp
    * @param publicMintingTimestamp_ is when public minting will be enabled.
    * Setting this to zero disables public minting.
    * If set, public minting must happen after private minting
    */
    function setPublicMintingTimestamp(uint256 publicMintingTimestamp_) external;

    /**
    /* @notice sets how many a minter can public mint
    /* @param maxPublicMintable_ is how many a public account can mint
    */
    function setMaxPublicMintable(uint16 maxPublicMintable_) external;

    /********************** EXTERNAL VIEW ********************************/

    /**
    * @notice returns the count an account has minted
    * @param minter is for the account being queried
    */
    function mintedBy(address minter) external view returns (uint256);

    /**
    * @notice returns the count an account has minted per type
    * @param minter is for the account being queried
    * @param mintingType is the type of minting expected
    */
    function mintedBy(address minter, MintingType mintingType) external view returns (uint256);

    /**
    * @notice Returns the tier for an nft id
    * @param tokenId is the id of the token being queried
    */
    function nftTier(uint256 tokenId) external view returns (uint16 tier);

    /**
    * @notice Returns true if the ticketsRandomWord has been set in the VRF Callback
    * @dev this is used by TicketNFT as a prerequisite for the airdrop. See TicketNFT for more info.
    */
    function ticketsRevealed() external view returns(bool);

    /**
    * @notice Returns an array of all NFT id's, with 500 winners, indicated by 1. The others are indicated by 0.
    */
    function winners() external view returns (uint16[] memory);

    /**
    * @notice returns the current supply of the NFT
    */
    function totalSupply() external view returns (uint256);

    /**
    * @notice returns the current contract status of the NFT
    */
    function contractStatus() external view returns (ContractStatus);

    /**
    * @notice Returns an array with all nft id's and their tier
    * @dev This function works by filling a pool with random values. When we exhaust the pool,
    * we refill the pool again with different values. We do it like this because we don't
    * know in advance how many random values we need.
    */
    function nftTiers() external view returns (uint16[] memory);
}