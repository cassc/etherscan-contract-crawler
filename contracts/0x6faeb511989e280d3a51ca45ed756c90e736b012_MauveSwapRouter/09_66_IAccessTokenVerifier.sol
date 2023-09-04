// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ~0.7.6;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// struct FunctionParam {
//     string typ; // explicit full solidity atomic type of the parameter
//     bytes value; // the byte formatted parameter value
// }

struct FunctionCall {
    // string name; // name of the function being called
    bytes4 functionSignature;
    address target;
    address caller;
    bytes parameters;
    // FunctionParam[] parameters; // array of input parameters to the function call
}

struct AccessToken {
    uint256 expiry;
    FunctionCall functionCall;
}

interface IAccessTokenVerifier {
    function verify(
        AccessToken calldata token,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);
}