// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "./security/ReEntrancyGuard.sol";
import "./security/SoftAdministered.sol";

contract TwoThousandThirty is SoftAdministered, ERC721A, ReEntrancyGuard {
    /// @dev  Starting and stopping sale, presale and whitelist
    bool public saleActive = true;

    /// @dev   Maximum limit of tokens that can ever exist
    uint256 public MAX_SUPPLY = 0;

    /// @dev  The base link that leads to the image / video of the token
    string public baseTokenURI = "#";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address _scVendor
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        baseTokenURI = _baseTokenURI;

        /// @dev Add the SC vendor to the whitelist
        _addRole(_scVendor);
    }

    /**
     *
     * @param _address  The address to mint to
     * @param _amount  The amount of tokens to mint
     */
    function mintReserved(
        address _address,
        uint256 _amount
    ) external onlyUserOrOwner {
        uint256 supply = totalSupply();
        uint256 _MAX_SUPPLY = MAX_SUPPLY;
        bool _saleActive = saleActive;

        require(_saleActive, "Sale isn't active");

        require(
            supply + _amount <= _MAX_SUPPLY,
            "Can't mint more than max supply"
        );

        _safeMint(_address, _amount);
    }

    /**
     * @dev  Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
     * @dev Returns the URI for `tokenId` token.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     *
     * @param _baseTokenURI The base link that leads to the image / video of the token
     */
    function setBaseURI(string memory _baseTokenURI) external onlyUserOrOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     *
     * @param val true or false
     */
    function setSaleActive(bool val) external onlyUserOrOwner {
        saleActive = val;
    }
}