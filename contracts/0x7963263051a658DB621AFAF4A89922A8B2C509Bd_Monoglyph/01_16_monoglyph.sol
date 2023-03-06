// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Monoglyph is ReentrancyGuard, ERC721, Ownable {
    using Strings for uint256;

    IERC721Enumerable private _parent;

    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_SUPPLY = 256;

    uint256 public pricePerToken = 0.1 ether;

    bool public isAllowListActive;
    bool public isSaleActive;
    bool public isClaimActive;

    mapping(address => uint256) public allowListNumMinted;
    mapping(uint256 => string) public scripts;
    mapping(uint256 => bytes32[]) internal _tokenSeeds;

    string public communityHash;
    string public traitScript;
    string public provenanceHash;
    bytes32 public merkleRoot;

    string private _baseURIextended;
    uint256 public immutable PARENT_SUPPLY;

    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;

    constructor(address parentAddress, uint256 _parentSupply)
        ERC721("Monoglyph", "MNGL")
    {
        require(
            IERC721Enumerable(parentAddress).supportsInterface(0x780e9d63),
            "Not ERC721Enumerable"
        );
        _parent = IERC721Enumerable(parentAddress);
        PARENT_SUPPLY = _parentSupply;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _claim(uint256 startingIndex, uint256 numberOfTokens) internal {
        require(isClaimActive, "Claim must be active to mint tokens");
        require(numberOfTokens > 0, "Must claim at least one token.");
        uint256 balance = _parent.balanceOf(msg.sender);
        require(
            balance >= startingIndex + numberOfTokens,
            "Insufficient parent tokens."
        );

        for (uint256 i; i < balance && i < numberOfTokens; i++) {
            uint256 parentTokenId = _parent.tokenOfOwnerByIndex(
                msg.sender,
                i + startingIndex
            );
            if (!_exists(parentTokenId)) {
                _mintToken(msg.sender, parentTokenId);
            }
        }
    }

    function claim(uint256 startingIndex, uint256 numberOfTokens)
        external
        nonReentrant
        callerIsUser
    {
        _claim(startingIndex, numberOfTokens);
    }

    function claimAll() external nonReentrant callerIsUser {
        _claim(0, _parent.balanceOf(msg.sender));
    }

    function claimByTokenIds(uint256[] calldata _parentTokenIds)
        external
        nonReentrant
        callerIsUser
    {
        require(isClaimActive, "Claim must be active to mint tokens");
        require(_parentTokenIds.length > 0, "Must claim at least one token.");
        for (uint256 i; i < _parentTokenIds.length; i++) {
            require(
                _parent.ownerOf(_parentTokenIds[i]) == msg.sender,
                "Must own all parent tokens."
            );
            if (!_exists(_parentTokenIds[i])) {
                _mintToken(msg.sender, _parentTokenIds[i]);
            }
        }
    }

    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(isAllowListActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Not on allow list");
        require(
            numberOfTokens <=
                MAX_ALLOWLIST_MINT - allowListNumMinted[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            this.totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            pricePerToken * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        allowListNumMinted[msg.sender] += numberOfTokens;
        for (uint256 i; i < numberOfTokens; i++) {
            uint256 tokenId = this.totalSupply();
            _mintToken(msg.sender, tokenId);
            _totalPublicSupply.increment();
        }
    }

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(isSaleActive, "Sale must be active to mint tokens");
        require(
            numberOfTokens <= MAX_PUBLIC_MINT,
            "Exceeded max token purchase"
        );
        require(
            this.totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            pricePerToken * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfTokens; i++) {
            uint256 tokenId = this.totalSupply();
            _mintToken(msg.sender, tokenId);
            _totalPublicSupply.increment();
        }
    }

    function _mintToken(address _to, uint256 _tokenId) internal {
        bytes32 seed = keccak256(
            abi.encodePacked(_tokenId, provenanceHash, communityHash)
        );
        _tokenSeeds[_tokenId].push(seed);
        _safeMint(_to, _tokenId);
    }

    function setSaleActive(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    function setClaimActive(bool newState) external onlyOwner {
        isClaimActive = newState;
    }

    function setAllowListActive(bool newState) external onlyOwner {
        isAllowListActive = newState;
    }

    function setAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function onAllowList(address claimer, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function numAvailableToMint(address claimer, bytes32[] memory proof)
        public
        view
        returns (uint256)
    {
        if (onAllowList(claimer, proof)) {
            return MAX_ALLOWLIST_MINT - allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    function setScript(uint256 _indexes, string memory _script)
        external
        onlyOwner
    {
        scripts[_indexes] = _script;
    }

    function setCommunityHash(string memory _communityHash) external onlyOwner {
        communityHash = _communityHash;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setTraitScript(string memory _traitScript) external onlyOwner {
        traitScript = _traitScript;
    }

    function showTokenSeeds(uint256 _tokenId)
        external
        view
        returns (bytes32[] memory)
    {
        return _tokenSeeds[_tokenId];
    }

    function totalSupply() public view returns (uint256) {
        return _totalPublicSupply.current() + PARENT_SUPPLY;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token ID does not exist");
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}