// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./additional/ERC1155UAEPresetUpgradeable.sol";
import "./additional/PaymentSplitterUAEPresetUpgradeable.sol";

contract ERC1155PaymentSplitterUAEUpgradeable is Initializable, ContextUpgradeable, ERC1155UAEPresetUpgradeable, PaymentSplitterUAEPresetUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        address releaseMintTo_,
        uint256 releaseTokenId_,
        string memory releaseTokenUri_,
        string memory defaultUri_,
        address[] memory payees_,
        uint256[] memory shares_
    ) public virtual initializer {
        __ERC1155PaymentSplitterUAE_init(name_, symbol_, releaseMintTo_, releaseTokenId_, releaseTokenUri_, defaultUri_, payees_, shares_);
    }

    function __ERC1155PaymentSplitterUAE_init(
        string memory name_,
        string memory symbol_,
        address releaseMintTo_,
        uint256 releaseTokenId_,
        string memory releaseTokenUri_,
        string memory defaultUri_,
        address[] memory payees_,
        uint256[] memory shares_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(defaultUri_);
        __ERC1155Supply_init_unchained();
        __ERC1155Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __ERC1155UAEPreset_init_unchained(name_, symbol_, releaseMintTo_, releaseTokenId_, releaseTokenUri_);
        __ReentrancyGuard_init_unchained();
        __PaymentSplitter_init_unchained(payees_, shares_);
        __PaymentSplitterUAEPreset_init_unchained();
        __ERC1155PaymentSplitterUAE_init_unchained();
    }

    function __ERC1155PaymentSplitterUAE_init_unchained() internal initializer {
    }
}