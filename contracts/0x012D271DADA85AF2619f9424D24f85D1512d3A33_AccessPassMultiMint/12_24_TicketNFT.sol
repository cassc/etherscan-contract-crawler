// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

/**
* @title NFTs for the TicketCompetition to the World Cup for Metaframes
* @author MetaFrames
* @notice This is the NFT contract used as basis to determine the winner of the World Cup Ticket. This is also
* related to the AccessPassNFT
* @dev The flow of the contract is as follows:
* Deployment: Contract is deployed and configured
* -----------------------------------------------
* Airdrop: Minting TicketNFTs to 500 Random Users
*  -airdrop()
* -----------------------------------------------
* Ticket Competition: Selection of the ticket winner
*  -setRegistered() means registration was done off-chain
*  -requestRandomWord() requests the random number from VRF
*  -ticketWinners() then returns the winner
* -----------------------------------------------
* Winners Frozen: When winning tokens are barred from trading their tokens
* -----------------------------------------------
* Trading Enabled: When all trading has been enabled again
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./AccessPassNFT.sol";
import "./interfaces/IAccessPassNFT.sol";
import "./interfaces/ITicketNFT.sol";

contract TicketNFT is Ownable, ERC721Royalty, VRFConsumerBaseV2, ITicketNFT {
    using Strings for uint256;

    uint16 public constant NUMBER_OF_WINNERS = 2;

    /**
    * @dev maxTotalSupply is the amount of NFTs that can be minted
    */
    uint16 public immutable maxTotalSupply;

    /**
    * @dev contractURI is an OpenSea standard. This should point to a metadata that tells who will receive revenues
    * from OpensSea. See https://docs.opensea.io/docs/contract-level-metadata
    */
    string public contractURI;

    /**
    * @dev frozenPeriod is a timestamp for when the ticket winners can start trading again
    */
    uint256 public frozenPeriod;

    /**
    * @dev if set to true, that particular nft is a winner
    */
    mapping(uint256 => bool) public isWinner;

    /**
    * @dev array of winning ids
    */
    uint256[] public ticketWinners;

    /**
    * @dev unrevealedURI is the placeholder token metadata when the reveal has not happened yet
    */
    string public unrevealedURI;

    /**
    * @dev baseURI is the base of the real token metadata after the airdrop
    */
    string public baseURI;

    /**
    * @dev flag that tells if the tickets have been airdropped
    */
    bool public ticketsAirdropped;

    /**
    * @dev flag that tells if the registration has been set
    */
    bool public hasSetRegistration;

    /**
    * @dev Mapping of token id to if the owner of that token id has not registered off-chain.
    * For example:
    * 1. owner of token id 0 has registered, so 0 => false
    * 2. owner of token id 2 has NOT registered, so 1 => true
    * This was purposely made as hasNotRegistered so that we only write for values that have not registered.
    * This is to save gas since there should be more people who have registered than those who have not.
    * The registration comes from an off-chain database.
    */
    mapping(uint16 => bool) private _hasNotRegistered;

    /**
    * @dev the related AccessPassNFT to this contract
    */
    AccessPassNFT public accessPassNFT;

    /**
    * @dev The following variables are needed to request a random value from Chainlink.
    * See https://docs.chain.link/docs/vrf-contracts/
    */
    address public chainlinkCoordinator; // Chainlink Coordinator address
    uint256 public requestId;            // Chainlink request id for the selection of the ticket winner
    uint256 public randomWord;           // Random value received from Chainlink VRF

    /**
    * @dev emitted when the unrevealed uri is set
    * @param oldUnrevealedURI is the unrevealedURI before it was set
    * @param newUnrevealedURI is the unrevealedURI after it was set
    */
    event UnrevealedURISet(string oldUnrevealedURI, string newUnrevealedURI);

    /**
    * @dev emitted when the reveal uri is set
    * @param baseURI is the final base token metadata uri
    */
    event Revealed(string baseURI);

    /**
    * @notice initializes the contract
    * @param unrevealedURI_ is the metadata's uri
    * @param contractURI_ is for OpenSeas compatability
    * @param royaltyAddress receives royalties fee from selling this token
    * @param royaltyFee is the fees taken from second-hand selling. This is expressed in _royaltyFee/1000.
    * So to do 5% means supplying 50 since 50/1000 is 5% (see ERC2981 function _setDefaultRoyalty(address receiver, uint96 feeNumerator))
    * @param accessPassNFT_ is the address of the AccessPassNFT related to this token
    * @param vrfCoordinator_ is the address of the VRF used for getting a random number
    * @param nftHolder is the temporary holder of the NFTs before the airdrop
    * @param frozenPeriod_ is a timestamp for when the ticket winners can start trading again
    */
    constructor(
        string memory unrevealedURI_,
        string memory contractURI_,
        address royaltyAddress,
        uint96 royaltyFee,
        AccessPassNFT accessPassNFT_,
        address vrfCoordinator_,
        address nftHolder,
        uint256 frozenPeriod_
    ) ERC721("Test TicketNFT Version 2", "TTV2")
      VRFConsumerBaseV2(vrfCoordinator_){

        // must have a '/' in the end since the token id follows the '/'
        if (!validateURI(unrevealedURI_)) revert IncorrectValue("unrevealedURI");
        unrevealedURI = unrevealedURI_;

        if (bytes(contractURI_).length == 0) revert EmptyString("contractURI");
        contractURI = contractURI_;

        if(royaltyAddress == address(0)) revert ZeroAddress("royaltyAddress");
        // not checking royaltyFee on purpose here
        _setDefaultRoyalty(royaltyAddress, royaltyFee);

        uint16 maxTotalSupply_ = accessPassNFT_.ticketSupply();
        maxTotalSupply = maxTotalSupply_;

        bytes4 accessPassNFTInterfaceId = type(IAccessPassNFT).interfaceId;
        if(!accessPassNFT_.supportsInterface(accessPassNFTInterfaceId)) revert IncorrectValue("accessPassNFT");
        accessPassNFT = accessPassNFT_;

        if(address(vrfCoordinator_) == address(0)) revert ZeroAddress("vrfCoordinator");
        chainlinkCoordinator = vrfCoordinator_;

        if(nftHolder == address(0)) revert ZeroAddress("nftHolder");

        // sending nfts to nftHolder which will be the eventual owner of the contract who will do the airdrop
        for (uint256 i = 0; i < maxTotalSupply_; i++) {
            _safeMint(nftHolder, i);
        }

        // not checking frozenPeriod_ on purpose here because there's a way to change it later
        frozenPeriod = frozenPeriod_;

    }

    /********************** EXTERNAL ********************************/

    /**
    * @inheritdoc ITicketNFT
    */
    function requestRandomWord(
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) external
        override
        onlyOwner
        onlyDuring(ContractStatus.SET_REGISTRATION)
    {

        // making sure that the request has enough callbackGasLimit to execute
        if (callbackGasLimit < 150_000) revert IncorrectValue("callbackGasLimit");

        /// Call Chainlink to receive a random word
        /// Will revert if subscription is not funded.
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(chainlinkCoordinator);
        requestId = coordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            3, /// Request confirmations
            callbackGasLimit,
            1 /// request 1 random number
        );
        /// Now Chainlink will call us back in a future transaction, see function fulfillRandomWords

        emit RandomWordRequested(requestId);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setContractURI(string memory uri) external override onlyOwner() {
        if (bytes(uri).length == 0) revert EmptyString("contractURI");
        emit ContractURISet(contractURI, uri);
        contractURI = uri;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyFee) external override onlyOwner(){
        if (address(0) == royaltyAddress) revert ZeroAddress("royaltyAddress");
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltiesSet(royaltyAddress, royaltyFee);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setRegistered(
        bool[] calldata hasRegistered_
    ) external
        override
        onlyOwner
        onlyDuring(ContractStatus.AIRDROPPED_TICKETS)
    {
        // sending an empty array means all accounts have registered
        if (hasRegistered_.length == 0) {
            hasSetRegistration = true;
        } else {
            if (hasRegistered_.length != maxTotalSupply) revert IncorrectValue("hasRegistered");
            uint16 notRegisteredCounter = 0;

            for (uint16 i = 0; i < hasRegistered_.length; i++) {
                if (!hasRegistered_[i]) {
                    // only writing for those who have not registered
                    _hasNotRegistered[i] = true;
                    // counting how many accounts have not registred
                    notRegisteredCounter++;
                }
            }

            // ensuring that there are enough registered to have enough winners
            if (maxTotalSupply - notRegisteredCounter < NUMBER_OF_WINNERS) revert IncorrectValue("notRegisteredCounter");
            hasSetRegistration = true;
        }
        emit RegistrationSet(hasRegistered_);
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function setFrozenPeriod(uint256 frozenPeriod_) external override onlyOwner() onlyBefore(ContractStatus.WINNERS_FROZEN) {
        if (frozenPeriod_ < block.timestamp && frozenPeriod_ != 0) revert IncorrectValue("frozenPeriod_");
        emit FrozenPeriodSet(frozenPeriod, frozenPeriod_);
        frozenPeriod = frozenPeriod_;
    }

    /**
    * @notice sets the unrevealed uri
    * @param unrevealedURI_ is the string to check
    */
    function setUnrevealedURI(string memory unrevealedURI_) external onlyOwner() {
        if (!validateURI(unrevealedURI_)) revert IncorrectValue("unrevealedURI_");
        emit UnrevealedURISet(unrevealedURI, unrevealedURI_);
        unrevealedURI = unrevealedURI_;
    }

    /**
    * @notice sets the final base uri
    * @param baseURI_ is the final token metadata uri
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
    * @notice airdrops and reveals the final token metadata uri
    * @param winners are accessPassNFT winners taken off-chain
    * @param baseURI_ is the final token metadata uri
    */
    function airdropAndReveal(uint16[] calldata winners, string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
        airdrop(winners);
    }

    /********************** PUBLIC ********************************/

    /**
    * @inheritdoc ITicketNFT
    */
    function airdrop(
        uint16[] calldata winners
    ) public
    override
    onlyOwner
    onlyDuring(ContractStatus.TICKETS_REVEALED)
    {
        if (winners.length != maxTotalSupply) revert IncorrectValue("winners");

        for (uint256 i = 0; i < winners.length; i++) {
            safeTransferFrom(msg.sender, accessPassNFT.ownerOf(winners[i]), i);
        }

        ticketsAirdropped = true;
        emit TicketsAirdropped(winners);
    }

    /********************** PUBLIC VIEW ********************************/

    /**
    * @notice returns a token metadata's uri
    * @param tokenId is the id of the token being queried
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) revert NonExistentToken();
        string memory baseTokenURI = bytes(baseURI).length == 0 ? unrevealedURI : baseURI;
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function hasRegistered(
        uint16 tokenId
    ) public
        view
        override
        onlyOnOrAfter(ContractStatus.SET_REGISTRATION)
        returns (bool)
    {
        if(tokenId >= maxTotalSupply) revert NonExistentToken();
        return !_hasNotRegistered[tokenId];
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function isAccountWinner(address account) public view override returns (bool){
        for (uint16 i = 0; i < ticketWinners.length; i++) {
            if (ownerOf(ticketWinners[i]) == account) return true;
        }
        return false;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function contractStatus() public view override returns (ContractStatus) {
        if(randomWord != 0) {
            if(block.timestamp < frozenPeriod) return ContractStatus.WINNERS_FROZEN;
            else return ContractStatus.TRADING_ENABLED;
        }
        if(hasSetRegistration) return ContractStatus.SET_REGISTRATION;
        if(ticketsAirdropped) return ContractStatus.AIRDROPPED_TICKETS;
        if(accessPassNFT.ticketsRevealed()) return ContractStatus.TICKETS_REVEALED;
        return ContractStatus.PRE_AIRDROP;
    }

    /**
    * @inheritdoc ITicketNFT
    */
    function totalSupply() public view override returns (uint256) {
        return maxTotalSupply;
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
            interfaceId == type(ITicketNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /********************** INTERNAL ********************************/

    /**
    * @notice sets the final base uri
    * @param baseURI_ is the final base uri
    */
    function _setBaseURI(string memory baseURI_) internal {
        if (!validateURI(baseURI_)) revert IncorrectValue("baseURI_");
        if (bytes(baseURI).length != 0) revert CallingMoreThanOnce();
        baseURI = baseURI_;
        emit Revealed(baseURI_);
    }

    /**
    * @notice check if token is frozen before transferring
    * @inheritdoc ERC721
    * @param from is the address that will give the token
    * @param to is the address that will receive the token
    * @param tokenId is the id being transferred
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        // not allowing winningIds to be transferred when in frozenPeriod
        if (
            block.timestamp < frozenPeriod &&
            isWinner[tokenId]
        ) revert TransferringFrozenToken(tokenId, block.timestamp, frozenPeriod);
    }

    /**
    * @notice sets the winners
    */
    function setWinners() internal {
        // Setup a pool with random values
        uint256 randomPoolSize = 16;
        uint256 batch = 0;
        uint16[] memory randomPool = randArray(randomPoolSize, batch++);

        uint256 counter = 0;
        uint16 randomId;

        for (uint16 i = 0; i < NUMBER_OF_WINNERS; i++) {
            randomId = randomPool[counter++];
            if (counter == randomPoolSize) {
                randomPool = randArray(randomPoolSize, batch++);
                counter = 0;
            }

            // only stays in the loop when the current id has not registered or if the current id already won
            while(_hasNotRegistered[randomId] || isWinner[randomId]) {
                randomId = randomPool[counter++];
                if (counter == randomPoolSize) {
                    randomPool = randArray(randomPoolSize, batch++);
                    counter = 0;
                }
            }

            ticketWinners.push(randomId);
            isWinner[randomId] = true; // Using mapping to keep track for if the id was already chosen as a winner
        }

        emit TicketWinnersFrozen(frozenPeriod);
    }

    /**
    * @notice Chainlink calls us with a random value. (See VRFConsumerBaseV2's fulfillRandomWords function)
    * @dev Note that this happens in a later transaction than the request. This approximately costs 139_000 in gas
    * @param requestId_ is the id of the request from VRF's side
    * @param randomWords is an array of random numbers generated by VRF
    */
    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords
    ) internal override {
        if(requestId != requestId_) revert IncorrectValue("requestId");
        if(randomWord != 0) revert CallingMoreThanOnce();
        randomWord = randomWords[0];
        emit TicketWinnersSelected(randomWords[0]);

        setWinners();
    }

    /**
    * @notice Returns a list of x random numbers, in increments of 16 numbers.
    * So you may receive x random numbers or up to 15 more. The random numbers are between 0 and 499
    * Each batch will be different, you can call multiple times with different batch numbers
    * This routine is deterministic and will always return the same result if randomWord is the same
    * @param max is the max numbers needed in a batch
    * @param batch represents the batch number
    */
    function randArray(
        uint256 max,
        uint256 batch
    ) internal
        view
        returns (uint16[] memory)
    {
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

                // Mask 16 bits, value between 0 .. maxTotalSupply-1
                randomValues[mainCounter * 16 + subCounter] = uint16(randomValue & mask) % maxTotalSupply;

                // Right shift 16 bits into oblivion
                randomValue = randomValue / 2 ** 16;
            }
        }
        return randomValues;
    }

    /**
    * @notice check if uri ends with a '/'
    * @param uri is the string to check
    */
    function validateURI(string memory uri) internal pure returns (bool) {
        // must have a '/' in the end since the token id follows the '/'
        bytes memory bytesURI = bytes(uri);
        return (bytesURI[bytesURI.length - 1] == bytes("/")[0]);
    }

    /********************** MODIFIER ********************************/

    /**
    * @notice functions like a less than to the supplied status
    * @param status is a ContractStatus in which the function must happen before in. For example:
    * setting the frozenPeriod should only happen before the ticketWinners have been selected to ensure that no one
    * messes with the trading period during ContractStatus.WINNERS_FROZEN. To do that add this modifier
    * with the parameter: ContractStatus.WINNERS_FROZEN
    */
    modifier onlyBefore(ContractStatus status) {
        // asserting here because there should be no state before PRE_AIRDROP
        assert(status != ContractStatus.PRE_AIRDROP);
        ContractStatus lastStatus = ContractStatus(uint(status) - 1);
        if (contractStatus() >= status) revert IncorrectContractStatus(contractStatus(), lastStatus);
        _;
    }

    /**
    * @notice the current status must be equal to the status in the parameter
    * @param status is the ContractStatus it must be in
    */
    modifier onlyDuring(ContractStatus status) {
        if (status != contractStatus()) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }


    /**
    * @notice the current status must be greater than or equal to the status in the parameter
    * @param status that the contract must at least be in. For example:
    * getting the nftTiers should only happen when TIERS_RANDOMIZED has already happened. so the parameter will be
    * TIERS_RANDOMIZED, because the function can only work once the status is TIERS_RANDOMIZED or has passed that
    */
    modifier onlyOnOrAfter(ContractStatus status) {
        if (contractStatus() < status) revert IncorrectContractStatus(contractStatus(), status);
        _;
    }
}