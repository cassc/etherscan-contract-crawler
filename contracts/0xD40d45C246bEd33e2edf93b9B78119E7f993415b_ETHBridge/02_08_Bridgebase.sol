// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IToken.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";
import "hardhat/console.sol";

abstract contract BridgeBase is Ownable {
    address public admin;
    IToken public token;
    uint256 internal fees;
    // address public owner;
    bool public whiteListOn;

    mapping(address => mapping(uint256 => bool)) public processedNonces;
    mapping(address => bool) public isWhiteList;
    mapping(address => uint256) public nonce;

    event TokenDeposit(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce,
        string transactionID
    );

    event TokenWithdraw(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce,
        bytes sign
    );

    event WhiteListToggled(bool state);

    event WhiteListAddressToggled(
        address _user,
        address _bridgeAddress,
        bool _state
    );

    constructor(address _token, address _admin) {
        require(_token != address(0), "Token cannot be 0 address");
        require(_admin != address(0), "Admin cannot be 0 address");
        token = IToken(_token);
        fees = 1;
        admin = _admin;
        // owner = msg.sender;
        whiteListOn = !whiteListOn;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return recover(message, v, r, s);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n / 2 + 1, and for v in (282): v in {27, 28 Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "sig length invalid");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function depositTokens(
        uint256 amount,
        address recipient,
        // uint256 nonce,
        string memory _transactionID
    ) external virtual;

    function withdrawTokens(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external virtual;

    function toggleWhiteListOnly() external onlyOwner {
        //require(msg.sender == owner, "Sender not Owner");
        whiteListOn = !whiteListOn;
        emit WhiteListToggled(whiteListOn);
    }

    function toggleWhiteListAddress(address[] calldata _addresses)
        external
        onlyOwner
    {
        // require(msg.sender == owner, "Sender not Owner");
        require(_addresses.length <= 200, "Addresses length exceeded");
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhiteList[_addresses[i]] = !isWhiteList[_addresses[i]];
            emit WhiteListAddressToggled(
                _addresses[i],
                address(this),
                isWhiteList[_addresses[i]]
            );
        }
    }
}