// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface iERC1155 {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4);
}

// author: jolan.eth
abstract contract ERC1155 {
    mapping(uint256 => uint256) supply;
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorApprovals;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return supply[id];
    }

    function balanceOf(address owner, uint256 id)
        public
        view
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC1155::balanceOf() - owner is address(0)"
        );
        return balances[id][owner];
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(
            owners.length == ids.length,
            "ERC1155::balanceOfBatch() - owners length don't match ids length"
        );

        uint256[] memory batchBalances = new uint256[](owners.length);

        uint256 i = 0;
        while (i < owners.length)
            batchBalances[i] = balanceOf(owners[i], ids[i++]);

        return batchBalances;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155::safeTransferFrom() - msg.sender is not owner or approved"
        );

        uint256 fromBalance = balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155::safeTransferFrom() - fromBalance is lower than amount"
        );

        unchecked {
            balances[id][from] = fromBalance - amount;
        }

        balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155::safeBatchTransferFrom() - msg.sender is not owner or approved"
        );

        require(
            ids.length == amounts.length,
            "ERC1155::safeBatchTransferFrom() - ids.length don't match amounts.length"
        );

        require(
            to != address(0),
            "ERC1155::safeBatchTransferFrom() - to is address(0)"
        );

        address operator = msg.sender;

        uint256 i = 0;
        while (i < ids.length) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155::safeBatchTransferFrom() - balance is lower than amount"
            );
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
            balances[id][to] += amount;
            ++i;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function safeBatchTransferFromInternal(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(
            ids.length == amounts.length,
            "ERC1155::safeBatchTransferFrom() - ids.length don't match amounts.length"
        );

        require(
            to != address(0),
            "ERC1155::safeBatchTransferFrom() - to is address(0)"
        );

        address operator = address(this);

        uint256 i = 0;
        while (i < ids.length) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155::safeBatchTransferFrom() - balance is lower than amount"
            );
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
            balances[id][to] += amount;
            ++i;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, "error owner");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155::_mint() - to is address(0)");

        supply[id]++;
        balances[id][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try
                iERC1155(to).onERC1155Received(operator, from, id, amount, data)
            returns (bytes4 response) {
                if (response != iERC1155.onERC1155Received.selector) {
                    revert(
                        "ERC1155::doSafeTransferAcceptanceCheck() - error receiver"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155::doSafeTransferAcceptanceCheck() - error receiver"
                );
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try
                iERC1155(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (response != iERC1155.onERC1155BatchReceived.selector) {
                    revert(
                        "ERC1155::doSafeTransferAcceptanceCheck() - error receiver"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155::doSafeTransferAcceptanceCheck() - error receiver"
                );
            }
        }
    }
}
