// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDropUpgradeable } from "./ERC721SeaDropUpgradeable.sol";
import { IPoseidonHasher } from "./interfaces/IPoseidonHasher.sol";
import { ITokenURI } from "./interfaces/ITokenURI.sol";

library zkMonStorage {
    struct Layout {
        /// @notice The only address that can burn tokens on this contract.
        address burnAddress;
        /// @notice The poseidon hasher contract.
        address poseidonAddress;
        /// @notice The actual zk proof verifier contract.
        address verifierAddress;
        /// @notice The merkle root of the zk proof.
        uint256 merkleRoot;
        /// @notice To allow on-chain metadata later
        address metadataAddress;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("seaDrop.contracts.storage.zkMon");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/*
 * @notice This contract uses ERC721PartnerSeaDrop,
 *         an ERC721A token contract that is compatible with SeaDrop.
 *         The set burn address is the only sender that can burn tokens.
 */
contract zkMon is ERC721SeaDropUpgradeable {
    using zkMonStorage for zkMonStorage.Layout;

    event MerkleRootVerified(uint256 indexed merkleRoot);

    /**
     * @notice A token can only be burned by the set burn address.
     */
    error BurnIncorrectSender();

    /**
     * @notice Initialize the token contract with its name, symbol, and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            name,
            symbol,
            allowedSeaDrop
        );
    }

    function setBurnAddress(address newBurnAddress) external onlyOwner {
        zkMonStorage.layout().burnAddress = newBurnAddress;
    }

    function getBurnAddress() public view returns (address) {
        return zkMonStorage.layout().burnAddress;
    }

    function setZkContracts(address poseidonAddress, address verifierAddress) external onlyOwner {
        zkMonStorage.layout().poseidonAddress = poseidonAddress;
        zkMonStorage.layout().verifierAddress = verifierAddress;
    }

    function setMetadataAddress(address metadataAddress) external onlyOwner {
        zkMonStorage.layout().metadataAddress = metadataAddress;
    }

    /**
     * @notice Destroys `tokenId`, only callable by the set burn address.
     *
     * @param tokenId The token id to burn.
     */
    function burn(uint256 tokenId) external {
        if (msg.sender != zkMonStorage.layout().burnAddress) {
            revert BurnIncorrectSender();
        }

        _burn(tokenId);
    }

    /**
     * @notice Main proof verification function.
     */
    function verify(bytes calldata proof, bytes calldata instances, uint256 claimedMerkleRoot) public {
        (bool success, ) = zkMonStorage.layout().verifierAddress.call(
            abi.encodePacked(instances, claimedMerkleRoot, proof)
        );
        require(success, "zkMon: Proof did not verify!");

        zkMonStorage.layout().merkleRoot = claimedMerkleRoot;
        emit MerkleRootVerified(claimedMerkleRoot);
    }

    /**
     * @notice View function to verify merkle path of single NFTs
     */
    function verifyMerklePath(uint256[] calldata path, uint256 input_hash, uint256 output_hash) public view returns (bool) {
        IPoseidonHasher hasher = IPoseidonHasher(zkMonStorage.layout().poseidonAddress);
        uint256 current = hasher.poseidon([input_hash, output_hash]);
        for (uint8 i = 0; i < path.length; i++) {
            current = hasher.poseidon([current, path[i]]);
        }
        return current == zkMonStorage.layout().merkleRoot;
    }

    /**
     * @notice Returns the metadata, overridden to make on-chain later
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (zkMonStorage.layout().metadataAddress != address(0)) {
            return ITokenURI(zkMonStorage.layout().metadataAddress).tokenURI(tokenId);
        }

        string memory baseURI = _baseURI();

        // Exit early if the baseURI is empty.
        if (bytes(baseURI).length == 0) {
            return "";
        }

        // Check if the last character in baseURI is a slash.
        if (bytes(baseURI)[bytes(baseURI).length - 1] != bytes("/")[0]) {
            return baseURI;
        }

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }
}