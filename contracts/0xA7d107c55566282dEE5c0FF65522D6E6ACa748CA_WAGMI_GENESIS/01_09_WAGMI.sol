//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AEnumarable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WAGMI_GENESIS is Ownable, ERC721AEnumerable {
    using Strings for uint256;
    string private _baseTokenURI;

    bytes32 private rootMembers;

    uint256 public totalMinted;

    mapping(address => uint256) userMinted;
    uint256 public mintLimit = 1;

    bool public mintable; // false

    mapping(uint256 => bool) isSold;
    mapping(uint256 => bool) isClaimed;

    uint256 maxSupply = 231;

    string public constant PROVENANCE =
        "f2982d58f8ec0a86a0d69a08778f8c2c1e493296ccabb59ff695c7a01a1c631c";

    constructor(
        string memory baseTokenURI,
        bytes32 _rootMembers
    ) ERC721A("WAGMI Genesis", "WAGMI_GENESIS") {
        rootMembers = _rootMembers;
        _baseTokenURI = baseTokenURI;
        _safeMint(msg.sender, 175);
    }

    function setRootMembers(bytes32 _rootMembers) external onlyOwner {
        rootMembers = _rootMembers;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function newPhase(uint256 _newMax) external onlyOwner {
        maxSupply = _newMax;
    }

    function setMintable() external onlyOwner {
        mintable = !mintable;
    }

    function setNewLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function mint(bytes32[] calldata _merkleProof) external {
        if (msg.sender != owner()) {
            require(mintable, "mint_not_started");
            bytes32 leaf = bytes32(uint256(uint160(msg.sender)));

            require(
                MerkleProof.verify(_merkleProof, rootMembers, leaf),
                "mint_player_not_whitelisted"
            );
            require(
                userMinted[msg.sender] < mintLimit,
                "mint_player_limit_reached"
            );
        }
        require(totalMinted < maxSupply, "mint_limit_reached");

        userMinted[msg.sender]++;
        totalMinted++;
        _safeMint(msg.sender, 1);
    }

    function batchMint(uint256 amount) external onlyOwner {
        require(totalMinted + amount <= maxSupply, "batch_mint_limit_reached");

        totalMinted += amount;
        _safeMint(msg.sender, amount);
    }

    function isWhitelisted(
        address _user,
        bytes32[] calldata _merkleProof
    ) external view returns (bool result) {
        bytes32 leaf = bytes32(uint256(uint160(_user)));
        if (MerkleProof.verify(_merkleProof, rootMembers, leaf)) {
            result = true;
        } else {
            result = false;
        }
    }

    // OVERRIDES

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "token_uri_not_found");
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}