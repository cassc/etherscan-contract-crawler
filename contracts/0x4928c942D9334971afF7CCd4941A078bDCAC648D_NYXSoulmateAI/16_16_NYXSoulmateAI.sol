// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NYXSoulmateAI is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public constant MAX_SOUL_SUPPLY = 10000;
    uint256 public maxPerWalletAl = 3;
    uint256 public maxPerWallet = 10;
    uint256 public publicMintCost = 88000000000000000; // 0.088 ETH
    uint256 public allowlistMintCost = 70000000000000000; // 0.07 ETH
    uint256 public tmpMaxSupply = 5000; // can never be higher than MAX_SOUL_SUPPLY
    uint256 public burnedSouls;

    bytes32 public merkleRoot;

    bool public isPublic;
    bool public isAllowList;
    bool public isBurningAllowed;

    mapping(address => uint256) public mintedCount;
    mapping(address => bool) public hasFreeMint;

    address payable internal constant po =
        payable(0x088927f87d11BE6C5D0411097aD0b7eaC89b9455);
    address payable internal constant dev =
        payable(0x9933Fc3Ae2188Ff5C53AEB6a24f31104733CD87F);

    constructor() ERC721("NYX Soulmate A.I.", "NYXAI") {}

    function mint(uint256 count) external payable nonReentrant {
        require(isPublic, "Public mint closed");

        if (hasFreeMint[msg.sender]) {
            require(
                mintedCount[msg.sender] + count <= maxPerWallet + 1,
                "Exceeds your allowance"
            );
        } else {
            require(
                mintedCount[msg.sender] + count <= maxPerWallet,
                "Exceeds your allowance"
            );
        }

        mintedCount[msg.sender] += count;

        uint256 supply = _owners.length;
        require(supply + count <= tmpMaxSupply, "Max supply reached");

        require(publicMintCost * count == msg.value, "Invalid funds provided");

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function allowListMint(
        bool freeRoot,
        uint256 count,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(isAllowList, "Wait for allowlist mint");

        bytes32 leaf = keccak256(abi.encodePacked(freeRoot, msg.sender));
        require(_verify(leaf, proof), "Invalid proof");

        bool isFreeMint = freeRoot && !hasFreeMint[msg.sender];

        if (isFreeMint) {
            require(
                mintedCount[msg.sender] + count <= maxPerWalletAl + 1,
                "Exceeds your allowance"
            );
            hasFreeMint[msg.sender] = true;
        } else if (hasFreeMint[msg.sender]) {
            require(
                mintedCount[msg.sender] + count <= maxPerWalletAl + 1,
                "Exceeds your allowance"
            );
        } else {
            require(
                mintedCount[msg.sender] + count <= maxPerWalletAl,
                "Exceeds your allowance"
            );
        }

        mintedCount[msg.sender] += count;

        uint256 supply = _owners.length;
        require(supply + count <= tmpMaxSupply, "Max supply reached");

        uint256 payedCount = isFreeMint ? count - 1 : count;
        require(
            allowlistMintCost * payedCount == msg.value,
            "Invalid funds provided"
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function burnMultiple(uint256[] calldata tokenIds) external nonReentrant {
        require(isBurningAllowed, "Burning not authorized");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenIds[i]),
                "Unauthorized"
            );
            _burn(tokenIds[i]);
        }
        burnedSouls += tokenIds.length;
    }

    function burnSingle(uint256 tokenId) external nonReentrant {
        require(isBurningAllowed, "Burning not authorized");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Unauthorized");
        _burn(tokenId);
        burnedSouls++;
    }

    /* VIEW FUNCTIONS */

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
        require(bytes(_baseTokenURI).length > 0, "Base URI missing");
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    /* ONLY OWNER FUNCTIONS */

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(
            supply + totalQuantity <= MAX_SOUL_SUPPLY,
            "Max supply reached"
        );

        delete totalQuantity;

        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function toggleAllowList() external onlyOwner {
        isAllowList = !isAllowList;
    }

    function toggleSales() external onlyOwner {
        isPublic = !isPublic;
        isAllowList = !isAllowList;
    }

    function togglePublicSale() external onlyOwner {
        isPublic = !isPublic;
    }

    function toggleBurningAllowed() external onlyOwner {
        isBurningAllowed = !isBurningAllowed;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setTmpMaxSupply(uint256 maxSupply) external onlyOwner {
        require(
            maxSupply <= MAX_SOUL_SUPPLY,
            "New max supply must be lower than MAX_SOUL_SUPPLY"
        );
        require(
            maxSupply > tmpMaxSupply,
            "New max supply must be higher than tmpMaxSupply"
        );
        tmpMaxSupply = maxSupply;
    }

    function setPublicMintCost(uint256 mintCost) external onlyOwner {
        publicMintCost = mintCost;
    }

    function setAllowListMintCost(uint256 mintCost) external onlyOwner {
        allowlistMintCost = mintCost;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerWalletAL(uint256 _maxPerWallet) external onlyOwner {
        maxPerWalletAl = _maxPerWallet;
    }

    function setBaseURI(string calldata newBaseURI, string calldata newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = newBaseURI;
        _tokenURISuffix = newSuffix;
    }

    function withdraw() external onlyOwner {
        uint256 devPart = ((address(this).balance * 5) / 100);
        dev.transfer(devPart);
        po.transfer(address(this).balance);
    }

    /* INTERNAL FUNCTIONS */

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length - burnedSouls;
    }
}