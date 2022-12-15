// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable, AccessControl {
    bytes32 networkId;
    bytes32 public constant MINTER1_ROLE = keccak256("MINTER1_ROLE");
    bytes32 public constant MINTER2_ROLE = keccak256("MINTER2_ROLE");

    event BurnTo(bytes32 indexed _userid, uint _amount);

    mapping (bytes32 => bool) public usedCoupon;

    constructor(bytes32 _network)
        ERC20("Shealthy", "SCH")
    {
        networkId = _network;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function useCoupon(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, uint8 _v2, bytes32 _r2, bytes32 _s2, address[] calldata _addresses, uint256[] calldata _values, uint256 _stamp) public {
        {
            require(!usedCoupon[_hashedMessage], "coupon already used");
            require(_stamp>block.timestamp,"coupon expired");
            address signer1 = ecrecover(_hashedMessage, _v, _r, _s);
            require(hasRole(MINTER1_ROLE, signer1), "signer1 not minter1");
            address signer2 = ecrecover(_hashedMessage, _v2, _r2, _s2);
            require(hasRole(MINTER2_ROLE, signer2), "signer2 not minter2");
            require(signer1!=signer2,"same signer for both signatures");            
        }
        require (_hashedMessage == keccak256(abi.encodePacked(networkId,address(this),_addresses,_values,_stamp)),"data not valid");
        usedCoupon[_hashedMessage] = true;
        for (uint i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i],_values[i]);
        }
    }

    function couponUsed(bytes32 _hashedMessage) public view returns (bool) {
        return usedCoupon[_hashedMessage];
    }

    function burnTo(uint256 _amount, bytes32 _userid) public {
        _burn(_msgSender(), _amount);
        emit BurnTo(_userid, _amount);
    }
}