// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedNFTs.sol";
import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/IDispatcher.sol";
import "../utils/Ownable.sol";
import "../utils/KeysMapping.sol";

contract AllowedNFTsAndTypeRegistry is Ownable, IAllowedNFTs {
    IDispatcher public hub;
    mapping(bytes32 => address) private nftTypes;

    mapping(address => bytes32) private nftPermits;

    event TypeUpdated(bytes32 indexed nftType, address indexed nftWrapper);

    event NFTPermit(address indexed nftContract, bytes32 indexed nftType);

    modifier onlyOwnerOrAirdropFactory(string memory _nftType) {
        if (
            KeysMapping.keyToId(_nftType) ==
            KeysMapping.keyToId(KeysMapping.AIRDROP_WRAPPER_STRING)
        ) {
            require(hub.getContract(KeysMapping.AIRDROP_FACTORY) == _msgSender(), "caller is not AirdropFactory");
        } else {
            require(owner() == _msgSender(), "caller is not owner");
        }
        _;
    }

    constructor(
        address _admin,
        address _dispatcher,
        string[] memory _definedNftTypes,
        address[] memory _definedNftWrappers,
        address[] memory _permittedNftContracts,
        string[] memory _permittedNftTypes
    ) Ownable(_admin) {
        hub = IDispatcher(_dispatcher);
        _setNftTypes(_definedNftTypes, _definedNftWrappers);
        _setNFTPermits(_permittedNftContracts, _permittedNftTypes);
    }

    function setNFTPermit(address _nftContract, string memory _nftType)
        external
        override
        onlyOwnerOrAirdropFactory(_nftType)
    {
        _setNFTPermit(_nftContract, _nftType);
    }

    function setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) external onlyOwner {
        _setNFTPermits(_nftContracts, _nftTypes);
    }

    function getNFTPermit(address _nftContract) external view override returns (bytes32) {
        return nftPermits[_nftContract];
    }

    function getNFTWrapper(address _nftContract) external view override returns (address) {
        bytes32 nftType = nftPermits[_nftContract];
        return getNftTypeWrapper(nftType);
    }

    function setNftType(string memory _nftType, address _nftWrapper) external onlyOwner {
        _setNftType(_nftType, _nftWrapper);
    }

    function setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) external onlyOwner {
        _setNftTypes(_nftTypes, _nftWrappers);
    }

    function getNftTypeWrapper(bytes32 _nftType) public view returns (address) {
        return nftTypes[_nftType];
    }

    function _setNftType(string memory _nftType, address _nftWrapper) internal {
        require(bytes(_nftType).length != 0, "nftType is empty");
        bytes32 nftTypeKey = KeysMapping.keyToId(_nftType);

        nftTypes[nftTypeKey] = _nftWrapper;

        emit TypeUpdated(nftTypeKey, _nftWrapper);
    }

    function _setNftTypes(string[] memory _nftTypes, address[] memory _nftWrappers) internal {
        require(_nftTypes.length == _nftWrappers.length, "setNftTypes function information arity mismatch");

        for (uint256 i = 0; i < _nftWrappers.length; i++) {
            _setNftType(_nftTypes[i], _nftWrappers[i]);
        }
    }

    function _setNFTPermit(address _nftContract, string memory _nftType) internal {
        require(_nftContract != address(0), "nftContract is zero address");
        bytes32 nftTypeKey = KeysMapping.keyToId(_nftType);

        if (nftTypeKey != 0) {
            require(getNftTypeWrapper(nftTypeKey) != address(0), "NFT type not registered");
        }

        require(
            nftPermits[_nftContract] != KeysMapping.keyToId(KeysMapping.AIRDROP_WRAPPER_STRING),
            "AirdropWrapper can't be modified"
        );
        nftPermits[_nftContract] = nftTypeKey;
        emit NFTPermit(_nftContract, nftTypeKey);
    }

    function _setNFTPermits(address[] memory _nftContracts, string[] memory _nftTypes) internal {
        require(_nftContracts.length == _nftTypes.length, "setNFTPermits function information arity mismatch");

        for (uint256 i = 0; i < _nftContracts.length; i++) {
            _setNFTPermit(_nftContracts[i], _nftTypes[i]);
        }
    }
}