// SPDX-License-Identifier: Copyright 2022 Shipyard Software
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface ClipperCoveInterface {
  function depositForCoin(address buyToken, uint256 minBuyAmount, address clipperAsset, uint256 depositAmount, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature, bytes32 auxData) payable external returns (uint256 buyAmount);
  function sellTokenForToken(address sellToken, address buyToken, uint256 minBuyAmount, address destinationAddress, bytes32 auxData) external returns (uint256 buyAmount);
  function transmitAndSellTokenForToken(address sellToken, uint256 sellAmount, address buyToken, uint256 minBuyAmount, address destinationAddress, bytes32 auxData) external returns (uint256 buyAmount);
  function clipperFeeBps() external returns (uint256);
}

interface ClipperCommonInterface {
    function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual;
    function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual;
    function depositSingleAsset(address sender, address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external payable virtual;
    function WRAPPER_CONTRACT() external returns(address);
}
interface IDaiLikePermit {
function permit(
  address holder,
  address spender,
  uint256 nonce,
  uint256 expiry,
  bool allowed,
  uint8 v,
  bytes32 r,
  bytes32 s
) external;
}

contract ClipperPermitRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address immutable CLIPPER_COVE;
    address immutable CLIPPER_CORE;

    constructor(address theCove, address _clipper_core){
        CLIPPER_COVE = theCove;
        CLIPPER_CORE = _clipper_core;
    }
    
    function permit_depositForCoin(address buyToken, uint256 minBuyAmount, address clipperAsset, uint256 depositAmount, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature, bytes32 auxData, bytes calldata permit) public nonReentrant {
        safePermit(clipperAsset, permit);
        IERC20(clipperAsset).safeTransferFrom(msg.sender, address(this), depositAmount);
        IERC20(clipperAsset).approve(CLIPPER_COVE, depositAmount);
        uint256 buyAmount = ClipperCoveInterface(CLIPPER_COVE).depositForCoin(buyToken, minBuyAmount, clipperAsset, depositAmount, poolTokens, goodUntil, theSignature, auxData);
        IERC20(buyToken).safeTransfer(msg.sender, buyAmount);
    }

    function permit_swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData, bytes calldata permit) public {
        safePermit(inputToken, permit);
        IERC20(inputToken).safeTransferFrom(msg.sender, CLIPPER_CORE, inputAmount);
        if(outputToken == address(0)){
            ClipperCommonInterface(CLIPPER_CORE).sellTokenForEth(inputToken, inputAmount, outputAmount, goodUntil, destinationAddress, theSignature, auxiliaryData);
        } else {
            ClipperCommonInterface(CLIPPER_CORE).swap(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress, theSignature, auxiliaryData);
        }
    }

    function permit_depositSingleAsset(address sender, address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature, bytes calldata permit) public {
        require(nDays==0, "Vesting period must be 0");
        safePermit(inputToken, permit);
        IERC20(inputToken).safeTransferFrom(msg.sender, CLIPPER_CORE, inputAmount);
        ClipperCommonInterface(CLIPPER_CORE).depositSingleAsset(sender, inputToken, inputAmount, nDays, poolTokens, goodUntil, theSignature);
        IERC20(CLIPPER_CORE).safeTransfer(msg.sender, poolTokens);
    }

    function permit_sellTokenForToken(address sellToken, uint256 sellAmount, address buyToken, uint256 minBuyAmount, address destinationAddress, bytes32 auxData, bytes calldata permit) public nonReentrant returns (uint256 buyAmount) {
        safePermit(sellToken, permit);
        IERC20(sellToken).safeTransferFrom(msg.sender, CLIPPER_COVE, sellAmount);
        buyAmount = ClipperCoveInterface(CLIPPER_COVE).sellTokenForToken(sellToken, buyToken, minBuyAmount, destinationAddress, auxData);
    }

    function safePermit(address token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        } else {
            revert("bad permit length");
        }
        if (!success) {
            revert("permit failed");
        }
    }

    function _makeCalldataCall(
        address token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
        // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

}