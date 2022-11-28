// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './ERC2981/ERC2981ContractWideRoyalties.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./OpenseaOperatorFilter//DefaultOperatorFilterer.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./BlackSquareNFT.sol";
import "./OBYToken.sol";


contract IlluminaNFT_V3 is ERC721, DefaultOperatorFilterer, Ownable, ERC2981ContractWideRoyalties, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    using Counters for Counters.Counter;

    uint256 public s_requestId;
    uint256 private min;
    uint256 private max;
    uint256 private illuminaFactor;
    uint256 public illuminationTimeStamp = 0;
    uint256 public maxMintable = 5;
    uint256 constant ILLUMINA_BASE_SUPPLY = 20000;
    uint256 constant ILLUMINA_REGULAR_PRICE = 225;
    uint256 constant ILLUMINA_MIN_PRICE = 30;
    uint256 constant THRESHOLD = 25;

    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint32 callbackGasLimit = 2500000;
    uint64 s_subscriptionId;

    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    address vrfCoordinator = address(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
    address private treasury;

    string private baseURI;

    bool public getRandomnessFromOracles;
    bool public editBlacksquareEditions = true;
    bool public simpleMintable = true;

    OBYToken obyToken;
    BlackSquareNFT blackSquare;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _eligibles;
    mapping(uint256 => bool) private _burnedTokens;

    event MintTokens(uint256[] tokens, address purchaser, uint256 quantity);


    constructor(address tokenAddress, address _blackSquareAddress, address _treasury, 
    uint256 _royaltyValue, uint64 _subscriptionId, string memory _illuminaBaseURI,
    uint256 _minTime, uint256 _maxTime, uint256 _illuminaFactor, bool _getRandomnessFromOracles) VRFConsumerBaseV2(vrfCoordinator) ERC721("Illumina", "Ill") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        obyToken = OBYToken(tokenAddress);
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        treasury = _treasury;
        s_subscriptionId = _subscriptionId;
        baseURI = _illuminaBaseURI;
        min = _minTime;
        max = _maxTime;
        illuminaFactor = _illuminaFactor;
        getRandomnessFromOracles = _getRandomnessFromOracles;
        _setRoyalties(_treasury, _royaltyValue);
    }

     modifier onlyEligible() {
        require(owner() == _msgSender() || _eligibles[_msgSender()] == true, "IlluminaNFT: caller is not eligible");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setEditBlacksquareEditions (bool _edit) public onlyEligible {
        editBlacksquareEditions = _edit;
    }

    function setBulkMintAttributes (uint256 _maxMintable, bool _simpleMintable) public onlyEligible {
        maxMintable = _maxMintable;
        simpleMintable = _simpleMintable;
    }

    function setEligibles(address _eligible, bool _val) public onlyOwner {
        _eligibles[_eligible] = _val;
    }

    function setIlluminationTimeStamp(uint256 _illuminationTimeStamp) public onlyEligible {
        illuminationTimeStamp = _illuminationTimeStamp;
    }

    function setRandomnessFromOracles(bool _getRandomnessFromOracles) public onlyOwner {
        getRandomnessFromOracles = _getRandomnessFromOracles;
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setMin(uint8 _min) external onlyOwner {
        min = _min;
    }

    function setMax(uint8 _max) external onlyOwner {
        max = _max;
    }

    function setSubscriptionId(uint64 _s_subscriptionId) external onlyOwner {
        s_subscriptionId = _s_subscriptionId;
    }

    function setBaseURI(string memory _illuminaBaseURI) external onlyOwner {
        baseURI = _illuminaBaseURI;
    }

    function setTokenIpfsHash(uint256 tokenId, string memory ipfsHash) external onlyOwner {
        _tokenURIs[tokenId] = ipfsHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory illuminaBaseURI = _baseURI();
        string memory tokenURIHash = _tokenURIs[tokenId];
        return bytes(illuminaBaseURI).length > 0 ? string(abi.encodePacked(illuminaBaseURI, tokenURIHash)) : "";
    }

     function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function requestRandomWords() internal  {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length > 0, 'OracleContract: No Number delivered');
        uint256 illuminationDate = randomWords[0] % (max - min + 1) + min;

        illuminationTimeStamp = illuminationDate;
    }

    function getTokensHeldByUser(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory emptyTokens = new uint256[](0);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 j = 0;
        for (uint256 i = 1; i <= _tokenIds.current(); i++ ) {
            if (!_burnedTokens[i]) {
                address tokenOwner = ownerOf(i);

                if (tokenOwner == user) {
                    tokenIds[j] = i;
                    j++;
                }
            }
        }
        return tokenIds.length > 0 ? tokenIds : emptyTokens;
    }

    function simpleMint(string[] memory _ipfsHashes, uint256[] memory _tokens) external {
        require(simpleMintable == true, 'No tokens can be minted at the moment');

        if (_tokens.length <= maxMintable) {
            fulfillRequirements(_tokens[0], _tokens.length);
            handleMint(_ipfsHashes, _tokens.length, _tokens);
        }
    }


    function fulfillRequirements(uint256 tokenId, uint256 qtyToMint) internal view {
        require(_tokenIds.current() <= ILLUMINA_BASE_SUPPLY, 'Max Amount of Illuminas minted');

        require(tokenId == getNextTokenId(), 'Trying to mint Token with incorrect Metadata');

        require(blackSquare.getAvailableIlluminaCount() >= (_tokenIds.current() + qtyToMint), 'IlluminaNFT, max mintable number reached');
        (uint256 pricePerToken, ,) = getIlluminaPrice();
        uint256 totalPrice = pricePerToken * qtyToMint;

        bool balancesChecked = obyToken.checkBalances(totalPrice, _msgSender());
        require(balancesChecked, 'IlluminaNFT, insufficient balances');
    }

    function handleMint (string[] memory _ipfsHashes, uint256 qtyToMint, uint256[] memory _tokens) internal {
        (uint256 pricePerToken, ,) = getIlluminaPrice();
        uint256 totalPrice = pricePerToken * qtyToMint;

        for (uint i = 0; i < qtyToMint; i++) {
            _tokenIds.increment();

            require(!_exists(_tokenIds.current()), "IlluminaNFT: Token already exists");

            _mint(_msgSender(), _tokenIds.current());

            _tokenURIs[_tokenIds.current()] = _ipfsHashes[i];

            if ((_tokenIds.current() == THRESHOLD || (_tokenIds.current() > THRESHOLD && _tokenIds.current() % THRESHOLD == 0))) {
                handleEditionEdit();
            }

        }

        emit MintTokens(_tokens, _msgSender(), qtyToMint);

        obyToken.burnToken(totalPrice, _msgSender());
    }

    function handleEditionEdit () internal {
        if (!getRandomnessFromOracles) {
            uint256 randmomNumber = uint256(keccak256("wow")) % (max - min + 1) + min;

            uint256 randomnDate = block.timestamp + randmomNumber;

            if(editBlacksquareEditions) {
                uint256 editionId = blackSquare.getFirstEditionToSetIlluminationDate();
                blackSquare.editEdition(editionId, randomnDate);
            } else {
                illuminationTimeStamp = randomnDate;
            }
        } else {
            if(editBlacksquareEditions) {
                requestRandomWords();
            }
        }
    }

    function getIlluminaPrice() public view returns (uint256, uint256, uint256) {
        uint256 availableIllumina = blackSquare.getAvailableIlluminaCount();

        uint256 soldIllumina = _tokenIds.current();

        uint256 vacantIllumina = availableIllumina - soldIllumina;

        if (ILLUMINA_REGULAR_PRICE > (vacantIllumina / illuminaFactor)) {
            uint256 residualPrice = ILLUMINA_REGULAR_PRICE - ( vacantIllumina / illuminaFactor );

            if (residualPrice > ILLUMINA_MIN_PRICE) {
                return (residualPrice, availableIllumina, vacantIllumina);
            }
        }

        return (ILLUMINA_MIN_PRICE, availableIllumina, vacantIllumina);
    }

    function getNextTokenId() public view returns (uint256) {
        return blackSquare.getAvailableIlluminaCount() == 0 ? 0 : _tokenIds.current() + 1;
    }

    function burnIllumina(address user, uint256 _burnThreshold) public onlyEligible {
        uint256[] memory tokenIds = getTokensHeldByUser(user);

        for (uint256 i = 0; i < tokenIds.length; i++ ) {
            if (i < _burnThreshold) {
                uint256 tokenId = tokenIds[i];

                super._burn(tokenId);

                _burnedTokens[tokenId] = true;
            }
        }
    }
}