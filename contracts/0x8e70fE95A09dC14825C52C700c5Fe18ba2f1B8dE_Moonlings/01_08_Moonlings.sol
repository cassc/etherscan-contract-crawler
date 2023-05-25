// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

import {ERC721} from "./ERC721.sol"; // Solmate: ERC721
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/// @title MerkleClaim721
/// @notice ERC721 claimable by members of a merkle tree
contract Moonlings is ERC721, PaymentSplitter {
    /// ============ Immutable storage ============

    uint256 public constant maxSupply = 10000;
    uint256 public constant price = 69000000000000000;

    /// ============ Mutable storage ============

    bytes32 public merkleRoot;
    bool public publicSaleIsOpen;
    bool public whitelistIsOpen;
    bool public isRevealed;
    address public owner;
    uint256 public currentSupply;
    string public baseURI = "ipfs://QmSNKJDGXjA8hj7LyD7F4C2R1wV7zTWkdpgLPwFmLLXSPx";

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => uint256) public hasClaimed;

    /// ============ Errors ============

    /// @notice Thrown if address has already claimed
    error AlreadyClaimed();
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();
    /// @notice Thrown if bad price
    error PaymentNotCorrect();
    error NotOwner();
    error MintExceedsMaxSupply();
    error TooManyMintsPerTransaction();
    error AllowlistSaleNotStarted();
    error PublicSaleNotStarted();

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaimERC721 contract
    constructor(
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        owner = msg.sender;
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    event Mint(address indexed to, uint256 amount);

    /// ============ Public Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param proofAmount of tokens owed to claimee in merkle tree
    /// @param mintAmount of tokens claimee wants to mint in this call
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(
        address to,
        uint256 proofAmount,
        uint256 mintAmount,
        bytes32[] calldata proof
    ) external payable {
        if (!whitelistIsOpen) revert AllowlistSaleNotStarted();
        if (mintAmount > proofAmount) revert();
        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, proofAmount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();
        unchecked {
            // Throw if address has already claimed tokens
            if (hasClaimed[to] + mintAmount > proofAmount) revert AlreadyClaimed();

            if (msg.value != price * mintAmount) revert PaymentNotCorrect();

            // Set address to claimed
            hasClaimed[to] += mintAmount;

            // Mint tokens to address
            for (uint256 i = 0; i < mintAmount; i++) {
                _mint(to, ++currentSupply);
            }
        }
        // Emit claim event
        emit Claim(to, mintAmount);
    }

    function publicMint(uint256 amount) external payable {
        if (!publicSaleIsOpen) revert PublicSaleNotStarted();
        if (amount > 5) revert TooManyMintsPerTransaction();
        unchecked {
            if (currentSupply + amount > maxSupply) revert MintExceedsMaxSupply();
            if (msg.value != price * amount) revert PaymentNotCorrect();
            for (uint256 i = 0; i < amount; i++) {
                _mint(msg.sender, ++currentSupply);
            }
        }
        emit Mint(msg.sender, amount);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (isRevealed) {
            return string(abi.encodePacked(baseURI, uint2str(id)));
        } else {
            return baseURI;
        }
    }

    /// ============ Owner Functions ============

    function setOwner(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        owner = newOwner;
    }

    function ownerMint(address to, uint256 amount) external {
        if (msg.sender != owner) revert NotOwner();

        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                _mint(to, ++currentSupply);
            }
        }
    }

    function setRoot(bytes32 _merkleRoot) external {
        if (msg.sender != owner) revert NotOwner();
        merkleRoot = _merkleRoot;
    }

    function reveal(string calldata _baseURI) external {
        if (msg.sender != owner) revert NotOwner();
        baseURI = _baseURI;
        isRevealed = true;
    }

    function setBools(bool whitelist, bool publicSale) external {
        if (msg.sender != owner) revert NotOwner();
        whitelistIsOpen = whitelist;
        publicSaleIsOpen = publicSale;
    }

    /// ========= Internal Functions ========

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}