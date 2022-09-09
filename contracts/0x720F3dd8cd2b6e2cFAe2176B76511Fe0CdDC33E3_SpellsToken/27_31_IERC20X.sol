// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20X is IERC20 {
    function totalTokenHeldSupply() external view returns (uint256);

    function balanceOf(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function nonce(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function transfer(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function allowance(
        address tokenOwner,
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function increaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function signedTransferFrom(
        DynamicAddress memory from,
        DynamicAddress memory to,
        uint256 amount,
        uint256 nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event XTransfer(
        address indexed from,
        uint256 fromTokenId,
        address indexed to,
        uint256 toTokenId,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event XApproval(
        address indexed _contract,
        uint256 tokenId,
        address indexed spender,
        uint256 value
    );
}

/// @param _address The address of the entity
/// @param _tokenId The token of the object (optional)
/// @param _useZeroToken Treat tokenId 0 as a token (default: ignore tokenId 0)
struct DynamicAddress {
    address _address;
    uint256 _tokenId;
    bool _useZeroToken;
}

library DynamicAddressLib {
    using Address for address;
    
    function isToken(DynamicAddress memory _address) internal view returns (bool) {
        return (_address._address.isContract() && (_address._tokenId > 0 || _address._useZeroToken));
    }
}