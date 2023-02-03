// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// transfer/withdraw locked Tokens
// unlock tokens
// destroy contract / close addUser

contract RDNWaitlist is AccessControlEnumerable {
    // bytes32 public constant USERADD_ROLE = keccak256("USERADD_ROLE");

    uint[] public tokens;

    mapping (uint => address) public addressByToken;
    mapping (address => uint) public tokenByAddress;

    constructor (address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function register(uint _token) public {
        require(addressByToken[_token] == address(0), "Token already registered");
        require(tokenByAddress[msg.sender] == 0, "Address already registered") ;
        addressByToken[_token] = msg.sender;
        tokenByAddress[msg.sender] = _token;
        tokens.push(_token);
    }

    function getAddressByToken(uint _token) public view returns(address) {
        return addressByToken[_token];
    }

    function getTokenByAddress(address _userAddress) public view returns(uint) {
        return tokenByAddress[_userAddress];
    }

    function getAllTokens() public view returns(uint[] memory) {
        return tokens;
    }

}