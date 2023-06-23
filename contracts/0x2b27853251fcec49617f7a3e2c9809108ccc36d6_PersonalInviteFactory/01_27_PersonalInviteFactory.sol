// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

// taken from https://docs.alchemy.com/docs/create2-an-alternative-to-deriving-contract-addresses

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "../contracts/PersonalInvite.sol";

/*
    One deployment of this contract can be used for deployment of any number of PersonalInvites using create2.
*/
contract PersonalInviteFactory {
    event Deploy(address indexed addr);

    /**
     * @notice Deploys a contract using create2.
     */
    function deploy(
        bytes32 _salt,
        address _currencyPayer,
        address _tokenReceiver,
        address _currencyReceiver,
        uint256 _tokenAmount,
        uint256 _tokenPrice,
        uint256 _expiration,
        IERC20 _currency,
        IERC20 _token
    ) external returns (address) {
        address actualAddress = Create2.deploy(
            0,
            _salt,
            getBytecode(
                _currencyPayer,
                _tokenReceiver,
                _currencyReceiver,
                _tokenAmount,
                _tokenPrice,
                _expiration,
                _currency,
                _token
            )
        );

        emit Deploy(actualAddress);
        return actualAddress;
    }

    /**
     * @notice Computes the address of a contract to be deployed using create2.
     */
    function getAddress(
        bytes32 _salt,
        address _currencyPayer,
        address _tokenReceiver,
        address _currencyReceiver,
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _expiration,
        IERC20 _currency,
        IERC20 _token
    ) external view returns (address) {
        bytes memory bytecode = getBytecode(
            _currencyPayer,
            _tokenReceiver,
            _currencyReceiver,
            _amount,
            _tokenPrice,
            _expiration,
            _currency,
            _token
        );
        return Create2.computeAddress(_salt, keccak256(bytecode));
    }

    function getBytecode(
        address _currencyPayer,
        address _tokenReceiver,
        address _currencyReceiver,
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _expiration,
        IERC20 _currency,
        IERC20 _token
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                type(PersonalInvite).creationCode,
                abi.encode(
                    _currencyPayer,
                    _tokenReceiver,
                    _currencyReceiver,
                    _amount,
                    _tokenPrice,
                    _expiration,
                    _currency,
                    _token
                )
            );
    }
}