// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Metadata.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev this is base Azuki ERC 721A with all the bells and whistles added.
 *
 * For Royalty info we can add at construction time.
 *
 * This NFT is also burnable if you chose to do so.
 */
abstract contract BaseERC721A is ERC721ABurnable, ERC721AQueryable, ERC2981, Ownable, ERC721Metadata, ReentrancyGuard {
    address internal _teamWallet;

    /**
     * @dev create our contract setting name, symbol, royaltyReceiver and their fee in basis points
     *
     * e.g. feeNumerator = 690 would equal 0.69% or 0.069 in decimal percentage 6.96 = 69600
     */
    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 feeNumerator,
        address teamWallet
    ) ERC721A(name, symbol) {
        // set our default royalties on init
        setTeamWallet(teamWallet);
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev set the default royalty
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     *
     * We have to define this in here so we can override the ERC721...
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @dev allow us to withdraw funds to a wallet
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        payable(_teamWallet).transfer((address(this).balance));
    }

    /**
     *  @dev if for some reason we get unwanted tokens sent by accident.
     */
    function withdrawTokens(IERC20 token) external nonReentrant onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev allow us to change the team wallet.
     */
    function setTeamWallet(address newTeamWallet) public onlyOwner {
        require(newTeamWallet != address(0), "cannot be empty!");
        _teamWallet = newTeamWallet;
    }
}