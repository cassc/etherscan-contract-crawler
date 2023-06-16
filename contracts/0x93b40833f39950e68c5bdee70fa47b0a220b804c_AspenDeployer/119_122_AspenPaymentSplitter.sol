// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../generated/impl/BaseAspenPaymentSplitterV2.sol";
import "../api/errors/ISplitPaymentErrors.sol";

contract AspenPaymentSplitter is PaymentSplitterUpgradeable, BaseAspenPaymentSplitterV2 {
    mapping(address => bool) private payeeExists;

    function initialize(address[] memory _payees, uint256[] memory _shares) external initializer {
        if (_payees.length != _shares.length)
            revert ISplitPaymentErrorsV0.PayeeSharesArrayMismatch(_payees.length, _shares.length);
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares = totalShares + _shares[i];

            if (payeeExists[_payees[i]] == true) revert ISplitPaymentErrorsV0.PayeeAlreadyExists(_payees[i]);
            payeeExists[_payees[i]] = true;
        }

        if (totalShares != 10000) revert ISplitPaymentErrorsV0.InvalidTotalShares(totalShares);

        __PaymentSplitter_init(_payees, _shares);
    }

    /// ==================================
    /// ========== Relase logic ==========
    /// ==================================
    /// @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
    ///     total shares and their previous withdrawals.
    /// @param account - The address of the payee to release funds to.
    function releasePayment(address payable account) external override {
        release(account);
    }

    /// @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
    ///     percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
    ///     contract.
    /// @param token - the address of an IERC20 contract.
    /// @param account - The address of the payee to release funds to.
    function releasePayment(IERC20Upgradeable token, address account) external override {
        release(token, account);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================

    /// @dev Getter for the total shares held by payees.
    function getTotalShares() external view override returns (uint256) {
        return totalShares();
    }

    /// @dev Getter for the amount of shares held by an account.
    function getShares(address account) external view override returns (uint256) {
        return shares(account);
    }

    /// @dev Getter for the address of the payee number `index`.
    function getPayee(uint256 index) external view override returns (address) {
        return payee(index);
    }

    /// @dev Getter for the total amount of Ether already released.
    function getTotalReleased() external view override returns (uint256) {
        return totalReleased();
    }

    /// @dev Getter for the total amount of `token` already released.
    /// @param token - the address of an IERC20 contract.
    function getTotalReleased(IERC20Upgradeable token) external view override returns (uint256) {
        return totalReleased(token);
    }

    /// @dev Getter for the amount of Ether already released to a payee.
    /// @param account - The address of the payee to check the funds that can be released to.
    function getReleased(address account) external view override returns (uint256) {
        return released(account);
    }

    /// @dev Getter for the total amount of `token` already released.
    /// @param token - the address of an IERC20 contract.
    /// @param account - The address of the payee to check the funds that can be released to.
    function getReleased(IERC20Upgradeable token, address account) external view override returns (uint256) {
        return released(token, account);
    }

    /// @dev Getter for the total amount of Ether that can be released for an account.
    /// @param account - The address of the payee to check the funds that can be released to.
    function getPendingPayment(address account) external view override returns (uint256) {
        if (shares(account) == 0) return 0;
        uint256 totalReceived = address(this).balance + totalReleased();

        return _getPendingPayment(account, totalReceived, released(account));
    }

    /// @dev Getter for the total amount of `token` that can be released for an account.
    /// @param token - the address of an IERC20 contract.
    /// @param account - The address of the payee to check the funds that can be released to.
    function getPendingPayment(IERC20Upgradeable token, address account) external view override returns (uint256) {
        if (shares(account) == 0) return 0;
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);

        return _getPendingPayment(account, totalReceived, released(token, account));
    }

    /// @dev internal logic for computing the pending payment of an `account` given the token historical balances and
    ///     already released amounts.
    ///     private logic taken from _pendingPayment() function from openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol
    function _getPendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) internal view returns (uint256) {
        return (totalReceived * shares(account)) / totalShares() - alreadyReleased;
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}