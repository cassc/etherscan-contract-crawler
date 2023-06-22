// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Cumming is ERC721, Ownable, ERC721Burnable {
    // Whitelist state
    // Merkle tree root hash
    bytes32 public _rootHash;

    // Token state
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 6969;

    string public _provenanceHash;
    string public _baseURL;

    bool private _isWhiteListOpen = false;
    bool private _isMintOpen = false;

    // One address can mint up to 10 tokens in the white list phase
    mapping(address => uint256) private _whiteListCapTracker;
    uint256 private WHITE_LIST_CAP = 10;


    constructor() ERC721("Cumming", "CMG") {}

    function _freeMint(uint256 count, address recipient) private {
        require(_tokenIds.current() + count <= _maxSupply, "Can not mint more than max supply.");

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }
    }

    function mint(uint256 amount) external {
        require(_isMintOpen, "Free mint is not active.");
        require(amount > 0 && amount <= 10, "You can mint between 1 and 10 in one transaction.");
        _freeMint(amount, msg.sender);
    }

    function whiteListMint(uint256 amount, bytes32[] calldata proof) external {
        require(_isWhiteListOpen, "Whitelist is not active.");
        require(amount > 0 && amount + _whiteListCapTracker[msg.sender] <= WHITE_LIST_CAP, "You can mint between 1 and 10 in total.");
        require(_verify(_leaf(msg.sender), proof), "Address not in white list.");
        _whiteListCapTracker[msg.sender] += amount;
        _freeMint(amount, msg.sender);
    }

    function reservedMint(uint amount, address recipient) public onlyOwner {
        _freeMint(amount, recipient);
    }

    // Merkle utils
    function _leaf(address recipient)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(recipient));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, _rootHash, leaf);
    }

    // Setters
    function flipWhiteListState() public onlyOwner {
        _isWhiteListOpen = !_isWhiteListOpen;
    }

    function flipMintState() public onlyOwner {
        _isMintOpen = !_isMintOpen;
    }

    function startFreeMinting() public onlyOwner {
        _isWhiteListOpen = false;
        _isMintOpen = true;
    }

    function setRootHash(bytes32 newRootHash) public onlyOwner {
        _rootHash = newRootHash;
    }

    // Setters
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        _maxSupply = newMaxSupply;
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

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function isWhiteListOpen() public view returns (bool) {
        return _isWhiteListOpen;
    }

    function isMintOpen() public view returns (bool) {
        return _isMintOpen;
    }

    function whiteListCapTracker(address wallet) public view returns (uint256) {
        return _whiteListCapTracker[wallet];
    }
}