// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**===============================================================================
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,@@,,,,,@@((,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,,,,,@@@@@((,,,,,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,@@@((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  @@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,@@@@@@@@@@@,,,,,@@,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@    @@,,,@@,,,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,@@@@@@@@@@@@@@,,@@@,,,,@@     @@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,@@@@@,,,,@@   @@@@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,@@@(((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@(((((((@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((((@@@@@((((((((((((((((((((((((((((((((@@@@(((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((**##############################################,,**@@@,,,,,,,,
,,,,,,,,,,@@(((((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((@@,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((((((((((((((((((((((((((((((((((((((((((((((((@@,,,,,,,,,,,,,
,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
==================================================================================
🐸                                 BASE LOGIC                                   🐸
🐸                       THE PEOPLES' NFT MADE BY FROGS                         🐸
================================================================================*/

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface IRenderer {
    function tokenURI(uint256 value) external view returns (string memory);
}

contract Base is ERC721AQueryable, ERC721ABurnable, Ownable, ERC2981 {

    uint256 public constant _price = 0.0069 ether;
    uint256 public constant WALLET_MAX = 10;
    uint256 public immutable MAX_POP;

    IRenderer _renderer;

    constructor(
        string memory name,
        string memory symbol,
        address rendererAddress,
        uint256 supply
    ) ERC721A(name, symbol) {
        _renderer = IRenderer(rendererAddress);
        _setDefaultRoyalty(msg.sender, 250);
        MAX_POP = supply;
    }

    /**
     🐸 @notice Minting starts at token id #1
     🐸 @return Token id to start minting at
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     🐸 @notice Retrieve how many tokens have been minted
     🐸 @return Total number of minted tokens
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     🐸 @notice Get the tokenURI from the renderer contract
     🐸 @param tokenId - Token ID of desired token
     🐸 @return Metadata for the given token ID
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return _renderer.tokenURI(tokenId);
    }

    /**
     🐸 @notice Set the address of the renderer
     🐸 @param rendererAddress - Address of new renderer contract
     */
    function setRenderer(address rendererAddress) external onlyOwner {
        _renderer = IRenderer(rendererAddress);
    }

    /**
     🐸 @notice Check that various interfaces are supported
     🐸 @param interfaceId - id of interface to check
     🐸 @return bool for support
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     🐸 @notice Set royalties for all tokens.
     🐸 @param receiver - Address receiving royalties.
     🐸 @param feeBasisPoints - Fee as Basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     🐸 @notice Withdraw all Eth funds
     */
    function withdrawAll() external onlyOwner {
        owner().call{value: address(this).balance}("");
    }

    /**
     🐸 @notice Withdraw erc20 that pile up, if any
     🐸 @param token - ERC20 token to withdraw
     */
    function withdrawAllERC20(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}