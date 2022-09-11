// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface iAlgocracyCollectionNFT {
    function onERC721Received(address operator, address from, uint256 id, bytes calldata data)
    external returns (bytes4);
}

/// @title Algocracy Collection NFT
/// @author jolan.eth

abstract contract AlgocracyCollectionNFT {
    uint256 supply;
    
    mapping (uint256 => address) owners;
    mapping (address => uint256) balances;
    
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
        return supply;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(
            owner != address(0),
            "AlgocracyCollectionNFT::balanceOf() - owner is address(0)"
        );
        return balances[owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyCollectionNFT::ownerOf() - id do not exist"
        );
        return owners[id];
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyCollectionNFT::getApproved() - id do not exist"
        );
        return approvals[id];
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            to != owner,
            "AlgocracyCollectionNFT::approve() - to is owner"
        );
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyCollectionNFT::approve() - msg.sender is not owner or approved"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(
            operator != msg.sender,
            "AlgocracyCollectionNFT::setApprovalForAll() - msg.sender is operator"
        );
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyCollectionNFT::transferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyCollectionNFT::transferFrom() - msg.sender is not owner or approved"
        );

        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyCollectionNFT::safeTransferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyCollectionNFT::safeTransferFrom() - msg.sender is not owner or approved"
        );

        _safeTransfer(from, to, id, '');
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            exist(id),
            "AlgocracyCollectionNFT::safeTransferFrom() - id do not exist"
        );
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender],
            "AlgocracyCollectionNFT::safeTransferFrom() - msg.sender is not owner or approved"
        );

        _safeTransfer(from, to, id, data);
    }

    function _mint(address to)
    internal {
        balances[to]++;
        owners[supply] = to;
        emit Transfer(address(this), to, supply++);
    }

    function _transfer(address from, address to, uint256 id)
    private {
        require(
            address(0) != to,
            "AlgocracyCollectionNFT::_transferFrom() - to is address(0)"
        );

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _safeTransfer(address from, address to, uint256 id, bytes memory data)
    private {
        _transfer(from, to, id);
        require(
            _checkOnERC721Received(from, to, id, data),
            "AlgocracyCollectionNFT::_safeTransfer() - to is not ERC721 receiver"
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try iAlgocracyCollectionNFT(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == iAlgocracyCollectionNFT(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("AlgocracyCollectionNFT::_checkOnERC721Received() - to is not receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }
}