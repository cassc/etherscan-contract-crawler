// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

abstract contract ERC721Base is IERC165, IERC721 {
    using Address for address;

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    uint256 internal constant OPERATOR_FLAG = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant NOT_OPERATOR_FLAG = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    mapping(uint256 => uint256) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    function name() public pure virtual returns (string memory) {
        revert("NOT_IMPLEMENTED");
    }

    /// @notice Approve an operator to transfer a specific token on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) external override {
        (address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "UNAUTHORIZED_APPROVAL");
        _approveFor(owner, blockNumber, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        if (msg.sender != from) {
            require(
                (operatorEnabled && _operators[id] == msg.sender) || isApprovedForAll(from, msg.sender),
                "UNAUTHORIZED_TRANSFER"
            );
        }
        _transferFrom(from, to, id);
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The send of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return balance The number of tokens owned by the address.
    function balanceOf(address owner) public view override returns (uint256 balance) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        balance = _balances[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
    }

    /// @notice Get the owner of a token and the blockNumber of the last transfer, useful to voting mechanism.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    /// @return blockNumber The blocknumber at which the last transfer of that id happened.
    function ownerAndLastTransferBlockNumberOf(uint256 id) internal view returns (address owner, uint256 blockNumber) {
        return _ownerAndBlockNumberOf(id);
    }

    struct OwnerData {
        address owner;
        uint256 lastTransferBlockNumber;
    }

    /// @notice Get the list of owner of a token and the blockNumber of its last transfer, useful to voting mechanism.
    /// @param ids The list of token ids to check.
    /// @return ownersData The list of (owner, lastTransferBlockNumber) for each ids given as input.
    function ownerAndLastTransferBlockNumberList(uint256[] calldata ids)
        external
        view
        returns (OwnerData[] memory ownersData)
    {
        ownersData = new OwnerData[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 data = _owners[ids[i]];
            ownersData[i].owner = address(uint160(data));
            ownersData[i].lastTransferBlockNumber = (data >> 160) & 0xFFFFFFFFFFFFFFFFFFFFFF;
        }
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool isOperator) {
        return _operatorsForAll[owner][operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        if (msg.sender != from) {
            require(
                (operatorEnabled && _operators[id] == msg.sender) || isApprovedForAll(from, msg.sender),
                "UNAUTHORIZED_TRANSFER"
            );
        }
        _safeTransferFrom(from, to, id, data);
    }

    /// @notice Check if the contract supports an interface.
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        /// 0x01ffc9a7 is ERC165.
        /// 0x80ac58cd is ERC721
        /// 0x5b5e139f is for ERC721 metadata
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal {
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(msg.sender, from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {}

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _beforeTokenTransfer(from, to, id);
        unchecked {
            _balances[to]++;
            if (from != address(0)) {
                _balances[from]--;
            }
        }
        _owners[id] = (block.number << 160) | uint256(uint160(to));
        emit Transfer(from, to, id);
    }

    /// @dev See approve.
    function _approveFor(
        address owner,
        uint256 blockNumber,
        address operator,
        uint256 id
    ) internal {
        if (operator == address(0)) {
            _owners[id] = (blockNumber << 160) | uint256(uint160(owner));
        } else {
            _owners[id] = OPERATOR_FLAG | (blockNumber << 160) | uint256(uint160(owner));
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param id The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721Receiver(to).onERC721Received(operator, from, id, _data);
        return (retval == ERC721_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view returns (address owner) {
        return address(uint160(_owners[id]));
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _owners[id];
        owner = address(uint160(data));
        operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
    }

    // @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return blockNumber the blockNumber at which the owner became the owner (last transfer).
    function _ownerAndBlockNumberOf(uint256 id) internal view returns (address owner, uint256 blockNumber) {
        uint256 data = _owners[id];
        owner = address(uint160(data));
        blockNumber = (data >> 160) & 0xFFFFFFFFFFFFFFFFFFFFFF;
    }

    // from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed.
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract.
    /// @return results The results from each of the calls passed in via data.
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}