//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interface/ITransferProxy.sol";

contract TransferProxy is AccessControl, ITransferProxy, Pausable {
    event operatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public owner;
    address public operator;

    constructor() {
        owner = msg.sender;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("OPERATOR_ROLE", operator);
    }

    function changeOperator(address _operator)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            _operator != address(0),
            "Operator: new operator is the zero address"
        );
        _revokeRole("OPERATOR_ROLE", operator);
        operator = _operator;
        _setupRole("OPERATOR_ROLE", operator);
        emit operatorChanged(address(0), operator);
        return true;
    }

    /** change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

    function pause() external onlyRole("OPERATOR_ROLE") {
        _pause();
    }

    function unpause() external onlyRole("OPERATOR_ROLE") {
        _unpause();
    }

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyRole("OPERATOR_ROLE") {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override onlyRole("OPERATOR_ROLE") {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }

    function mintAndSafe1155Transfer(
        ILazyMint token,
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        uint256 qty
    ) external override onlyRole("OPERATOR_ROLE")  {
        token.mintAndTransfer(from, to, _tokenURI, _royaltyFee, supply, qty);
    }

    function mintAndSafe721Transfer(
        ILazyMint token,
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external override onlyRole("OPERATOR_ROLE") {
        token.mintAndTransfer(from, to, _tokenURI, _royaltyFee);
    }

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external override onlyRole("OPERATOR_ROLE") {
        require(
            token.transferFrom(from, to, value),
            "failure while transferring"
        );
    }
}