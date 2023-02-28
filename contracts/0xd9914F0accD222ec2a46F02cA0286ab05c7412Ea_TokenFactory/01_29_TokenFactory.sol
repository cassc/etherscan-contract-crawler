// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@dlsl/dev-modules/pool-contracts-registry/pool-factory/PublicBeaconProxy.sol";
import "@dlsl/dev-modules/pool-contracts-registry/ProxyBeacon.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";

contract TokenFactory is ITokenFactory, OwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;

    bytes32 internal constant _CREATE_TYPEHASH =
        keccak256(
            "Create(uint256 tokenContractId,bytes32 tokenName,bytes32 tokenSymbol,uint256 pricePerOneToken,address voucherTokenContract,uint256 voucherTokensAmount,uint256 minNFTFloorPrice)"
        );

    ProxyBeacon public override tokenContractsBeacon;
    uint8 public override priceDecimals;
    string public override baseTokenContractsURI;

    EnumerableSet.AddressSet internal _tokenContracts;
    EnumerableSet.AddressSet internal _admins;

    mapping(uint256 => address) public override tokenContractByIndex;

    function __TokenFactory_init(
        address[] memory adminsArr_,
        string memory baseTokenContractsURI_,
        uint8 priceDecimals_
    ) external override initializer {
        __Ownable_init();
        __EIP712_init("TokenFactory", "1");

        tokenContractsBeacon = new ProxyBeacon();
        priceDecimals = priceDecimals_;
        baseTokenContractsURI = baseTokenContractsURI_;

        _updateAddressSet(_admins, adminsArr_, true);

        emit AdminsUpdated(adminsArr_, true);
    }

    function setBaseTokenContractsURI(string memory baseTokenContractsURI_)
        external
        override
        onlyOwner
    {
        baseTokenContractsURI = baseTokenContractsURI_;

        emit BaseTokenContractsURIUpdated(baseTokenContractsURI_);
    }

    function setNewImplementation(address newImplementation_) external override onlyOwner {
        if (tokenContractsBeacon.implementation() != newImplementation_) {
            tokenContractsBeacon.upgrade(newImplementation_);
        }
    }

    function updateAdmins(address[] calldata adminsToUpdate_, bool isAdding_)
        external
        override
        onlyOwner
    {
        _updateAddressSet(_admins, adminsToUpdate_, isAdding_);

        emit AdminsUpdated(adminsToUpdate_, isAdding_);
    }

    function deployTokenContract(
        DeployTokenContractParams calldata params_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external override {
        require(
            tokenContractByIndex[params_.tokenContractId] == address(0),
            "TokenFactory: TokenContract with such id already exists."
        );

        bytes32 structHash_ = keccak256(
            abi.encode(
                _CREATE_TYPEHASH,
                params_.tokenContractId,
                keccak256(abi.encodePacked(params_.tokenName)),
                keccak256(abi.encodePacked(params_.tokenSymbol)),
                params_.pricePerOneToken,
                params_.voucherTokenContract,
                params_.voucherTokensAmount,
                params_.minNFTFloorPrice
            )
        );

        address signer_ = ECDSA.recover(_hashTypedDataV4(structHash_), v_, r_, s_);
        require(isAdmin(signer_), "TokenFactory: Invalid signature.");

        address newTokenContract_ = address(
            new PublicBeaconProxy(address(tokenContractsBeacon), "")
        );

        ITokenContract(newTokenContract_).__TokenContract_init(
            ITokenContract.TokenContractInitParams(
                params_.tokenName,
                params_.tokenSymbol,
                address(this),
                params_.pricePerOneToken,
                params_.voucherTokenContract,
                params_.voucherTokensAmount,
                params_.minNFTFloorPrice
            )
        );

        _tokenContracts.add(newTokenContract_);
        tokenContractByIndex[params_.tokenContractId] = newTokenContract_;

        emit TokenContractDeployed(newTokenContract_, params_);
    }

    function getTokenContractsImpl() external view override returns (address) {
        return tokenContractsBeacon.implementation();
    }

    function getTokenContractsCount() external view override returns (uint256) {
        return _tokenContracts.length();
    }

    function getTokenContractsPart(uint256 offset_, uint256 limit_)
        external
        view
        override
        returns (address[] memory)
    {
        return _tokenContracts.part(offset_, limit_);
    }

    function getBaseTokenContractsInfo(address[] memory tokenContractsArr_)
        external
        view
        override
        returns (BaseTokenContractInfo[] memory tokenContractsInfoArr_)
    {
        tokenContractsInfoArr_ = new BaseTokenContractInfo[](tokenContractsArr_.length);

        for (uint256 i = 0; i < tokenContractsArr_.length; i++) {
            tokenContractsInfoArr_[i] = BaseTokenContractInfo(
                tokenContractsArr_[i],
                ITokenContract(tokenContractsArr_[i]).pricePerOneToken()
            );
        }
    }

    function getUserNFTsInfo(address userAddr_)
        external
        view
        override
        returns (UserNFTsInfo[] memory userNFTsInfoArr_)
    {
        uint256 tokenContractsCount_ = _tokenContracts.length();

        userNFTsInfoArr_ = new UserNFTsInfo[](tokenContractsCount_);

        for (uint256 i = 0; i < tokenContractsCount_; i++) {
            address tokenContractAddr = _tokenContracts.at(i);

            userNFTsInfoArr_[i] = UserNFTsInfo(
                tokenContractAddr,
                ITokenContract(tokenContractAddr).getUserTokenIDs(userAddr_)
            );
        }
    }

    function getAdmins() external view override returns (address[] memory) {
        return _admins.values();
    }

    function isAdmin(address userAddr_) public view override returns (bool) {
        return _admins.contains(userAddr_);
    }

    function _updateAddressSet(
        EnumerableSet.AddressSet storage addressSet,
        address[] memory addressesToUpdate_,
        bool isAdding_
    ) internal {
        for (uint256 i; i < addressesToUpdate_.length; i++) {
            if (isAdding_) {
                require(addressesToUpdate_[i] != address(0), "PoolFactory: Bad address.");

                addressSet.add(addressesToUpdate_[i]);
            } else {
                addressSet.remove(addressesToUpdate_[i]);
            }
        }
    }

    function _authorizeUpgrade(address newImplementation_) internal override onlyOwner {}
}