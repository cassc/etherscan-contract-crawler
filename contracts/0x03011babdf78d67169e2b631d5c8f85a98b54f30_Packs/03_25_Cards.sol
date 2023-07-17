// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Constants.sol";

/**
 * @title Cards
 * @author David Lafeta
 * @notice This contract creates Cards tokens which can be obtained by opening Packs.
 * @dev Implementation based on Sector4Parts Contract by Alicenet developers' Troy Salem (Cr0wn_Gh0ul), Hunter Prendergast (et3p), ZJ Lin
 */
contract Cards is ERC721Enumerable, ERC2981, Ownable {
    // Uint256 to string for tokenURI
    using Strings for uint256;
    // Mint random id
    uint256 internal _currentPrng;
    // Mapping of token id swaps
    mapping(uint256 => uint256) internal _idSwaps;
    // Tokens left to mint
    uint256 internal _leftToMint = TOTAL_NUM_CARDS;
    // URI for after reveal
    string public baseTokenURI = "";
    // Address of packs
    address internal immutable _packs;
    /**
     * @dev Event for when a new cards are created.
     */
    event NewCards(address owner, uint256 packId, uint256[] cardsId);

    /**
     * @dev Sets secondary sales royalties to 5% of the contract price and sends them to Packs.
     * That allows for a split in the royalties between the project's contributors
     */
    constructor(address packContractAddress_) ERC721("Area54Cards", "AC") {
        _packs = packContractAddress_;
        ERC2981._setDefaultRoyalty(packContractAddress_, 500);
    }

    /**
     * @notice Mint cards from a pack. This method can only can called by Packs(`_packs`), after a pack is burned
     */
    function mintCards(address user_, uint256 packId_) external payable {
        require(
            msg.sender == address(_packs),
            "Only the Packs contract is allowed to call this method"
        );
        uint256[] memory tokensOpened = _mint(user_);
        emit NewCards(user_, packId_, tokensOpened);
    }

    /**
     * @notice Set the base uri for the token metadata
     * @param uri_ the uri to the metadata ending with "/"
     */
    function setBaseTokenURI(string memory uri_) public onlyOwner {
        baseTokenURI = uri_;
    }

    /**
     * @dev returns a single metadata URI per id
     * @param tokenId_ token id for the metadata to be returned
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");
        return string(abi.encodePacked(baseTokenURI, tokenId_.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get the total number of packs that the project will have
     */
    function getAvailableSupply() public view returns (uint256) {
        return _leftToMint;
    }

    /**
     * @dev Internal mint function to be called by `mintCards`
     */
    function _mint(address user_) internal returns (uint256[] memory) {
        uint256 currentPrng = _currentPrng;
        uint256 leftToMint = _leftToMint;

        uint256 tokenId;
        uint256[] memory tokensOpened = new uint256[](NUM_CARDS_IN_PACK);
        for (uint256 i = 0; i < NUM_CARDS_IN_PACK; i++) {
            (tokenId, leftToMint, currentPrng) = _pullRandomTokenId(leftToMint, currentPrng);
            ERC721._safeMint(user_, tokenId);
            tokensOpened[i] = tokenId;
        }
        _leftToMint = leftToMint;
        _currentPrng = currentPrng;
        return tokensOpened;
    }

    /**
     * @notice Pull a random token id to be minted next
     * @dev Created by dievardump (Simon Fremaux)
     * @dev Implemented in CyberBrokersMint Contract(0xd64291d842212bcf20db9dbece7823fe103061ab) by cybourgeoisie (Ben Herdorn)
     * @dev Modifications of this function were made by Alicenet's developers to optimize gas
     * @param leftToMint_ How many tokens are left to be minted
     * @param currentPrng_ The curent set prng
     **/
    function _pullRandomTokenId(uint256 leftToMint_, uint256 currentPrng_)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(leftToMint_ > 0, "No more to mint");
        uint256 newPrng = _prng(leftToMint_, currentPrng_);
        uint256 index = 1 + (newPrng % leftToMint_);
        uint256 tokenId = _idSwaps[index];
        if (tokenId == 0) {
            tokenId = index;
        }
        uint256 temp = _idSwaps[leftToMint_];
        if (temp == 0) {
            _idSwaps[index] = leftToMint_;
        } else {
            _idSwaps[index] = temp;
        }
        return (tokenId, leftToMint_ - 1, newPrng);
    }

    /**
     * @dev prng to be used by _pullRandomTokenId
     * @param leftToMint_ number of tokens left to mint
     * @param currentPrng_ the last value returned by this function
     */
    function _prng(uint256 leftToMint_, uint256 currentPrng_) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), currentPrng_, leftToMint_))
            );
    }
}