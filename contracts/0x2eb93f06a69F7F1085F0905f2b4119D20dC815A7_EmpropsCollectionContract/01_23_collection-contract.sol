// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./token-contract.sol";
pragma solidity ^0.8.4;

contract EmpropsCollectionContract is Ownable, ReentrancyGuard {
    address public tokenContract;
    bool public adminOnly = false;
    uint256 public constant ONE_MILLION = 1000000;
    uint256 public collectionIdCount = 1;
    enum MintMode {
        PUBLIC,
        ALLOWLIST
    }

    constructor(address token, bool isAdminOnly) {
        tokenContract = token;
        adminOnly = isAdminOnly;
    }

    struct Collection {
        address author;
        uint256 price;
        uint64 editions;
        uint16 royalty;
        address freeMinter;
        uint8 status;
        bool flag;
        string metadata;
        MintMode mintMode;
        bytes32 allowlist;
    }

    event CollectionCreated(
        uint256 id,
        address author,
        uint256 price,
        uint64 editions,
        uint16 royalty,
        address freeMinter,
        uint8 status,
        string metadata
    );

    mapping(uint256 => Collection) public collections;
    mapping(uint256 => uint64) public mintCount;
    mapping(uint256 => uint256) public fundsCollected;
    mapping(uint256 => mapping(address => uint128)) public allowlistCount;

    /**
     * @dev Throws if called by any account other than
     * the collection author or contract owner.
     */
    modifier onlyAdmin(uint256 collectionId) {
        require(
            collections[collectionId].author == _msgSender() ||
                owner() == _msgSender(),
            "caller is not the owner or collection creator"
        );
        _;
    }

    function createCollection(
        address author,
        uint256 price,
        uint64 editions,
        uint16 royalty,
        address freeMinter,
        uint8 status,
        string memory metadata,
        MintMode mintMode,
        bytes32 allowlist
    ) public {
        require(royalty <= 10000, "royalty overflows max percentage");
        if (adminOnly) {
            require(
                owner() == _msgSender(),
                "Ownable: caller is not the owner"
            );
        }
        collections[collectionIdCount] = Collection(
            author,
            price,
            editions,
            royalty,
            freeMinter,
            status,
            true,
            metadata,
            mintMode,
            allowlist
        );
        mintCount[collectionIdCount] = 0;

        emit CollectionCreated(
            collectionIdCount,
            author,
            price,
            editions,
            royalty,
            freeMinter,
            status,
            metadata
        );

        collectionIdCount += 1;
    }

    function setStatus(
        uint256 collectionId,
        uint8 status
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].status = status;
    }

    function setMode(
        uint256 collectionId,
        MintMode mode
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].mintMode = mode;
    }

    function setAllowlist(
        uint256 collectionId,
        bytes32 allowlist
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].allowlist = allowlist;
    }

    function mint(
        uint256 collectionId,
        address owner,
        bytes32[] calldata proof,
        uint32 quantity
    ) public payable nonReentrant {
        mintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = mintCount[collectionId];

        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Mint process is disabled at this moment");
        require(msg.value == c.price, "Insufficient funds");
        require(c.editions >= collectionMintCount, "Collection minted out");

        if (c.mintMode == MintMode.ALLOWLIST) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantity));
            require(
                MerkleProof.verify(proof, c.allowlist, leaf),
                "Invalid proof"
            );

            // Checks sender has mints remaining
            require(
                allowlistCount[collectionId][msg.sender] < quantity,
                "User supply minted out"
            );

            // Increase sender's count
            allowlistCount[collectionId][msg.sender] += 1;
        }

        uint256 thisTokenId = (collectionId * ONE_MILLION) +
            collectionMintCount;

        EmpropsTokenContract token = EmpropsTokenContract(tokenContract);
        token.mint(owner, thisTokenId, c.author, c.royalty);

        fundsCollected[collectionId] += msg.value;
    }

    function freeMint(uint256 collectionId, address owner) public {
        mintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = mintCount[collectionId];
        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Mint process is disabled at this moment");
        require(c.freeMinter == _msgSender(), "Sender is not the freeMinter");
        require(c.editions >= collectionMintCount, "Collection minted out");

        uint256 thisTokenId = (collectionId * ONE_MILLION) +
            collectionMintCount;

        EmpropsTokenContract token = EmpropsTokenContract(tokenContract);
        token.mint(owner, thisTokenId, c.author, c.royalty);
    }

    function withdrawFunds(uint256 collectionId) public nonReentrant {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        require(
            collections[collectionId].author == _msgSender(),
            "Sender is not the collection author"
        );
        uint256 funds = fundsCollected[collectionId];
        require(funds > 0, "No funds collected yet");

        // Reset funds collected for this collection
        fundsCollected[collectionId] = 0;

        // Send ether to collection's author
        (bool success, ) = payable(collections[collectionId].author).call{
            value: funds
        }("");
        require(success, "Transfer failed");
    }
}