// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library ECCMath {
    error InvalidPoint();

    // https://eips.ethereum.org/EIPS/eip-197#definition-of-the-groups
    uint256 internal constant GX = 1;
    uint256 internal constant GY = 2;

    struct Point {
        uint256 x;
        uint256 y;
    }

    /// @notice returns the corresponding public key of the private key
    /// @dev calculates G^k, aka G^privateKey = publicKey
    function publicKey(uint256 privateKey) internal view returns (Point memory) {
        return ecMul(Point(GX, GY), privateKey);
    }

    /// @notice calculates point^scalar
    /// @dev returns (1,1) if the ecMul failed or invalid parameters
    /// @return corresponding point
    function ecMul(Point memory point, uint256 scalar) internal view returns (Point memory) {
        bytes memory data = abi.encode(point, scalar);
        if (scalar == 0 || (point.x == 0 && point.y == 0)) return Point(1, 1);
        (bool res, bytes memory ret) = address(0x07).staticcall{gas: 6000}(data);
        if (!res) return Point(1, 1);
        return abi.decode(ret, (Point));
    }

    /// @dev after encryption, both the seller and buyer private keys can decrypt
    /// @param encryptToPub public key to which the message gets encrypted
    /// @param encryptWithPriv private key to use for encryption
    /// @param message arbitrary 32 bytes
    function encryptMessage(Point memory encryptToPub, uint256 encryptWithPriv, bytes32 message)
        internal
        view
        returns (Point memory buyerPub, bytes32 encryptedMessage)
    {
        Point memory sharedPoint = ecMul(encryptToPub, encryptWithPriv);
        bytes32 sharedKey = hashPoint(sharedPoint);
        encryptedMessage = message ^ sharedKey;
        buyerPub = publicKey(encryptWithPriv);
    }

    /// @notice decrypts a message that was encrypted using `encryptMessage()`
    /// @param sharedPoint G^k1^k2 where k1 and k2 are the
    ///      private keys of the two parties that can decrypt
    function decryptMessage(Point memory sharedPoint, bytes32 encryptedMessage)
        internal
        pure
        returns (bytes32 decryptedMessage)
    {
        return encryptedMessage ^ hashPoint(sharedPoint);
    }

    /// @dev we hash the point because unsure if x,y is normal distribution (source needed)
    function hashPoint(Point memory point) internal pure returns (bytes32) {
        return keccak256(abi.encode(point));
    }
}