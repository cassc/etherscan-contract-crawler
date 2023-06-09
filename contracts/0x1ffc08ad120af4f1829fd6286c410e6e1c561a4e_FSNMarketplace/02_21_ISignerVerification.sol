// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
		uint256 _auctionId,
		uint256 _price,
		address _buyer,
        address _artist,
        string memory _tokenURI,
        uint256 _signatureTimestampExpiration
	) external pure returns (string memory);

    function concatParamsForRoyalty(
	   string memory _id,
       uint256 _amount,
       address _artist,
       uint256 _signatureTimestampExpiration
	) external pure returns (string memory);

     function concatParamsForMultipleArt(
		uint256 _auctionId,
		uint256 _price,
        uint256 _amount,
		address _buyer,
        address _artist,
        string memory _tokenURI,
        uint256 _signatureTimestampExpiration,
        uint256 _totalSupply
	) external pure returns (string memory);

	function _addressToString(address _addr) external pure returns (string memory);
}