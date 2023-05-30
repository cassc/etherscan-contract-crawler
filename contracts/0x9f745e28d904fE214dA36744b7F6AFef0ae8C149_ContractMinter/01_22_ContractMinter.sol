// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721Configurable} from "@esportsplus/erc721/contracts/base/ERC721Configurable.sol";
import {ERC721Royalty} from "@esportsplus/erc721/contracts/ERC721Royalty.sol";
import {IERC721ABurnable} from "erc721a/contracts/extensions/IERC721ABurnable.sol";
import {IERC721AQueryable} from "erc721a/contracts/extensions/IERC721AQueryable.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

error CallerNotOwnerNorApproved();

contract ContractMinter is ERC721Configurable {

    address public constant LEGACY_CONTRACT = 0xbd0766b0f10e778e1861e0e9CdCeF4113683B15f;

    // Collection max mint
    uint256 public constant MAX_MINT = 15;

    // Collection max supply
    uint32 public constant MAX_SUPPLY = 10000;


    constructor() ERC721Configurable(MAX_MINT, MAX_SUPPLY, 'Contract Minter', 'contract-minter') ERC721Royalty(_msgSender(), 1000) {
        setBaseURI('https://niftyvs.com/metadata/contract-minter/json/');

        // Holders Snapshot
        setAllowlist(0, 0x61b9a1ae1db1a876ca6140ec013af3cfec2db569fd3aba982f53a7d792541066);
        setConfig(0, 1658041200, 5, MAX_SUPPLY, 0.1 ether, 1657911600);

        // Allowlist
        setAllowlist(1, 0xfa6efa09c50262a32a03b6bc7e48c1e89f8c25469281f8d8478f240f6499107f);
        setConfig(1, 1658041200, 5, MAX_SUPPLY, 0.125 ether, 1657911600);

        // Public Mint
        setConfig(2, 1658041200, 5, MAX_SUPPLY, 0.15 ether, 1657911600);

        // Giveaways
        _mintERC2309(owner(), 50);
    }


    function _availableSupply() internal override(ERC721Configurable) view virtual returns (uint256) {
        return ERC721Configurable._availableSupply() - IERC721A(LEGACY_CONTRACT).totalSupply();
    }

    function legacyBalanceOf(address account) external view returns (uint256) {
        return IERC721A(LEGACY_CONTRACT).balanceOf(account);
    }

    function legacyTokensOfOwner(address account) external view returns (uint256[] memory) {
        return IERC721AQueryable(LEGACY_CONTRACT).tokensOfOwner(account);
    }

    function legacySwap(uint256[] calldata ids) external {
        uint256 n = ids.length;
        address sender = _msgSender();

        for (uint256 i; i < n; i++) {
            if (IERC721A(LEGACY_CONTRACT).ownerOf(ids[i]) != sender) {
                revert CallerNotOwnerNorApproved();
            }

            IERC721ABurnable(LEGACY_CONTRACT).burn(ids[i]);
        }

        _safeMint(sender, n);
    }

    function withdraw() external onlyOwner {
        uint256 split = (address(this).balance * 3300) / 10000;

        _withdraw(0x1D33Db15e1A8e85Ffc5b3a6983c2E1C45349a98B, split);
        _withdraw(0x266c3dF72B45F963192BcE641Eb4d56476D296D2, split);
        _withdraw(owner(), address(this).balance);
    }
}