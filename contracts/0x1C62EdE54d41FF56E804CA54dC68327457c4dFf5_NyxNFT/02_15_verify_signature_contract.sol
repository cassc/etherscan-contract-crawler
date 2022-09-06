// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library VerifySign
{
    // function getSignerKeccak256FromHash2(bytes32 hash, bytes memory sig)
    //     public
    //     returns (address)
    // {
    //     address signer = ECDSA.recover(hash, sig);
    //     return signer;
    // }

    function getSignerKeccak256FromHash(uint8 v, bytes32 r, bytes32 s, bytes32 hash)
        public pure
        returns (address)
    {
        address signer = ecrecover(hash, v, r, s);
        return signer;
    }

    function getSignerSha256FromHash(uint8 v, bytes32 r, bytes32 s, bytes32 hash)
        public pure
        returns (address)
    {
        address signer = ecrecover(hash, v, r, s);
        return signer;
    }

    function getSignerKeccak256(uint8 v, bytes32 r, bytes32 s, string memory message, string memory nonce)
        public pure
        returns (address)
    {
        // Using a nonce increase the resistance to replay attack 
        // ie when an attacker reads the blockchain to find value of v, r and s, and can then peacfully
        // pretend to be another signer
        // With a nonce, attacker have to know the nonce to be able to do a replay attack
        // A mapping of nonce have to be implemented in the contract using this function

        bytes32 hash = keccak256(abi.encodePacked(message, nonce));
        address signer = ecrecover(hash, v, r, s);
        return signer;
    }

    function getSignerSha256(uint8 v, bytes32 r, bytes32 s, string memory message, string memory nonce)
        public pure
        returns (address)
    {
        // Using a nonce increase the resistance to replay attack 
        // ie when an attacker reads the blockchain to find value of v, r and s, and can then peacfully
        // pretend to be another signer
        // With a nonce, attacker have to know the nonce to be able to do a replay attack
        // A mapping of nonce have to be implemented in the contract using this function

        bytes32 hash = sha256(abi.encodePacked(message, nonce));
        address signer = ecrecover(hash, v, r, s);
        return signer;
    }

    function getSignerKeccak256WithDeadline(uint8 v, bytes32 r, bytes32 s, string memory message, string memory nonce, uint256 deadline)
        public view
        returns (address)
    {
        require(deadline <= block.timestamp, "Signing too late");
        bytes32 hash = keccak256(abi.encodePacked(message, nonce, deadline));
        address signer = ecrecover(hash, v, r, s);

        return signer;
    }

    function getSignerSha256WithDeadline(uint8 v, bytes32 r, bytes32 s, string memory message, string memory nonce, uint256 deadline)
        public view
        returns (address)
    {
        require(deadline <= block.timestamp, "Signing too late");
        bytes32 hash = sha256(abi.encodePacked(message, nonce, deadline));
        address signer = ecrecover(hash, v, r, s);

        return signer;
    }

    function recoverSigner2(address addr, uint8 v, bytes32 r, bytes32 s, string memory nonce)
        public pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce)), v, r, s);
    }
    
    
    function recoverSigner(address addr, uint8 v, bytes32 r, bytes32 s, string memory nonce, uint256 deadline)
        public pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce, deadline)), v, r, s);
    }

    function recoverSigner3(address addr, uint8 v, bytes32 r, bytes32 s, string memory nonce, string memory deadline)
        public pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce, deadline)), v, r, s);
    }

    function recoverSigner4(address addr, uint8 v, bytes32 r, bytes32 s, uint256 nonce, string memory deadline)
        public pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce, deadline)), v, r, s);
    }
}