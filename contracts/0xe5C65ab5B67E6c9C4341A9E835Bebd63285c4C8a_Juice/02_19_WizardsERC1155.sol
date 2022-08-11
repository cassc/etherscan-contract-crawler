// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../royalties/ERC2981ContractWideRoyalties.sol";
import "../utils/ERC1155Metadata.sol";
import "../utils/Administration.sol";

error MaxSupplyUnchangeable();
error MaxSupplyReached();
error TransferCallerNotOwnerNorApproved();

contract WizardsERC1155 is
    ERC1155,
    ERC1155Metadata,
    ERC2981ContractWideRoyalties,
    Administration
{
    string private _name;
    string private _symbol;

    mapping(uint256 => uint256) private _maxSupply;
    mapping(uint256 => uint256) internal _issuanceCounter;
    mapping(uint256 => uint256) internal _burnCounter;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyRecipient,
        uint24 royaltyValue,
        address owner
    ) ERC1155(baseTokenURI) Administration(owner) {
        _symbol = symbol_;
        _name = name_;

        _setContractURI(contractURI);
        _setRoyalties(royaltyRecipient, royaltyValue);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalMinted(uint256 id) public view returns (uint256) {
        return _issuanceCounter[id];
    }

    function totalBurned(uint256 id) public view returns (uint256) {
        return _burnCounter[id];
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        unchecked {
            return _issuanceCounter[id] - _burnCounter[id];
        }
    }

    function maxSupply(uint256 id) public view returns (uint256) {
        return _maxSupply[id];
    }

    function setMaxSupply(uint256 id, uint256 maxSupply_) public isAdmin {
        if (_maxSupply[id] > 0) revert MaxSupplyUnchangeable();
        _maxSupply[id] = maxSupply_;
    }

    function setRoyalties(address recipient, uint24 value) external isAdmin {
        _setRoyalties(recipient, value);
    }

    function setContractURI(string memory contractURI) external isAdmin {
        _setContractURI(contractURI);
    }

    function setBaseURI(string memory uri_) external isAdmin {
        _setURI(uri_);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        external
        isAdmin
    {
        _setTokenURI(tokenId, tokenURI);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        bool isApprovedOrOwner = (_msgSender() == account ||
            isApprovedForAll(account, _msgSender()));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        unchecked {
            _burnCounter[id] = _burnCounter[id] + value;
        }

        _burn(account, id, value);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external isMinter whenNotPaused {
        _mint(to, id, amount, "");
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        unchecked {
            _issuanceCounter[id] = _issuanceCounter[id] + amount;
            if (_maxSupply[id] > 0 && totalMinted(id) >= _maxSupply[id]) {
                revert MaxSupplyReached();
            }
        }
        super._mint(account, id, amount, data);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override(ERC1155, ERC1155Metadata)
        returns (string memory)
    {
        return ERC1155Metadata.uri(id);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base, Administration)
        returns (bool)
    {
        return
            interfaceId == type(ERC1155Metadata).interfaceId ||
            interfaceId == type(ERC2981Base).interfaceId ||
            interfaceId == type(ERC2981ContractWideRoyalties).interfaceId ||
            interfaceId == type(Administration).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}