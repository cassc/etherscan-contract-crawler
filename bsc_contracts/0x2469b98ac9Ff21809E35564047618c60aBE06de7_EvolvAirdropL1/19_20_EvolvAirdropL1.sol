// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EvolvERC721Settleable.sol";

/// @dev This module is supposed to be used in layer 1 (settlement layer).

contract EvolvAirdropL1 is Ownable, EvolvERC721Settleable, Pausable {
    string private _baseTokenURI;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol,
        string memory baseURI_,
        string memory ext_
    ) EvolvERC721Settleable(bridgeAddress) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        setBaseURI(baseURI_, ext_);
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        _;
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
}