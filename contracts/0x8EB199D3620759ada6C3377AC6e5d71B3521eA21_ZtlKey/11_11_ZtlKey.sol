// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Zeitls Devil's Whitelist token contract
 * Every WL token holder can participate in limited Devil's auctions.
 * Token can be transferred to a different address if needed.
 */
contract ZtlKey is Ownable, ERC721 {

    /// @dev Token supply counter
    uint256 public totalSupply = 0;

    /// @dev Token metadata uri
    string public uri;

    constructor(string memory _uri) ERC721("Zeitls Key", "ZTL-KEY") {
        uri = _uri;
    }

    /**
     * @notice Creates new key token and sends it to an address.
     */
    function mint(address target) external onlyOwner {
        totalSupply++;
        _safeMint(target, totalSupply);
    }

    /**
     * @notice Creates new key tokens in batch.
     */
    function mintBatch(address[] calldata targets) external onlyOwner {
        for (uint i = 0; i < targets.length; i++) {
            totalSupply++;
            _safeMint(targets[i], totalSupply);
        }
    }

    /**
     * @notice Revoke key token from an address.
     */
    function burn(uint id) external onlyOwner {
        totalSupply--;
        _burn(id);
    }

    /**
     * @notice Revoke key tokens in batch.
     */
    function burnBatch(uint[] calldata ids) external onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            totalSupply--;
            _burn(ids[i]);
        }
    }

    /**
     * @notice Updates Key token metadata source.
     */
    function setURI(string calldata _uri) external onlyOwner {
        uri = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }
}