// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

// taken from https://docs.alchemy.com/docs/create2-an-alternative-to-deriving-contract-addresses

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

/**
 * @title VestingWalletFactory
 * @author malteish
 * @notice This contract deploys VestingWallets using create2.
 * @dev One deployment of this contract can be used for deployment of any number of VestingWallets using create2.
 */
contract VestingWalletFactory {
    event Deploy(address indexed addr);

    /**
     * @notice Deploys VestingWallet contract using create2.
     * @param   _salt salt used for privacy. Could be used for vanity addresses, too.
     * @param   beneficiaryAddress address receiving the tokens
     * @param   startTimestamp timestamp of when to start releasing tokens linearly
     * @param   durationSeconds duration of the vesting period in seconds
     */
    function deploy(
        bytes32 _salt,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external returns (address) {
        address actualAddress = Create2.deploy(
            0,
            _salt,
            getBytecode(beneficiaryAddress, startTimestamp, durationSeconds)
        );

        emit Deploy(actualAddress);
        return actualAddress;
    }

    /**
     * @notice Computes the address of VestingWallet contract to be deployed using create2.
     * @param   _salt salt for vanity addresses
     * @param   beneficiaryAddress address receiving the tokens
     * @param   startTimestamp timestamp of when to start releasing tokens linearly
     * @param   durationSeconds duration of the vesting period in seconds
     */
    function getAddress(
        bytes32 _salt,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external view returns (address) {
        bytes memory bytecode = getBytecode(beneficiaryAddress, startTimestamp, durationSeconds);
        return Create2.computeAddress(_salt, keccak256(bytecode));
    }

    /**
     * @dev Generates the bytecode of the contract to be deployed, using the parameters.
     * @param   beneficiaryAddress address receiving the tokens
     * @param   startTimestamp timestamp of when to start releasing tokens linearly
     * @param   durationSeconds duration of the vesting period in seconds
     * @return bytecode of the contract to be deployed.
     */
    function getBytecode(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                type(VestingWallet).creationCode,
                abi.encode(beneficiaryAddress, startTimestamp, durationSeconds)
            );
    }
}