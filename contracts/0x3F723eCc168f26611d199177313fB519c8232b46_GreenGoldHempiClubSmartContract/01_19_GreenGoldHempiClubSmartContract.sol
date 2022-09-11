// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error GreenGoldHempiClubSmartContract__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 raffleState,
    uint256 currentTokenId,
    uint32 numberOfDraw
);
error GreenGoldHempiClubSmartContract__TransferFailed();
error GreenGoldHempiClubSmartContract__AddressIsNull();
error GreenGoldHempiClubSmartContract__TokenBurned();

contract GreenGoldHempiClubSmartContract is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface
{
    using Strings for uint256;

    /* Type declararations */
    enum LotteryState {
        OPEN,
        CALCULATING,
        CLOSE
    }

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    /* State Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /* Lottery Variables */
    LotteryState public s_lotteryState;
    uint256 public s_numberOfDraw;
    address[] public s_winner;
    uint256 private s_lastTimeStamp;
    uint256 private constant INTERVAL = 30 days;
    uint256 private constant NINETY_PERCENT = 9000;

    /* Events */
    event WinnerPicked(address indexed winner);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);

        s_lotteryState = LotteryState.CLOSE;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        while (
            (s_numberOfDraw + s_winner.length + 1) < (_totalMinted() / 750) &&
            (s_numberOfDraw + s_winner.length) < 12
        ) {
            s_numberOfDraw = s_numberOfDraw++;
        }
        if (
            _totalMinted() >= NINETY_PERCENT &&
            s_lotteryState == LotteryState.CLOSE
        ) {
            s_lotteryState = LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
        }
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
        while (
            (s_numberOfDraw + s_winner.length + 1) < (_totalMinted() / 750) &&
            (s_numberOfDraw + s_winner.length) < 12
        ) {
            s_numberOfDraw = s_numberOfDraw++;
        }
        if (
            _totalMinted() >= NINETY_PERCENT &&
            s_lotteryState == LotteryState.CLOSE
        ) {
            s_lotteryState = LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{
            value: (address(this).balance - (s_numberOfDraw * 10 ether))
        }("");
        if (!success) {
            revert GreenGoldHempiClubSmartContract__TransferFailed();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // --------------------------------Lottery Part Start-----------------------------------------

    function extendNumberOfDraw(uint32 _numberOfDraw) public payable {
        require(msg.value >= (_numberOfDraw * 10 ether), "Insufficient funds!");
        s_numberOfDraw = s_numberOfDraw + _numberOfDraw;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData  */
        )
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool is90PercentSold = (_totalMinted() >= NINETY_PERCENT);
        bool isNumberOfDrawSufficient = (s_numberOfDraw > 0);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > INTERVAL);
        bool hasBalance = (address(this).balance >=
            (s_numberOfDraw * 10 ether));
        upkeepNeeded = (isOpen &&
            hasBalance &&
            is90PercentSold &&
            isNumberOfDrawSufficient &&
            timePassed);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert GreenGoldHempiClubSmartContract__UpkeepNotNeeded(
                address(this).balance,
                uint256(s_lotteryState),
                uint256(_totalMinted()),
                uint32(s_numberOfDraw)
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinnerTokenId = (randomWords[0] % _totalMinted()) + 1;
        if (!_exists(indexOfWinnerTokenId)) {
            revert GreenGoldHempiClubSmartContract__TokenBurned();
        }
        if (ownerOf(indexOfWinnerTokenId) == address(0)) {
            revert GreenGoldHempiClubSmartContract__AddressIsNull();
        }
        address payable winner = payable(ownerOf(indexOfWinnerTokenId));
        s_winner.push(winner);
        s_numberOfDraw = s_numberOfDraw - 1;
        s_lastTimeStamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
        (bool success, ) = winner.call{value: 10 ether}("");
        if (!success) {
            revert GreenGoldHempiClubSmartContract__TransferFailed();
        }
        emit WinnerPicked(winner);
    }

    // ----------------------------------------------------------------------------------------------
}