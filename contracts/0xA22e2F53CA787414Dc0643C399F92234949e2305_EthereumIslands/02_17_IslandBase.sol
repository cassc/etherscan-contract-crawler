// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MetadataStorage.sol";
import "../ERC-20/IERC20Burnable.sol";

contract IslandBase is ERC721Enumerable, Ownable {
    uint256 public constant GENESIS_FALLBACK_ID = 10000000;
    uint256 public constant FALLBACK_ID = 20000000;

    bool public burnIsActive;

    // @dev max mintable genesis Islands
    uint256 public genesisLimit = 1000;

    uint256 public mintIndex = genesisLimit;
    // @dev max mintable "non-genesis" Islands
    uint256 public limit = 3000;
    uint256 public mintPrice = 100000 * 10**18;

    IERC20Burnable public pml;

    IMetadataStorage public metadataStorage;

    // @dev occurs when a mint function is called and the current supply + the amount would exceed the limit
    error MintWouldExceedLimit();
    // @dev occurs when the burn function is called when the burning functionality is inactive
    error BurnNotActive();
    // @dev occurs if anything is to be done with the token for which the sender must be the owner or approved by the
    // owner and the sender does not match any of these criteria
    error NotTheOwnerOrApproved(uint256 tokenId);

    constructor(
        string memory name,
        string memory symbol,
        IERC20Burnable _pml,
        IMetadataStorage _metadataStorage
    ) ERC721(name, symbol) {
        pml = _pml;
        metadataStorage = _metadataStorage;
    }

    // @notice mint "non-genesis" islands
    function mint(uint256 amount) external {
        if (mintIndex + amount > limit + genesisLimit) revert MintWouldExceedLimit();
        pml.burnFrom(msg.sender, amount * mintPrice);
        uint256 newMintIndex = mintIndex;
        for (uint256 i = 0; i < amount; i++) {
            ++newMintIndex;
            _safeMint(msg.sender, newMintIndex);
        }
        mintIndex = newMintIndex;
    }

    // @notice tokens can only be burned is the flag burnIsActive is set to true
    function burn(uint256 tokenId) external {
        if (!burnIsActive) revert BurnNotActive();
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotTheOwnerOrApproved(tokenId);
        _burn(tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(owner, i);
            }
            return result;
        }
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
    }

    // @notice get the BASE64 encoded metadata from a OnChainMetadataStorage contract on chain.
    // @dev if the metadata is not stored under the ID, a fallback is used: genesis 1000000, "non-genesis" 2000000
    // @return the metadata BASE64 encoded.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 fallbackId = tokenId <= genesisLimit ? GENESIS_FALLBACK_ID : FALLBACK_ID;
        return metadataStorage.getMetadata(tokenId, fallbackId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ------------------
    // Setter
    // ------------------

    function toggleBurnState() external onlyOwner {
        burnIsActive = !burnIsActive;
    }

    function setMetadataStorage(IMetadataStorage _metadataStorage) external onlyOwner {
        metadataStorage = _metadataStorage;
    }

    function setLimit(uint256 _limit) external onlyOwner {
        limit = _limit;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
}