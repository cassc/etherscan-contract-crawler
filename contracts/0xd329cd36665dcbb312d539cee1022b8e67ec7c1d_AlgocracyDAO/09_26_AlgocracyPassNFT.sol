// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface iAlgocracyPassNFT {
    function onERC721Received(address operator, address from, uint256 id, bytes calldata data)
    external returns (bytes4);
}

/// @title Algocracy Pass NFT
/// @author jolan.eth

abstract contract AlgocracyPassNFT {
    uint256 supply;
    
    mapping (address => uint256) owned;
    mapping (uint256 => address) owners;
    
    mapping (uint256 => address) approvals;
    mapping (address => mapping(address => bool)) operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function exist(uint256 id)
    public view returns (bool) {
        return owners[id] != address(0);
    }

    function totalSupply()
    public view returns (uint256) {
        return supply == 0 ? 0 : supply - 1;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(
            owner != address(0),
            "AlgocracyPassNFT::balanceOf() - owner is address(0)"
        );
        return owned[owner] > 0 ? 1 : 0;
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyPassNFT::ownerOf() - id do not exist"
        );
        return owners[id];
    }

    function ownedBy(address owner)
    public view returns (uint256) {
        uint256 id = owned[owner];
        require(
            exist(id),
            "AlgocracyPassNFT::ownedBy() - id do not exist"
        );
        return id;
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyPassNFT::getApproved() - id do not exist"
        );
        return approvals[id];
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            to != owner,
            "AlgocracyPassNFT::approve() - to is owner"
        );
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyPassNFT::approve() - msg.sender is not owner or approved"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(
            operator != msg.sender,
            "AlgocracyPassNFT::setApprovalForAll() - msg.sender is operator"
        );
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyPassNFT::transferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyPassNFT::transferFrom() - msg.sender is not owner or approved"
        );

        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyPassNFT::safeTransferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyPassNFT::safeTransferFrom() - msg.sender is not owner or approved"
        );

        _safeTransfer(from, to, id, '');
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyPassNFT::safeTransferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyPassNFT::safeTransferFrom() - msg.sender is not owner or approved"
        );

        _safeTransfer(from, to, id, data);
    }

    function _mint(address to)
    internal {
        require(
            balanceOf(to) == 0,
            "AlgocracyPassNFT::_mint() - balance of to is not 0"
        );

        if (supply == 0) supply = 1;        
        owned[to] = supply;
        owners[supply] = to;
        emit Transfer(address(this), to, supply++);
    }

    function _transfer(address from, address to, uint256 id)
    private {
        require(
            address(0) != to,
            "AlgocracyPassNFT::_transferFrom() - to is address(0)"
        );

        require(
            balanceOf(to) == 0,
            "AlgocracyPassNFT::_mint() - balance of to is not 0"
        );

        approve(address(0), id);
        delete owned[from];
        owned[to] = id;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _safeTransfer(address from, address to, uint256 id, bytes memory data)
    private {
        _transfer(from, to, id);
        require(
            _checkOnERC721Received(from, to, id, data),
            "AlgocracyPassNFT::_safeTransfer() - to is not ERC721 receiver"
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try iAlgocracyPassNFT(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == iAlgocracyPassNFT(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }

}