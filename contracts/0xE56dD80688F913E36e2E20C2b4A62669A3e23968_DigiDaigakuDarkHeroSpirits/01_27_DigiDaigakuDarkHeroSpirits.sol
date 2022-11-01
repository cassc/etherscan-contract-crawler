// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "limit-break-contracts/contracts/adventures/AdventureNFT.sol";
import "limit-break-contracts/contracts/utils/tokens/SequentialAirdropMint.sol";

contract DigiDaigakuDarkHeroSpirits is AdventureNFT, SequentialAirdropMint {

    constructor(uint256 maxSupply_, address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") {
        initializeERC721("DigiDaigakuDarkHeroSpirits", "DIHDSP");
        initializeURI("https://digidaigaku.com/dark-hero-spirits/metadata/", ".json");
        initializeAdventureERC721(10);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeMaxSupply(maxSupply_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(IMaxSupplyInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}