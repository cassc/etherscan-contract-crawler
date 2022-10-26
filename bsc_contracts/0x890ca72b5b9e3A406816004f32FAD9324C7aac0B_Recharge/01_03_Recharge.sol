// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Configable.sol";

contract Recharge is Configable {
    address public SIGNER;    
    IERC20 public burger20;

    mapping(address => mapping(uint => bool)) public records; //user->key->use

    event RechargeItem(address account, uint32 id, uint key, uint price);

    constructor(address _burger20) {
        owner = msg.sender;
        SIGNER = msg.sender;
        burger20 = IERC20(_burger20);
    }

    function pay(uint32 _id, uint _key, uint _price, bytes memory _sign) external {
        require(records[msg.sender][_key] == false, "recharged");
        require(verify(_id, _key, _price, _sign), "this sign is not valid");
        burger20.transferFrom(msg.sender, address(this), _price);
        records[msg.sender][_key] = true;
        emit RechargeItem(msg.sender, _id, _key, _price);
    }

    //*****************************************************************************
    //* inner
    //*****************************************************************************
    function verify(uint32 _id, uint _key, uint _price, bytes memory _signatures) public view returns (bool) {

        bytes32 message = keccak256(abi.encodePacked(address(this), _id, _key, _price, address(msg.sender)));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address[] memory sign_list = recoverAddresses(hash, _signatures);
        return sign_list[0] == SIGNER;
    }

    function recoverAddresses(bytes32 _hash, bytes memory _signatures) internal pure returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

    function _countSignatures(bytes memory _signatures) internal pure returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }

    function _parseSignature(bytes memory _signatures, uint _pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }

    //*****************************************************************************
    //* manage
    //*****************************************************************************
    function withdraw(address _to) external onlyAdmin
    {
        if (address(this).balance > 0) {
            payable(_to).transfer(address(this).balance);
        }
    }

    function withdrawBurger(address _to) external onlyAdmin
    {
        uint balance = burger20.balanceOf(address(this));
        if (balance > 0) {
            burger20.transfer(_to, balance);
        }
    }

    function balanceOfBurger() external view returns (uint)
    {
        return burger20.balanceOf(address(this));
    }

    function setBurger20(address _burger20) external onlyDev
    {
        require(_burger20 != address(0), "address should not 0");
        burger20 = IERC20(_burger20);
    }

    function setSigner(address _signer) external onlyDev
    {
        SIGNER = _signer;
    }

    function kill() external onlyOwner
    {
        uint balance = burger20.balanceOf(address(this));
        if (balance > 0) {
            burger20.transfer(owner, balance);
        }
        selfdestruct(payable(owner));
    }
}