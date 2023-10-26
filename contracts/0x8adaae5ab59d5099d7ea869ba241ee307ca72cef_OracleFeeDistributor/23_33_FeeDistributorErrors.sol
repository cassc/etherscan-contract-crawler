// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../feeDistributorFactory/IFeeDistributorFactory.sol";

/// @notice Should be a FeeDistributorFactory contract
/// @param _passedAddress passed address that does not support IFeeDistributorFactory interface
error FeeDistributor__NotFactory(address _passedAddress);

/// @notice Service address should be a secure P2P address, not zero.
error FeeDistributor__ZeroAddressService();

/// @notice Client address should be different from service address.
/// @param _passedAddress passed client address that equals to the service address
error FeeDistributor__ClientAddressEqualsService(address _passedAddress);

/// @notice Client address should be an actual client address, not zero.
error FeeDistributor__ZeroAddressClient();

/// @notice Client basis points should be >= 0 and <= 10000
/// @param _clientBasisPoints passed incorrect client basis points
error FeeDistributor__InvalidClientBasisPoints(uint96 _clientBasisPoints);

/// @notice Referrer basis points should be > 0 if the referrer exists
error FeeDistributor__ZeroReferrerBasisPointsForNonZeroReferrer();

/// @notice The sum of (Client basis points + Referral basis points) should be >= 0 and <= 10000
/// @param _clientBasisPoints passed client basis points
/// @param _referralBasisPoints passed referral basis points
error FeeDistributor__ClientPlusReferralBasisPointsExceed10000(uint96 _clientBasisPoints, uint96 _referralBasisPoints);

/// @notice Referrer address should be different from service address.
/// @param _passedAddress passed referrer address that equals to the service address
error FeeDistributor__ReferrerAddressEqualsService(address _passedAddress);

/// @notice Referrer address should be different from client address.
/// @param _passedAddress passed referrer address that equals to the client address
error FeeDistributor__ReferrerAddressEqualsClient(address _passedAddress);

/// @notice Only factory can call `initialize`.
/// @param _msgSender sender address.
/// @param _actualFactory the actual factory address that can call `initialize`.
error FeeDistributor__NotFactoryCalled(address _msgSender, IFeeDistributorFactory _actualFactory);

/// @notice `initialize` should only be called once.
/// @param _existingClient address of the client with which the contact has already been initialized.
error FeeDistributor__ClientAlreadySet(address _existingClient);

/// @notice Cannot call `withdraw` if the client address is not set yet.
/// @dev The client address is supposed to be set by the factory.
error FeeDistributor__ClientNotSet();

/// @notice basisPoints of the referrer must be zero if referrer address is empty.
/// @param _referrerBasisPoints basisPoints of the referrer.
error FeeDistributor__ReferrerBasisPointsMustBeZeroIfAddressIsZero(uint96 _referrerBasisPoints);

/// @notice service should be able to receive ether.
/// @param _service address of the service.
error FeeDistributor__ServiceCannotReceiveEther(address _service);

/// @notice client should be able to receive ether.
/// @param _client address of the client.
error FeeDistributor__ClientCannotReceiveEther(address _client);

/// @notice referrer should be able to receive ether.
/// @param _referrer address of the referrer.
error FeeDistributor__ReferrerCannotReceiveEther(address _referrer);

/// @notice zero ether balance
error FeeDistributor__NothingToWithdraw();

/// @notice Throws if called by any account other than the client.
/// @param _caller address of the caller
/// @param _client address of the client
error FeeDistributor__CallerNotClient(address _caller, address _client);

/// @notice Throws in case there was some ether left after `withdraw` and it has failed to recover.
/// @param _to destination address for ether.
/// @param _amount how much wei the destination address should have received, but didn't.
error FeeDistributor__EtherRecoveryFailed(
    address _to,
    uint256 _amount
);

/// @notice ETH receiver should not be a zero address
error FeeDistributor__ZeroAddressEthReceiver();