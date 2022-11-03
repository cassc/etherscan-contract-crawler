// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ModelNFT.sol";
import "./interfaces/IRoyaltyRegistry.sol";

contract ModelNFTFactory is OwnableUpgradeable {
    // Instantiate NFT contract
    ModelNFT private _modelNFT;

    mapping(string => address) public modelNFTs;

    /// @dev royalty registry address that store the royalty info.
    IRoyaltyRegistry public factoryRoyaltyRegistry;

    // Event
    event NFTCreated(string indexed modelID, address modelNFTAddress);
    event RoyaltyRegistryUpdated(address indexed _sender, address _oldAddress, address _newAddress);

    /**
     * @dev initialization function for proxy.
     *
     * @param _royaltyRegistry royalty registry address.
     */
    function initialize(address _royaltyRegistry) external initializer {
        require(_royaltyRegistry != address(0), "Invalid royalty address");
        factoryRoyaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
        __Ownable_init_unchained();
    }

    /**
     * @dev Update the royalty registry address.
     *
     * @param _royaltyRegistry new royalty registry address.
     */
    function changeFactoryRoyaltyRegistry(address _royaltyRegistry) external onlyOwner {
        require(_royaltyRegistry != address(0), "Invalid address");
        address oldRoyaltyRegistry = address(factoryRoyaltyRegistry);
        factoryRoyaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
        emit RoyaltyRegistryUpdated(msg.sender, oldRoyaltyRegistry, address(factoryRoyaltyRegistry));
    }

    /**
     * @dev Create new model NFT smart contract with parameters.
     * @param _modelName name of model.
     * @param _modelID ID of model.
     * @param _designer Address of designer.
     * @param _royaltyReceiver Address of royalty receiver.
     * @param _royaltyRate royalty Rate
     * @param _mintLimit upper limit of minting.
     */
    function createModelNFT(
        string memory _modelName,
        string memory _modelID,
        address _tokenPayment,
        address _designer,
        address _royaltyReceiver,
        uint96 _royaltyRate,
        uint256 _mintLimit
    ) external {
        require(_mintLimit > 0, "Invalid mint limit");
        require(modelNFTs[_modelID] == address(0), "Model ID has been used");
        require(_designer != address(0), "Invalid designer address");
        require(_royaltyReceiver != address(0), "Invalid royalty receiver address");

        _modelNFT = new ModelNFT(
            _modelName,
            _modelID,
            _mintLimit,
            _tokenPayment,
            _designer,
            address(factoryRoyaltyRegistry)
        );

        modelNFTs[_modelID] = address(_modelNFT);

        factoryRoyaltyRegistry.setRoyaltyRateForCollection(address(_modelNFT), _royaltyRate, _royaltyReceiver);

        emit NFTCreated(_modelID, address(_modelNFT));
    }
}