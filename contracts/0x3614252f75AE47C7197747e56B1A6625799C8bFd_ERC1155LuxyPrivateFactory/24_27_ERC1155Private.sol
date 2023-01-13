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
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "./ERC1155BaseUri.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../../RoyaltiesV1Luxy.sol";
import "../ERC1271/ERC1271.sol";

contract ERC1155LuxyPrivate is
    OwnableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155BaseURI,
    RoyaltiesV1Luxy
{
    string public name;
    string public symbol;
    bool public isChangeable;
    uint256 public maxSupply;
    mapping(address => bool) private defaultApprovals;
    event DefaultApproval(address indexed operator, bool hasApproval);
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    mapping(address => bool) private approvedMinters;

    function __ERC1155PrivateLuxy_init(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _minters,
        bool _isChangeable,
        uint256 _maxSupply
    ) public initializer {
        name = _name;
        symbol = _symbol;
        __Ownable_init_unchained();
        __ERC1155Burnable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        _setBaseURI(_baseURI);
        _setInitialMinters(_minters);
        _setChangeable(_isChangeable);
        _setMaxSupply(_maxSupply);
    }

    function __ERC1155PrivateLuxy_init_unchained(string memory _baseURI, address[] memory _minters, bool _isChangeable, uint256 _maxSupply)
        internal
        initializer
    {
        _setBaseURI(_baseURI);
        _setInitialMinters(_minters);
        _setChangeable(_isChangeable);
        _setMaxSupply(_maxSupply);
    }

    function _setDefaultApproval(address operator, bool hasApproval) internal {
        defaultApprovals[operator] = hasApproval;
        emit DefaultApproval(operator, hasApproval);
    }

    function setApprovedMinter(address _minter, bool _approved)
        external
        onlyOwner
    {
        approvedMinters[_minter] = _approved;
    }

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

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return
            defaultApprovals[_operator] ||
            super.isApprovedForAll(_owner, _operator);
    }

    function setDefaultApproval(address operator, bool hasApproval)
        external
        onlyOwner
    {
        _setDefaultApproval(operator, hasApproval);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override(ERC1155BaseURI, ERC1155Upgradeable)
        returns (string memory)
    {
        return _tokenURI(id);
    }

    function mint(
        address account,
        uint256 amount,
        LibPart.Part[] memory royalties,
        string memory tokenURI
    ) public {
        require(
            _isApprovedMinterorOwner(_msgSender()),
            "Sender must be an approved minter or owner"
        );
        uint256 id = _tokenIds.current();
        if(maxSupply != 0){
            require(id < maxSupply, "ERC721: minting above the total supply");
        }
        _mint(account, id, amount, "");
        _setRoyalties(id, royalties);
        _setTokenURI(id, tokenURI);
        _tokenIds.increment();
    }

    function transferFrom(
        uint256 id,
        address from,
        address to,
        uint256 amount
    ) public {
        uint256 balance = balanceOf(from, id);
        if (balance != 0) {
            require(balance >= amount, "Insufficient balance");
            super.safeTransferFrom(from, to, id, amount, "");
        }
    }

    function updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) external {
        require(_msgSender() == _from, "not allowed");
        super._updateAccount(_id, _from, _to);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        require(isChangeable, "Base URI is not changeable.");
        _setBaseURI(_baseURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC1155BaseURI, IERC165Upgradeable)
        returns (bool)
    {
        return
            _interfaceId == type(RoyaltiesV1Luxy).interfaceId ||
            _interfaceId == type(ERC1155BaseURI).interfaceId ||
            _interfaceId == type(ERC1155BurnableUpgradeable).interfaceId ||
            _interfaceId == type(OwnableUpgradeable).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function _setMaxSupply(uint256 maxSupply_) internal virtual {
        maxSupply = maxSupply_;
    }

    function getMaxSupply() public view returns (uint256) {
        require(maxSupply > 0, "There is no MaxSupply for this collection.");
        return maxSupply;
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
     * @dev Internal function to set changeability of BaseURI for NFT drops.
     */
    function _setChangeable(bool isChangeable_) internal virtual {
        isChangeable = isChangeable_;
    }

    uint256[100] private __gap;
}