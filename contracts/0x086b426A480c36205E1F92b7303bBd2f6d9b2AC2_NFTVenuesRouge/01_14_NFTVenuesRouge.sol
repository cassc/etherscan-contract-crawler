// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTVenuesRouge is ERC721, Ownable, ERC721Burnable {

    // Whitelist state
    struct WhiteList {
        // The amount to pay
        uint256 mintValue;
        // The root of the merkle tree
        bytes32 rootHash;
        // The amount of tokens an address can mint
        uint8 cap;
        mapping(address => uint256) capTracker;
    }
    // whitelist id => whitelist
    mapping (uint8 => WhiteList) public whiteLists;
    uint8 public openWhiteListId = 0;

    bool public isMintOpen = false;
    uint256 public openMintValue = 150000000000000000;



    // Token
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxSupply = 3000;
    address public feeReceiver;


    string public _provenanceHash;
    string public _baseURL;


    constructor() ERC721("NFTVenues Rouge", "NVR") {}

    function _baseMint(uint256 count, address recipient, uint256 mintValue) private {
        require(_tokenIds.current() + count <= maxSupply, "Can not mint more than max supply.");
        require(msg.value >= count * mintValue, "Insufficient payment");

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }

        bool success = false;
        (success,) = feeReceiver.call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function airdrop(address receiver, uint256 amount) external onlyOwner {
        _baseMint(amount, receiver, 0);
    }

    function mint(uint256 amount) external payable {
        require(isMintOpen, "Mint is not active.");
        require(amount > 0 && amount <= 10, "You can mint between 1 and 10 in one transaction.");
        _baseMint(amount, msg.sender, openMintValue);
    }

    function whiteListMint(uint256 amount, bytes32[] calldata proof) external payable {
        WhiteList storage whiteList = whiteLists[openWhiteListId];
        require(whiteList.rootHash != bytes32(0), "Whitelist phase is not active.");
        require(
            amount > 0 && amount + whiteList.capTracker[msg.sender] <= whiteList.cap,
                "You are exceeded the amount of tokens you can mint for this white list"
        );
        require(_verify(_leaf(msg.sender), proof, whiteList.rootHash), "Address not in white list.");
        whiteList.capTracker[msg.sender] += amount;
        _baseMint(amount, msg.sender, whiteList.mintValue);
    }

    // Merkle utils
    function _leaf(address recipient)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(recipient));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 rootHash)
    internal pure returns (bool)
    {
        return MerkleProof.verify(proof, rootHash, leaf);
    }

    // Setters
    function addWhiteList(uint8 whiteListId, uint256 mintValue, bytes32 rootHash, uint8 cap) public onlyOwner {
        require(whiteListId != 0, "whiteListId must be greater than 0");
        WhiteList storage whiteList = whiteLists[whiteListId];
        whiteList.mintValue = mintValue;
        whiteList.rootHash = rootHash;
        whiteList.cap = cap;
    }

    function flipMintState() public onlyOwner {
        isMintOpen = !isMintOpen;
    }

    function startWhitelist(uint8 whiteListId) public onlyOwner {
        openWhiteListId = whiteListId;
    }

    function startMinting() public onlyOwner {
        openWhiteListId = 0;
        isMintOpen = true;
    }

    function setOpenMintValue(uint256 newMintValue) public onlyOwner {
        openMintValue = newMintValue;
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        feeReceiver = newFeeReceiver;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;
    }

    function setBaseURL(string memory newBaseURI) public onlyOwner {
        _baseURL = newBaseURI;
    }

    // Getters
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function whiteListCapTracker(uint8 whiteListId, address wallet) public view returns (uint256) {
        return whiteLists[whiteListId].capTracker[wallet];
    }

    function getWhiteList(uint8 whiteListId) public view returns (uint256, bytes32, uint8) {
        WhiteList storage whiteList = whiteLists[whiteListId];
        return (whiteList.mintValue, whiteList.rootHash, whiteList.cap);
    }
}