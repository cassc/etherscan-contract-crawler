// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Drop721F.sol";

contract Factory is Ownable {
    address internal implementationAddress;
    address internal dev;
    mapping(address => address[]) internal userDeployedContracts;

    event collectionCreated(address indexed sender, address indexed receiver, address collection);

    constructor(address _implementationAddress, address _dev) {
        implementationAddress = _implementationAddress;
        dev = _dev;
    }

    struct CollectionData {
        string name;
        string symbol;
        string baseURI;
        uint256 maxSupply;
        uint256 maxFreeSupply;
        uint256 costPublic;
        uint256 maxMintPublic;
        uint256 freePerWallet;
        uint256 platformFee;
        uint256 costWL;
        uint256 maxMintWL;
        address withdrawAddress;
    }

    function createCollection(CollectionData memory _data) public returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_data.name));
        address clone = ClonesUpgradeable.cloneDeterministic(implementationAddress, salt);
        Drop721F token = Drop721F(clone);

        require(_data.platformFee >= 5 && _data.platformFee <= 100, "must be between 5 and 100");
        
        InitParams memory params = InitParams({
            baseURI: _data.baseURI,
            maxSupply: _data.maxSupply,
            maxFreeSupply: _data.maxFreeSupply,
            costPublic: _data.costPublic,
            maxMintPublic: _data.maxMintPublic,
            freePerWallet: _data.freePerWallet,
            platformFee: _data.platformFee,
            costWL: _data.costWL,
            maxMintWL: _data.maxMintWL,
            withdrawAddress: _data.withdrawAddress,
            dev: dev
        });

        token.initialize(_data.name, _data.symbol, params);

        token.transferOwnership(msg.sender);

        userDeployedContracts[msg.sender].push(clone);

        emit collectionCreated(msg.sender, _data.withdrawAddress, clone);
        return clone;
    }

    function setImplementationAddress(address _newImplementationAddress) public onlyOwner {
        implementationAddress = _newImplementationAddress;
    }

    function setDev(address _newDev) public onlyOwner {
        dev = _newDev;
    }

    function getDeployedContracts(address user) public view returns (address[] memory) {
        return userDeployedContracts[user];
    }
}