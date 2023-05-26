// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../ERC721Settleable.sol";

/// @dev This module is supposed to be used in layer 1 (settlement layer).

contract ERC721PresetL1 is ERC721Settleable, Pausable {
    string private _baseTokenURI;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event SetBaseURI(string baseURI);

    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721Settleable(bridgeAddress) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _baseTokenURI = baseURI_;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        _;
    }

    /// @notice Sets `baseURI` as the `_baseURI` for all tokens
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @notice Emits a {SetBaseURI} event.
    function setBaseURI(string calldata newBaseTokenURI) external onlyAdmin {
        _baseTokenURI = newBaseTokenURI;
        emit SetBaseURI(newBaseTokenURI);
    }

    function burn(uint256 tokenId) external virtual {
        // solhint-disable-next-line reason-string
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
        super._incrementTotalBurned(1);
    }

    function pause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "must have pauser role to pause"
        );
        _pause();
    }

    function unpause() external {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "must have pauser role to unpause"
        );
        _unpause();
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function totalMinted() external view returns (uint256) {
        return super._totalMinted();
    }

    function totalSupply() external view returns (uint256) {
        return super._totalMinted() - super._totalBurned();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // solhint-disable-next-line reason-string
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}