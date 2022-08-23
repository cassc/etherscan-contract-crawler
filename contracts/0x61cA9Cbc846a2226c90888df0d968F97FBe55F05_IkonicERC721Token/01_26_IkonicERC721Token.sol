// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ERC721Base.sol";

/**
 * @title IkonicERC721Token
 * @dev anyone can mint token.
 */
contract IkonicERC721Token is
    ERC721Base,
    ERC721Enumerable
{
    using ECDSA for bytes32;

    address private signer;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: IKONIC Token
     * @param _symbol symbol of the token ex: IKONIC
     * @param baseURI_ ex: https://ipfs.ikonic.com
     * @param _signer signer account
    */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        address _signer
    ) ERC721Base(_name, _symbol, baseURI_) {
        signer = _signer;
        _registerInterface(bytes4(keccak256("MINT_WITH_ADDRESS")));
    }

    /**
     * @notice mint ERC721 token
     * @param _tokenId token ID
     * @param _tokenURI token URI
     * @param royaltyRecipient royalty recipient address
     * @param royaltyValue royalty fee value
     * @param sig signature
     * @param _fees affiliate fee array
     */
    function mint(
        uint256 _tokenId,
        string memory _tokenURI,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory sig,
        AffiliateFee[] memory _fees
    ) external {
        require(
            keccak256(abi.encodePacked(address(this), _tokenId, msg.sender)).toEthSignedMessageHash().recover(sig) == signer,
            "IkonicERC721Token.mint: Invalid signature"
        );
        _mint(_tokenId, _tokenURI, royaltyRecipient, royaltyValue, _fees);
    }

    /**
     * @notice set signer address
     * @param _signer signer address
     */
    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0x0), "IkonicERC721Token.setSignerAddress: Invalid address");
        signer = _signer;
    }

    /// @notice returns signer address
    function getSignerAddress() external view returns(address) {
        return signer;
    }

    /** 
     * @notice set base URI
     * @param baseURI_ base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Internal function that returns base URI
    function _baseURI() internal view virtual override(ERC721, ERC721Base) returns (string memory) {
        return ERC721Base._baseURI();
    }

    /// @notice returns base URI
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice See {ERC721Base-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Base, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice See {ERC721Enumerable-_beforeTokenTransfer}
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice See {ERC721Base-tokenURI}
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Base) returns (string memory) {
        return ERC721Base.tokenURI(tokenId);
    }

    /// @notice See {ERC721Base-_burn}.
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Base) {
        ERC721Base._burn(tokenId);
    }

    /// @notice override function that burn token.
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "IkonicERC721Token.burn: caller is not owner nor approved");
        _burn(tokenId);
    }
}