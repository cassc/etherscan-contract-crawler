// SPDX-License-Identifier: Apache 2.0

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

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../../drop/lib/CurrencyTransferLib.sol";
import "../../api/errors/IPaymentsErrors.sol";
import "../../api/payments/IPaymentNotary.sol";

/// @title PaymentsNotary
/// @notice This smart contract acts as a notary for payments. It is responsible for keeping track of payments made by
///         subscribers by emitting an event when a payment happens. No funds are stored on this contract.
contract PaymentsNotary is Initializable, ContextUpgradeable, AccessControlUpgradeable, IPaymentNotaryV1 {
    /// @dev Max basis points (bps) in Aspen system.
    uint256 public constant MAX_BPS = 10_000;
    uint256 private __feeBps;
    address private __feeReceiver;

    modifier validFeeDetails(address _feeReceiver, uint256 _feeBPS) {
        if (_feeReceiver == address(0)) revert IPaymentsErrorsV0.InvalidFeeReceiver();
        if (_feeBPS == 0) revert IPaymentsErrorsV0.InvalidFeeBps();
        _;
    }

    function __PaymentsNotary_init(address _feeReceiver, uint256 _feeBPS) internal validFeeDetails(_feeReceiver, _feeBPS) onlyInitializing {
        __PaymentsNotary_init_unchained(_feeReceiver, _feeBPS);
    }

    function __PaymentsNotary_init_unchained(address _feeReceiver, uint256 _feeBPS) internal validFeeDetails(_feeReceiver, _feeBPS) onlyInitializing {
        __feeReceiver = _feeReceiver;
        __feeBps = _feeBPS;
    }

    /// @dev Allows anyone to pay a nonzero amount of any token (native and ERC20) to any receiver address.
    ///     Fee is calulated using feeAmount = (_paymentAmount * feeBps) / MAX_BPS
    ///     Certain checks are in place and if all is good, it emits a PaymentSent event.
    /// @param _namespace The namespace related with the payment.
    /// @param _receiver The address that will receive the payment.
    /// @param _paymentReference An (ideally) unique reference for this payment.
    /// @param _currency The currency of the payment.
    /// @param _paymentAmount The amount of the payment.
    function pay(
        string calldata _namespace,
        address _receiver,
        bytes32 _paymentReference,
        address _currency,
        uint256 _paymentAmount
    ) external virtual payable {
        if (_paymentAmount == 0) revert IPaymentsErrorsV0.ZeroPaymentAmount();
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == _paymentAmount)) revert IPaymentsErrorsV0.InvalidPaymentAmount();
        uint256 feeAmount = (_paymentAmount * __feeBps) / MAX_BPS;

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), __feeReceiver, feeAmount);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), _receiver, _paymentAmount - feeAmount);

        emit PaymentSent(_namespace, _msgSender(), _receiver, _paymentReference, _currency, _paymentAmount);
    }

    /// @dev This functions updates the deployment fee and fee receiver address.
    /// @param _newFeeReceiver The new fee receiver address
    /// @param _newfeeBps The new fee BPS
    function updateFeeDetails( address _newFeeReceiver, uint256 _newfeeBps)
        public
        validFeeDetails(_newFeeReceiver, _newfeeBps)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        __feeReceiver = payable(_newFeeReceiver);
        __feeBps = _newfeeBps;
    }

    function getFeeDetails() public view returns (address feeReceiver, uint256 feeBps) {
        feeBps = __feeBps;
        feeReceiver = __feeReceiver;
    }
}