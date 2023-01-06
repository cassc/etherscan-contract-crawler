pragma solidity ^0.4.24;

interface IWeeziCore {
    function isValidSignature(
        bytes32 _hash,
        bytes _signature
    ) external view returns (bool);
    
    function isValidSignatureDate(uint256 _timestamp)
        external
        view
        returns (bool);

    function getFeeWalletAddress() view external returns (address);
}