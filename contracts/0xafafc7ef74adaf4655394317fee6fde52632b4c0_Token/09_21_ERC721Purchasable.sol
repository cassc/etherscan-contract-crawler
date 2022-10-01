// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./ERC721Base.sol";

abstract contract ERC721Purchasable is ERC721Base, ReentrancyGuard, Pausable {
    constructor(
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI
    ) ERC721Base(_maxSupply, _name, _symbol, _baseURI, _contractURI) {}

    /**
     * @notice Returns token price
     */
    function tokenPrice(uint256) public view virtual returns (uint256);

    /**
     * @notice Updates single token price
     */
    function setTokenPrice(uint256, uint256) external virtual {
        revert("Not implemented");
    }

    /**
     * @notice Updates token prices by batch
     */
    function setTokenPriceBatch(uint256[] memory, uint256[] memory) external virtual {
        revert("Not implemented");
    }

    /**
     * @notice Unpause the contract
     * @dev Can be done only by the contract owner
     */
    function activateContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Pause the contract
     * @dev Can be done only by the contract owner
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    function _getPaymentDetails(uint256 amount, uint256 tokenId)
        internal
        view
        virtual
        returns (address[] memory, uint[] memory);
}