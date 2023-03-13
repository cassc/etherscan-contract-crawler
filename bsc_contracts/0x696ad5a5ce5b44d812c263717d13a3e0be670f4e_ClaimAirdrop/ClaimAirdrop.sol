/**
 *Submitted for verification at BscScan.com on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ClaimAirdrop {
    address owner;
    address public rewardToken;
    mapping(uint256 => bool) usedNonces;
    mapping(address => bool) public claimedUsers;

    constructor(address _rewardToken) payable {
        owner = msg.sender;
        rewardToken = _rewardToken;
    }
    
     /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
function genMessage(uint256 amount,uint256 nonce,address receiver)public view returns (bytes32 message){
 // this recreates the message that was signed on the client
        message = prefixed(keccak256(abi.encodePacked(amount, nonce, receiver)));
}
    function claimPayment(uint256 amount, uint256 nonce,address receiver, bytes memory signature) external {
        require(!usedNonces[nonce],"Already used nonce");
        require(claimedUsers[msg.sender]==false,"Already Claimed");
        usedNonces[nonce] = true;
        claimedUsers[msg.sender]=true;
        bytes32 message = genMessage(amount, nonce, receiver);
        require(recoverSigner(message, signature) == owner,"Signer is not owner");
        require(IERC20(rewardToken).transfer(msg.sender,amount),"Transfer of tokens fails");
    }

    /// destroy the contract and reclaim the leftover funds.
    function shutdown(uint256 _amount) external {
        require(msg.sender == owner);
        IERC20(rewardToken).transfer(owner,_amount);
    }

    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    function setRewardToken(address _token) external{
        require(msg.sender==owner,"Only owner");
        rewardToken = _token;
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
        


}