pragma solidity >=0.6.0  <0.7.0;
/**
 * @title ERC677 transferAndCall token interface
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and
 *      discussion.
 *
 * We deviate from the specification and we don't define a tokenfallback. That means
 * tranferAndCall can specify the function to call (bytes4(sha3("setN(uint256)")))
 * and its arguments, and the respective function is called.
 *
 * If an invalid function is called, its default function (if implemented) is called.
 *
 * We also deviate from ERC865 and added a pre signed transaction for transferAndCall.
 */

/*
 Notes on signature malleability: Ethereum took the same
 precaution as in bitcoin was used to prevent that:

 https://github.com/ethereum/go-ethereum/blob/master/vendor/github.com/btcsuite/btcd/btcec/signature.go#L48
 https://github.com/ethereum/go-ethereum/blob/master/crypto/signature_test.go
 https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
 https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2.md

 However, ecrecover still allows ambigous signatures. Thus, recover that wraps ecrecover checks for ambigous
 signatures and only allows unique signatures.
*/

abstract contract ERC865Plus677ish {
    event TransferAndCall(address indexed _from, address indexed _to, uint256 _value, bytes4 _methodName, bytes _args);
    function transferAndCall(address _to, uint256 _value, bytes4 _methodName, bytes memory _args) public virtual returns (bool);

    event TransferPreSigned(address indexed _from, address indexed _to, address indexed _delegate,
        uint256 _amount, uint256 _fee);
    event TransferAndCallPreSigned(address indexed _from, address indexed _to, address indexed _delegate,
        uint256 _amount, uint256 _fee, bytes4 _methodName, bytes _args);

    function transferPreSigned(bytes memory _signature, address _from, address _to, uint256 _value,
        uint256 _fee, uint256 _nonce) public virtual returns (bool);
    function transferAndCallPreSigned(bytes memory _signature, address _from, address _to, uint256 _value,
        uint256 _fee, uint256 _nonce, bytes4 _methodName, bytes memory _args) public virtual returns (bool);
}