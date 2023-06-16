// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Drop721.sol";

contract Factory  {
    address internal implementationAddress;

    address internal dev;

    mapping(address => address[]) internal userDeployedContracts;

    event collectionCreated(address indexed sender, address indexed receiver, address collection);

    constructor(address _implementationAddress, address _dev) {
        implementationAddress = _implementationAddress;
        dev = _dev;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        uint256 _maxFreeSupply,
        uint256 _costPublic,
        uint256 _maxMintPublic,
        uint256 _freePerWallet,
        uint256 _dShare,
        address _withdrawAddress
    ) public returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name));
        address clone = ClonesUpgradeable.cloneDeterministic(implementationAddress, salt);
        Drop721 token = Drop721(clone);
        require(_dShare >= 5 && _dShare <= 100, "must be between 5 and 100");
        token.initialize(
            name,
            symbol,
            _baseURI,
            _maxSupply,
            _maxFreeSupply,
            _costPublic,
            _maxMintPublic,
            _freePerWallet,
            _dShare,
            _withdrawAddress,
            dev
        );

        token.transferOwnership(msg.sender);

        userDeployedContracts[msg.sender].push(clone);

        emit collectionCreated(msg.sender, _withdrawAddress, clone);
        return clone;
    }

    function getDeployedContracts(address user) public view returns (address[] memory) {
        return userDeployedContracts[user];
    }

}