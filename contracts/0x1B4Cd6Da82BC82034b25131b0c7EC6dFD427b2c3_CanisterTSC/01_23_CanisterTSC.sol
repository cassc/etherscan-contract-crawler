// SPDX-License-Identifier: MIT
/**
 * N.T.P. Canisters by Toxic Skulls Club.
 * WEB3NC, Pagzi Tech Inc.
 * Modules: Ownable, ERC721PsiBurnableUpgradeable, RoyaltyInfo, OperatorFilterer.
 */
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc721psi/contracts/extension/ERC721PsiBurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "./ITSCProject.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract CanisterTSC is
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ERC721PsiBurnableUpgradeable, 
    OperatorFilterer
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
        _registerForOperatorFiltering();
        upgrade = true;
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
        require(!upgraded.get(canisters[0]), "Using upgraded");
        require(!upgraded.get(canisters[1]), "Using upgraded");

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

    // Operator Filters Override for approval and transfer functions

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override 
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override 
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override 
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
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