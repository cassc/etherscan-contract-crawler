//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./base64.sol";

contract ApeHarbourDinghies is ERC721Enumerable, VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IERC721 private bayc;
    IERC721 private bakc;

    address private minter;

    // Random number generation
    uint256 public randomSeed;
    bytes32 internal keyHash;
    uint256 internal chainLinkFee;

    bytes32 public requestId;

    string constant preRevealImageUrl = 'ipfs://QmNNmPE3FEk5xZ79zTKQC6ekm1vVX25gQivfQguVwRGMbu';
    string public revealedCollectionBaseURL;
    bool public frozen;

    uint8 constant BITMASK = 255;

    uint8[][2] private cutoffs;
    string[][2] private traitValues;

    enum Keys { backgrounds, surfboard }

    string[] private traits = [ "Background", "Surfboard" ];


    event Reveal(uint256 randomness);
    event Mint(address indexed owner);


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

    modifier onlyMinter() {
        require(msg.sender == minter, 'Minting only allowed from AHY');

        _;
    }

    constructor(
        address _baycAddress,
        address _bakcAddress,
        address _linkAddress,
        address _vrfCoordinatorAddress,
        bytes32 _keyHash,
        uint256 _chainLinkFee
    ) ERC721("Ape Harbour Dinghies", "AHD") 
    VRFConsumerBase(_vrfCoordinatorAddress, _linkAddress) {
        bayc = IERC721(_baycAddress);
        bakc = IERC721(_bakcAddress);
        keyHash = _keyHash;
        chainLinkFee = _chainLinkFee;

        traitValues[uint256(Keys.backgrounds)] = ['Apelantic', 'Banana Bay', 'Everglades Ape Park', 'Ape Island', 'Apebiza'];
        traitValues[uint256(Keys.surfboard)] = ['Black', 'Prison', 'Trippy', 'Cheetah', 'Ocean Green', 'Wooden', 'Diamond', 'Mahogany', 'Classic', 'Pink', 'Gold', 'Pizza', 'White Stripes', 'Radioactive', 'USA', 'Polkadots', 'Plastic', 'Banana Pirates', 'Watermelons', 'Rainbow', 'Fomo Blue', 'Pink HOLD', 'Red Apes', 'Lofi Pink', 'Lofi Blue', 'VHS', 'Static'];

        cutoffs[uint256(Keys.backgrounds)] = [30,111,154,197,253];
        cutoffs[uint256(Keys.surfboard)] = [12,19,24,29,41,48,50,57,69,81,83,95,107,114,126,133,138,150,162,174,186,193,205,212,224,231,238];
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function mint(address _to) external onlyMinter returns (uint256) {

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(_to, newTokenId);

        emit Mint(_to);

        return _tokenIds.current();
    }

        function reveal() public onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= chainLinkFee,
            "Not enough LINK - fill contract with faucet"
        );
        require(randomSeed == 0, 'Randomness has already been set');
        requestId = requestRandomness(keyHash, chainLinkFee);
    }

    
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(requestId == _requestId);
        randomSeed = _randomness;

        emit Reveal(_randomness);
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

        uint8[2] memory shifts = [ 0, 8 ];
        uint256[] memory tokenPart = new uint256[](shifts.length);

        for (uint256 i = 0; i < shifts.length; i++) {
            tokenPart[i] = (tokenCode >> shifts[i]) & BITMASK;
        }

        for (uint256 i = 0; i < tokenPart.length; i++) {
            uint256 currentIdx = 0;
            for (uint256 j = 0; j < cutoffs[i].length; j++) {
                if (tokenPart[i] < cutoffs[i][j]) {
                    currentIdx = j;
                    break;
                }
            }
            tokenPart[i] = currentIdx;
        }

        return tokenPart;
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

    function getAttributes(uint256[] memory tokenPart)
        private
        view
        returns (string memory) {

        bytes memory attributes = '"attributes": [';
        bytes memory singleAtt;
        bool attPresent;

        (singleAtt, attPresent) = getAttributeBytes(0, tokenPart[0]);

        attributes = abi.encodePacked(attributes, singleAtt);

        for (uint256 i = 1; i < traits.length; i++) {
            (singleAtt, attPresent) = getAttributeBytes(i, tokenPart[i]);
            if (attPresent) {
                attributes = abi.encodePacked(attributes, ", ", singleAtt);
            }
        }

        return string(attributes);
    }

    function setRevealedCollectionBaseURL(string memory _ipfsHash) onlyOwner public {
        require(!frozen, 'Metadata has been frozen');
        revealedCollectionBaseURL = string(abi.encodePacked('ipfs://', _ipfsHash, '/'));
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
        bytes memory tokenName = abi.encodePacked('Board ', Strings.toString(_tokenId));

        bytes memory content = abi.encodePacked('{"name":"', tokenName, '"');

        if (keccak256(abi.encodePacked(revealedCollectionBaseURL))  == keccak256(abi.encodePacked(''))) {
            content = abi.encodePacked(content, 
                ', ',
                '"description": "An unrevealed Ape Harbour Surfboard"',
                ', ',
                '"image": "', preRevealImageUrl, '"',
                '}');
        } else {
            uint256[] memory tokenParts = decodeTokenId(randomSeed, _tokenId);

            content = abi.encodePacked(content, 
                ', ', 
                getAttributes(tokenParts),
                '], ',
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