// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITransferProxy.sol";

contract TransferProxy is ITransferProxy {
    event OperatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public operator;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OperatorRole: caller does not have the Operator role");
        _;
    }

    /** change the OperatorRole from contract creator address to trade contractaddress
            @param _operator :trade address 
        */

    function changeOperator(address _operator) external onlyOwner returns (bool) {
        require(_operator != address(0), "Operator: new operator is the zero address");
        emit OperatorChanged(operator, _operator);
        operator = _operator;
        return true;
    }

    /** change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function ownerTransfership(address newOwner) external onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyOperator {
        IERC721Upgradeable(token).safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override onlyOperator {
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external override onlyOperator {
        require(IERC20(token).transferFrom(from, to, value), "failure while transferring");
    }
}