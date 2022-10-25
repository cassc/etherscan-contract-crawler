//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SageNFT.sol";
import "../../interfaces/ISageStorage.sol";

error PermissionDenied();

contract NFTFactory {
    bytes32 public constant ADMIN_ROLE = keccak256("role.admin");
    bytes32 public constant ARTIST_ROLE = keccak256("role.artist");
    uint256 private constant DEFAULT_ARTIST_SHARE = 8333;

    mapping(address => SageNFT) artistContracts;
    ISageStorage immutable sageStorage;

    event NewNFTContract(
        address indexed contractAddress,
        address indexed artistAddress
    );

    /**
     * @dev Throws if not called by an admin account.
     */
    modifier onlyAdmin() {
        require(
            sageStorage.hasRole(ADMIN_ROLE, msg.sender),
            "Admin calls only"
        );
        _;
    }

    modifier onlyMultisig() {
        require(sageStorage.hasRole(0x00, msg.sender), "Admin calls only");
        _;
    }

    modifier onlyArtist() {
        require(
            sageStorage.hasRole(ARTIST_ROLE, msg.sender),
            "Artist calls only"
        );
        _;
    }

    constructor(address _sageStorage) {
        sageStorage = ISageStorage(_sageStorage);
    }

    function setArtistContract(address _artist, address payable _contract)
        public
        onlyMultisig
    {
        artistContracts[_artist] = SageNFT(_contract);
    }

    function createNFTContract(
        address artistAddress,
        string calldata name,
        string calldata symbol,
        uint256 artistShare
    ) internal returns (SageNFT) {
        require(
            address(artistContracts[artistAddress]) == address(0),
            "Contract already exists"
        );

        SageNFT newContract = new SageNFT(
            name,
            symbol,
            address(sageStorage),
            artistAddress,
            artistShare
        );
        artistContracts[artistAddress] = newContract;
        emit NewNFTContract(address(newContract), artistAddress);
        return newContract;
    }

    function deployByAdmin(
        address artistAddress,
        string calldata name,
        string calldata symbol,
        uint256 artistShare
    ) public onlyAdmin {
        createNFTContract(artistAddress, name, symbol, artistShare);
    }

    function deployByArtist(string calldata name, string calldata symbol)
        public
        onlyArtist
    {
        SageNFT newContract = createNFTContract(
            msg.sender,
            name,
            symbol,
            DEFAULT_ARTIST_SHARE
        );
        newContract.transferOwnership(sageStorage.multisig());
    }

    function getContractAddress(address artistAddress)
        public
        view
        returns (address)
    {
        return address(artistContracts[artistAddress]);
    }
}