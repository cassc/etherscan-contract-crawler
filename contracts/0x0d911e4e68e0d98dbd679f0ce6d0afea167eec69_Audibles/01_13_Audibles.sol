// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AudiblesKeyManagerIncreaseKeysInterface} from "./AudiblesKeyManagerInterface.sol";

contract Audibles is ERC721A, ERC721AQueryable, Ownable {
    using ECDSA for bytes32;

    event MetadataKey(bytes32 indexed key);
    event TokenInscribed(
        uint256 indexed tokenId,
        bytes32 indexed inscriptionId
    );

    enum GridSize {
        grid8x8,
        grid16x16,
        grid24x24,
        grid32x32,
        grid64x64
    }

    uint16[5] public gridSupply = [444, 1111, 2444, 3444, 9999];
    uint256[5] public gridPrice = [
        0.0088 ether,
        0.0133 ether,
        0.0177 ether,
        0.022 ether,
        0.03 ether
    ];

    bytes32 public freeMintRoot;
    uint32 public mintStartTime;
    uint32 public mintEndTime;
    address public signer;
    address public audiblesKeyManager;
    string private _baseTokenURI;
    string[] private _baseGridURI;
    bool public burnUnlocked;
    bool public metadataUnlocked;

    mapping(GridSize => uint16) public gridCurrentSupply;
    mapping(uint256 => GridSize) public tokenGridSize;
    mapping(address => bool) public freeMintUsed;

    constructor(
        address newAudiblesKeyManager,
        address newSigner,
        uint32 mintStart,
        uint32 mintEnd
    ) ERC721A("Audibles", "AUDIBLES") {
        audiblesKeyManager = newAudiblesKeyManager;
        signer = newSigner;
        mintStartTime = mintStart;
        mintEndTime = mintEnd;
    }

    function freeMint(
        GridSize size,
        bytes32[] calldata proof,
        bytes32 data
    ) external {
        require(
            block.timestamp >= mintStartTime && block.timestamp < mintEndTime,
            "Mint not active"
        );
        require(!freeMintUsed[msg.sender], "Free mint used");
        require(
            MerkleProof.verify(
                proof,
                freeMintRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Cannot use free mint"
        );
        require(
            gridCurrentSupply[size] + 1 <= gridSupply[uint(size)],
            "Grid size sold out"
        );
        uint256 tokenId = _nextTokenId();
        _safeMint(msg.sender, 1);
        tokenGridSize[tokenId] = size;
        freeMintUsed[msg.sender] = true;
        AudiblesKeyManagerIncreaseKeysInterface(audiblesKeyManager)
            .increaseKeys(msg.sender, uint8(size), 1);
        gridCurrentSupply[size]++;
        emit MetadataKey(data);
    }

    function publicMint(
        GridSize size,
        uint8 quantity,
        bytes32 data
    ) external payable {
        require(
            block.timestamp >= mintStartTime && block.timestamp < mintEndTime,
            "Mint not active"
        );
        require(
            gridCurrentSupply[size] + quantity <= gridSupply[uint(size)],
            "Grid size sold out"
        );
        require(quantity <= 10, "Minting too many in transaction");
        require(
            msg.value == gridPrice[uint(size)] * quantity,
            "Insufficient payment"
        );
        uint256 tokenId = _nextTokenId();
        _safeMint(msg.sender, quantity);
        unchecked {
            for (uint8 i = 0; i < quantity; ++i) {
                tokenGridSize[tokenId + i] = size;
            }
        }
        AudiblesKeyManagerIncreaseKeysInterface(audiblesKeyManager)
            .increaseKeys(msg.sender, uint8(size), quantity);
        gridCurrentSupply[size] += quantity;
        emit MetadataKey(data);
    }

    function burnForKeys(uint256 tokenId) external {
        require(burnUnlocked, "Cannot burn");
        _burn(tokenId);
        AudiblesKeyManagerIncreaseKeysInterface(audiblesKeyManager)
            .increaseKeysBurn(msg.sender);
    }

    function inscribeForKeys(
        uint256 tokenId,
        bytes32 inscriptionId,
        bytes calldata signature
    ) external {
        require(burnUnlocked, "Cannot burn");
        bytes32 hash = keccak256(
            abi.encodePacked(
                tokenId,
                inscriptionId,
                keccak256(abi.encodePacked(msg.sender))
            )
        );
        address recovered = hash.toEthSignedMessageHash().recover(signature);
        require(signer == recovered, "Invalid action");
        _burn(tokenId);
        AudiblesKeyManagerIncreaseKeysInterface(audiblesKeyManager)
            .increaseKeysInscribe(msg.sender);
        emit TokenInscribed(tokenId, inscriptionId);
    }

    function setMintStartTime(uint32 start) external onlyOwner {
        mintStartTime = start;
    }

    function setMintEndTime(uint32 end) external onlyOwner {
        mintEndTime = end;
    }

    function setFreeRoot(uint256 root) external onlyOwner {
        freeMintRoot = bytes32(root);
    }

    function toggleBurnUnlocked() external onlyOwner {
        burnUnlocked = !burnUnlocked;
    }

    function toggleMetadataUnlocked() external onlyOwner {
        metadataUnlocked = !metadataUnlocked;
    }

    function setBaseTokenURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseGridURI(string[] memory baseGridURI) external onlyOwner {
        _baseGridURI = baseGridURI;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        if (metadataUnlocked) {
            return super.tokenURI(tokenId);
        } else {
            if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
            if (_baseGridURI.length != 5) {
                return "";
            }
            return _baseGridURI[uint(tokenGridSize[tokenId])];
        }
    }
}