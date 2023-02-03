// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "../BaseRecoverableContract.sol";
import "../nft-permit/ERC721WithPermit.sol";
import "./NFTStorage.sol";
import "./INFT.sol";

error MaximumTotalSupplyReached(uint256 maximum);
error BatchSizeTooLarge(uint256 maximum, uint256 actual);
error BurningIsNotEnabled();

// solhint-disable no-empty-blocks
abstract contract NFTBase is
    INFTUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    BaseRecoverableContract,
    ERC721WithPermit,
    NFTStorage
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 private constant _BATCH_SIZE_LIMIT = 100;

    event BaseURIChanged(string baseURI);
    event TokenURIChanged(uint256 tokenId, string tokenURI);

    modifier whenBurnEnabled() {
        if (!_burnEnabled) revert BurningIsNotEnabled();
        _;
    }

    function mint(address to) external onlyMinter returns (uint256 tokenId) {
        return _mintTo(to);
    }

    function burn(uint256 tokenId) external override onlyMinter whenBurnEnabled {
        _burn(tokenId);
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOperator {
        _baseTokenURI = baseTokenURI;
        emit BaseURIChanged(baseTokenURI);
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyOperator {
        _setTokenURI(tokenId, _tokenURI);
        emit TokenURIChanged(tokenId, tokenURI(tokenId));
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external {
        if (tokenIds.length > _BATCH_SIZE_LIMIT) revert BatchSizeTooLarge(_BATCH_SIZE_LIMIT, tokenIds.length);

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < tokenIds.length; ) {
            transferFrom(from, to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function batchMint(address[] calldata accounts, uint256 tokens) external onlyMinter {
        if (accounts.length * tokens > _BATCH_SIZE_LIMIT)
            revert BatchSizeTooLarge(_BATCH_SIZE_LIMIT, accounts.length * tokens);

        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < accounts.length; ) {
            address account = accounts[i];
            for (uint256 j = 0; j < tokens; ) {
                _mintTo(account);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getMaxTokenSupply() external view returns (uint256) {
        return _maxTokenSupply;
    }

    function getBaseTokenURI() external view returns (string memory) {
        return _baseURI();
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721WithPermit, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __NFT_init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI,
        uint256 maxTokenSupply,
        bool burnEnabled,
        address aclContract
    ) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721WithPermit_init_unchained();
        __BaseContract_init(aclContract);
        _baseTokenURI = baseTokenURI;
        _maxTokenSupply = maxTokenSupply;
        _burnEnabled = burnEnabled;
        // nextTokenId is initialized to 1
        _tokenIdCounter.increment();
    }

    function _mintTo(address to) internal returns (uint256 tokenId) {
        if (totalSupply() >= _maxTokenSupply) revert MaximumTotalSupplyReached(_maxTokenSupply);
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721WithPermit) {
        super._transfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}