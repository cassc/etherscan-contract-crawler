// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Sale/IBlxPresale.sol";
import "../interfaces/Sale/IIBCO.sol";

/* provide 'batched' tx for permit then sale, mainly designed for metatx(like biconomy forwarder) usage where
 * only 2 signature(permit and biconomy call to this) is needed instead of 3 (permit, bicononmy call to presale/ibco, biconomy call to this)
 * the later 3 sig mode can be done via MultiCall(third one is biconomy call to Multicall)
 */
contract TokenSale is ERC2771Context, Ownable {
    address public usdcAddress;
    address public presaleAddress;
    address public ibcoAddress;

    constructor (address trustedForwarder, address _usdcAddress) ERC2771Context(trustedForwarder) {
        require(trustedForwarder != address(0), "TOKEN:FORWARDER_ADDRESS_ZERO");
        require(_usdcAddress != address(0), "TOKEN:USDC_ADDRESS_ZERO");
        usdcAddress = _usdcAddress;
    }

    function setAddresses(address _presaleAddress, address _ibcoAddress) external onlyOwner {
        require(_presaleAddress != address(0), "TOKEN:PRESALE_ADDRESS_ZERO");
        require(_ibcoAddress != address(0), "TOKEN:IBCO_ADDRESS_ZERO");
        presaleAddress = _presaleAddress;
        ibcoAddress = _ibcoAddress;
    }

    /// @dev enterPresale with optional USDC permit before entering actual sale
    /// @param amount amount in USDC
    /// @param referrer optional referrer(passthrough)
    /// @param permit optional USDC permit calldata
    function enterPresale(uint amount, address referrer, bytes calldata permit, bytes calldata forwarderPermit) external {
        if (permit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(permit);
            _verifyCallResult(success, result, "USDC sale permit failed");
        }
        if (forwarderPermit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(forwarderPermit);
            _verifyCallResult(success, result, "USDC forward permit failed");
        }
        IBlxPresale(presaleAddress).purchase(amount, referrer, _msgSender(), isTrustedForwarder(msg.sender));
    }

    /// @dev enterIBCO with optional USDC permit before entering actual sale
    /// @param blxAmount amount in BLX
    /// @param referrer optional referrer(passthrough)
    /// @param permit optional USDC permit calldata
    function enterIbco(uint blxAmount, uint maxUsdc, address referrer, bytes calldata permit, bytes calldata forwarderPermit) external {
        if (permit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(permit);
            _verifyCallResult(success, result, "USDC sale permit failed");
        }
        if (forwarderPermit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(forwarderPermit);
            _verifyCallResult(success, result, "USDC forward permit failed");
        }
        IIBCO(ibcoAddress).purchase(blxAmount, maxUsdc, referrer, _msgSender(),isTrustedForwarder(msg.sender));
    }

    /// @dev pick ERC2771Context over Ownable
    function _msgSender() internal view override(Context, ERC2771Context)
        returns (address sender) {
        sender = ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context)
        returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    /**
     * @dev verifies the call result and bubbles up revert reason for failed calls
     *
     * @param success : outcome of forwarded call
     * @param returndata : returned data from the frowarded call
     * @param errorMessage : fallback error message to show 
     */
     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure {
        if (!success) {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}