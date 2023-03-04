// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/ArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import "./ArttacaERC721SplitsUpgradeable.sol";
import "./IArttacaERC721Upgradeable.sol";
import "./ArttacaERC721URIStorageUpgradeable.sol";

interface Operatable {
    function isOperator(address _user) external view returns (bool);
}

/**
 * @title ArttacaERC721Upgradeable
 * @dev This contract is an Arttaca ERC721 upgradeable collection.
 */
contract ArttacaERC721Upgradeable is OwnableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable, ArttacaERC721URIStorageUpgradeable, ArttacaERC721SplitsUpgradeable, IArttacaERC721Upgradeable, EIP712Upgradeable {

    // @dev Factory address
    address public override factoryAddress;

    // @dev Contract metadata URI
    string public override contractURI;

    uint public totalSupply;

    function __ArttacaERC721_initialize(
        address _factoryAddress,
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        uint96 _royaltyPct,
        string memory _contractURI
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __EIP712_init("Arttaca Collection", "1");
        __Ownable_init();
        __Pausable_init();
        __ERC721Burnable_init();
        __ArttacaERC721URIStorage_init(baseURI_);
        __Splits_init(_royaltyPct);
        _transferOwnership(_owner);

        factoryAddress = _factoryAddress;
        contractURI = _contractURI;
    }

    function mintAndTransferByOwner(address _to, uint _tokenId, string calldata _tokenURI, Ownership.Royalties memory _royalties) override external onlyOwner {
        mint(_to, _tokenId, _tokenURI, _royalties);
    }

    function mintAndTransfer(
        LazyMint721.TokenData calldata _tokenData,
        LazyMint721.MintData calldata _mintData
    ) override external {
        require(Operatable(factoryAddress).isOperator(msg.sender), "ArttacaERC721Upgradeable:mintAndTransfer:: Caller is not a valid factory operator.");
        require(block.timestamp <= _mintData.expTimestamp, "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is expired.");
        require(
            ECDSAUpgradeable.recover(
                _hashTypedDataV4(LazyMint721.hashMint(address(this), _tokenData, _mintData)),
                _mintData.signature
            ) == owner(),
            "ArttacaERC721Upgradeable:mintAndTransfer:: Signature is not valid."
        );
        mint(_mintData.to, _tokenData.id, _tokenData.URI, _tokenData.royalties);
    }

    function mint(address _to, uint _tokenId, string calldata _tokenURI, Ownership.Royalties memory _royalties) internal {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _setRoyalties(_tokenId, _royalties);
        totalSupply++;
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function _burn(uint tokenId) internal virtual override(ERC721Upgradeable, ArttacaERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function tokenURI(uint _tokenId) public view override(ERC721Upgradeable, ArttacaERC721URIStorageUpgradeable) returns (string memory) {
        require(_exists(_tokenId), "ArttacaERC721Upgradeable::tokenURI: token has not been minted.");
        return ArttacaERC721URIStorageUpgradeable.tokenURI(_tokenId);
    }

    function getTokenInformation(uint _tokenId) external view override returns (TokenInformation memory tokenInformation) {
        require(_exists(_tokenId), "ArttacaERC721Upgradeable::getTokenInformation: token has not been minted.");
        return TokenInformation({
            owner: ownerOf(_tokenId),
            tokenURI: tokenURI(_tokenId),
            royalties: getRoyalties(_tokenId)
        });
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IArttacaERC721Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    uint256[49] private __gap;
}