// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./cryptography/SignatureChecker.sol";
import "./libraries/Ownable.sol";
import "./interfaces/IERC20Metadata.sol";

contract GSSHoldV4 is Ownable {

    address public GSSToken;

    /// @notice Info of user.
    mapping(uint256 => bool) public pendingStatus;

    event WithdrawPending(address indexed user, uint256 pending, uint256 time);

    constructor() {

    }

    function withdrawPending(address recipient, uint256 id, uint256 amount, bytes32 hash, bytes memory signature) external returns (bool){

        require(id > 0, "EGSSHoldV4:cannot be less than 0");

        require(!pendingStatus[id], "EGSSHoldV4:Repeat withdrawal");

        require(getTokenIdHash(id, amount, msg.sender) == hash, "GSSHoldV4:data is invalid");

        //  Verify signature
        require(SignatureChecker.isValidSignatureNow(owner(), getEthSignedMessageHash(hash), signature), "GSSHoldV4:Failed to verify signature");

        pendingStatus[id] = true;

        IERC20Metadata(GSSToken).transfer(recipient, amount);

        return true;
    }

    function getTokenIdHash(uint256 _id, uint256 _amount, address _user) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _amount, _user));
    }
    
    function getEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function setGSSToken(address _token) external onlyOwner {

        GSSToken = _token;
    }

    function withdrawEth(address payable receiver, uint amount) public onlyOwner payable {
        uint balance = address(this).balance;
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "no balance");
        receiver.transfer(amount);
    }

    function withdrawToken(address receiver, address tokenAddress, uint amount) public onlyOwner payable {
        uint balance = IERC20Metadata(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }

        require(amount > 0 && balance >= amount, "bad amount");
        IERC20Metadata(tokenAddress).transfer(receiver, amount);
    }

}