// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../common/BlockAware.sol";
import "./IZeeNFT.sol";

contract ZeeNFT is
    IZeeNFT,
    UUPSUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    AccessControlledUpgradeable,
    BlockAware
{
    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializerERC721A {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(address acl) external initializer initializerERC721A {
        __ERC721A_init("Zee NFT", "Zee");
        __BlockAware_init();
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __AccessControlled_init(acl);
    }

    function mint(address receiver, uint256 quantity) external override onlyRole(Roles.ZEE_NFT_MINT) {
        _safeMint(receiver, quantity);
    }

    function burn(uint256 tokenId) public override(ERC721ABurnableUpgradeable, IZeeNFT) onlyRole(Roles.ZEE_NFT_BURN) {
        _burn(tokenId);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }
}