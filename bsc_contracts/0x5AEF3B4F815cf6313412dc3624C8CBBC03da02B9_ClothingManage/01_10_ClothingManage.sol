// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/openzeppelin/contracts/access/Ownable.sol";
import "./lib/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/openzeppelin/contracts/utils/Strings.sol";
import "./Common.sol";

contract ClothingManage is ReentrancyGuard, Ownable {
    IClothing721 public clothing721;

    mapping(address => mapping(uint32 => bool)) private purchase_get; // user->clothes_id->isget

    address private SIGNER = 0x13a2032Ec8E6f8Def8338bBF86588aA5df4Ad2e6;

    event PurchaseWhitelist(address account, uint32 clothes_id, string tx_id);

    constructor(
        address _clothing_address
    ) {
        clothing721 = IClothing721(_clothing_address);
    }

    function airdrop(address[] memory _to, uint32[] memory _clothes_id) external onlyOwner
    {
        require(_to.length == _clothes_id.length, "airdrop to.length != clothes_id.length");

        for (uint256 i = 0; i < _to.length; ++i) {
            clothing721.manageMintTo(_to[i], _clothes_id[i]);
        }
    }

    function purchaseWhitelist(uint32 _clothes_id, bytes memory _sign, string memory _tx_id) external {
        require(purchase_get[msg.sender][_clothes_id] == false, "clothes_id already get");
        require(verify(msg.sender, _clothes_id, _sign), "this sign is not valid");

        purchase_get[msg.sender][_clothes_id] = true;
        clothing721.manageMintTo(msg.sender, _clothes_id);
        emit PurchaseWhitelist(msg.sender, _clothes_id, _tx_id);
    }


    //*****************************************************************************
    //* inner
    //*****************************************************************************
    function verify(address _user, uint32 _clothes_id, bytes memory _signatures) public view returns (bool) {

        bytes32 message = keccak256(abi.encodePacked(_user, address(this), _clothes_id));
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
    function withdraw() external onlyOwner
    {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }

    function setClothing721(address _clothing_address) external onlyOwner
    {
        require(_clothing_address != address(0), "clothing721 address should be not 0");
        clothing721 = IClothing721(_clothing_address);
    }

    function setSigner(address _signer) external onlyOwner {
        SIGNER = _signer;
    }

    function kill() external onlyOwner
    {
        selfdestruct(payable(owner()));
    }
}