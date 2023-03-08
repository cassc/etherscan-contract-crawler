// SPDX-License-Identifier: MIT

/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./OperatorFilterer.sol";
import "../interfaces/IOperatorFilterRegistry.sol";

contract CvgPepe is ERC721Enumerable, Ownable, OperatorFilterer {
    enum State {
        NOT_ACTIVE,
        MINT_ACTIVE
    }
    struct BurnRecord {
        address owner;
        uint256 timestamp;
        string btcReceiverAddress;
        string btcTransactionHash;
    }

    State public state;

    bytes32 public merkleRoot;

    uint256 public nextTokenId = 1;
    uint256 public constant MAX_SUPPLY = 117;

    string internal baseURI;

    uint256[] public burntTokenIds;

    mapping(address => bool) public isMinted;

    mapping(uint256 => BurnRecord) public burnRecords;

    constructor(string memory _baseUri)
        ERC721("Convergence Pepe", "cvgPepe")
        OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true)
    {
        baseURI = _baseUri;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setState(State _state) external onlyOwner {
        state = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            MINT
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function mintOwner(uint256 amount) external onlyOwner {
        require(state == State.NOT_ACTIVE, "ALREADY_ACTIVE");
        require(totalSupply() + amount <= MAX_SUPPLY, "MAX_SUPPLY");
        uint256 _tokenId = nextTokenId;
        for (uint256 i; i < amount; ) {
            _mint(msg.sender, _tokenId++);

            unchecked {
                ++i;
            }
        }
        nextTokenId = _tokenId;
    }

    function mintOwnerReceiver(uint256 amount, address[] calldata addresses) external onlyOwner {
        require(state == State.NOT_ACTIVE, "ALREADY_ACTIVE");
        require(totalSupply() + amount <= MAX_SUPPLY, "MAX_SUPPLY");
        require(amount == addresses.length, "LENGTH");
        uint256 _tokenId = nextTokenId;
        for (uint256 i; i < amount; ) {
            _mint(addresses[i], _tokenId++);
            unchecked {
                ++i;
            }
        }
        nextTokenId = _tokenId;
    }

    function mintWl(bytes32[] calldata _merkleProof) external {
        require(state > State.NOT_ACTIVE, "MINT_NOT_ACTIVE");
        require(merkleVerify(_merkleProof), "INVALID_PROOF");
        require(totalSupply() + 1 <= MAX_SUPPLY, "MAX_SUPPLY");
        require(!isMinted[msg.sender], "ALREADY_MINTED");
        isMinted[msg.sender] = true;
        _mint(msg.sender, nextTokenId++);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            BURNS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function burn(uint256 tokenId, string calldata btcReceiverAddress) public {
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNED");

        burnRecords[tokenId] = BurnRecord({
            owner: msg.sender,
            timestamp: block.timestamp,
            btcReceiverAddress: btcReceiverAddress,
            btcTransactionHash: ""
        });
        burntTokenIds.push(tokenId);
        _burn(tokenId);
    }

    function batchBurn(uint256[] calldata tokenIds, string[] calldata btcReceiverAddresses) external {
        require(tokenIds.length == btcReceiverAddresses.length, "Invalid input");
        for (uint256 i; i < tokenIds.length; ) {
            burn(tokenIds[i], btcReceiverAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getBurntTokenIds() external view returns (uint256[] memory) {
        return burntTokenIds;
    }

    function getBurnRecord(uint256 tokenId) external view returns (BurnRecord memory) {
        return burnRecords[tokenId];
    }

    function getBurnRecords(uint256[] calldata tokenId) external view returns (BurnRecord[] memory records) {
        records = new BurnRecord[](tokenId.length);
        for (uint256 i; i < tokenId.length; ) {
            records[i] = burnRecords[tokenId[i]];
            unchecked {
                ++i;
            }
        }
    }

    function getBurnRecords() external view returns (BurnRecord[] memory records) {
        uint256 n = burntTokenIds.length;
        records = new BurnRecord[](n);
        for (uint256 i; i < n; ) {
            records[i] = burnRecords[burntTokenIds[i]];
            unchecked {
                ++i;
            }
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        ADMIN BURNS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function adminBurnOverride(uint256 tokenId, BurnRecord calldata record) external onlyOwner {
        if (burnRecords[tokenId].timestamp == 0) {
            burntTokenIds.push(tokenId);
        }
        burnRecords[tokenId] = record;
    }

    function linkBtcTransactions(uint256[] calldata tokenIds, string[] calldata btcTransactionHash) external onlyOwner {
        require(tokenIds.length == btcTransactionHash.length, "LENGTH");

        for (uint256 i; i < tokenIds.length; ) {
            burnRecords[tokenIds[i]].btcTransactionHash = btcTransactionHash[i];
            unchecked {
                ++i;
            }
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        ALLOWED OPERATOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function merkleVerify(bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}