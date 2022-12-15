// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks, func-name-mixedcase

// inheritance
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// libs
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./token/ArtWhaleERC721.sol";
import "./token/ArtWhaleERC1155.sol";
import "./token/lib/RoyaltyUpgradeable.sol";

contract ArtWhaleFactoryV1 is
    ProxyAdmin
{
    using AddressUpgradeable for address payable;

    event DeployArtWhaleERC721(
        address indexed deployer,
        address indexed newContract,
        string name_,
        string symbol_,
        address operator_,
        RoyaltyUpgradeable.RoyaltyInfo[] defaultRoyaltyInfo_
    );

    event DeployArtWhaleERC1155(
        address indexed newContract,
        address indexed deployer,
        string name_,
        string symbol_,
        string uri_,
        address operator_,
        RoyaltyUpgradeable.RoyaltyInfo[] defaultRoyaltyInfo_
    );

    function deployArtWhaleERC721(
        address implementation_,
        uint256 salt_,
        string memory name_,
        string memory symbol_,
        address operator_,
        RoyaltyUpgradeable.RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) external onlyOwner returns(address) {
        TransparentUpgradeableProxy newProxy = new TransparentUpgradeableProxy{salt: bytes32(salt_)}(
            implementation_,
            address(this),
            abi.encodeCall(ArtWhaleERC721.initialize, (name_, symbol_, operator_, defaultRoyaltyInfo_))
        );

        emit DeployArtWhaleERC721(
            msg.sender,
            address(newProxy),
            name_,
            symbol_,
            operator_,
            defaultRoyaltyInfo_
        );

        return address(newProxy);
    }

    function deployArtWhaleERC1155(
        address implementation_,
        uint256 salt_,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address operator_,
        RoyaltyUpgradeable.RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) external onlyOwner returns(address) {
        TransparentUpgradeableProxy newProxy = new TransparentUpgradeableProxy{salt: bytes32(salt_)}(
            implementation_,
            address(this),
            abi.encodeCall(ArtWhaleERC1155.initialize, (name_, symbol_, uri_, operator_, defaultRoyaltyInfo_))
        );

        emit DeployArtWhaleERC1155(
            msg.sender,
            address(newProxy),
            name_,
            symbol_,
            uri_,
            operator_,
            defaultRoyaltyInfo_
        );

        return address(newProxy);
    }
}