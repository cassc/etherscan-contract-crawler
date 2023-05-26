//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./base64.sol";
import "./ApeHarbourDinghies.sol";

contract ApeHarbourYachts is ERC721Enumerable, VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 constant MAX_MINTABLE = 20;
    uint256 constant public PRICE = 70000000000000000; // 0.07 ETH
    uint256 constant MAX_SUPPLY = 7777;
    uint256 constant MAX_RANGE = 100;
    uint256 constant MAX_SPEED = 99;

    uint8 constant BITMASK = 255;

    uint256 immutable startMinting;

    string constant preRevealImageUrl = "ipfs://QmWt3pBeGmTEg5RU5j82XoEjGuaD767LfBFJ5g86iccCX7";

    string public revealedCollectionBaseURL;
    bool public frozen;

    IERC721 private bayc;
    IERC721 private bakc;
    ApeHarbourDinghies private ahd;

    uint8[][13] private cutoffs;
    string[][13] private traitValues;

    enum Keys { backgrounds, hulls_background, masts, sails, anchors, balloons, backprops, bananaboats, centerprops, carpets, chains, flags, cargos, range, speed }

    string[] private traits = [ "Background", "Hull", "Mast", "Sail", "Anchor", "Equipment", "Equipment", "Sideboat", "Equipment", "Equipment", "Equipment", "Flag", "Equipment", "Range", "Speed" ];

    mapping(uint256 => string) private names;

    // Random number generation
    uint256 public randomSeed;
    bytes32 internal keyHash;
    uint256 internal chainLinkFee;
    bytes32 public requestId;

    event Mint(address indexed _to, uint256 _amount);
    event NameChange(uint256 indexed _tokenId, string _name);
    event Reveal(uint256 randomness);
    event SetCollectionHash(string ipfsHash);


    modifier onlyApeOwner() {
        require(
            bayc.balanceOf(msg.sender) > 0,
            "ApeOwner: Caller is not an ape owner"
        );

        _;
    }

    modifier onlyDogOwner() {
        require(
            bakc.balanceOf(msg.sender) > 0,
            "DogOwner: Caller is not a dog owner"
        );

        _;
    }

    constructor(
        address _baycAddress,
        address _bakcAddress,
        address _ahdAddress,
        address _linkAddress,
        address _vrfCoordinatorAddress,
        bytes32 _keyHash,
        uint256 _chainLinkFee,
        uint256 _startMinting
    )
        ERC721("Ape Harbour Yachts", "AHY")
        VRFConsumerBase(_vrfCoordinatorAddress, _linkAddress)
    {
        keyHash = _keyHash;
        chainLinkFee = _chainLinkFee;
        bayc = IERC721(_baycAddress);
        bakc = IERC721(_bakcAddress);
        ahd = ApeHarbourDinghies(_ahdAddress);

        startMinting = _startMinting;

        cutoffs[uint256(Keys.backgrounds)] = [30,81,132,170,221,254];
        cutoffs[uint256(Keys.hulls_background)] = [58,98,136,184,219,239,249,251];
        cutoffs[uint256(Keys.masts)] = [25,204,255];
        cutoffs[uint256(Keys.sails)] = [25,63,80,95,115,153,165,180,195,207,219,226,236,243,248];
        cutoffs[uint256(Keys.anchors)] = [51,76,114,139,215,253];
        cutoffs[uint256(Keys.balloons)] = [51,89,140,178,203,254];
        cutoffs[uint256(Keys.backprops)] = [25,53,70,108,125,150,167,190,215,232,249];
        cutoffs[uint256(Keys.bananaboats)] = [204,221,254];
        cutoffs[uint256(Keys.centerprops)] = [25,48,71,88,100,117,132,144,154,166,189,206,223,235,247];
        cutoffs[uint256(Keys.carpets)] = [230,255];
        cutoffs[uint256(Keys.chains)] = [38,140,216,254];
        cutoffs[uint256(Keys.flags)] = [25,55,85,100,125,140,155,172,189,212,235,250];
        cutoffs[uint256(Keys.cargos)] = [40,55,80,103,126,143,155,180,203,220,243,250];

        traitValues[uint256(Keys.backgrounds)] = ['Apelantic', 'Banana Bay', 'Everglades Ape Park', 'Ape Harbour', 'Ape Island', 'Apebiza'];
        traitValues[uint256(Keys.hulls_background)] = ['Classic', 'Pink', 'Mahogany', 'Royal', 'Ocean Green', 'Robot', 'Gold', 'Diamond'];
        traitValues[uint256(Keys.masts)] = ['null', 'Wood', 'Bone'];
        traitValues[uint256(Keys.sails)] = ['null', 'Pennant Chain', 'Pink', 'Classic', 'Banana Pirates', 'Bulb Chain', 'Denim', 'White Stripes', 'Cheetah', 'USA', 'Fireflys', 'Trippy', 'Prison', 'Pizza', 'Gold'];
        traitValues[uint256(Keys.anchors)] = ['null', 'Royal Gold', 'Pirate', 'Gold', 'Classic', 'Steel'];
        traitValues[uint256(Keys.balloons)] = ['null', 'Banana Balloons', 'Colorful Balloons', 'Yellow Balloons', 'Pink Balloons', 'Ape Balloon'];
        traitValues[uint256(Keys.backprops)] = ['null', 'Tiki Lamp', 'Water Slide', 'Jumping Board', 'Palm', 'Banana Tree', 'Curved Palm', 'Fish', 'Fishing Set', 'Lamp', 'Disco Ball'];
        traitValues[uint256(Keys.bananaboats)] = ['null', 'Banana Boat', 'Flamingo'];
        traitValues[uint256(Keys.centerprops)] = ['null', 'DJ Booth', 'Bar', 'Hammock', 'Old Couch', 'Fishbowl Lounge', 'Deewan Couch', 'Jacuzy', 'Bathtub', 'BBQ', 'Deckchair', 'Drums', 'Wine Lounge', 'Pizza Oven', 'Radio'];
        traitValues[uint256(Keys.carpets)] = ['null', 'Carpet'];
        traitValues[uint256(Keys.chains)] = ['null', 'Pennant Chain', 'Bulb Chain', 'Fireflys'];
        traitValues[uint256(Keys.flags)] = ['null', 'Apes', 'Fomo', 'Lofi', 'Hodl', 'One Banana', 'Three Bananas', 'Doggo Red', 'Doggo Orange', 'Banana Pirates', 'Aped', 'Two Bananas'];
        traitValues[uint256(Keys.cargos)] = ['null', 'Moneky Paw', 'Coconuts', 'Beer', 'Boxes of Oranges', 'Box of Oranges', 'Golden Banana', 'Whiskey Bottles', 'Banana Boxes', 'Banana Box', 'Coffee', 'Diamond Banana'];
    }

    function mint(address _ape, uint8 _amount)
        public
        payable
        returns (uint256)
    {
        require(block.timestamp >= startMinting, 'Minting has not started');
        require(_amount <= MAX_MINTABLE, "You can only mint up to 20 tokens at once");
        require(msg.value >= PRICE * _amount, "Insufficient funds");
        require(
            _amount + totalSupply() <= MAX_SUPPLY,
            "Request exeeds maximum supply"
        );

        if (block.timestamp < startMinting + 6 hours) {
            require(bayc.balanceOf(msg.sender) > 0, "No ape, no yacht");
        }


        bool ownsDog = bakc.balanceOf(msg.sender) > 0;
        bool ownsApe = bayc.balanceOf(msg.sender) > 0;

        for (uint8 i = 0; i < _amount; i++) {
            _tokenIds.increment();

            uint256 newTokenId = _tokenIds.current();
            _safeMint(_ape, newTokenId);
        }

        if (ownsApe && ownsDog && block.timestamp < startMinting  + 12 hours) {
            ahd.mint(_ape);
        }

        emit Mint(_ape, _amount);

        return _tokenIds.current();
    }

    function setName(uint256 _tokenId, string memory _name)
        public
        returns (string memory)
    {
        require(ownerOf(_tokenId) == msg.sender, "Only boat owner can name it");

        names[_tokenId] = _name;

        emit NameChange(_tokenId, _name);

        return _name;
    }

    function getName(uint256 _tokenId) public view returns (string memory) {
        return names[_tokenId];
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable receiver = payable(msg.sender);
        receiver.transfer(balance);
    }

    function decodeTokenId(uint256 randomValue, uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        require(randomValue != 0, "Tokens have not been revealed yet");

        uint256 tokenCode = uint256(
            keccak256(abi.encode(randomValue, _tokenId))
        );

        uint8[15] memory shifts = [ 0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, 104, 112 ];
        uint256[] memory tokenPart = new uint256[](shifts.length);

        for (uint256 i = 0; i < shifts.length; i++) {
            tokenPart[i] = (tokenCode >> shifts[i]) & BITMASK;
        }

        // only use cutoffs for string attributes, that's why the loop is until lenght -2
        for (uint256 i = 0; i < tokenPart.length - 2; i++) {
            uint256 currentIdx = 0;
            for (uint256 j = 0; j < cutoffs[i].length; j++) {
                if (tokenPart[i] < cutoffs[i][j]) {
                    currentIdx = j;
                    break;
                }
            }
            tokenPart[i] = currentIdx;
        }

        bool noMast = (tokenPart[uint256(Keys.masts)] == 0);

        // special treatment for no mast boats:
        if (noMast) {
            tokenPart[uint256(Keys.sails)] = 0;
            tokenPart[uint256(Keys.chains)] = 0;
            tokenPart[uint256(Keys.flags)] = 0;
        }

        tokenPart[uint256(Keys.range)] =
            (tokenPart[uint256(Keys.range)] % MAX_RANGE) +
            1;
        tokenPart[uint256(Keys.speed)] =
            (tokenPart[uint256(Keys.speed)] % MAX_SPEED) +
            1;

        return tokenPart;
    }

    function reveal() public onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= chainLinkFee,
            "Not enough LINK - fill contract with faucet"
        );
        require(randomSeed == 0, 'randomSeed has already been set');
        requestId = requestRandomness(keyHash, chainLinkFee);

    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(requestId == _requestId, "Wrong request Id");
        require(randomSeed == 0, 'randomSeed has already been set');
        randomSeed = _randomness;

        emit Reveal(_randomness);
    }

    function getAttributeBytes(uint256 key, uint256 value)
        private
        view
        returns (bytes memory, bool attributePresent)
    {
        if (
            keccak256(abi.encodePacked(traitValues[key][value])) ==
            keccak256(abi.encodePacked("null"))
        ) {
            return ("", false);
        }
        return (
            abi.encodePacked(
                '{"trait_type": "',
                traits[key],
                '", "value": "',
                traitValues[key][value],
                '"}'
            ),
            true
        );
    }

    function getNumericAttributeBytes(uint256 _key, uint256 _value)
        private
        view
        returns (bytes memory)
    {
        return (
            abi.encodePacked(
                '{"trait_type": "',
                traits[_key],
                '", "value": ',
                Strings.toString(_value),
                "}"
            )
        );
    }

    function getAttributes(uint256[] memory tokenPart)
        private
        view
        returns (string memory) {

        bytes memory attributes = '"attributes": [';
        bytes memory singleAtt;
        bool attPresent;

        (singleAtt, attPresent) = getAttributeBytes(0, tokenPart[0]);

        attributes = abi.encodePacked(attributes, singleAtt);

        // loop through string attributes only
        for (uint256 i = 1; i < traits.length - 2; i++) {
            (singleAtt, attPresent) = getAttributeBytes(i, tokenPart[i]);
            if (attPresent) {
                attributes = abi.encodePacked(attributes, ", ", singleAtt);
            }
        }

        // add range and speed
        attributes = abi.encodePacked(
            attributes,
            ", ",
            getNumericAttributeBytes(
                uint256(Keys.speed),
                tokenPart[uint256(Keys.speed)]
            ),
            ", ",
            getNumericAttributeBytes(
                uint256(Keys.range),
                tokenPart[uint256(Keys.range)]
            ),
            "]"
        );

        return string(attributes);
    }

    function setRevealedCollectionBaseURL(string memory _ipfsHash) onlyOwner public {
        require(!frozen, 'Metadata has been frozen');
        revealedCollectionBaseURL = string(abi.encodePacked('ipfs://', _ipfsHash, '/'));
        emit SetCollectionHash(_ipfsHash);
    }

    function freezeMetadata() onlyOwner public {
        frozen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenName = names[_tokenId];
        if (keccak256(abi.encodePacked(tokenName)) == keccak256(abi.encodePacked(''))) {
            tokenName = string(abi.encodePacked('Yacht ', Strings.toString(_tokenId)));
        }

        bytes memory content = abi.encodePacked('{"name":"', tokenName, '"');

        if (keccak256(abi.encodePacked(revealedCollectionBaseURL))  == keccak256(abi.encodePacked(''))) {
            content = abi.encodePacked(content, 
                ', ',
                '"description": "An unrevealed Ape Harbour Yacht"',
                ', ',
                '"image": "', preRevealImageUrl, '"',
                '}');
        } else {
            uint256[] memory tokenParts = decodeTokenId(randomSeed, _tokenId);
            content = abi.encodePacked(content, 
                ', ', 
                getAttributes(tokenParts),
                ', ',
                '"image": "', revealedCollectionBaseURL, Strings.toString(_tokenId), '.png"',
                '}');
        }

        string memory result = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(content)
            )
        );

        return result;
    }
}