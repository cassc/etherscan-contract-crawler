// SPDX-License-Identifier: MIT
// solhint-disable reason-string
pragma solidity ^0.8.0;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./IDelegationRegistry.sol";
import "./ILazyPayableClaim.sol";

// Libaries
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

/**
 * @title Lazy Payable Claim
 * @author manifold.xyz
 * @notice Lazy payable claim with optional whitelist ERC721 tokens
 */
abstract contract LazyPayableClaim is ILazyPayableClaim, AdminControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant MAX_UINT_24 = 0xffffff;
    //uint256 internal constant MAX_UINT_32 = 0xffffffff;
    uint256 internal constant MAX_UINT_56 = 0xffffffffffffff;
    //uint256 internal constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address private constant ADDRESS_ZERO = 0x0000000000000000000000000000000000000000;

    EnumerableSet.AddressSet private _proxyAddresses;

    /**
     * @notice This extension is shared, not single-creator. So we must ensure
     * that a claim's initializer is an admin on the creator contract
     * @param creatorContractAddress    the address of the creator contract to check the admin against
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        AdminControl creatorCoreContract = AdminControl(creatorContractAddress);
        require(creatorCoreContract.isAdmin(msg.sender), "Wallet is not an administrator for contract");
        _;
    }

    /**
     * See {ILazyPayableClaim-withdraw}.
     */
    function withdraw(address payable receiver, uint256 amount) external override adminRequired {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to transfer to receiver");
    }

    function _transferFunds(address erc20, uint256 cost, address payable recipient, uint16 mintCount) internal {
        uint256 payableCost;
        if (erc20 != ADDRESS_ZERO) {
            require(IERC20(erc20).transferFrom(msg.sender, recipient, cost*mintCount), "Insufficient funds");
        } else {
            payableCost = cost;
        }

        if (mintCount > 1) {
            payableCost *= mintCount;
        }

        // Check price
        require(msg.value >= payableCost, "Invalid amount");
        if (erc20 == ADDRESS_ZERO && cost != 0) {
            // solhint-disable-next-line
            (bool sent, ) = recipient.call{value: msg.value}("");
            require(sent, "Failed to transfer to receiver");
        }
    }

    function _validateMintTime(uint48 startDate, uint48 endDate) internal view {
        // Check timestamps
        require(
            (startDate <= block.timestamp) &&
            (endDate == 0 || endDate >= block.timestamp),
            "Claim inactive"
        );
    }
}