// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberOrderBook.sol";
import "./interfaces/CloberOrderNFT.sol";
import "./Errors.sol";
import "./utils/OrderKeyUtils.sol";

contract OrderNFT is ERC165, CloberOrderNFT {
    using Address for address;
    using Strings for uint256;
    using OrderKeyUtils for OrderKey;

    CloberMarketFactory private immutable _factory;
    address private immutable _canceler;

    string public override name;
    string public override symbol;
    string public override baseURI;
    address public override market;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(address factory, address canceler) {
        _factory = CloberMarketFactory(factory);
        _canceler = canceler;
    }

    function init(
        string memory name_,
        string memory symbol_,
        address market_
    ) external {
        if (market != address(0)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        if (market_ == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        name = name_;
        symbol = symbol_;
        market = market_;
    }

    modifier onlyMarket() {
        if (msg.sender != market) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _;
    }

    modifier onlyExists(uint256 tokenId) {
        if (_getOrderOwner(tokenId) == address(0)) {
            revert Errors.CloberError(Errors.INVALID_ID);
        }
        _;
    }

    function changeBaseURI(string memory newBaseURI) external {
        if (_getHost() != msg.sender) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address user) public view returns (uint256) {
        if (user == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        uint256 balance = _balances[user];
        return balance > 0 ? balance - 1 : balance;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _getOrderOwner(tokenId);
        if (tokenOwner == address(0)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        return tokenOwner;
    }

    function tokenURI(uint256 tokenId) public view onlyExists(tokenId) returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (to == tokenOwner) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        _approve(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view onlyExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (msg.sender == operator) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.CloberError(Errors.ACCESS);
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert Errors.CloberError(Errors.NOT_IMPLEMENTED_INTERFACE);
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || isApprovedForAll(tokenOwner, spender) || getApproved(tokenId) == spender);
    }

    function _increaseBalance(address to) internal {
        _balances[to] += _balances[to] > 0 ? 1 : 2;
    }

    function _decreaseBalance(address to) internal {
        _balances[to] -= 1;
    }

    function onMint(address to, uint256 tokenId) external onlyMarket {
        if (to == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }

        _increaseBalance(to);

        emit Transfer(address(0), to, tokenId);
    }

    function onBurn(uint256 tokenId) external onlyMarket {
        address tokenOwner = ownerOf(tokenId);

        // Clear approvals
        _approve(tokenOwner, address(0), tokenId);

        _decreaseBalance(tokenOwner);

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external {
        if (msg.sender != _canceler) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        OrderKey[] memory orderKeys = new OrderKey[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (!_isApprovedOrOwner(from, tokenIds[i])) {
                revert Errors.CloberError(Errors.ACCESS);
            }
            orderKeys[i] = decodeId(tokenIds[i]);
        }
        CloberOrderBook(market).cancel(receiver, orderKeys);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (ownerOf(tokenId) != from) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        if (to == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }

        // Clear approvals from the previous owner
        _approve(from, address(0), tokenId);

        _decreaseBalance(from);
        _increaseBalance(to);
        CloberOrderBook(market).changeOrderOwner(decodeId(tokenId), to);

        emit Transfer(from, to, tokenId);
    }

    function _approve(
        address tokenOwner,
        address to,
        uint256 tokenId
    ) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert Errors.CloberError(Errors.NOT_IMPLEMENTED_INTERFACE);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function decodeId(uint256 id) public pure returns (OrderKey memory) {
        return OrderKeyUtils.decode(id);
    }

    function encodeId(OrderKey memory orderKey) external pure returns (uint256 id) {
        return orderKey.encode();
    }

    function owner() external view returns (address) {
        return _getHost();
    }

    function _getHost() internal view returns (address) {
        return _factory.getMarketHost(market);
    }

    function _getOrderOwner(uint256 tokenId) internal view returns (address) {
        return CloberOrderBook(market).getOrder(decodeId(tokenId)).owner;
    }
}