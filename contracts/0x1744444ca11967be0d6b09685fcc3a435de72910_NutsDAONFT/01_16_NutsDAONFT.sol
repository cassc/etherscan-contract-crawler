// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "./libraries/MinterAccess.sol";
import "./libraries/Recoverable.sol";

/*
 * @title NutsDAO Poker Players NFT Collection
 */
contract NutsDAONFT is ERC721A, ERC2981, Ownable, MinterAccess, Recoverable {
    uint256 public immutable maxSupply;
    bool public isMetadataLocked;
    string public baseURI;

    event LockMetadata();

    constructor(uint256 maxSupply_) ERC721A("NutsDAO Poker Players", "NutsDAO") {
        maxSupply = maxSupply_;
    }

    /**
     * @notice First NFT id is 1
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Allows the owner to lock the contract's metadata
     * @dev Callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "NFT: Metadata are locked");
        require(bytes(baseURI).length > 0, "NFT: BaseUri not set");
        isMetadataLocked = true;
        emit LockMetadata();
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param uri_: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory uri_) external onlyOwner {
        require(!isMetadataLocked, "NFT: Metadata are locked");
        baseURI = uri_;
    }

    /**
     * @dev Base URI for computing {tokenURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Uodate the royalties for the collection
     */
    function setRoyalties(address receiver, uint96 feeNumerator) external onlyOwner {
        require(feeNumerator <= _feeDenominator() / 10, "Invalid fee");
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Allows a member of the minters group to mint tokens to a specific address
     * @param to: address to receive the token
     * @param quantity: number of tokens to mint
     * @dev Callable by minters
     */
    function mint(address to, uint256 quantity) external onlyMinters {
        uint256 total = totalSupply();
        require(total < maxSupply, "NFT: Total supply reached");
        require(total + quantity <= maxSupply, "NFT: Quantity above supply");
        require(quantity > 0, "NFT: Invalid quantity");

        uint256 minted = 0;
        while (minted < quantity) {
            // mint by batch to limit ERC721A transfer costs
            uint256 q = quantity > minted + 20 ? 20 : quantity - minted;

            _mint(to, q);
            minted += q;
        }
    }
}