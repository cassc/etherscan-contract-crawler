// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


interface ICollectionContract {
    function initialize(
        address payable _owner,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _priceInWei,
        uint256 _priceWhitelist,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _maxWhitelist,
        bool _revealed,
        bytes32 _merkleroot

    ) external;
}

interface IRoyaltyManager {
    function getRoyalties(address _contract) external view returns (uint256);
    function royaltyRecipient() external view returns (address);
}

contract CloneFactoryV1 is Ownable {
    using Clones for address;

    event ProxyContractCreated(address _proxy, string _name, string _symbol);

    address public implementation;
    address public royaltyManager;

    function createProxyContract(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _priceInWei,
        uint256 _priceWhitelist,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _maxWhitelist,
        bool _revealed,
        bytes32 _merkleroot,
        uint256 nonce
    ) external returns (address) {
        address proxy = implementation.cloneDeterministic(keccak256(abi.encodePacked(msg.sender, nonce)));
        ICollectionContract(proxy).initialize(
            payable(msg.sender),
            _name, 
            _symbol,
            _baseURI,
            _priceInWei,
            _priceWhitelist,
            _maxSupply,
            _maxPerWallet,
            _maxWhitelist,
            _revealed,
            _merkleroot
        );
        emit ProxyContractCreated(proxy, _name, _symbol);
        return address(proxy);
    }

    function setImplementation(address _implementation) public onlyOwner {
        implementation = _implementation;
    }

    function setRoyaltyManager(address _royaltyManager) public onlyOwner {
        royaltyManager = _royaltyManager;
    }

    function getProtocolFeeAndRecipient(address _contract) public view returns (uint256, address) {
        address _protocolFeeRecipient = IRoyaltyManager(royaltyManager).royaltyRecipient();
        uint256 _protocolFee = IRoyaltyManager(royaltyManager).getRoyalties(_contract);

        return (_protocolFee, _protocolFeeRecipient);  
    }

    function predictCollectionAddress(uint256 nonce) external view returns (address) {
        return implementation.predictDeterministicAddress(keccak256(abi.encodePacked(msg.sender, nonce)));
    }
}