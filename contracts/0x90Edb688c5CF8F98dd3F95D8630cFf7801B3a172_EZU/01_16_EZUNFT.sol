// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./utils/ERC721Enumerable.sol";
import "./utils/OpenSea.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EZU is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    address payable internal team =
        payable(0xe629791e0314370Af8B602fc174dF66D4189beb8);
    address payable internal dev =
        payable(0x66Fa6Ee62835e0A986973adaDCD1C80E0cBC3f85);

    uint256 public constant MINT_COST = 0.02 ether;
    uint256 public MAX_SUPPLY = 15000;
    uint256 public RESERVED_SUPPLY = 0;
    uint256 public freeTokensMinted = 0;
    string private _preReveal;

    bytes32 public merkleRoot;

    bool public isPublic;
    bool public isPresale;
    bool public isBurningAllowed;

    mapping(address => uint256) public addressToMinted;

    constructor() ERC721("EZUXYZ", "EZU") {}

    function mint(uint256 count) external payable nonReentrant {
        require(isPublic, "Wait for public sale");
        require(
            addressToMinted[msg.sender] + count <= 5,
            "Exceeds limit per wallet"
        );
        addressToMinted[msg.sender] += count;
        uint256 supply = _owners.length;
        uint256 maxSupply = MAX_SUPPLY - (RESERVED_SUPPLY - freeTokensMinted);
        require(supply + count < maxSupply + 2, "Max supply reached");
        require(MINT_COST * count <= msg.value, "Invalid funds provided");
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function presaleMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(isPresale, "Wait for presale");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(_verify(leaf, proof), "Invalid proof");
        require(
            addressToMinted[msg.sender] + count <= allowance,
            "Exceeds your allowance"
        );

        bool hasFreeMint = addressToMinted[msg.sender] == 0;
        if (hasFreeMint) freeTokensMinted++;
        addressToMinted[msg.sender] += count;

        uint256 supply = _owners.length;

        uint256 maxSupply = MAX_SUPPLY - (RESERVED_SUPPLY - freeTokensMinted);
        string memory errMsg = "Max payed supply reached";
        if (hasFreeMint && supply + 1 < maxSupply + 2)
            errMsg = "Only free mints left";

        require(supply + count < maxSupply + 2, errMsg);

        uint256 payedMints = hasFreeMint ? count - 1 : count;

        require(MINT_COST * payedMints <= msg.value, "Invalid funds provided");

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

    function burn(uint256 tokenId) external {
        require(isBurningAllowed, "Burning not authorized");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Unauthorized");
        _burn(tokenId);
    }

    function toggleSales() external onlyOwner {
        isPresale = !isPresale;
        isPublic = !isPublic;
    }

    function togglePresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function toggleIsBurningAllowed() external onlyOwner {
        isPublic = false;
        isBurningAllowed = !isBurningAllowed;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        require(
            maxSupply > 942 && maxSupply < 6942,
            "New max supply must be lower than 6942 and higher than 942"
        );
        MAX_SUPPLY = maxSupply;
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setPreRevealURL(string calldata _newPreReveal) external onlyOwner {
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
        override(ERC721,IERC721)
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function withdrawAllFunds() external onlyOwner {
        uint256 devPart = address(this).balance / 8;
        dev.transfer(devPart);
        team.transfer(address(this).balance);
    }
}