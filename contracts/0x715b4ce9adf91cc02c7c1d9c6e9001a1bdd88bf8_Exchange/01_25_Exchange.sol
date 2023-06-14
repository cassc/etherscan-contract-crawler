// SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

import "./ExchangeCore.sol";

/**
 * @title Exchange
 * @author Wyvern Protocol Developers
 */
contract Exchange is ExchangeCore {

    /* external ABI-encodable method wrappers. */
    
    function hashOrder_(address maker, address target, address token, uint256 percent, uint256 price, uint256 tokenId, uint256 listingTime, uint256 expirationTime, uint256 salt)
        external
        pure
        returns (bytes32 hash)
    {


        return hashOrder(Order(maker, target, token, percent, price, tokenId, listingTime, expirationTime, salt));
    }

    function hashToSign_(bytes32 orderHash)
        external
        view
        returns (bytes32 hash)
    {
        return hashToSign(orderHash);
    }

    function addFarmAddress_(address _token)public onlyOwner{
        addFarmAddress(_token);
    }
    
    function addMoneyHandAddress_(address _contract)public onlyOwner{
        addMoneyHandAdd(_contract);
    }
 
    function validateOrderParameters_(address maker, address target, address token, uint256 percent, uint price, uint tokenId, uint listingTime, uint expirationTime, uint salt)
        external
        view
        returns (bool)
    {
        Order memory order = Order(maker, target, token, percent, price, tokenId, listingTime, expirationTime, salt);
        return validateOrderParameters(order, hashOrder(order));
    }

    function validateOrderAuthorization_(bytes32 hash, address maker, bytes calldata signature)
        external
        view
        returns (bool)
    {
        return validateOrderAuthorization(hash, maker, signature);
    }

    function atomicMatch_(address[6] memory addresses, uint256[12] memory uints, bytes memory signatures)
        public
        payable
    {
        return atomicMatch(
            Order(addresses[0], addresses[1], addresses[2], (uints[0]), uints[1], uints[2], uints[3], uints[4], uints[5]),
            Order(addresses[3], addresses[4], addresses[5], (uints[6]), uints[7], uints[8], uints[9], uints[10], uints[11]),
            signatures
        );
    }

    function ecrecover_(bytes32 calculatedHashToSign, bytes memory signature) public view returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        return ecrecover(keccak256(abi.encodePacked(personalSignPrefix,"32",calculatedHashToSign)), v, r, s);
    }
}