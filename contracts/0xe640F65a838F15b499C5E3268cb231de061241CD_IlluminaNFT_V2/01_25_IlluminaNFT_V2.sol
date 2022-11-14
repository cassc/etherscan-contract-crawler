// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './ERC2981/ERC2981ContractWideRoyalties.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Erc721OperatorFilter/IOperatorFilter.sol";
import "./BlackSquareNFT.sol";

contract IlluminaNFT_V2 is ERC721, Ownable, ERC2981ContractWideRoyalties, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    using Counters for Counters.Counter;

    uint256 public s_requestId;
    uint256 private min;
    uint256 private max;
    uint256 private illuminaFactor;
    uint256 public illuminationTimeStamp = 0;
    uint256 constant ILLUMINA_BASE_SUPPLY = 20000;
    uint256 constant ILLUMINA_REGULAR_PRICE = 225;
    uint256 constant ILLUMINA_MIN_PRICE = 30;
    uint256 constant THRESHOLD = 25;

    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint32 callbackGasLimit = 2500000;
    uint64 s_subscriptionId;

    bytes32 keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address private treasury;

    string private illuminaURI;
    string private baseURI;

    bool private simpleMintable = true;
    bool public getRandomnessFromOracles;
    bool public editBlacksquareEditions = true;

    OBYToken obyToken;
    BlackSquareNFT blackSquare;
    IOperatorFilter operatorFilter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _eligibles;
    mapping(uint256 => bool) private _burnedTokens;

    event MintToken(uint256 tokenId, address purchaser);
    event BatchMinted();

    constructor(address tokenAddress, address _blackSquareAddress, address _treasury, 
    uint256 _royaltyValue, uint64 _subscriptionId, string memory _illuminaBaseURI,
    uint256 _minTime, uint256 _maxTime, uint256 _illuminaFactor, bool _getRandomnessFromOracles, address _operatorFilter) VRFConsumerBaseV2(vrfCoordinator) ERC721("Illumina", "Ill") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        obyToken = OBYToken(tokenAddress);
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        operatorFilter = IOperatorFilter(_operatorFilter);
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

    function setSimpleMintable(bool _simpleMintable) public onlyEligible {
        simpleMintable = _simpleMintable;
    }

    function setEditBlacksquareEditions (bool _edit) public onlyEligible {
        editBlacksquareEditions = _edit;
    }

    function setEligibles(address _eligible) public onlyOwner {
        _eligibles[_eligible] = true;
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

    function setContractURI(string memory _contractURI) external onlyOwner {
        illuminaURI = _contractURI;
    }

    function setBaseURI(string memory _illuminaBaseURI) external onlyOwner {
        baseURI = _illuminaBaseURI;
    }

    function setTokenIpfsHash(uint256 tokenId, string memory ipfsHash) external onlyOwner {
        _tokenURIs[tokenId] = ipfsHash;
    }

    function getIlluminaMaxSupply () internal pure returns (uint256) {
        return ILLUMINA_BASE_SUPPLY;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return illuminaURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory illuminaBaseURI = _baseURI();
        string memory tokenURIHash = _tokenURIs[tokenId];
        return bytes(illuminaBaseURI).length > 0 ? string(abi.encodePacked(illuminaBaseURI, tokenURIHash)) : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }

    function requestRandomWords() public onlyEligible  {
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
        if (tokenIds.length > 0) {
            return tokenIds;
        }  else {
            return emptyTokens;
        }
    }


    function simpleMint(string memory ipfsHash, uint256 tokenId) external {
        require(simpleMintable == true, 'No tokens can be minted at the moment');

        require(_tokenIds.current() <= getIlluminaMaxSupply(), 'Max Amount of Illuminas minted');

        require(tokenId == getNextTokenId(), 'Trying to mint Token with incorrect Metadata');

        require(blackSquare.getAvailableIlluminaCount() > _tokenIds.current(), 'IlluminaNFT, max mintable number reached');

        (uint256 pricePerToken, ,) = getIlluminaPrice();

        bool ok1 = obyToken.checkBalances(pricePerToken, _msgSender());
        require(ok1, 'IlluminaNFT, insufficient balances');

        _tokenIds.increment();

        require(!_exists(_tokenIds.current()), "IlluminaNFT: Token already exists");

        _mint(_msgSender(), _tokenIds.current());

        emit MintToken(_tokenIds.current(), _msgSender());

        obyToken.burnToken(pricePerToken, _msgSender());

        _tokenURIs[_tokenIds.current()] = ipfsHash;

        if ((_tokenIds.current() == THRESHOLD || (_tokenIds.current() > THRESHOLD && _tokenIds.current() % THRESHOLD == 0))) {

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
        if (blackSquare.getAvailableIlluminaCount() == 0) {
            return 0;
        } else {
            return _tokenIds.current() + 1;
        }
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