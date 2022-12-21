// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IDividendManager.sol";
import "../interfaces/IInvestNFT.sol";
import "../RecoverableFunds.sol";
import "./Depositary.sol";

contract InvestNFT is IInvestNFT, ERC721Burnable, ERC721Enumerable, Depositary, RecoverableFunds, AccessControl, Pausable  {

    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;

    IDividendManager dividendManager;

    constructor() ERC721("Blockchain Name Services Investment NFT", "BNSI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setDividendManager(address newDividendManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dividendManager = IDividendManager(newDividendManager);
    }

    function safeMint(address to, uint256 shares) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _mintShares(tokenId, shares);
        dividendManager.handleMint(IDividendManager.AccountId.wrap(tokenId));
    }

    function withdrawDividend() external {
        for (uint256 i; i < balanceOf(msg.sender); i++) {
            dividendManager.withdrawDividend(IDividendManager.AccountId.wrap(tokenOfOwnerByIndex(msg.sender, i)));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveTokens(recipient, tokenAddress);
    }

    function retrieveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveETH(recipient);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) override internal virtual {
        dividendManager.handleBurn(IDividendManager.AccountId.wrap(tokenId));
        _burnShares(tokenId);
        super._burn(tokenId);
    }

}