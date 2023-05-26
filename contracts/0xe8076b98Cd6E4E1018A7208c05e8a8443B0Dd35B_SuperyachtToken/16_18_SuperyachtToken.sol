//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// import "@openzeppelin/contracts/utils/Counters.sol";
import "./NftDescriptor.sol";

contract SuperyachtToken is ERC721, ERC721Burnable, Ownable, VRFConsumerBase {
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;

    // uint256 private yachtIds;

    // prettier-ignore
    // address private immutable ahyAddress;

    // prettier-ignore
    address private constant BURNER_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // prettier-ignore
    bytes32 private constant EMPTY_STRING_HASH = keccak256(abi.encodePacked(""));

    // prettier-ignore
    uint256 public constant MAX_SUPPLY_PLUS_ONE = 7778;

    mapping(uint256 => string) public names;
    mapping(bytes32 => bool) public nameTaken;

    IERC721 private immutable ahy;
    NftDescriptor private nftDescriptor;

    uint256 private immutable mintStart;
    uint256 private immutable mintEnd;

    string internal baseUrl;

    bool private frozen;

    // Random number generation
    uint256 public randomSeed;
    bytes32 internal keyHash;
    uint256 internal chainLinkFee;
    bytes32 public requestId;

    event NameChanged(uint256 indexed yachtId, string indexed name);
    event SetRandomSeed(uint256 randomSeed);

    modifier onlyInClaimingPhase() {
        require(block.timestamp > mintStart, "Claiming hasn't started");
        require(block.timestamp < mintEnd, "Claiming has ended");
        _;
    }

    modifier onlyAfterClaimingPhase() {
        require(block.timestamp > mintEnd, "Not in post claiming phase yet");
        _;
    }

    modifier onlyNotFrozen() {
        require(!frozen, "Contract frozen, no changes possible");
        _;
    }

    constructor(
        uint256 _mintStartTS,
        address _nftDescriptorAddress,
        address _ahyAddress,
        address _linkAddress,
        address _vrfCoordinatorAddress,
        bytes32 _keyHash,
        uint256 _chainLinkFee
    ) ERC721("Ape Harbour Superyachts", "AHSY") VRFConsumerBase(_vrfCoordinatorAddress, _linkAddress) {
        ahy = IERC721(_ahyAddress);
        mintStart = _mintStartTS;
        mintEnd = _mintStartTS + 30 days;
        nftDescriptor = NftDescriptor(_nftDescriptorAddress);
        keyHash = _keyHash;
        chainLinkFee = _chainLinkFee;
        frozen = false;
        baseUrl = "ipfs://<HASH>/";
    }

    function claim(uint256[] memory ogYachts)
        external
        onlyInClaimingPhase
        returns (uint256)
    {
        for (uint256 i; i < ogYachts.length; i++) {
            require(!_exists(ogYachts[i]), "Yacht has been claimed already");
            require(
                ahy.ownerOf(ogYachts[i]) == msg.sender,
                "You do not own a yacht"
            );

            _mint(msg.sender, ogYachts[i]);
        }

        return ogYachts.length;
    }

    function claimAH(uint256[] memory _superyachtIds)
        external
        onlyOwner
        onlyAfterClaimingPhase
        returns (uint256)
    {
        for (uint256 i = 0; i < _superyachtIds.length; i++) {
            require(
                !_exists(_superyachtIds[i]),
                "Yacht has been claimed already"
            );
            _mint(msg.sender, _superyachtIds[i]);
        }

        return _superyachtIds.length;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function updateNftDescriptor(address _nftDescriptorAddress) external onlyOwner onlyNotFrozen {
        nftDescriptor = NftDescriptor(_nftDescriptorAddress);
    }

    function setBaseUrl(string memory _ipfsHash) external onlyOwner onlyNotFrozen {
        baseUrl = string(abi.encodePacked("ipfs://", _ipfsHash, "/"));
    }

    function freeze() external onlyOwner {
        frozen = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable receiver = payable(msg.sender);
        receiver.transfer(balance);
    }

    function setName(
        uint256 _yachtId,
        string memory _yachtName,
        uint256 _ogYachtToBurn
    ) public {
        bytes32 hashedName = keccak256(abi.encodePacked(toLower(_yachtName)));

        require(
            keccak256(abi.encodePacked(names[_yachtId])) == EMPTY_STRING_HASH,
            "Yacht has already been named"
        );
        require(!nameTaken[hashedName], "Name already taken");

        ahy.safeTransferFrom(_msgSender(), BURNER_ADDRESS, _ogYachtToBurn);

        nameTaken[hashedName] = true;
        names[_yachtId] = _yachtName;

        emit NameChanged(_yachtId, _yachtName);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            nftDescriptor.tokenURI(
                _tokenId,
                names[_tokenId],
                randomSeed,
                baseUrl
            );
    }


    function requestRandomSeed() external onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= chainLinkFee,
            "Not enough LINK - fill contract with faucet"
        );
        require(randomSeed == 0, "randomSeed has already been set");
        requestId = requestRandomness(keyHash, chainLinkFee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(requestId == _requestId, "Wrong request Id");
        require(randomSeed == 0, "randomSeed has already been set");
        randomSeed = _randomness;

        emit SetRandomSeed(_randomness);
    }



    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}