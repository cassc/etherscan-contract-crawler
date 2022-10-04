// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

/**
* @title NFTs for the AccessPass to Metaframes Maradona Club
* @author MetaFrames
* @notice This NFT Contract follows the ERC721 Standards and sets one of its properties (tier), on chain.
* The three tiers are as follows: GOLD, SILVER, BRONZE. This contract is also connected to Metaframes' TicketNFT
* which are used to join Metaframes' Ticket Competition for the World Cup Ticket.
* @dev The flow of this contract is as follows:
*    Deployment: Contract is deployed and configured
*    -----------------------------------------------
*    Additional Configuration
*     -setWhitelistSigner()
*     -setPrivateMintingTimestamp() if privateMintingTimestamp is 0
*    -----------------------------------------------
*    Private Minting: Allows accounts in the mint whitelist to mint
*    -----------------------------------------------
*    Public Minting: Allows all accounts to mint
*     -setPublicMintingTimestamp() if publicMintingTimestamp is 0
*    -----------------------------------------------
*    Reveal: Revealing the tiers
*     -randomizeTiers()
*     -nftTiers() then builds the final token metadata
*    -----------------------------------------------
*    Airdrop: Minting TicketNFTs to 500 Random Users
*     -randomizeTickets()
*     -winners() then builds the 500 random users
*     NOTE: the actual minting will happen in the TicketNFT contract
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./WhitelistVerifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./TicketNFT.sol";
import "./interfaces/IAccessPassNFT.sol";
import "./interfaces/ITicketNFT.sol";

contract AccessPassNFT is Ownable, WhitelistVerifier, ERC721Royalty, VRFConsumerBaseV2, IAccessPassNFT {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
    * @dev maxTotalSupply is the amount of NFTs that can be minted
    */
    uint16 public immutable maxTotalSupply;

    /**
    * @dev goldenTierSupply is the amount of GOLD NFTs
    */
    uint16 public immutable goldenTierSupply;

    /**
    * @dev silverTierSupply is the amount of SILVER NFTs
    */
    uint16 public immutable silverTierSupply;

    /**
    * @dev ticketSupply is the amount of TicketNFTs to be airdropped
    */
    uint16 public immutable ticketSupply;

    /**
    * @dev Mapping minter address to amount minted
    */
    struct Minted {
        uint256 publicMinted;
        uint256 privateMinted;
    }
    mapping(address => Minted) private minted;

    /**
    * @dev Keeps track of how many NFTs have been minted
    */
    Counters.Counter public tokenIdCounter;

    /**
    * @dev privateMintingTimestamp sets when privateMinting is enabled. When this is 0,
    * it means all minting is disabled
    */
    uint256 public privateMintingTimestamp;

    /**
    * @dev publicMintingTimestamp sets when publicMinting is enabled. When this is 0, it means
    * public minting is disabled. This value must be greater than the privateMintingTimestamp if this is not 0
    */
    uint256 public publicMintingTimestamp;

    /**
    * @dev price specifies how much eth an account pays for a mint. This is in wei
    */
    uint256 public price;

    /**
    * @dev maxPublicMintable is the maximum an account can publicMint
    */
    uint16 public maxPublicMintable;

    /**
    * @dev flag that tells if the final uri has been set
    */
    bool public tiersRevealed;

    /**
    * @dev unrevealedURI is the placeholder token metadata when the reveal has not happened yet
    */
    string unrevealedURI;

    /**
    * @dev baseURI is the base of the real token metadata after the reveal
    */
    string baseURI;

    /**
    * @dev contractURI is an OpenSea standard. This should point to a metadata that tells who will
    * receive revenues from OpensSea. See https://docs.opensea.io/docs/contract-level-metadata
    */
    string public contractURI;

    /**
    * @dev receives the eth from accounts private and public minting and the royalties from selling the token.
    * All revenues should be sent to this address
    */
    address payable public treasury;

    /**
    * @dev ticketNFT decides the trade freeze when the winners have been selected
    */
    TicketNFT public ticketNFT;

    /**
    * @dev The following variables are needed to request a random value from Chainlink
    * see https://docs.chain.link/docs/vrf-contracts/
    */
    address public chainlinkCoordinator;  // Chainlink coordinator address
    uint256 public tiersRequestId;        // Chainlink request id for tier randomization
    uint256 public tiersRandomWord;       // Random value received from Chainlink VRF
    uint256 public ticketsRequestId;      // Chainlink request id for ticket randomization
    uint256 public ticketsRandomWord;     // Random value received from Chainlink VRF

    /**
    * @notice initializes the contract
    * @param treasury_ is the recipient of eth from private and public minting as well as the recipient for token selling fees
    * @param vrfCoordinator_ is the address of the VRF Contract for generating random number
    * @param maxTotalSupply_ is the max number of tokens that can be minted
    * @param goldenTierSupply_ is the max number of golden tiered tokens
    * @param silverTierSupply_ is the max number of silver tiered tokens
    * @param ticketSupply_ is the max number of tickets that will be airdropped
    * @param privateMintingTimestamp_ is when the private minting will be enabled. NOTE: this could also be set later. 0 is an acceptable value
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in _royaltyFee/10_000.
    * So to do 5% means supplying 500 since 500/10_000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    * @param price_ is the price of a public or private mint in wei
    * @param contractURI_ is an OpenSeas standard and is necessary for getting revenues from OpenSeas
    * @param unrevealedURI_ is the token metadata placeholder while the reveal has not happened yet.
    */
    constructor(
        address payable treasury_,
        address vrfCoordinator_,

        uint16 maxTotalSupply_,
        uint16 goldenTierSupply_,
        uint16 silverTierSupply_,
        uint16 ticketSupply_,

        uint256 privateMintingTimestamp_,

        uint96 royaltyFee,
        uint256 price_,

        string memory contractURI_,
        string memory unrevealedURI_
    )   ERC721("Test Access Pass Version 2", "TAPV2")
        WhitelistVerifier()
        VRFConsumerBaseV2(vrfCoordinator_) {

        if (treasury_ == address(0)) revert ZeroAddress("treasury");
        treasury = treasury_;

        if (vrfCoordinator_ == address(0)) revert ZeroAddress("vrfCoordinator");
        chainlinkCoordinator = vrfCoordinator_;

        if (maxTotalSupply_ == 0) revert IsZero("maxTotalSupply");
        maxTotalSupply = maxTotalSupply_;

        // The following is to ensure that there will be bronzeTierSupply
        require(
            goldenTierSupply_ + silverTierSupply_ < maxTotalSupply_,
                "Tier Supplies must be less than maxTotalSupply"
        );
        if (goldenTierSupply_ == 0) revert IsZero("goldenTierSupply");
        goldenTierSupply = goldenTierSupply_;

        if (silverTierSupply_ == 0) revert IsZero("silverTierSupply");
        silverTierSupply = silverTierSupply_;

        if (ticketSupply_ > maxTotalSupply_) revert IncorrectValue("ticketSupply");
        ticketSupply = ticketSupply_;

        // not checking for zero on purpose here
        privateMintingTimestamp = privateMintingTimestamp_;

        if (royaltyFee == 0) revert IsZero("royaltyFee");
        _setDefaultRoyalty(treasury_, royaltyFee);

        if (price_ == 0) revert IsZero("price");
        price = price_;

        bytes memory bytesUnrevealedURI = bytes(unrevealedURI_);
        if (bytesUnrevealedURI[bytesUnrevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("unrevealedURI");
        unrevealedURI = unrevealedURI_;

        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        contractURI = contractURI_;

        maxPublicMintable = 10;

        // mint one to deployer so the OpenSeas store front can be edited before private minting starts
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        tokenIdCounter.increment();

        // classifying this mint as a private mint
        minted[msg.sender].privateMinted += 1;
    }

    /********************** EXTERNAL ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function privateMint(
        VerifiedSlot calldata verifiedSlot
    ) external
        override
        payable
        onlyDuring(ContractStatus.PRIVATE_MINTING)
    {
        validateVerifiedSlot(msg.sender, minted[msg.sender].privateMinted, verifiedSlot);
        internalMint(msg.sender, msg.value, MintingType.PRIVATE_MINT);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function publicMint() external override payable onlyDuring(ContractStatus.PUBLIC_MINTING) {
        if (minted[msg.sender].publicMinted >= maxPublicMintable) revert ExceedMintingCapacity(minted[msg.sender].publicMinted);
        internalMint(msg.sender, msg.value, MintingType.PUBLIC_MINT);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function randomizeTiers(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.END_MINTING)
    {
        /// Only allow randomize if random word has not been set
        if (tiersRandomWord != 0) revert CanNoLongerCall();

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 40_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords

        tiersRequestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );

        emit TiersRandomWordRequested(tiersRequestId);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function revealTiers(
        string memory revealedURI
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED)
    {
        if (tiersRevealed) revert CallingMoreThanOnce();
        bytes memory bytesRevealedURI = bytes(revealedURI);
        if (bytesRevealedURI[bytesRevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("revealedURI");
        baseURI = revealedURI;
        tiersRevealed = true;

        emit TiersRevealed();
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function randomizeTickets(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyOnOrAfter(ContractStatus.END_MINTING)
    {
        // Only allow randomize if random word has not been set
        if (ticketsRandomWord != 0) revert CanNoLongerCall();

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 40_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        ticketsRequestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );

        emit TicketsRandomWordRequested(ticketsRequestId);
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setWhitelistSigner(address whiteListSigner_) external override onlyOwner {
        _setWhiteListSigner(whiteListSigner_);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setTicketNFT(TicketNFT ticketNFT_) external override onlyOwner() {
        bytes4 ticketNFTInterfaceId = type(ITicketNFT).interfaceId;
        if (!ticketNFT_.supportsInterface(ticketNFTInterfaceId)) revert IncorrectValue("ticketNFT_");

        // should not be able to setTicketNFT if ticketNFTs have been airdropped
        if (address(ticketNFT) != address(0)) {

            // contractStatus 2 means that the tickets have been airdropped so any status before that should be good
            if (uint(ticketNFT.contractStatus()) > 1) revert  CanNoLongerCall();
        }
        emit TicketNFTSet(ticketNFT, ticketNFT_);
        ticketNFT = ticketNFT_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setTreasury(address payable treasury_) external override onlyOwner() {
        if (treasury_ == address(0)) revert ZeroAddress("treasury");
        emit TreasurySet(treasury, treasury_);
        treasury = treasury_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setRoyaltyFee(uint96 royaltyFee) external override onlyOwner() {
        _setDefaultRoyalty(treasury, royaltyFee);

        emit RoyaltyFeesSet(royaltyFee);
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPrice(uint256 price_) external override onlyOwner {
        if (price_ == 0) revert IsZero("price");
        emit PriceSet(price, price_);
        price = price_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setContractURI(string memory contractURI_) external override onlyOwner() {
        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        emit ContractURISet(contractURI, contractURI_);
        contractURI = contractURI_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setUnrevealedURI(string memory unrevealedURI_) external override onlyOwner {
        bytes memory bytesUnrevealedURI = bytes(unrevealedURI_);
        if (bytesUnrevealedURI[bytesUnrevealedURI.length - 1] != bytes("/")[0]) revert IncorrectValue("unrevealedURI");
        emit UnrevealedURISet(unrevealedURI, unrevealedURI_);
        unrevealedURI = unrevealedURI_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPrivateMintingTimestamp(
        uint256 privateMintingTimestamp_
    ) external
        override
        onlyOwner
        onlyBefore(ContractStatus.PRIVATE_MINTING)
    {
        if (
            privateMintingTimestamp_ >= publicMintingTimestamp &&
            privateMintingTimestamp_ != 0 &&
            publicMintingTimestamp != 0
        ) revert IncorrectValue("privateMintingTimestamp");
        emit PrivateMintingTimestampSet(privateMintingTimestamp, privateMintingTimestamp_);
        privateMintingTimestamp = privateMintingTimestamp_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setPublicMintingTimestamp(
        uint256 publicMintingTimestamp_
    ) external
        override
        onlyOwner
        onlyBefore(ContractStatus.PUBLIC_MINTING)
    {
        if (
            publicMintingTimestamp_ < privateMintingTimestamp &&
            publicMintingTimestamp_ != 0
        ) revert IncorrectValue("publicMintingTimestamp");

        emit PublicMintingTimestampSet(publicMintingTimestamp, publicMintingTimestamp_);
        publicMintingTimestamp = publicMintingTimestamp_;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function setMaxPublicMintable(uint16 maxPublicMintable_) external override onlyOwner {
        if (maxPublicMintable_ == 0) revert IsZero("maxPublicMintable");
        emit MaxPublicMintableSet(maxPublicMintable, maxPublicMintable_);
        maxPublicMintable = maxPublicMintable_;
    }

    /********************** EXTERNAL VIEW ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function mintedBy(address minter) external view override returns (uint256) {
        if(minter == address(0)) revert ZeroAddressQuery();
        return minted[minter].privateMinted + minted[minter].publicMinted;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function mintedBy(address minter, MintingType mintingType) external view override returns (uint256) {
        if(minter == address(0)) revert ZeroAddressQuery();
        if (mintingType == MintingType.PRIVATE_MINT) return minted[minter].privateMinted;
        else return minted[minter].publicMinted;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function nftTier(
        uint256 tokenId
    ) external
        view
        override
        onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED)
        returns (uint16 tier)
    {
        if (!_exists(tokenId)) revert NonExistentToken();
        return nftTiers()[tokenId];
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function ticketsRevealed() external view override returns(bool) {
        return ticketsRandomWord != 0;
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function winners() external view override onlyOnOrAfter(ContractStatus.TICKETS_RANDOMIZED) returns (uint16[] memory) {

        // Setup a pool with random values
        uint256 randomPoolSize = 100;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);

        /// Setup an array with nfts that will be returned
        uint16[] memory nfts = new uint16[](maxTotalSupply);
        uint256 counter;
        uint256 randomId;

        // Assign 500 winners
        for(uint256 i = 0; i < ticketSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) {
                randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) {
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) {
                    randomPool = randArray(ticketsRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = 1;     // Winner
        }

        return nfts;
    }

    /********************** PUBLIC ********************************/

    /**
    * @inheritdoc IAccessPassNFT
    */
    function totalSupply() public view override returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function contractStatus() public view override returns (ContractStatus) {
        if (ticketsRandomWord != 0) return ContractStatus.TICKETS_RANDOMIZED;
        if (tiersRevealed) return ContractStatus.TIERS_REVEALED;
        if (tiersRandomWord != 0) return ContractStatus.TIERS_RANDOMIZED;
        if (maxTotalSupply == tokenIdCounter.current()) return ContractStatus.END_MINTING;
        if (
            block.timestamp >= privateMintingTimestamp &&
            privateMintingTimestamp != 0 &&
            (
            block.timestamp < publicMintingTimestamp ||
            publicMintingTimestamp == 0
            )
        ) return ContractStatus.PRIVATE_MINTING;
        if (
            block.timestamp >= publicMintingTimestamp &&
            publicMintingTimestamp != 0 &&
            privateMintingTimestamp != 0
        ) return ContractStatus.PUBLIC_MINTING;
        return ContractStatus.NO_MINTING;
    }

    /**
    * @notice returns the unrevealed uri when the reveal hasn't happened yet and when it has, returns the real uri
    * @param tokenId should be a minted tokenId owned by an account
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();

        if (!tiersRevealed) return string(abi.encodePacked(unrevealedURI, tokenId.toString(), ".json"));
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
    * @inheritdoc IAccessPassNFT
    */
    function nftTiers() public view override onlyOnOrAfter(ContractStatus.TIERS_RANDOMIZED) returns (uint16[] memory) {
        /// Setup a pool with random values
        uint256 randomPoolSize = 500;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);

        /// Setup an array with nfts that will be returned
        uint16[] memory nfts = new uint16[](maxTotalSupply);
        uint256 counter;    /// Loop counter to check when we exhaust our random pool and need to fill it again
        uint256 randomId;   /// Random NFT id

        /// Assign goldenTierSupply golden tier nfts
        for(uint256 i = 0; i < goldenTierSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) { /// Loop while the NFT id already has a tier assigned
                randomId = randomPool[counter++]; /// If we exhaust the random pool, fill it again
                if (counter == randomPoolSize) {
                    randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = uint16(Tier.GOLD);
        }

        // Assign silverTierSupply silver tier nfts
        for(uint256 i = 0; i < silverTierSupply; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                counter = 0;
            }
            while(nfts[randomId] != 0) { /// Loop while the NFT id already has a tier assigned
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) { /// If we exhaust the random pool, fill it again
                    randomPool = randArray(tiersRandomWord, randomPoolSize, batch++);
                    counter = 0;
                }
            }
            nfts[randomId] = uint16(Tier.SILVER);
        }

        // All remaining nfts are automatically bronze because they are already set to 0
        return nfts;
    }

    /**
    * @inheritdoc IERC165
    */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Royalty, IERC165)
    returns (bool)
    {
        return
            interfaceId == type(IAccessPassNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /********************** INTERNAL ********************************/

    /**
    * @notice check if the owner has a winning ticket
    * @inheritdoc ERC721
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        if (address(ticketNFT) != address(0)) {
            uint256 frozenPeriod = ticketNFT.frozenPeriod();
            // not allowing winners to transfer if they only have one AccessPassNFT
            if (
                block.timestamp < frozenPeriod &&
                ticketNFT.isAccountWinner(from) &&
                balanceOf(from) == 1
            ) revert TransferringFrozenAccount(from, block.timestamp, frozenPeriod);
        }
    }

    /**
    * @notice pays treasury the amount
    * @param account is the account that paid
    * @param amount is how much the account has paid
    */
    function payTreasury(address account, uint256 amount) internal {
        (bool success, ) = treasury.call{value: amount}("");
        require (success, "Could not pay treasury");
        emit TreasuryPaid(account, amount);
    }

    /**
    * @notice internal mint function
    * @param to is the account receiving the NFT
    * @param amountPaid is the amount that the account has paid for the mint
    * @param mintingType could be PRIVATE_MINT or PUBLIC_MINT
    */
    function internalMint(
        address to,
        uint256 amountPaid,
        MintingType mintingType
    ) internal
        onlyBefore(ContractStatus.END_MINTING)
    {
        if (amountPaid != price) revert IncorrectValue("amountPaid");
        uint256 tokenId = tokenIdCounter.current();

        payTreasury(to, amountPaid);

        tokenIdCounter.increment();
        if (MintingType.PRIVATE_MINT == mintingType) {
            minted[to].privateMinted += 1;
        } else {
            minted[to].publicMinted += 1;
        }

        _safeMint(to, tokenId);
    }

    /**
    * @notice Chainlink calls us with a random value. (See VRFConsumerBaseV2's fulfillRandomWords function)
    * @dev Note that this happens in a later transaction than the request.
    * @param requestId is the id of the request from VRF's side
    * @param randomWords is an array of random numbers generated by VRF
    */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (requestId == 0) revert IsZero("requestId");
        if (requestId == tiersRequestId) {
            if (tiersRandomWord != 0) revert CallingMoreThanOnce();
            tiersRandomWord = randomWords[0]; /// Set the random value received from Chainlink
            emit TiersRandomized(tiersRandomWord);
        } else if (requestId == ticketsRequestId) {
            if (ticketsRandomWord != 0) revert CallingMoreThanOnce();
            ticketsRandomWord = randomWords[0]; /// Set the random value received from Chainlink
            emit TicketsRandomized(ticketsRandomWord);
        }
    }

    /**
    * @notice Returns a list of x random numbers, in increments of 16 numbers.
    * So you may receive x random numbers or up to 15 more. The random numbers are between 0 and 499
    * Each batch will be different, you can call multiple times with different batch numbers
    * This routine is deterministic and will always return the same result if randomWord is the same
    * @param randomWord can only be tiersRandomWord and ticketsRandomWord
    * @param max is the max numbers needed in a batch
    * @param batch represents the batch number
    */
    function randArray(uint256 randomWord, uint256 max, uint256 batch) internal view returns (uint16[] memory) {
        // First make sure the random chainlinkVRF value is initialized
        if (randomWord == 0) revert IsZero("randomWord");
        uint256 mask = 0xFFFF;   // 0xFFFF == [1111111111111111], masking the last 16 bits

        uint256 mainCounterMax = max / 16;
        if (max % 16 > 0) {
            mainCounterMax +=1;
        }
        uint256 batchOffset = (batch * mainCounterMax * 16);
        uint16[] memory randomValues = new uint16[](mainCounterMax * 16);
        for (uint256 mainCounter = 0; mainCounter < mainCounterMax; mainCounter++) {
            uint256 randomValue = uint256(keccak256(abi.encode(randomWord, mainCounter + batchOffset)));
            for (uint256 subCounter = 0; subCounter < 16; subCounter++) {
                randomValues[mainCounter * 16 + subCounter] = uint16(randomValue & mask) % maxTotalSupply;   // Mask 16 bits, value between 0 .. MAX_TOTAL_SUPPLY-1
                randomValue = randomValue / 2 ** 16;     // Right shift 16 bits into oblivion
            }
        }
        return randomValues;
    }

    /********************** MODIFIERS ********************************/

    /**
    * @notice functions like a less than to the supplied status
    * @param status is a ContractStatus in which the function must happen before in. For example:
    * setting the privateMintTimestamp should only happen before private minting starts to ensure that no one
    * messes with the privateMint settings during ContractStatus.PrivateMinting. To do that add this modifier
    * with the parameter: ContractStatus.PrivateMinting
    */
    modifier onlyBefore(ContractStatus status) {
        // asserting here because there should be no state before NO_MINTING
        assert(status != ContractStatus.NO_MINTING);
        ContractStatus lastStatus = ContractStatus(uint(status) - 1);
        if (contractStatus() >= status) revert IncorrectContractStatus(contractStatus(), lastStatus);
        _;
    }

    /**
    * @notice functions like a an equal to the supplied status
    * @param status is the ContractStatus it must be in
    */
    modifier onlyDuring(ContractStatus status) {
        if (contractStatus() != status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }

    /**
    * @notice functions like a greater than or equal to. The current status must be the same as or happened after the parameter.
    * @param status that the contract must at least be in. For example:
    * getting the nftTiers should only happen when TIERS_RANDOMIZED has already happened. so the parameter will be
    * TIERS_RANDOMIZED, because the function can only work once the status is TIERS_RANDOMIZED or has passed that
    */
    modifier onlyOnOrAfter(ContractStatus status) {
        if (contractStatus() < status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }
}