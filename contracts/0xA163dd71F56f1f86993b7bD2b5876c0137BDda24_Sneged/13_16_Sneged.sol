// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./utils/ERC721Enumerable.sol";
import "./utils/OpenSea.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Sneged is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    address payable internal team =
        payable(0x11c965C6cFb836D76ef9BcEaA4aB7E3873ea7bC7);
    address payable internal dev =
        payable(0x19C5B892f2c742AA1FC8452390cbe7Abf39b836d);

    uint256 public constant MINT_COST = 0.0199 ether;
    uint256 public MAX_SUPPLY = 9999;
    uint256 public MAX_PUBLIC = 4000;
    uint256 public MAX_PER_WLT = 5;
    uint256 public RESERVED_SUPPLY = 1700;
    uint256 public freeTokensMinted = 0;
    uint256 public publicTokens = 0;
    string private _preReveal =
        "ipfs://QmdTnCXopKcidLt5zemvXkv6nudUfSV1ZdnoDV2EfQkBYv";

    bytes32 public merkleRoot;

    bool public isPublic;
    bool public isPresale;

    mapping(address => uint256) public addressToMinted;

    constructor() ERC721("Sneged", "Sneged") {}

    function mint(uint256 count) external payable nonReentrant {
        require(isPublic, "Wait for public sale");
        require(
            addressToMinted[msg.sender] + count <= MAX_PER_WLT,
            "Exceeds limit per wallet"
        );
        addressToMinted[msg.sender] += count;
        uint256 supply = _owners.length;
        publicTokens += count;
        uint256 maxSupply = MAX_SUPPLY - (RESERVED_SUPPLY - freeTokensMinted);

        require(publicTokens <= MAX_PUBLIC, "Max public supply reached");
        require(supply + count < maxSupply + 2, "Max supply reached");
        require(MINT_COST * count <= msg.value, "Invalid funds provided");
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function presaleMint(
        bool freeRoot,
        uint256 count,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(isPresale, "Wait for presale");

        bytes32 leaf = keccak256(abi.encodePacked(freeRoot, msg.sender));
        require(_verify(leaf, proof), "Invalid proof");
        require(
            addressToMinted[msg.sender] + count <= MAX_PER_WLT,
            "Exceeds your allowance"
        );

        bool hasFreeMint = freeRoot &&
            addressToMinted[msg.sender] == 0 &&
            freeTokensMinted < RESERVED_SUPPLY;
        if (hasFreeMint) freeTokensMinted++;
        uint256 maxSupply = MAX_SUPPLY - (RESERVED_SUPPLY - freeTokensMinted);

        uint256 supply = _owners.length;
        string memory errMsg = "Max supply reached";
        if (supply + 1 < maxSupply + 2) errMsg = "Only free mints left";
        require(supply + count < maxSupply + 2, errMsg);

        uint256 payedMints = hasFreeMint ? count - 1 : count;

        addressToMinted[msg.sender] += count;
        string memory fundMsg = "Invalid funds provided";
        if (freeTokensMinted >= RESERVED_SUPPLY)
            fundMsg = "Invalid funds (free supply exhausted)";
        require(MINT_COST * payedMints <= msg.value, fundMsg);

        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        tokenId.toString(),
                        _tokenURISuffix
                    )
                )
                : _preReveal;
    }

    function toggleSales() external onlyOwner {
        isPublic = !isPublic;
        isPresale = !isPresale;
    }

    function togglePresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        require(maxSupply < MAX_SUPPLY, "New value must be < MAX_SUPPLY");
        MAX_SUPPLY = maxSupply;
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setPreReveal(string calldata _newPreReveal) external onlyOwner {
        _preReveal = _newPreReveal;
    }

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity;
        for (uint256 i; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(supply + totalQuantity < MAX_SUPPLY + 2, "Max supply reached");

        delete totalQuantity;

        for (uint256 i; i < recipient.length; ++i) {
            for (uint256 j; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function withdrawFunds() external virtual onlyOwner {
        uint256 devPart = (address(this).balance * 3) / 40; //7.5%
        dev.transfer(devPart);
        team.transfer(address(this).balance);
    }
}