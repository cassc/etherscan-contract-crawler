// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ILoversNft.sol";
import "./Adminable.sol";

//  ╭╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭╮╱╭╮╱╱╱╱╭╮╱╱╱╱╱╭━━━━┳╮╱╱╱╱╱╭━╮╭━╮
//  ┃┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃┃╱┃┃╱╱╱╱┃┃╱╱╱╱╱┃╭╮╭╮┃┃╱╱╱╱╱┃┃╰╯┃┃
//  ┃┃╱╱╭━━┳╮╭┳━━┳━┳━━╮┃┃╱┃┣━╮╭━╯┣━━┳━╮╰╯┃┃╰┫╰━┳━━╮┃╭╮╭╮┣━━┳━━┳━╮
//  ┃┃╱╭┫╭╮┃╰╯┃┃━┫╭┫━━┫┃┃╱┃┃╭╮┫╭╮┃┃━┫╭╯╱╱┃┃╱┃╭╮┃┃━┫┃┃┃┃┃┃╭╮┃╭╮┃╭╮╮
//  ┃╰━╯┃╰╯┣╮╭┫┃━┫┃┣━━┃┃╰━╯┃┃┃┃╰╯┃┃━┫┃╱╱╱┃┃╱┃┃┃┃┃━┫┃┃┃┃┃┃╰╯┃╰╯┃┃┃┃
//  ╰━━━┻━━╯╰╯╰━━┻╯╰━━╯╰━━━┻╯╰┻━━┻━━┻╯╱╱╱╰╯╱╰╯╰┻━━╯╰╯╰╯╰┻━━┻━━┻╯╰╯

contract LoversNft is ILoversNft, ERC721A, Adminable, ReentrancyGuard, Pausable {
    /**
     * Maximum number of supply
     */
    uint256 public maximumSupply;

    /**
     *  To make token uri immutable permanently
     */
    bool public permanent;

    modifier notPermanent() {
        if (permanent) {
            revert ImmutableState();
        }
        _;
    }

    /**
     *  Minting rounds
     */
    mapping(uint16 => Round) rounds;

    uint256 public revealBlockOffset = 3000;

    /**
     *  Current round number
     */
    uint16 public currentRoundNumber;

    address private _receiver;

    /**
     * Base uri for token uri
     */
    string public baseURI;

    /**
     * Default unrevealed uri
     */
    string private defaultUnrevealedURI;

    constructor(
        address receiver,
        uint256 maxSupply,
        string memory _baseUri,
        string memory _defaultUnrevealedURI,
        address admin_
    ) ERC721A("Lovers Under The Moon", "LOVER")
        Adminable(admin_)
        Pausable()
    {
        _receiver = receiver;
        maximumSupply = maxSupply;
        baseURI = _baseUri;
        defaultUnrevealedURI = _defaultUnrevealedURI;
    }

    /**
     *  Create a new minting round
     *  For owner only
     */
    function newRound(
        MintingType mintingType,
        uint256 supply,   // total supply for the round
        uint256 startTime, // round starting time
        uint256 endTime, // round ending time
        uint256 mintingFee, // minting fee
        uint16 maxMintingQuantity, // maximum number of minting quantity per address
        bool revealed // reveal image or not
    ) external onlyOwner notPermanent {
        // wrap-up the existing round
        if (currentRoundNumber > 0) {
            endRound();
        }

        uint256 maxMintingId = _nextTokenId() + supply - 1;

        // the maxMintingId of new round can NOT exceed the maximumSupply
        if (maxMintingId > maximumSupply) {
            revert BadRequest("maxMintingId exceed the maximumSupply");
        }

        if (startTime >= endTime) {
            revert BadRequest("endTime should be bigger");
        }

        uint16 newRoundNumber = ++currentRoundNumber;

        rounds[newRoundNumber] = Round({
            roundNumber: newRoundNumber,
            mintingType: mintingType,
            startTime: startTime,
            endTime: endTime,
            maxMintingQuantity: maxMintingQuantity,
            mintingFee: mintingFee,

            maxMintingId: maxMintingId,
            startId: _nextTokenId(),
            lastMintedId: 0,
            tokenURIPrefix: "",
            revealed: revealed,
            revealBlockNumber: 0,
            randomSelection: 0,
            closedTime: 0
        });

        emit NewRoundCreated(newRoundNumber);
    }

    /**
     * End the current round
     * For owner and admin
     */
    function endRound() public onlyOwnerOrAdmin {
        Round storage currentRound = rounds[currentRoundNumber];
        currentRound.lastMintedId = _nextTokenId() - 1;
        currentRound.closedTime = block.timestamp;

        emit RoundEnded(currentRoundNumber);
    }

    /**
     *  Get the detail of the current round
     */
    function getCurrentRound() public view returns (Round memory) {
        return getRound(currentRoundNumber);
    }

    /**
     *  Get round detail
     */
    function getRound(uint16 roundNumber) public view returns (Round memory) {
        return rounds[roundNumber];
    }

    /**
     *  Get the STATE of the contract
     */
    function getState() public view returns (State) {
        if (currentRoundNumber == 0) {
            return State.DEPLOYED;
        }

        Round memory currentRound = rounds[currentRoundNumber];

        uint256 closedTime = currentRound.closedTime;
        uint256 startTime = currentRound.startTime;
        uint256 endTime = currentRound.endTime;
        uint256 currentTime = block.timestamp;

        State currentState;

        if (closedTime != 0) {
            currentState = State.END_MINTING;
        } else {
            if (currentTime < startTime) {
                currentState = State.PREPARE_MINTING;
            } else if (currentTime < endTime) {
                if (currentRound.maxMintingId > totalSupply()) {
                    currentState = State.ON_MINTING;
                } else {
                    currentState = State.END_MINTING;
                }
            } else {
                currentState = State.END_MINTING;
            }
        }

        return currentState;
    }

    /**
     * Minting
     */
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
        notPermanent
    {
        Round memory currentRound = getRound(currentRoundNumber);

        _sanityCheckForMinting(currentRound, quantity);

        require(safeMint(msg.sender, quantity));
    }

    /**
     * Admin minting
     * Only for owner or admin
     */
    function mint(address to, uint256 quantity)
        external
        payable
        onlyOwnerOrAdmin
        notPermanent
    {
        Round memory currentRound = rounds[currentRoundNumber];

        _sanityCheckForMinting(currentRound, quantity);

        require(safeMint(to, quantity));
    }

    /**
     * Change Minting type
     * For only owner or admin
     */
    function changeMintingType(uint16 roundNumber, MintingType mintingType) 
        external onlyOwnerOrAdmin notPermanent {
        Round storage round = rounds[roundNumber];
        round.mintingType = mintingType;

        emit MintingTypeChanged(roundNumber, mintingType);
    }

    /**
     *  Change the maximum minting id for the specified round
     *  For owner and admin
     */
    function changeMaxMintingId(uint16 roundNumber, uint256 maxId)
        public onlyOwnerOrAdmin notPermanent
    {
        if (maxId < _nextTokenId()) {
            revert MaxMintingIdLowerThanCurrentId();
        }

        if (maxId > maximumSupply) {
            revert ExceedMaximumSupply();
        }

        Round storage round = rounds[roundNumber];
        round.maxMintingId = maxId;

        emit MaxMintingIdChanged(roundNumber, maxId);
    }

    /**
     *  Change minting start time for the specified round
     *  Only for owner and admin
     */
    function changeStartTime(uint16 roundNumber, uint256 time)
        public onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];
        round.startTime = time;

        emit StartTimeChanged(roundNumber, time);
    }

    /**
     *  Change minting end time for the specified round
     *  Only for owner and admin
     */
    function changeEndTime(uint16 roundNumber, uint256 time)
        public onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];
        round.endTime = time;

        emit EndTimeChanged(roundNumber, time);
    }

    /**
     *  Change maximum minting quantity for an account
     *  For owner and admin
     */
    function changeMaxMintingQuantity(uint16 roundNumber, uint16 quantity)
        public onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];
        round.maxMintingQuantity = quantity;

        emit MaxMintingQuantityChanged(roundNumber, quantity);
    }

    /**
     *  Set the minting for the specified round
     *  OnlyOwner functions
     */
    function changeMintingFee(uint16 roundNumber, uint256 fee)
        external onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];
        round.mintingFee = fee;

        emit MintingFeeChanged(roundNumber, fee);
    }

    /**
     *  Set the token uri prefix for the specified round
     *  For owner and admin
     */
    function setTokenURIPrefix(uint16 roundNumber, string memory prefix)
        public onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];
        round.tokenURIPrefix = prefix;

        emit TokenURIPrefixUpdated(roundNumber, prefix);
    }

    function safeMint(address receiver, uint256 quantity)
        private
        returns (bool)
    {
        _safeMint(receiver, quantity);
        return true;
    }



    /**
     * Minting and transfer tokens
     * Only for owner
     */
    function adminMintTo(address[] calldata tos, uint256[] calldata quantities)
        external
        payable
        onlyOwnerOrAdmin 
        notPermanent
    {
        uint256 length = tos.length;
        if (length != quantities.length) {
            revert BadRequest("Input size not match");
        }

        uint256 totalQuantity = 0;

        for (uint256 i = 0; i < tos.length; i++) {
            totalQuantity += quantities[i];
        }

        Round memory currentRound = rounds[currentRoundNumber];
        // check if minting does not exceed the maximum tokens for the round
        uint256 maxMintingId = currentRound.maxMintingId;

        if (!_isTokenAvailable(totalQuantity, maxMintingId)) {
            revert ExceedMaximumForTheRound();
        }

        for (uint256 i = 0; i < length; i++) {
            require(safeMint(tos[i], quantities[i]));
        }
    }

    /**
     * Transfer multiple tokens to an account
     */
    function transferBatch(uint256[] calldata tokenIds, address to)
        external
        nonReentrant
        notPermanent
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(_msgSender(), to, tokenIds[i]);
        }
    }

    /**
     * Get token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        Round memory round = _getRoundByTokenId(tokenId);

        if (
            round.revealed &&
            keccak256(abi.encodePacked(round.tokenURIPrefix)) !=
            keccak256(abi.encodePacked(""))
        ) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        round.tokenURIPrefix,
                        "/",
                        _toString(tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        defaultUnrevealedURI,
                        _toString(tokenId),
                        ".json"
                    )
                );
        }
    }

    /**
     *  Trigger reveal process for the specified round
     *  For owner and admin
     */
    function setRevealBlock(uint16 roundNumber)
        public onlyOwnerOrAdmin notPermanent
    {
        Round storage round = rounds[roundNumber];

        if (round.lastMintedId == 0) {
            revert BadRequest("Round should be closed");
        }

        round.revealBlockNumber = block.number + revealBlockOffset;

        emit SetRevealBlock(round.revealBlockNumber);
    }

    /**
     *  Set random selection number based on entropy
     *  It set the reveal on
     */
    function setRandomSelection(uint16 roundNumber) public notPermanent {
        Round storage round = rounds[roundNumber];

        if (round.revealed) {
            revert AlreadyRevealed();
        }

        uint256 revealBlockNumber = round.revealBlockNumber;

        if (revealBlockNumber > block.number) {
            revert BadRequest("Random selection is not ready");
        }

        bytes32 entropy;

        if (blockhash(revealBlockNumber - 1) != 0) {
            entropy = keccak256(
                abi.encodePacked(
                    blockhash(revealBlockNumber),
                    blockhash(revealBlockNumber - 1),
                    block.timestamp
                )
            );
        } else {
            entropy = keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    blockhash(block.number - 2),
                    block.timestamp
                )
            );
        }

        round.revealed = true;

        uint256 selected = _getRandomInRange(
            entropy,
            round.startId,
            round.lastMintedId
        );

        round.randomSelection = selected;

        emit Revealed(roundNumber);
    }

    /**
     *  Internal function to override the ERC721A _baseURI()
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     *  Get the base uri
     */
    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * Set the base uri
     * Only for the owner
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner notPermanent {
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * Set the default unrevealed uri
     * Only for the owner
     */
    function setDefaultUnrevealedURI(string memory _defaultUnrevealedURI)
        external onlyOwner notPermanent
    {
        defaultUnrevealedURI = _defaultUnrevealedURI;
        emit DefaultUnrevealedURIUpdated(_defaultUnrevealedURI);
    }

    /**
     *  Paused the contract
     *  Only for the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     *  Unpause the contract
     *  Only for the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     *  Set the receiver
     *  Only for the owner
     */
    function setReceiver(address receiver) external onlyOwner {
        _receiver = receiver;
    }

    /**
     * Withdraw the balance in the contract
     */
    function withdraw() external payable onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = _receiver.call{value: amount}("");
        if (!success) {
            revert FailedToSendBalance();
        }
        emit Withdraw(_receiver, amount);
    }

    /**
     *  Fallback function
     */
    fallback() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /**
     *  Fallback function
     */
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /**
     * Set the 'perment' to true to prevent token uri change
     */
    function setPermanent() external onlyOwner {
        permanent = true;
    }

    function updateRevealBlockOffset(uint256 newOffset) external onlyOwner notPermanent {
        revealBlockOffset = newOffset;
    }

    function changeMaximumSupply(uint256 newMaximum) external onlyOwner notPermanent {
        maximumSupply = newMaximum;
    }

    /**
     *  Sanity check before transfer tokens
     */
    function _sanityCheckForMinting(Round memory currentRound, uint256 quantity)
        private
    {
        State currentState = getState();

        if (currentState != State.ON_MINTING) {
            revert MintingNotAllowed();
        }

        if (currentRound.mintingType == MintingType.ADMIN_ONLY 
            && owner() != _msgSender() && admin() != _msgSender()) {
            revert NotOwnerNorAdmin();
        }

        // check if not exceeding the maxAllowedMintingQuantity
        if (currentRound.maxMintingQuantity < quantity) {
            revert ExceedAllowedQuantity(
                currentRound.maxMintingQuantity
            );
        }

        // check if minting does not exceed the maximum tokens for the round
        if (!_isTokenAvailable(quantity, currentRound.maxMintingId)) {
            revert ExceedMaximumForTheRound();
        }

        // check if proper fee is received (except owner or admin)
        if (currentRound.mintingType == MintingType.REGULAR 
            && owner() != _msgSender() && admin() != _msgSender()) {
            uint256 neededFee = currentRound.mintingFee * quantity;
            if (neededFee != msg.value) revert NoMatchingFee();
        }
    }

    /**
     *  Check the availability of tokens mintable for the round
     */
    function _isTokenAvailable(uint256 quantity, uint256 maxId)
        private
        view
        returns (bool)
    {
        // check if minting does not exceed the maximum tokens for the round
        if ((_nextTokenId() + quantity) > (maxId + 1)) {
            return false;
        }

        return true;
    }

    /**
     *  Private function to get the round number with token id
     */
    function _getRoundByTokenId(uint256 tokenId)
        private
        view
        returns (Round memory r)
    {
        if (!_exists(tokenId)) revert NonExistingToken(tokenId);

        uint16 roundNumber = 1;

        while (roundNumber <= currentRoundNumber) {
            r = rounds[roundNumber];
            uint256 roundMax = r.lastMintedId != 0
                ? r.lastMintedId
                : r.maxMintingId;
            if (tokenId > roundMax) {
                roundNumber++;
                continue;
            }
            return r;
        }
    }

    function _getRandomInRange(
        bytes32 hash,
        uint256 begin,
        uint256 end
    ) private pure returns (uint256) {
        uint256 diff = end - begin + 1;
        return (uint256(hash) % diff) + begin;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}