// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AModified.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Meekicks
 * @author maikir
 * @notice This contract allows the distribution, minting and exchange of ERC-721 Meekicks Tokens.
 *
 */
contract Meekicks is ERC721AModified, Ownable, ReentrancyGuard {
    using Address for address;
    // Sale active boolean
    bool public isSaleActive;

    // Base URI
    string private _uri;

    IERC721 public immutable meebits;

    constructor(string memory _baseURI_, IERC721 _meebits, bool _isSaleActive) ERC721AModified("Meekicks", "MEEKICKS") {
        _uri = _baseURI_;
        meebits = _meebits;
        isSaleActive = _isSaleActive;
    }

    /**
     * @dev Allows to enable minting of sale and create sale period.
     */
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /**
     * @dev Allows owner to set the baseURI dynamically.
     * @param uri The base uri for the metadata store.
     */
    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    /**
     * @dev Override for allowing setting of a base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function kickMintEligible(address _address, uint256[] calldata tokenIds)
        public
        view
        returns (bool)
    {
        uint256 i;
        do {
            if (meebits.ownerOf(tokenIds[i]) != _address) {
                break;
            }
            i++;
        } while (i < tokenIds.length);

        if (i == tokenIds.length) {
            return true;
        } else {
            return false;
        }
    }

    //MINTING
    /**
     * @dev Minting function for kicks
     * @param tokenIds Meebits token ID(s) to mint equivalent MeebitsKicks for.
     * @param quantity quantity of MeebitsKicks to mint for number of Meebits held.
     */
    function mintKicks(uint256[] calldata tokenIds, uint256 quantity) external nonReentrant {
        require(isSaleActive, "Sale must be active");
        require(
          kickMintEligible(msg.sender, tokenIds),
          "Caller is not the owner of the meebits token ID provided"
        );
        _safeMint(msg.sender, tokenIds, quantity);
    }
}