// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IZerionGenesisNFT.sol";

contract ZerionGenesisNFT is ERC1155Supply, IZerionGenesisNFT {
    /// @inheritdoc IZerionGenesisNFT
    mapping(address => bool) public override claimed;
    /// @inheritdoc IZerionGenesisNFT
    uint256 public immutable override deadline;
    /// @inheritdoc IZerionGenesisNFT
    string public override name;
    /// @inheritdoc IZerionGenesisNFT
    string public override symbol;
    /// @inheritdoc IZerionGenesisNFT
    string public override contractURI;

    bytes10 internal immutable rarities;
    uint256 internal immutable totalRarity;
    mapping(uint256 => string) internal ipfsHashes;

    uint256 internal constant TOKEN_AMOUNT = 1;
    string internal constant IPFS_PREFIX = "ipfs://";
    bytes4 private constant INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    error AlreadyClaimed(address account);
    error ExceedsDeadline(uint256 timestamp, uint256 deadline);
    error OnlyTxOrigin();

    /// @notice Creates Zerion NFTs, stores all the required parameters.
    /// @param ipfsHashes_ IPFS hashes for `tokenId` from 0 to 9.
    /// @param contractIpfsHash_ IPFS hash for the collection metadata.
    /// @param rarities_ Rarities for `tokenId` from 0 to 9.
    /// @param name_ Collection name.
    /// @param symbol_ Collection symbol.
    /// @param deadline_ Deadline the tokens cannot be claimed after.
    constructor(
        string[10] memory ipfsHashes_,
        string memory contractIpfsHash_,
        bytes10 rarities_,
        string memory name_,
        string memory symbol_,
        uint256 deadline_
    ) ERC1155("") {
        for (uint256 i = 0; i < 10; i++) {
            ipfsHashes[i + 1] = ipfsHashes_[i];
            emit URI(hashToURI(ipfsHashes_[i]), i + 1);
        }
        contractURI = hashToURI(contractIpfsHash_);

        rarities = rarities_;
        uint256 temp = 0;
        for (uint256 i = 0; i < 10; i++) {
            temp += uint256(uint8(rarities_[i]));
        }
        totalRarity = temp;

        name = name_;
        symbol = symbol_;
        deadline = deadline_;
    }

    /// @inheritdoc IZerionGenesisNFT
    function claim() external override {
        address msgSender = _msgSender();
        checkRequirements(msgSender);

        // solhint-disable-next-line not-rely-on-time
        uint256 tokenId = getId(block.timestamp);
        _mint(msgSender, tokenId, TOKEN_AMOUNT, new bytes(0));

        claimed[msgSender] = true;
    }

    /// @inheritdoc IZerionGenesisNFT
    function rarity(uint256 tokenId) external view override returns (uint256) {
        if (tokenId == 0 || tokenId > 10) return uint256(0);

        return (uint256(uint8(rarities[tokenId - 1])) * 1000) / uint256(totalRarity);
    }

    /// @inheritdoc IZerionGenesisNFT
    function uri(uint256 tokenId) public view virtual override(ERC1155, IZerionGenesisNFT) returns (string memory) {
        if (tokenId == 0 || tokenId > 10) return "";

        return hashToURI(ipfsHashes[tokenId]);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_CONTRACT_URI || super.supportsInterface(interfaceId);
    }

    /// @dev Reverts if the `account` has already claimed an NFT or is not an EOA.
    /// @dev Also reverts if the current timestamp exceeds the deadline.
    function checkRequirements(address account) internal view {
        // solhint-disable-next-line avoid-tx-origin
        if (tx.origin != account) revert OnlyTxOrigin();
        if (claimed[account]) revert AlreadyClaimed(account);
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > deadline) revert ExceedsDeadline(block.timestamp, deadline);
    }

    /// @dev Randomly (based on caller address and block timestamp) gets a token id.
    /// @param salt Used to call this function multiple times (initially, `block.timestamp`).
    function getId(uint256 salt) internal view returns (uint256) {
        // We do not need a true random here as it is not worth manipulating a timestamp.
        // slither-disable-next-line weak-prng
        uint256 number = uint256(keccak256(abi.encodePacked(_msgSender(), salt))) % totalRarity;

        uint256 limit = totalRarity;
        for (uint256 i = 9; i > 0; i--) {
            limit -= uint256(uint8(rarities[i]));
            // slither-disable-next-line timestamp
            if (number >= limit) return i + 1;
        }

        // We limit the amount of NFTs with `id == 1` by 10.
        if (totalSupply(1) == 10) return getId(salt + 1);
        return uint256(1);
    }

    /// @dev Adds IPFS prefix for a given IPFS hash.
    function hashToURI(string memory ipfsHash) internal pure returns (string memory) {
        return string(abi.encodePacked(IPFS_PREFIX, ipfsHash));
    }
}