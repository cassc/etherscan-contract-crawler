//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BaseMintModuleCloneable.sol";
import "../../interfaces/modules/minting/IMintingModule.sol";

contract ClaimList is BaseMintModuleCloneable, IMintingModule {
    bytes32 public claimlistRoot;

    mapping(address => bool) public claimlistClaimed; // claimlist address -> claimed

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer function for contract creation
    /// @param _admin The address of the admin
    /// @param _minter The address of the wallet or contract that can call canMint (passport or LL)
    /// @param data encoded bytes32 claimlist - merkle root & uint256 mintPrice - price per token in wei
    function initialize(
        address _admin,
        address _minter,
        bytes calldata data
    ) external override initializer {
        (bytes32 _claimlistRoot, uint256 _mintPrice) = abi.decode(data, (bytes32, uint256));
        __BaseMintModule_init(_admin, _minter, 0, _mintPrice);
        claimlistRoot = _claimlistRoot;
    }

    function decodeCanMint(bytes memory data) public pure returns (uint256 maxAmount, uint256 claimAmount) {
        (maxAmount, claimAmount) = abi.decode(data, (uint256, uint256));
        require(maxAmount >= claimAmount, "T7");
    }

    function validateProof(
        bytes32[] calldata proof,
        address minter,
        uint256 maxAmount
    ) public view {
        bool validProof = MerkleProof.verify(proof, claimlistRoot, keccak256(abi.encodePacked(minter, maxAmount)));
        require(validProof, "T11");
    }

    function validateMinter(address minter) internal view onlyMinter {
        require(!claimlistClaimed[minter], "T12");
        require(isActive, "T6");
    }

    /// @notice Mint Passport token(s) to caller
    /// @dev Must first enable claim & set fee/amount (if desired)
    /// @param minter address the address to mint to
    /// @param value uint256 amount eth sent to minting transaction, in wei
    /// @param proof bytes32[] merkle tree proof of minter claim
    /// @param data supplemental data with [uint256 maxAmount, uint256 claimAmount]
    function canMint(
        address minter,
        uint256 value,
        uint256[] calldata, /*tokenIds*/
        uint256[] calldata, /*mintAmounts*/
        bytes32[] calldata proof,
        bytes calldata data
    ) external returns (uint256) {
        validateMinter(minter);
        (uint256 maxAmount, uint256 claimAmount) = decodeCanMint(data);
        require(value == mintPrice * claimAmount, "T8");

        validateProof(proof, minter, maxAmount);

        claimlistClaimed[minter] = true;

        return claimAmount;
    }

    /// @notice Allows admin to set the merkle tree root for the claimlist
    /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled. Leaf is abi encodePacked address & amount
    /// @param _claimlistRoot Merkle tree root
    function setClaimlistRoot(bytes32 _claimlistRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimlistRoot = _claimlistRoot;
    }
}