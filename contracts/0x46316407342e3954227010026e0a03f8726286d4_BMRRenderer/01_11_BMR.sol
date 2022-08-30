// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "lib/solmate/src/auth/Owned.sol";
import "lib/solmate/src/tokens/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "./utils/Receivable.sol";


contract BMR is ERC721, IERC2981, Owned, Receivable {

    constructor() ERC721("Brain Machine Ratio", "BMR") Owned(msg.sender) {}

    /**
     *  @dev mint logic
     */
    address public mintController;

    function setMintController(address mintController_) external onlyOwner {
        mintController = mintController_;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == mintController, "UNAUTHORIZED");
        require(tokenId >= 1 && tokenId <= 6666, "INVALID_TOKEN_ID");
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev {IERC721Metadata-tokenURI}
     */

    address public renderer;

    function setRenderer(address renderer_) external onlyOwner {
        renderer = renderer_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "NONEXISTENT_TOKEN");
        return IRenderer(renderer).tokenURI(tokenId);
    }

    /**
     * @dev {IERC2981-royaltyInfo}
     */

    function royaltyInfo(
        uint256 tokenId, uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        require(_ownerOf[tokenId] != address(0), "NONEXISTENT_TOKEN");
        return (address(this), salePrice * 5 / 100);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

}

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}