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
import "../../api/config/IGlobalConfig.sol";

/// @title PaymentsNotary
/// @notice This smart contract acts as a notary for payments. It is responsible for keeping track of payments made by
///         subscribers by emitting an event when a payment happens. No funds are stored on this contract.
contract PaymentsNotary is Initializable, ContextUpgradeable, AccessControlUpgradeable, IPaymentNotaryV2 {
    address private constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    IGlobalConfigV1 private _aspenConfig;

    function __PaymentsNotary_init(address _globalConfig) internal onlyInitializing {
        __PaymentsNotary_init_unchained(_globalConfig);
    }

    function __PaymentsNotary_init_unchained(address _globalConfig) internal onlyInitializing {
        if (_globalConfig == address(0)) revert IPaymentsErrorsV1.InvalidGlobalConfigAddress();
        _aspenConfig = IGlobalConfigV1(_globalConfig);
    }

    /// @dev Allows anyone to pay a nonzero amount of any token (native and ERC20) to any receiver address.
    ///     Certain checks are in place and if all is good, it emits a PaymentSent event.
    /// @param _namespace The namespace related with the payment.
    /// @param _receiver The address that will receive the payment.
    /// @param _paymentReference An (ideally) unique reference for this payment.
    /// @param _currency The currency of the payment.
    /// @param _paymentAmount The amount of the payment.
    /// @param _feeAmount The fee amount to be paid to Aspen platformn.
    function pay(
        string calldata _namespace,
        address _receiver,
        bytes32 _paymentReference,
        address _currency,
        uint256 _paymentAmount,
        uint256 _feeAmount,
        uint256 _deadline
    ) external payable virtual {
        if (_deadline < block.timestamp) revert IPaymentsErrorsV1.PaymentDeadlineExpired();
        if (_receiver == address(0) || _receiver == BURN_ADDRESS || _receiver == CurrencyTransferLib.NATIVE_TOKEN)
            revert IPaymentsErrorsV1.InvalidReceiverAddress(_receiver);
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == _paymentAmount))
            revert IPaymentsErrorsV0.InvalidPaymentAmount();
        address feeReceiver = _aspenConfig.getPlatformFeeReceiver();

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), feeReceiver, _feeAmount);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), _receiver, _paymentAmount - _feeAmount);

        emit PaymentSent(
            _namespace,
            _msgSender(),
            _receiver,
            _paymentReference,
            _currency,
            _paymentAmount,
            _feeAmount,
            _deadline
        );
    }

    function getFeeReceiver() public view returns (address feeReceiver) {
        feeReceiver = _aspenConfig.getPlatformFeeReceiver();
    }
}