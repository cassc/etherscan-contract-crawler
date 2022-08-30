// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract DOGsFirstBirthday is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string[] baseTokenURIs;
    uint256 public totalSupply;
    mapping(uint256 => uint256) tokenURITypes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(bytes32 _merkleRoot, string[] memory _baseTokenURIs, uint256 _totalSupply) initializer public {
        __ERC721_init("DOGs First Birthday", "DOGFirstBirthday");
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        merkleRoot = _merkleRoot;
        baseTokenURIs = _baseTokenURIs;
        totalSupply = _totalSupply;
    }

    function safeMint(bytes32[] calldata _merkleProof, uint256 _tokenURIType) public whenNotPaused {
        // make sure address has not already claimed
        require(!whitelistClaimed[msg.sender], "Address already claimed");

        // leaf from caller
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // require user to be whitelisted to claim
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not in whitelisted addresses");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + 1 < totalSupply, "Total supply exceeded");

        // mark address as claimed
        whitelistClaimed[msg.sender] = true;

        _tokenIdCounter.increment();
        tokenURITypes[tokenId] = _tokenURIType;
        _safeMint(msg.sender, tokenId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function hasClaimed(address account) public view returns (bool) {
        return whitelistClaimed[account];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseTokenURIs[tokenURITypes[tokenId]];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(
        address ,
        address,
        uint256
    ) internal override pure{
        revert("not allowed transfer");
    }

    function setBaseURIs(string[] memory _baseTokenURIs) public onlyOwner {
        baseTokenURIs = _baseTokenURIs;
    }

    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }
}