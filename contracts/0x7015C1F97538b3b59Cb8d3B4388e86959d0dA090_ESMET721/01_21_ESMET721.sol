// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "./access/Governable.sol";
import "./storage/ESMET721Storage.sol";
import "./interface/IESMET721.sol";

contract ESMET721 is IESMET721, Governable, ERC721Enumerable, ESMET721StorageV1 {
    /// Emitted when `baseTokenURI` is updated
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC721_init(name_, symbol_);
        __Governable_init();

        nextTokenId = 1;
    }

    /**
     * @notice Burn NFT
     * @dev Revert if caller isn't the esMET
     * @param tokenId_ The id of the token to burn
     */
    function burn(uint256 tokenId_) external override {
        require(_msgSender() == address(esMET), "not-esmet");
        _burn(tokenId_);
    }

    /**
     * @notice Mint NFT
     * @dev Revert if caller isn't the esMET
     * @param to_ The receiver account
     */
    function mint(address to_) external override returns (uint256 _tokenId) {
        require(_msgSender() == address(esMET), "not-esmet");
        _tokenId = nextTokenId++;
        _mint(to_, _tokenId);
    }

    /**
     * @notice Base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Transfer position (locked/boosted) when transferring the NFT
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        super._beforeTokenTransfer(from_, to_, tokenId_);

        if (from_ != address(0) && to_ != address(0)) {
            esMET.transferPosition(tokenId_, to_);
        }
    }

    /** Governance methods **/

    /**
     * @notice Update the base token URI
     */
    function setBaseTokenURI(string memory baseTokenURI_) external onlyGovernor {
        emit BaseTokenURIUpdated(baseTokenURI, baseTokenURI_);
        baseTokenURI = baseTokenURI_;
    }

    /**
     * @notice Initialized esMET contract
     * @dev Called once
     */
    function initializeESMET(IESMET esMET_) external onlyGovernor {
        require(address(esMET) == address(0), "already-initialized");
        require(address(esMET_) != address(0), "address-is-null");
        esMET = esMET_;
    }
}