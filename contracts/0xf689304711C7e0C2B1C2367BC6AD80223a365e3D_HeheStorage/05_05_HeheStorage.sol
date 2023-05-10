// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HeheStorage is Initializable, OwnableUpgradeable {
    // Address of the delegate.cash delegation registry
    address public immutable DELEGATION_REGISTRY_ADDRESS =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    // Address of the BattlePass contract
    address private _battlePassAddress;

    // Address that houses the implementation to check if operators are allowed or not
    address private _operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators
    address private _filterRegistrant;

    // Signer address used for the mintSignature method
    address private _signerAddress;

    // Mapping from tokenId to its minted supply
    mapping(uint256 => uint256) private _mintedSupply;
    // Total mints allowed for each val tokenId
    uint256 private _maxValMintSupply;
    // Mapping from Valhalla tokenId to how many tokens it has minted
    mapping(uint256 => uint256) private _valMintedSupply;
    // Mapping from signature to an indication whether its been used
    mapping(bytes32 => bool) private _signatureUsed;

    // Mapping from tokenId to its metadata URI
    mapping(uint256 => string) private _tokenURIs;

    // Modifier to restrict access to the BattlePass contract
    modifier onlyBattlePass() {
        if (msg.sender != _battlePassAddress)
            revert OnlyBattlePassContractAllowed();
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function battlePassAddress() external view returns (address) {
        return _battlePassAddress;
    }

    /**
     * @notice Returns the address of the operator filter registry.
     */
    function operatorFilterRegistryAddress() external view returns (address) {
        return _operatorFilterRegistryAddress;
    }

    /**
     * @notice Returns the filter registrant address.
     */
    function filterRegistrant() external view returns (address) {
        return _filterRegistrant;
    }

    /**
     * @notice Returns the signer address used for the mintSignature method.
     */
    function signerAddress() external view returns (address) {
        return _signerAddress;
    }

    /**
     * @notice Returns the max number of tokens allowed to mint for each Valhalla.
     */
    function maxValMintSupply() external view returns (uint256) {
        return _maxValMintSupply;
    }

    /**
     * @notice Returns the minted supply for a specific tokenId.
     * @param tokenId The token ID.
     */
    function mintedSupply(uint256 tokenId) external view returns (uint256) {
        return _mintedSupply[tokenId];
    }

    /**
     * @notice Returns the number of tokens minted by a Valhalla tokenId.
     * @param valTokenId The Valhalla token ID.
     */
    function valMintedSupply(
        uint256 valTokenId
    ) external view returns (uint256) {
        return _valMintedSupply[valTokenId];
    }

    /**
     * @notice Checks if a signature has been used.
     * @param sigHash The signature hash.
     */
    function signatureUsed(bytes32 sigHash) external view returns (bool) {
        return _signatureUsed[sigHash];
    }

    /**
     * @notice Returns the metadata URI for a specific tokenId.
     * @param tokenId The token ID.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setBattlePassAddress(
        address battlePassAddress_
    ) external onlyOwner {
        _battlePassAddress = battlePassAddress_;
    }

    /**
     * @notice Sets the signer address used for the mintSignature method.
     * @param signerAddress_ The new signer address.
     */
    function setSignerAddress(address signerAddress_) external onlyOwner {
        _signerAddress = signerAddress_;
    }

    /**
     * @notice Sets the max allowed mints for each val tokenId.
     */
    function setMaxValMintSupply(uint256 maxValMintAmount_) external onlyOwner {
        _maxValMintSupply = maxValMintAmount_;
    }

    /**
     * @notice Sets the minted supply for a specific tokenId.
     * @param tokenId The token ID for which the minted supply is being updated.
     * @param mintedSupply_ The new minted supply.
     */
    function setMintedSupply(
        uint256 tokenId,
        uint256 mintedSupply_
    ) external onlyBattlePass {
        _mintedSupply[tokenId] = mintedSupply_;
    }

    /**
     * @notice Sets the minted supply for a specific Valhalla tokenID.
     * @param valTokenId The Valhalla token ID for which the minted supply is being updated.
     * @param mintedSupply_ The new minted supply.
     */
    function setValMintedSupply(
        uint256 valTokenId,
        uint256 mintedSupply_
    ) external onlyBattlePass {
        _valMintedSupply[valTokenId] = mintedSupply_;
    }

    /**
     * @notice Sets a signature to be used.
     * @param sigHash The signature hash.
     */
    function setSignatureUsed(bytes32 sigHash) external onlyBattlePass {
        _signatureUsed[sigHash] = true;
    }

    /**
     * @notice Sets the metadata URI for a specific tokenId.
     * @param tokenId The token ID for which the metadata URI is being updated.
     * @param tokenURI_ The new metadata URI.
     */
    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) external onlyOwner {
        _tokenURIs[tokenId] = tokenURI_;
    }

    /**
     * @notice Sets the address of the operator filter registry.
     * @param registryAddress The address of the operator filter registry.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        _operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Sets the filter registrant address.
     * @param newRegistrant The new filter registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        _filterRegistrant = newRegistrant;
    }

    error OnlyBattlePassContractAllowed();
    error InvalidMaxSupply();
}