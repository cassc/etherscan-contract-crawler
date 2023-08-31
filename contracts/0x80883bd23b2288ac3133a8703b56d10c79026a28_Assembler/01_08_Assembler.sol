// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Assembler is Ownable, AccessControl {
    event CollectionPaid(bytes32 indexed hash, address indexed collectionOwner);
    mapping(bytes32 => bool) private _paidCollections;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address private _japo;
    address private _shawn;
    uint256 private _assemblyPrice;

    constructor(
        address japo,
        address shawn,
        uint256 assemblyPrice
    ) Ownable() {
        _japo = japo;
        _shawn = shawn;
        _assemblyPrice = assemblyPrice;
        _setupRole(ADMIN_ROLE, _japo);
        _setupRole(ADMIN_ROLE, _shawn);
    }

    function pay(bytes32 collectionHash) external payable {
        require(!isPaid(collectionHash), "Collection already paid for");
        require(msg.value == checkPrice(), "Incorrect tx value");
        _paidCollections[collectionHash] = true;
        emit CollectionPaid(collectionHash, msg.sender);
    }

    function isPaid(bytes32 collectionHash) public view returns (bool) {
        return _paidCollections[collectionHash];
    }

    function withdraw() external onlyRole(ADMIN_ROLE) {
        uint256 sendAmount = address(this).balance;
        require(sendAmount != 0, "Nothing to withdraw");

        bool success;
        // transfer 50% to japo
        (success, ) = _japo.call{value: ((sendAmount * 50) / 100)}("");
        require(success, "Transaction Unsuccessful");
        // transfer 50% to shawn
        (success, ) = _shawn.call{value: ((sendAmount * 50) / 100)}("");
        require(success, "Transaction Unsuccessful");
    }

    function changePrice(uint256 newPrice) external onlyRole(ADMIN_ROLE) {
        _assemblyPrice = newPrice;
    }

    function checkPrice() public view returns (uint256) {
        return _assemblyPrice;
    }
}