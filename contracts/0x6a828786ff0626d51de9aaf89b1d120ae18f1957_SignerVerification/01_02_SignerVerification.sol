//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';

contract SignerVerification {
    function isMessageVerified(
        address signer,
        bytes calldata signature,
        string calldata concatenatedParams
    ) external pure returns (bool) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature) == signer;
    }

    function getSigner(bytes calldata signature, string calldata concatenatedParams) external pure returns (address) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature);
    }

    function getPrefixedHashMessage(string calldata concatenatedParams) internal pure returns (bytes32) {
        uint256 messageLength = bytes(concatenatedParams).length;
        bytes memory prefix = abi.encodePacked('\x19Ethereum Signed Message:\n', Strings.toString(messageLength));
        return keccak256(abi.encodePacked(prefix, concatenatedParams));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function concatParams(
		uint256 _auctionId,
		uint256 _price,
		address _buyer,
        address _artist,
        string memory _tokenURI,
        uint256 _signatureTimestampExpiration
	) external pure returns (string memory) {

        return string(
				abi.encodePacked(
					Strings.toString(_auctionId),
                    Strings.toString(_price),
					_addressToString(_buyer),
					_addressToString(_artist),
                    _tokenURI,
					Strings.toString(_signatureTimestampExpiration)
				)
			);
	}

      function concatParamsForMultipleArt(
		uint256 _auctionId,
		uint256 _price,
        uint256 _amount,
		address _buyer,
        address _artist,
        string memory _tokenURI,
        uint256 _signatureTimestampExpiration,
        uint256 _totalSupply
	) external pure returns (string memory) {

        return string(
				abi.encodePacked(
					Strings.toString(_auctionId),
                    Strings.toString(_price),
                    Strings.toString(_amount),
					_addressToString(_buyer),
					_addressToString(_artist),
                    _tokenURI,
					Strings.toString(_signatureTimestampExpiration),
                    Strings.toString(_totalSupply)
				)
			);
	}

       function concatParamsForRoyalty(
	   string memory _id,
       uint256 _amount,
       address _artist,
       uint256 _signatureTimestampExpiration
	) external pure returns (string memory) {

        return string(
				abi.encodePacked(
					_id,
                    Strings.toString(_amount),
					_addressToString(_artist),
					Strings.toString(_signatureTimestampExpiration)
				)
			);
	}

	function _addressToString(address _addr) public pure returns (string memory) {
		bytes memory addressBytes = abi.encodePacked(_addr);

		bytes memory stringBytes = new bytes(42);

		stringBytes[0] = "0";
		stringBytes[1] = "x";

		for (uint256 i = 0; i < 20; i++) {
			uint8 leftValue = uint8(addressBytes[i]) / 16;
			uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

			bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
			bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

			stringBytes[2 * i + 3] = rightChar;
			stringBytes[2 * i + 2] = leftChar;
		}

		return string(stringBytes);
	}
}