// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IDepositContract.sol";
import "../feeDistributorFactory/IFeeDistributorFactory.sol";
import "./IP2pEth2Depositor.sol";

/**
* @notice Should be a FeeDistributorFactory contract
* @param _passedAddress passed address that does not support IFeeDistributorFactory interface
*/
error P2pEth2Depositor__NotFactory(address _passedAddress);

/**
* @notice do not send ETH directly here
*/
error P2pEth2Depositor__DoNotSendEthDirectlyHere();

/**
* @notice you can deposit only 1 to 400 validators per transaction
*/
error P2pEth2Depositor__ValidatorCountError();

/**
* @notice the amount of ETH does not match the amount of validators
*/
error P2pEth2Depositor__EtherValueError();

/**
* @notice amount of parameters do no match
*/
error P2pEth2Depositor__AmountOfParametersError();

/**
* @title Batch deposit contract
* @dev Makes up to 400 ETH2 DepositContract calls within 1 transaction
* @dev Create a FeeDistributor instance (1 for batch)
*/
contract P2pEth2Depositor is ERC165, IP2pEth2Depositor {
    
    /**
    * @dev 400 deposits (12800 ETH) is determined by calldata size limit of 128 kb
    * @dev https://ethereum.stackexchange.com/questions/144120/maximum-calldata-size-per-block
    */
    uint256 public constant validatorsMaxAmount = 400;

    /**
     * @dev Collateral size of one node.
     */
    uint256 public constant collateral = 32 ether;

    /**
     * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public immutable i_depositContract;

    /**
    * @dev Factory for cloning (EIP-1167) FeeDistributor instances pre client
    */
    IFeeDistributorFactory public immutable i_feeDistributorFactory;

    /**
     * @dev Setting Eth2 Smart Contract address during construction.
     */
    constructor(bool _mainnet, address _depositContract, address _feeDistributorFactory) {
        if (!ERC165Checker.supportsInterface(_feeDistributorFactory, type(IFeeDistributorFactory).interfaceId)) {
            revert P2pEth2Depositor__NotFactory(_feeDistributorFactory);
        }

        i_depositContract = _mainnet
        ? IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa) // real Mainnet DepositContract
        : (_depositContract == 0x0000000000000000000000000000000000000000)
            ? IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b) // real Goerli DepositContract
            : IDepositContract(_depositContract);

        i_feeDistributorFactory = IFeeDistributorFactory(_feeDistributorFactory);
    }

    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert P2pEth2Depositor__DoNotSendEthDirectlyHere();
    }

    /**
    * @notice Function that allows to deposit up to 400 validators at once.
    *
    * @dev In _clientConfig, recipient is mandatory.
    * @dev In _clientConfig, basisPoints can be 0, defaultClientBasisPoints from FeeDistributorFactory will be applied in that case.
    * @dev In _referrerConfig, both recipient and basisPoints can be 0 if there is no referrer.
    *
    * @param _pubkeys Array of BLS12-381 public keys.
    * @param _withdrawal_credentials Commitment to a public keys for withdrawals. 1, same for all
    * @param _signatures Array of BLS12-381 signatures.
    * @param _deposit_data_roots Array of the SHA-256 hashes of the SSZ-encoded DepositData objects.
    * @param _clientConfig Address and basis points (percent * 100) of the client
    * @param _referrerConfig Address and basis points (percent * 100) of the referrer.
    */
    function deposit(
        bytes[] calldata _pubkeys,
        bytes calldata _withdrawal_credentials, // 1, same for all
        bytes[] calldata _signatures,
        bytes32[] calldata _deposit_data_roots,
        IFeeDistributor.FeeRecipient calldata _clientConfig,
        IFeeDistributor.FeeRecipient calldata _referrerConfig
    ) external payable {

        uint256 validatorCount = _pubkeys.length;

        if (validatorCount == 0 || validatorCount > validatorsMaxAmount) {
            revert P2pEth2Depositor__ValidatorCountError();
        }

        if (msg.value != collateral * validatorCount) {
            revert P2pEth2Depositor__EtherValueError();
        }

        if (!(
            _signatures.length == validatorCount &&
            _deposit_data_roots.length == validatorCount
        )) {
            revert P2pEth2Depositor__AmountOfParametersError();
        }

        uint64 firstValidatorId = toUint64(i_depositContract.get_deposit_count()) + 1;

        for (uint256 i = 0; i < validatorCount;) {
            // pubkey, withdrawal_credentials, signature lengths are already checked inside ETH DepositContract

            i_depositContract.deposit{value : collateral}(
                _pubkeys[i],
                _withdrawal_credentials,
                _signatures[i],
                _deposit_data_roots[i]
            );

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        // First, make sure all the deposits are successful, then deploy FeeDistributor
        address newFeeDistributorAddress = i_feeDistributorFactory.createFeeDistributor(
            _clientConfig,
            _referrerConfig,
            IFeeDistributor.ValidatorData({
                clientOnlyClRewards : 0,
                firstValidatorId : firstValidatorId,
                validatorCount : uint16(validatorCount)
            })
        );

        emit P2pEth2DepositEvent(msg.sender, newFeeDistributorAddress, firstValidatorId, validatorCount);
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IP2pEth2Depositor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev Convert deposit_count from ETH2 DepositContract to uint64
    * ETH2 DepositContract returns inverted bytes. Need to invert them back.
    */
    function toUint64(bytes memory b) internal pure returns (uint64) {
        uint64 result;
        assembly {
            let x := mload(add(b, 8))

            result := or(
                or (
                    or(
                        and(0xff, shr(56, x)),
                        and(0xff00, shr(40, x))
                    ),
                    or(
                        and(0xff0000, shr(24, x)),
                        and(0xff000000, shr(8, x))
                    )
                ),

                or (
                    or(
                        and(0xff00000000, shl(8, x)),
                        and(0xff0000000000, shl(24, x))
                    ),
                    or(
                        and(0xff000000000000, shl(40, x)),
                        and(0xff00000000000000, shl(56, x))
                    )
                )
            )
        }
        return result;
    }
}