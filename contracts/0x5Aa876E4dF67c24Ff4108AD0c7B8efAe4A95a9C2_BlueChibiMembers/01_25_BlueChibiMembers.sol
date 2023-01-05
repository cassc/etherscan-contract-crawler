// SPDX-License-Identifier: MIT

//////////////////////////////////////////////////////////////////////
//                                                                  //
//   ██████╗░██╗░░░░░██╗░░░██╗███████╗░█████╗░██╗░░██╗██╗██████╗░   //
//   ██╔══██╗██║░░░░░██║░░░██║██╔════╝██╔══██╗██║░░██║██║██╔══██╗   //
//   ██████╦╝██║░░░░░██║░░░██║█████╗░░██║░░╚═╝███████║██║██████╔╝   //
//   ██╔══██╗██║░░░░░██║░░░██║██╔══╝░░██║░░██╗██╔══██║██║██╔═══╝░   //
//   ██████╦╝███████╗╚██████╔╝███████╗╚█████╔╝██║░░██║██║██║░░░░░   //
//   ╚═════╝░╚══════╝░╚═════╝░╚══════╝░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░   //
//                                                                  //
//          bluechibimembers contract by Charactor DAO              //
//                                                                  //
//////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";

contract BlueChibiMembers is
    Ownable,
    AccessControl,
    DefaultOperatorFilterer,
    ERC721RestrictApprove
{
    mapping(uint256 => string) private _tokenURIs;
    bytes32 public constant ADMIN = keccak256("ADMIN");

    constructor() ERC721Psi("bluechibimembers", "BCM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _grantRole(ADMIN, 0x1b632c9a883DF07A18d4b2813840E029bEceFf6D);
        _grantRole(ADMIN, 0x480d565527086DC3dc2262648194E1e9cCAB70EF);
        _grantRole(ADMIN, 0xf3CfAD477A0f8443b0b6E81BF7A4a1fF7B69D46f);
        _grantRole(ADMIN, 0x0dAE5FcaD0DF8E5C029D76927582DFBdFd7eeC79);
    }

    function safeMint(address to) external onlyRole(ADMIN) {
        require(to != address(0), "address shouldn't be 0");
        //start from tokenId = 0
        _safeMint(to, 1);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyRole(ADMIN) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    ////////// The following functions are overrides required by Solidity.//////////

    //Copy Pasta from ERC721URIStorage
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC721RestrictApprove)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId);
            //super.supportsInterface(interfaceId);
    }

    ////////// OVERRIDES DefaultOperatorFilterer functions //////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ////////// OVERRIDES ERC721RestrictApprove functions //////////

    function addLocalContractAllowList(
        address transferer
    ) external override onlyRole(ADMIN) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(
        address transferer
    ) external override onlyRole(ADMIN) {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        override
        returns (address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) external override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }
}