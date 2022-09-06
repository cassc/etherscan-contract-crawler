// SPDX-License-Identifier: MIT
/**
 * N.T.P. Canisters by Toxic Skullz Club.
 * WEB3NC, Pagzi Tech Inc.
 * Modules: Ownable, ERC721PsiBurnableUpgradeable, RoyaltyInfo.
 */
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc721psi/contracts/extension/ERC721PsiBurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "./ITSCProject.sol";

contract CanisterTSC is
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ERC721PsiBurnableUpgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap upgraded;

    bool consume;
    bool upgrade;

    ITSCProject public iTSCProject;

    function initialize() public initializer {
        __ERC721Psi_init("N.T.P. Canisters", "CANISTERS");
        __ERC2981_init();
        __Ownable_init();
        _setDefaultRoyalty(address(0xF04ee8223974F933184DA78532837B62fC089384), 750);
        upgrade = false;
        consume = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ntpcanisters.nftapi.art/meta/";
    }

    // airdrop for sending assets.
    function airdrop(address[] calldata recipient,uint[] calldata quantity) external onlyOwner {
        uint256 qty = recipient.length;
        unchecked {
            for (uint256 i = 0; i < qty; ++i) {
                _mint(recipient[i], quantity[i]);
            }
        }
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokenLevel(uint256 tokenId) public view returns (uint256 level) {
        require(_exists(tokenId), "Nonexistant tokenId!");
        if (upgraded.get(tokenId)) {
            level = 2;
        } else {
            level = 1;
        }
    }

    /// Burn 3 canisters and get a new hazardous canister.
    /// @param tokenId | base canister to upgrade, canisters | IDs of the canisters used as source.
    /// The canisters in the canisters list will be burned.
    function upgradeToHazardous(uint256 tokenId, uint256[2] calldata canisters)
        external
    {
        require(upgrade, "Not enabled yet!");

        require(ownerOf(tokenId) == msg.sender, "Not NFT Owner for the base!");
        require(
            ownerOf(canisters[0]) == msg.sender,
            "Not NFT Owner for the canisters!"
        );
        require(
            ownerOf(canisters[1]) == msg.sender,
            "Not NFT Owner for the canisters!"
        );

        require(canisters[0] != tokenId);
        require(canisters[1] != tokenId);

        require(!upgraded.get(tokenId), "Already upgraded");

        // This prevents canisters[0] == canisters[1] automatically. As the same token cannot be burned twice.
        _burn(canisters[0]);
        _burn(canisters[1]);

        upgraded.set(tokenId);
    }

    /// TODO : Burn a hazardous canister to mint a new NFT TSC collection.
    /// @param canister | ID of the canister used as the source.
    /// The canister needs to be hazardous and it will be burned.
    function consumeHazardous(uint256 canister) public {
        require(consume, "Not enabled yet!");

        require(ownerOf(canister) == msg.sender, "Not the owner!");
        require(tokenLevel(canister) == 2, "Not a super!");
        // Burn the hazardous canister.
        _burn(canister);
        iTSCProject.mintProject(msg.sender, 1);
    }

    /* Administrative Functions */

    function toggleUpgrade() external onlyOwner {
        upgrade = !upgrade;
    }

    function toggleConsume() external onlyOwner {
        consume = !consume;
    }

    function setTSCProject(ITSCProject _tscProject) external onlyOwner {
        iTSCProject = _tscProject;
    }

    function setRoyalty(address royaltyWallet, uint96 multiplier) external onlyOwner {
        _setDefaultRoyalty(royaltyWallet, multiplier);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}