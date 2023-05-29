// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../proxy/interface/IContractAllowListProxy.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//tokenURI interface
interface ITokenURI {
    function tokenURI_future(uint256 _tokenId)
        external
        view
        returns (string memory);
}

contract CNPC is
    Ownable,
    RevokableDefaultOperatorFilterer,
    ERC2981,
    ERC721A,
    AccessControl
{
    bytes32 public MINTER = "MINTER";
    bytes32 public BURNER = "BURNER";
    bytes32 public ADMIN = "ADMIN";
    string baseURI;
    string public baseExtension = ".json";
    ITokenURI public tokenuri;
    IContractAllowListProxy public cal;
    uint256 public calLevel = 1;
    address public royaltyAddress = msg.sender; //contract default owner, changable.
    uint96 public royaltyFee = 1000; // 10%, changable.

    constructor() ERC721A("CNP Charm", "CNPC") {
        _setRoleAdmin(MINTER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        grantRole(ADMIN, msg.sender);
        _adminMint();
    }

    function mint(address to, uint256 amount)
        external
        payable
        onlyRole(MINTER)
    {
        _safeMint(to, amount);
    }

    function burn(address holder, uint256[] calldata burnTokenIds)
        external
        payable
        onlyRole(BURNER)
    {
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require(holder == ownerOf(tokenId), "only holder.");
            _burn(tokenId);
        }
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //image and metadata
    function setBaseURI(string memory _newBaseURI) external onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyRole(ADMIN)
    {
        baseExtension = _newBaseExtension;
    }

    //Full on chain
    function setTokenURI(ITokenURI _tokenuri) external onlyRole(ADMIN) {
        tokenuri = _tokenuri;
    }

    //override
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(tokenuri) == address(0)) {
            if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
            return
                bytes(_baseURI()).length != 0
                    ? string(
                        abi.encodePacked(
                            _baseURI(),
                            _toString(tokenId),
                            baseExtension
                        )
                    )
                    : "";
        } else {
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (address(cal) != address(0)) {
            require(
                cal.isAllowed(operator, calLevel) == true,
                "address no list"
            );
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        if (address(cal) != address(0)) {
            require(cal.isAllowed(to, calLevel) == true, "address no list");
        }
        super.approve(to, tokenId);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    //CAL
    function setCalContract(IContractAllowListProxy _cal)
        external
        onlyRole(ADMIN)
    {
        cal = _cal;
    }

    function setCalLevel(uint256 _value) external onlyRole(ADMIN) {
        calLevel = _value;
    }

    //Royalty setting
    function setRoyaltyFee(uint96 _feeNumerator) external onlyRole(ADMIN) {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress)
        external
        onlyRole(ADMIN)
    {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    // AdminMint
    function _adminMint() internal {
        _safeMint(0xBadb0C8a52Eeb022Dad686CC9eB119b4c65dA4B1, 1);
        _safeMint(0xaC85abe26e5D67492BD4D321223c526cAcCD9A1f, 150);
        _safeMint(0x35c31fC8C7e274Bd88D69c8B947EFB9a6C312b92, 250);
        _safeMint(0x4bF43e9F769A2723A0151cf0dB48fbbd47a3fbbb, 150);
        _safeMint(0x0Ed35594FDb513f955cddE0B0B54a12d619d109c, 150);
        _safeMint(0x1fa6096F902220528b42963a84D171e4de67aC85, 150);
        _safeMint(0xf1FaAFA985fdC96513bA4acf72D0b6Bf6903b7Cf, 125);
        _safeMint(0xd3005389DfEfe5CabBa55149cFB9e8017809B0D6, 1525);
    }
}