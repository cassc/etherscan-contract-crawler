// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "https://github.com/chiru-labs/ERC721A/blob/v3.3.0/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhiteRabbitKey is ERC721A, Ownable {
    string private _baseTokenURI;
    bytes32 private _merkleRoot;

    mapping(address => bool) private _claimedWalletAddresses;

    bool public isClaimingActive = false;
    uint256 public immutable maxSupply;
    // Required for ERC721A contracts (https://chiru-labs.github.io/ERC721A/#/erc721a?id=_mint)
    uint256 public constant BATCH_SIZE = 20;

    constructor(uint256 maxSupply_) ERC721A("WhiteRabbitKey", "WRKEY") {
        maxSupply = maxSupply_;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function setClaimingState(bool isActive) external onlyOwner {
        isClaimingActive = isActive;
    }

    function hasAlreadyClaimed(address wallet) external view returns (bool) {
        return _claimedWalletAddresses[wallet];
    }

    /**
     * @dev Claims `quantity` tokens for the connected wallet if the `proof` is valid
     *
     * Requirements:
     *
     * - The claiming state is active
     * - The max supply is not exceeded by the quantity
     * - The connected wallet has not already claimed
     * - The merkle proof is valid
     */
    function claim(uint256 quantity, bytes32[] calldata proof) public {
        require(isClaimingActive, "Claiming is unavailable");

        uint256 ts = totalSupply();

        require(ts + quantity <= maxSupply, "Purchase would exceed max tokens");
        require(
            !_claimedWalletAddresses[msg.sender],
            "Wallet has already claimed"
        );
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            ),
            "Invalid merkle proof"
        );

        _claimedWalletAddresses[msg.sender] = true;
        _mintWrapper(msg.sender, quantity);
    }

    // Used to mint directly to a single address (also useful for testing)
    function devMint(address to, uint256 quantity) external onlyOwner {
        uint256 ts = totalSupply();

        require(ts + quantity <= maxSupply, "Purchase would exceed max tokens");

        _mintWrapper(to, quantity);
    }

    /**
     * @dev Burns `tokenIds` tokens
     *
     * Requirements:
     *
     * - The tokens are owned by the wallet triggering the transaction
     */
    function burn(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // We pass in `true` to enforce ownership of the token
            _burn(tokenIds[i], true);
        }
    }

    /**
     * @dev Mints `quantity` tokens in batches of `BATCH_SIZE` to the specified address
     *
     * Requirements:
     *
     * - The quantity does not exceed the max supply
     */
    function _mintWrapper(address to, uint256 quantity) internal {
        require(
            totalSupply() + quantity <= maxSupply,
            "Quantity exceeds max supply"
        );

        for (uint256 i; i < quantity / BATCH_SIZE; i++) {
            _mint(to, BATCH_SIZE);
        }
        // Mint leftover quantity
        if (quantity % BATCH_SIZE > 0) {
            _mint(to, quantity % BATCH_SIZE);
        }
    }
}