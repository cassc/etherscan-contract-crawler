// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Deep42 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    event LogMint(uint256 tokenID, uint16 characterType);
    event LogEvolutionStagePurchase(uint256 tokenID, uint16 evolutionStage);
    event LogEvolve(uint256 tokenID, uint16 evolutionStage);

    address public evolverAddress;

    Counters.Counter public differentCharacterTypesCounter;

    uint256 public cost = 9200000000000000 wei;
    uint256 public evolveCost = 4600000000000000 wei;    
    mapping(uint256 => uint8) public quantityDiscounts;

    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;

    // Character data by the token ID
    mapping(uint256 => CharacterData) public characterDataById;
    struct CharacterData {
        uint16 evolutionStage;
        uint16 evolutionStagesPurchased;
        uint16 characterType;
        string tokenURI;
    }

    mapping(uint256 => CharacterDataLimits)
        public characterDataLimitsByCharacterTypes;
    struct CharacterDataLimits {
        uint256 maxSupply;
        Counters.Counter counter;
        uint16 maxCharacterEvolutionStage;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _evolverAddress,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        _initCharacterDataLimitsByCharacterTypes();
        _initBaseDiscounts();
        setEvolverAddress(_evolverAddress);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _initCharacterDataLimitsByCharacterTypes() internal {
        // 1 = Gargasaur, 2 = Grimblefly, 3 = Cosmic Tinch
        for (uint16 i = 1; i <= 3; i++) {
            characterDataLimitsByCharacterTypes[i].maxSupply = 1000000;
            characterDataLimitsByCharacterTypes[i]
                .maxCharacterEvolutionStage = 65535;
            differentCharacterTypesCounter.increment();
        }
    }

    function _initBaseDiscounts() internal {
        quantityDiscounts[3] = 10;
        quantityDiscounts[10] = 20;
    }

    // public
    function mint(uint256 _mintAmount, uint16 _characterType) public payable {
        require(!paused, "Contract is paused!");
        require(_mintAmount > 0, "You have to mint more than 0 characters!");
        require(
            characterTypeExists(_characterType),
            "Character type does not exist!"
        );

        uint256 supply = getCharactersCountByCharacterType(_characterType);
        uint256 maxSupply = characterDataLimitsByCharacterTypes[_characterType]
            .maxSupply;

        require(supply + _mintAmount <= maxSupply, "Maximum supply reached");

        uint256 costWithDiscount = calculateDiscountedValue(_mintAmount);

        if (msg.sender != owner()) {
            require(msg.value >= costWithDiscount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply = getCharactersCountByCharacterType(_characterType);
            uint256 _tokenId = totalSupply() + 1;
            _safeMint(msg.sender, _tokenId);
            characterDataById[_tokenId].evolutionStage = 1;
            characterDataById[_tokenId].evolutionStagesPurchased = 1;
            characterDataById[_tokenId].characterType = _characterType;
            characterDataLimitsByCharacterTypes[_characterType]
                .counter
                .increment();
            emit LogMint(_tokenId, _characterType);
        }
    }

    function getCharactersCountByCharacterType(uint16 _characterType)
        public
        view
        returns (uint256)
    {
        require(
            characterTypeExists(_characterType),
            "Character type does not exist!"
        );

        return
            characterDataLimitsByCharacterTypes[_characterType]
                .counter
                .current();
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return characterDataById[tokenId].tokenURI;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function hide() public onlyOwner {
        revealed = false;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setEvolutionCost(uint256 _newCost) public onlyOwner {
        evolveCost = _newCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setQuantityDiscountsDiscount(uint256 _mintAmount, uint8 _discount)
        public
        onlyOwner
    {
        quantityDiscounts[_mintAmount] = _discount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function purchaseEvolutionStage(uint256 _tokenId) public payable {
        if (msg.sender != owner()) {
            require(
                msg.value >= evolveCost,
                "You are not sending enough ether for next evolution stage."
            );
        }

        CharacterData memory _character = characterDataById[_tokenId];
        uint256 _maxCharacterEvolutionStage = characterDataLimitsByCharacterTypes[
                characterDataById[_tokenId].characterType
            ].maxCharacterEvolutionStage;

        require(
            _character.evolutionStagesPurchased <= _maxCharacterEvolutionStage,
            "Max evolution stage already purchased!"
        );

        characterDataById[_tokenId].evolutionStagesPurchased++;

        emit LogEvolutionStagePurchase(
            _tokenId,
            characterDataById[_tokenId].evolutionStagesPurchased
        );
    }

    function evolve(
        uint256 _tokenId,
        uint16 _newEvolutionStage,
        string memory _newTokenURI
    ) public {
        require(_tokenId <= totalSupply(), "Token does not exist");
        require(
            msg.sender == evolverAddress || msg.sender == owner(),
            "Sender is not authorized to evolve this character."
        );

        CharacterData memory _character = characterDataById[_tokenId];

        require(
            _newEvolutionStage <= _character.evolutionStagesPurchased,
            "New evolution stage has to be less or equal to the amount of evolution stages purchased."
        );

        characterDataById[_tokenId].evolutionStage = _newEvolutionStage;
        characterDataById[_tokenId].tokenURI = _newTokenURI;

        emit LogEvolve(_tokenId, _newEvolutionStage);
    }

    function addCharacterType(uint256 _maxSupply) public onlyOwner {
        require(
            _maxSupply >= 0,
            "Max mint hast to be less or equal to max supply"
        );

        differentCharacterTypesCounter.increment();
        characterDataLimitsByCharacterTypes[
            differentCharacterTypesCounter.current()
        ].maxSupply = _maxSupply;
        characterDataLimitsByCharacterTypes[
            differentCharacterTypesCounter.current()
        ].maxCharacterEvolutionStage = 65535;
    }

    function setEvolverAddress(address _evolverAddress) public onlyOwner {
        evolverAddress = _evolverAddress;
    }

    // For increasing or decreasing the max level of the characters
    function setMaxCharacterTypeEvolutionStage(
        uint16 _characterType,
        uint16 _maxCharacterEvolutionStage
    ) public onlyOwner {
        require(
            characterTypeExists(_characterType),
            "Character type does not exist!"
        );

        characterDataLimitsByCharacterTypes[_characterType]
            .maxCharacterEvolutionStage = _maxCharacterEvolutionStage;
    }

    // For increasing or decreasing the max supply ba character type
    function setMaxSupply(uint16 _characterType, uint16 _maxSupply)
        public
        onlyOwner
    {
        require(
            characterTypeExists(_characterType),
            "Character type does not exist!"
        );

        characterDataLimitsByCharacterTypes[_characterType]
            .maxSupply = _maxSupply;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function characterTypeExists(uint16 _characterType)
        public
        view
        returns (bool exists)
    {
        if (
            _characterType > 0 &&
            _characterType <= differentCharacterTypesCounter.current()
        ) {
            return true;
        }
        return false;
    }

    function calculateDiscountedValue(uint256 _mintAmount)
        public
        view
        returns (uint256)
    {
        uint256 maxDiscount = 0;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (quantityDiscounts[i] > maxDiscount) {
                maxDiscount = quantityDiscounts[i];
            }
        }
        return ((cost * _mintAmount) * (100 - maxDiscount)) / 100;
    }
}