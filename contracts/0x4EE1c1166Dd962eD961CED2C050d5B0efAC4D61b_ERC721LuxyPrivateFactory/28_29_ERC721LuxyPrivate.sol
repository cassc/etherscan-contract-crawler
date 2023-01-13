/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../RoyaltiesV1Luxy.sol";
import "../ERC1271/ERC1271.sol";
import "../ERC2981/IERC2981.sol";

contract ERC721LuxyPrivate is
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    RoyaltiesV1Luxy
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    mapping(address => bool) private approvedMinters;

    // Base URI
    string public baseURI;
    bool public isChangeable;
    uint256 public maxSupply;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721LuxyPrivate_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address[] memory minters_,
        bool isChangeable_,
        uint256 maxSupply_
    ) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        _setInitialMinters(minters_);
        __ERC721Enumerable_init_unchained();
        __Ownable_init_unchained();
        _setBaseURI(baseURI_);
        _setChangeable(isChangeable_);
        _setMaxSupply(maxSupply_);
    }

    function __ERC721LuxyPrivate_init_unchained(string memory baseURI_ ,address[] memory minters_, bool isChangeable_, uint256 maxSupply_)
        internal
        initializer
    {
        _setInitialMinters(minters_);
        _setBaseURI(baseURI_);
        _setChangeable(isChangeable_);
        _setMaxSupply(maxSupply_);
    }

    function mint(
        address payable _recipient,
        string memory _metadata,
        LibPart.Part[] memory _royalties
    ) external returns (uint256) {
        require(
            _isApprovedMinterorOwner(_msgSender()),
            "Sender must be an approved minter or owner"
        );
        uint256 itemId = _tokenIds.current();
        if(maxSupply != 0){
            require(itemId < maxSupply, "ERC721: minting above the total supply");
        }
        _safeMint(_recipient, itemId);
        _setTokenURI(itemId, _metadata);
        _setRoyalties(itemId, _royalties);
        _tokenIds.increment();
        return itemId;
    }

    function setApprovedMinter(address _minter, bool _approved)
        external
        onlyOwner
    {
        approvedMinters[_minter] = _approved;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            _interfaceId == type(RoyaltiesV1Luxy).interfaceId ||
            _interfaceId == type(ERC721URIStorageUpgradeable).interfaceId ||
            _interfaceId == type(ERC721EnumerableUpgradeable).interfaceId ||
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @dev External function to allow base URI changes when necessary.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(isChangeable, "Base URI is not changeable.");
        _setBaseURI(baseURI_);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    /**
     * @dev Internal function to set changeability of BaseURI for NFT drops.
     */
    function _setChangeable(bool isChangeable_) internal virtual {
        isChangeable = isChangeable_;
    }

    function _setMaxSupply(uint256 maxSupply_) internal virtual {
        maxSupply = maxSupply_;
    }

    /**
     * @dev Internal function to set changeability of BaseURI for NFT drops.
     */
    function _setInitialMinters(address[] memory minters) internal virtual {
        //initializing base minters list
        for (uint256 i = 0; i < minters.length; i++) {
            approvedMinters[minters[i]] = true;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. The resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * See {ERC721Upgradeable-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getMaxSupply() public view returns (uint256) {
        require(maxSupply > 0, "There is no MaxSupply for this collection.");
        return maxSupply;
    }

    /**
     * @dev See {ERC721EnumerableUpgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {ERC721URIStorageUpgradeable-_burn}.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedMinterorOwner(address minter)
        internal
        view
        virtual
        returns (bool)
    {
        if (minter == owner()) return true;
        require(minter != address(0));
        return approvedMinters[minter];
    }

    uint256[100] private __gap;
}