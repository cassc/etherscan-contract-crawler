pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./MNTContract.sol";

/// @author Monumental Team
/// @title MNT Factory
contract MNTFactory  is Ownable {

    address private _implementationStandard;
    address private _implementationCommunity;
    address private _implementationAuction;

    event MNTCreatedAddress(address _creator, uint256 pinCode, address _address);
    event MNTAuctionCreated(uint userId, uint contractId, address _address);

    constructor() {
    }

    /// Set implementation standard address
    /// @param implementationStandard address
    function setImplementationStandard(address implementationStandard) public onlyOwner {
        _implementationStandard = implementationStandard;
    }

    /// Set implementation community address
    /// @param implementationCommunity address
    function setImplementationCommunity(address implementationCommunity) public onlyOwner {
        _implementationCommunity = implementationCommunity;
    }

    /// Set implementation auction address
    /// @param implementationAuction address
    function setImplementationAuction(address implementationAuction) public onlyOwner {
        _implementationAuction = implementationAuction;
    }

    /// Create a standard edition contract
    /// @param creator creator address
    /// @param pinCode pin code
    /// @param nftName contract name
    /// @param nftSymbol contract symbol
    /// @param baseURL base URL of token
    /// @param royalties royalties
    /// @param maxSupply max supply
    /// @notice Create a standard edition contract
    function createStandard(
        address creator,
        uint256 pinCode,
        string memory nftName,
        string memory nftSymbol,
        string memory baseURL,
        uint256 royalties,
        uint256 maxSupply)
    external returns(address instance) {

        require(_implementationStandard != address(0), "invalid implementation address");

        instance = Clones.clone(_implementationStandard);

        require(instance != address(0), "clone failed");

        bool success = MNTContract(payable(instance)).initializeStandard(creator, pinCode, nftName,  nftSymbol, baseURL, royalties, maxSupply);

        require(success, "init failed");

        emit MNTCreatedAddress(creator, pinCode, address(instance));

    }

    /// Create a community edition contract
    /// @param _creator creator address
    /// @param _pinCode pin code
    /// @param stringOptions contract name
    /// @param _royalties royalties
    /// @param _maxSupply max supply
    /// @param _communityOptions community options
    /// @param _onlyWhitelisted only white listed
    /// @param _whitelistedAddresses whitelisted addresses
    /// @param _feeRecipients fee recipients
    /// @param _feePercentages fee percentages
    /// @notice Create a community edition contract
    function createCommunity(
        address _creator,
        uint256 _pinCode,
        string[] memory stringOptions,
        uint8 _royalties,
        uint8 _maxSupply,
        uint256[] memory _communityOptions,
        bool _onlyWhitelisted,
        address[] memory _whitelistedAddresses,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external returns(address instance) {

        require(_implementationCommunity != address(0), "invalid implementation address");

        instance = Clones.clone(_implementationCommunity);

        require(instance != address(0), "clone failed");

        bool success = MNTContract(payable(instance)).initializeCommunity(stringOptions, _creator, _royalties, _maxSupply, _communityOptions, _onlyWhitelisted, _whitelistedAddresses, _feeRecipients, _feePercentages);

        require(success, "init failed");

        emit MNTCreatedAddress(_creator, _pinCode, address(instance));
    }

    /// Create a sell contract
    /// @param userId user ID
    /// @param contractId contract ID
    /// @param owner owner
    /// @notice Create a sell contract
    function createSellContract(uint userId, uint contractId, address owner)
    external returns(address instance) {

        instance = Clones.clone(_implementationAuction);
        (bool success, ) = instance.call(abi.encodeWithSignature("initialize(address)",owner));

        require(success);

        emit MNTAuctionCreated(userId, contractId, address(instance));

        return instance;
    }

    function getImplementationStandard()
    public view returns(address) {
    return _implementationStandard;
    }

    function getImplementationCommunity()
    public view returns(address) {
        return _implementationCommunity;
    }

    function getImplementationAuction()
    public view returns(address) {
        return _implementationAuction;
    }

}