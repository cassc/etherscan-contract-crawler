// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC721A, IERC721A} from "ERC721A/ERC721A.sol";
import {IERC2981, ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./IERC4906.sol";
import {ERC721RestrictApprove} from "./CAL/ERC721RestrictApprove.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";

contract SpaceCrocos is
    IERC4906,
    AccessControl,
    ERC2981,
    OperatorFilterer,
    ERC721RestrictApprove
{
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant MAX_SUPPLY = 6000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public operatorFilteringEnabled = true;
    string private baseURI =
        "ar://0zrdKZJlZRdZz5cW28QFah35ze-zkhDF82ew2Q8-bCA/";

    mapping(uint256 => string) private metadataURI;

    constructor(
        address _CALAddress
    ) ERC721RestrictApprove("SpaceCrocos", "CROCOS") {
        _setDefaultRoyalty(0x8C4da4F8a860dd2d1F79c1a9370D6400b1aFc452, 1000);
        _registerForOperatorFiltering();
        _setCAL(_CALAddress);
        CALLevel = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION)
                );
        } else {
            return metadataURI[tokenId];
        }
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function batchMintTo(
        address[] memory list,
        uint256[] memory amount
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < list.length; i++) {
            _mint(list[i], amount[i]);
        }
    }

    function mint(
        address _address,
        uint256 _count
    ) external onlyRole(MINTER_ROLE) {
        _mint(_address, _count);
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
    }

    function withdraw(
        address _to
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721RestrictApprove, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721RestrictApprove.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function addLocalContractAllowList(
        address transferer
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(
        address transferer
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function setCALLevel(
        uint256 level
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setCAL(calAddress);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}