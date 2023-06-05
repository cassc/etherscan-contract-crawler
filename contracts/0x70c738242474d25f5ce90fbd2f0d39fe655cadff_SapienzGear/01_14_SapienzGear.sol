// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SapienzGear is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    error TokenClaimed();
    error SapienzClaimed();
    error NotSapienzOwner();
    error InvalidProof();

    using StringsUpgradeable for uint256;

    function initialize(string memory _uri) public initializer {
        __ERC1155_init(_uri);
        __Ownable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function contractURI() external pure returns (string memory) {
        return "https://engine.sapienz.xyz/metadata/gear/contract";
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }

    function airdrop(
        address[] calldata recipients,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = recipients.length;
        for (uint256 i = 0; i < len; i++) {
            _airdrop(recipients[i], tokenIds[i], amounts[i]);
        }
    }

    function _airdrop(
        address recipient,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        _mintBatch(recipient, tokenIds, amounts, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}