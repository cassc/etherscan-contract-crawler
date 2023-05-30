// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Whitelist.sol";

/**
 * @title FoxesV2
 * @author Jorge Izquierdo (https://github.com/izqui)
 * @dev ERC721 token with a whitelisted presale and lazy minting
 */
contract FoxesV2 is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;

    address public mintAccount;
    uint256 public lazyMintedCount;

    bool public isPresale;
    Whitelist public presaleWhitelist;
    uint64 public presaleBuyLimit;
    mapping(address => uint256) public presaleBuys;

    event BaseURIChanged(string baseURI);
    event MintAccountChanged(address mintAccount);
    event PresaleFinalized();

    /**
     * @param _presaleWhitelist Reference to whitelist contract to check if a user is whitelisted
     * @param _mintAccount Address of the account that will receive ownership of all minted tokens
     * @param _presaleBuyLimit Limit of tokens that can be bought by a whitelisted account during presale
     * @param _initialBaseURI Base URI for all NFTs
     */
    constructor(
        Whitelist _presaleWhitelist,
        address _mintAccount,
        uint64 _presaleBuyLimit,
        string memory _initialBaseURI
    ) ERC721("Philosophical Foxes V2", "FOX") {
        require(_mintAccount != address(0), "FoxesV2: bad presale seller");
        require(_presaleBuyLimit > 0, "FoxesV2: presale limit zero");

        presaleWhitelist = _presaleWhitelist;
        mintAccount = _mintAccount;
        presaleBuyLimit = _presaleBuyLimit;
        isPresale = true;

        baseURI = _initialBaseURI;
    }

    /**
     * @notice Mints multiple new NFTs to the mint account
     * @param _amount Amount of NFTs to mint
     * @param _mintLazily Whether to mint the NFTs lazily or immediately
     */
    function mintMany(uint256 _amount, bool _mintLazily) external onlyOwner {
        address seller = mintAccount;
        uint256 initialSupply = totalSupply();

        if (_mintLazily) {
            // Keep track of how many NFTs have been minted lazily to avoid re-minting them
            lazyMintedCount += _amount;

            for (uint256 i = 0; i < _amount; i++) {
                // An event is emitted to make contract consumers to believe that the NFT is minted
                emit Transfer(address(0), seller, initialSupply + i);
            }
        } else {
            for (uint256 i = 0; i < _amount; i++) {
                _mint(seller, initialSupply + i);
            }
        }
    }

    /**
     * @notice Sets a new base URI for all NFTs
     * @param _newBaseURI New base URI for all NFTs
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;

        emit BaseURIChanged(_newBaseURI);
    }

    /**
     * @notice Sets a new mint account
     * @dev We require that there are no outstanding NFTs to be minted lazily to avoid the new mint account 'stealing' previously lazy minted tokens
     * @param _newMintAccount New mint account
     */
    function setMintAccount(address _newMintAccount) external onlyOwner {
        require(lazyMintedCount == 0, "FoxesV2: pending lazy minted tokens");
        mintAccount = _newMintAccount;

        emit MintAccountChanged(_newMintAccount);
    }

    /**
     * @notice Ends presale mode, removing transfer restrictions from mint account to other accounts
     */
    function finalizePresale() external onlyOwner {
        isPresale = false;

        emit PresaleFinalized();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            tokenId < totalSupply(),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    baseURI,
                    "metadata/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + lazyMintedCount;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (_isLazyMinted(tokenId)) {
            return mintAccount;
        } else {
            return super.ownerOf(tokenId);
        }
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return
            super.balanceOf(owner) +
            (owner == mintAccount ? lazyMintedCount : 0);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Special checks only apply for tokens being transferred from the mintAccount, as it might be a primary sale
        if (from == mintAccount) {
            // If the presale is not finalized, check transfer restrictions
            if (isPresale) {
                uint256 buyerPresaleBuys = presaleBuys[to];

                require(
                    buyerPresaleBuys < presaleBuyLimit,
                    "FoxesV2: presale limit"
                );
                require(
                    presaleWhitelist.isWhitelisted(to),
                    "FoxesV2: not in whitelist"
                );

                presaleBuys[to] = buyerPresaleBuys + 1;
            }

            // A lazy minted token is being transferred, mint it for real now
            if (_isLazyMinted(tokenId)) {
                _mint(from, tokenId);
                lazyMintedCount -= 1;
            }
        }

        super._transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (_isLazyMinted(tokenId)) {
            return
                spender == mintAccount ||
                isApprovedForAll(mintAccount, spender);
        }
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function _isLazyMinted(uint256 tokenId) internal view returns (bool) {
        return !_exists(tokenId) && tokenId < totalSupply();
    }
}