// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IOutputReceiverV3.sol";
import "./interfaces/IFNFTHandler.sol";
import "./interfaces/IResonate.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IResonateHelper.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IMetadataHandler.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/** @title Output Receiver Proxy. */
contract OutputReceiverProxy is Ownable, IOutputReceiverV3, ERC165 {

    /// Resonate address
    address public resonate;

    /// Metadata handler address
    address public metadataHandler;
    
    /// Address registry
    address public immutable ADDRESS_REGISTRY;

    /// Vault for tokens
    address public TOKEN_VAULT;

    /// Whether or not Resonate is set
    bool private _resonateSet;

    /// FNFT Handler address, immutable for increased decentralization
    IFNFTHandler private immutable FNFT_HANDLER;

    address public REVEST;


    constructor(address _addressRegistry) {
        ADDRESS_REGISTRY = _addressRegistry;
        TOKEN_VAULT = IAddressRegistry(_addressRegistry).getTokenVault();
        FNFT_HANDLER = IFNFTHandler(IAddressRegistry(_addressRegistry).getRevestFNFT());
        REVEST = IAddressRegistry(ADDRESS_REGISTRY).getRevest();
    }

    /**
     * @notice called during the end of the life-cycle for an FNFT, upon withdrawal.
     *         Should handle withdrawing funds and returning them to the holder of the FNFT
     * @param fnftId the FNFT which is being withdrawn from
     * @param recipient the owner of the FNFT which is being withdrawn from, who made the withdrawal call
     * @param quantity how many FNFTs are being withdrawn from
     */
    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable recipient,
        uint quantity
    ) external override {
        require(msg.sender == TOKEN_VAULT, 'ER012');
        require(IAddressRegistry(ADDRESS_REGISTRY).getRevest() == REVEST, 'ER042');
        require(IAddressRegistry(ADDRESS_REGISTRY).getRevestFNFT() == address(FNFT_HANDLER), 'ER042');
        IResonate(resonate).receiveRevestOutput(fnftId, address(0), recipient, quantity);
    }

    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable override {}

    /**
     * @notice Called to claim interest on a given FNFT
     * @param fnftId the FNFT which is being updated
     * @dev can only be called by someone who owns the FNFT they pass in
     */
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory
    ) external override {
        require(FNFT_HANDLER.getBalance(msg.sender, fnftId) > 0, 'ER010');
        IResonate(resonate).claimInterest(fnftId, msg.sender);
    }

    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external {}
    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external override {}
    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external override {}
    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external override {}

    ///
    /// View Functions
    ///

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return  interfaceId == type(IOutputReceiver).interfaceId
        || interfaceId == type(IOutputReceiverV2).interfaceId
        || interfaceId == type(IOutputReceiverV3).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function getAddressRegistry() external view returns (address) {
        return ADDRESS_REGISTRY;
    }

    function getCustomMetadata(uint) external view override returns (string memory) {
        return IMetadataHandler(metadataHandler).getOutputReceiverURL();
    }

    function getValue(uint fnftId) external view override returns (uint) {
        IResonate resonateContract = IResonate(resonate);
        uint index = resonateContract.fnftIdToIndex(fnftId);
        (uint principalId,,,bytes32 poolId) = resonateContract.activated(index);
        if(fnftId == principalId) {
            (,,,,,, uint256 packetSize) = resonateContract.pools(poolId);
            return packetSize;
        } else {
            (uint accruedInterest,) = IResonateHelper(resonateContract.RESONATE_HELPER()).calculateInterest(fnftId);
            return accruedInterest;
        }
    }

    function getAsset(uint fnftId) external view override returns (address asset) {
        IResonate resonateContract = IResonate(resonate);
        uint index = resonateContract.fnftIdToIndex(fnftId);
        (,,,bytes32 poolId) = resonateContract.activated(index);
        (,,address vaultAdapter,,,,) = resonateContract.pools(poolId);
        asset = IERC4626(vaultAdapter).asset();
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory output) {
        output = IMetadataHandler(metadataHandler).getOutputReceiverBytes(fnftId);
    }

    function setAddressRegistry(address revest) external override {}

    /// Allow for semi-upgradeable Revest contracts, requires Resonate DAO to sign-off on changes
    function updateRevestVariables() external onlyOwner {
        IAddressRegistry registry = IAddressRegistry(ADDRESS_REGISTRY);
        REVEST = registry.getRevest();
        TOKEN_VAULT = registry.getTokenVault();
    }

    function setResonate(address _resonate) external onlyOwner {
        require(!_resonateSet, 'ER031');
        _resonateSet = true;
        resonate = _resonate;
    }

    function setMetadataHandler(address _metadata) external onlyOwner {
        metadataHandler = _metadata;
    }

}