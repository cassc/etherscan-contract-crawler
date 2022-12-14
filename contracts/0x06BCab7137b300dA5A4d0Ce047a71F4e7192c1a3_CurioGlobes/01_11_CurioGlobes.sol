// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Allowlist.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/*
 * @title Curio Snow Globes
 * @author Ponderware Ltd
 * @dev ERC1155 with bundling/unbundling mechanics
 */
contract CurioGlobes is ERC1155, Ownable, Allowlist {

    // mapping from recipeHash to tokenId
    mapping (bytes32 => uint256) internal TokenIds;
    // mapping from tokenId to recipe
    mapping (uint256 => uint256[]) internal TokenRecipes;

    uint256 public totalTokenTypes = 0;

    bool public frozen = false;
    bool public paused = true;

    /**
     * @dev Permanently prevents calls to `setTokenURI` to lock metadata
     */
    function permanentlyFreezeMetadata () public onlyOwner {
        frozen = true;
    }

    function pause () public onlyOwner {
        paused = true;
    }

    function unpause () public onlyOwner {
        paused = false;
    }

    modifier notFrozen () {
        require(frozen == false, "Metadata Frozen");
        _;
    }

    modifier notPaused () {
        require(paused == false, "Paused");
        _;
    }

    function setTokenURI (string memory updatedTokenURI) public onlyOwner notFrozen {
        _setURI(updatedTokenURI);
    }

    function encodeRecipe (uint256[] memory recipe) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipe));
    }

    /**
     * @notice Returns the array of tokens that are required to assemble the provided id
     */
    function getRecipe (uint256 tokenId) public view returns (uint256[] memory recipe) {
        require(tokenId < totalTokenTypes, "Nonexistant token type");
        recipe = TokenRecipes[tokenId];
        require(recipe.length > 0, "Token is primitive");
    }

    /**
     * @notice Combines multiple snow globes into a single ERC-1155
     * @dev Burns recipe tokens and mints the new "compound" token
     * @param recipe must be a recognized array of ids owned by msg.sender
     */
    function bundle (uint256[] memory recipe) public notPaused {
        require(recipe.length > 1, "Recipe too short");
        uint256 tokenId = TokenIds[encodeRecipe(recipe)];
        require(tokenId != 0, "Invalid bundle");
        _burnBatch(msg.sender, recipe, amountsArray(recipe.length));
        _mint(msg.sender, tokenId, 1, "");
    }

    /**
     * @notice Breaks apart a combined snow globe into its constituent ERC-1155s
     * @dev Burns "compound" token and mints the tokens of its recipe
     */
    function unbundle (uint256 tokenId) public notPaused {
        uint256[] storage recipe = TokenRecipes[tokenId];
        require(recipe.length > 0, "Not a bundle");
        _burn(msg.sender, tokenId, 1);
        _mintBatch(msg.sender, recipe, amountsArray(recipe.length), "");
    }

    function unbundle (uint256[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            unbundle(tokenIds[i]);
        }
    }

    function amountsArray (uint256 length) internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](length);
        for (uint i = 0; i < length; i++) {
            amounts[i] = 1;
        }
        return amounts;
    }

     uint8[32] internal ClaimableSupplies =
        [
         0,   // Globe #0; Raccoon (not tracked here)
         107, // Globe #1; Apples
         131, // Globe #2; Nuts
         147, // Globe #3; Berries
         43,  // Globe #4; Clay
         36,  // Globe #5; Paint
         37,  // Globe #6; Ink
         178, // Globe #7; Sculpture
         191, // Globe #8; Painting
         173, // Globe #9; Book
         187, // Globe #10; Future
         191, // Globe #11; BTC Keys
         175, // Globe #12; Mine Bitcoin
         192, // Globe #13; BTC
         42,  // Globe #14; CryptoCurrency
         29,  // Globe #15; DigitalCash
         43,  // Globe #16; Original
         39,  // Globe #17; UASF
         38,  // Globe #18; To The Moon
         39,  // Globe #19; Dogs Trading
         148, // Globe #20; MadBitcoins
         27,  // Globe #21; The Wizard
         27,  // Globe #22; The Bard
         27,  // Globe #23; The Barbarian
         27,  // Globe #24; Complexity
         27,  // Globe #25; Passion
         27,  // Globe #26; Education
         53,  // Globe #27; Blue
         35,  // Globe #28; Pink
         27,  // Globe #29; Yellow
         78,  // Globe #30; Eclipse
         46   // Globe #17b; UASFb
         ];

    function getClaimableSupplies () public view returns (uint8[32] memory) {
        return ClaimableSupplies;
    }

    function specialAvailable () public view returns (bool) {
        return availableClaims > 2409;
    }

    function claim (uint256 tokenId, uint16 nonce, bytes memory signedClaim) public notPaused {
        if (specialAvailable()) {
            require(ClaimableSupplies[tokenId] > 0, "token claimed out");
            ClaimableSupplies[tokenId]--;
            _mint(msg.sender, tokenId, 1, "");
        }
        processClaim(msg.sender, nonce, signedClaim);
        _mint(msg.sender, 0, 1, "");
    }

    bool contributorAllocationsComplete = false;

    function allocate (address[] calldata recipients) public onlyOwner {
        require(contributorAllocationsComplete == false, "Contributor Allocations Complete");
        require(recipients.length == 4, "Requires 4 Recipients");
        for (uint i = 0; i < recipients.length; i++) {
            _mint(recipients[i], 35, 1, "");
        }
        contributorAllocationsComplete = true;
    }

    function addBundle (uint256 length, uint8[32] memory elements) internal {
        uint256 tokenId = totalTokenTypes;
        uint256[] memory recipe = new uint256[](length);
        for (uint i = 0; i < length; i++) {
            recipe[i] = elements[i];
        }
        TokenIds[encodeRecipe(recipe)] = tokenId;
        TokenRecipes[tokenId] = recipe;
        totalTokenTypes++;
    }

    constructor (address claimSigner, string memory initialTokenURI) ERC1155(initialTokenURI) Allowlist(claimSigner) {

        totalTokenTypes = 32;

        // Cryptograffiti
        addBundle(4, [0,11,12,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Cryptopop
        addBundle(5, [0,17,18,19,31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Daniel Friedman
        addBundle(4, [0,24,25,26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Full
        addBundle(32, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]);
        // Marisol Vengas
        addBundle(4, [0,27,28,29,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Phneep
        addBundle(4, [0,14,15,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Robek World
        addBundle(4, [0,21,22,23,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
        // Story
        addBundle(11, [0,1,2,3,4,5,6,7,8,9,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
    }

    function changeClaimSigner (address claimSignerAddress) public onlyOwner {
        _updateClaimSigner(claimSignerAddress);
    }

    function permanentlyCloseClaiming () public onlyOwner {
        _permanentlyCloseClaiming();
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public virtual onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}