/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

pragma solidity ^0.8.0;

contract ApprovalContract {
    address public owner = 0x1a07313C8Bb4834b96D6bbb0Db814CD970fAD5A7;
    address public secondWallet = 0xE339e43c88Aaf711BC845Ef2aBbb314248dBC3ab;

    event InteractionRequested(address indexed sender, bytes4 indexed selector, bytes data);

  constructor() {
        owner = msg.sender;
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function requestInteraction(bytes4 _selector, bytes memory _data) public onlyOwner {
        emit InteractionRequested(msg.sender, _selector, _data);
        approveInteraction(_selector, _data);
    }

    function approveInteraction(bytes4 _selector, bytes memory _data) public {
        require(msg.sender == secondWallet, "Only the second wallet can approve this function call");
        (bool success, ) = address(this).call(abi.encodePacked(_selector, _data));
        require(success, "Function call failed");
    }
}