//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Trophy is Ownable, ERC721, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    bytes32 public immutable merkleRoot;
    uint256 public constant MAX_SUPPLY = 476;
    string public uri;
    string public provenance;
    mapping(address => bool) internal claimStatus;

    event SetBaseURI(string baseUri);
    event SetProvenance(string provenance);
    event Minted(address indexed user, uint256 entries);
    event MintUnclaimed(uint256 entries);

    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        bytes32 _merkleRoot
    ) ERC721(_nftName, _nftSymbol) {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        uri = _uri;
        emit SetBaseURI(_uri);
    }

    function setProvenance(string calldata _provenance) public onlyOwner {
        provenance = _provenance;
        emit SetProvenance(_provenance);
    }

    function isClaimed(address _callerAddr) public view returns (bool) {
        return claimStatus[_callerAddr];
    }

    function mint(uint256 numOfTokens, bytes32[] calldata merkleProof)
        external
        nonReentrant
    {
        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender, numOfTokens));

        require(claimStatus[msg.sender] == false, "Already claimed");

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid Proof"
        );

        require(
            _tokenIds.current() + numOfTokens <= MAX_SUPPLY,
            "Max mints reached"
        );

        for (uint256 i = 0; i < numOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }

        claimStatus[msg.sender] = true;

        emit Minted(msg.sender, numOfTokens);
    }

    function mintUnclaimed(uint256 numOfTokens) external onlyOwner {
        require(
            _tokenIds.current() + numOfTokens <= MAX_SUPPLY,
            "Max mints reached"
        );

        for (uint256 i = 0; i < numOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }

        emit MintUnclaimed(numOfTokens);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId > 0, "Token id cannot be less than 1.");
        require(tokenId <= _tokenIds.current(), "Token id exceeds max limit");

        return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}