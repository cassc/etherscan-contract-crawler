// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
 * @dev Interface of the Signer Verification;
 */
interface ISignerVerification {

    function isMessageVerified(
        address signer,
        bytes calldata signature,
        string memory concatenatedParams
    ) external pure returns (bool);

    function getSigner(bytes calldata signature, string calldata concatenatedParams) external pure returns (address);

    function concatParams(
	    uint256 _pointsAmount,
		address _buyer,
        uint256 _nonce
	) external pure returns (string memory);
}