// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SignedAirdrop {

    address public token;
    address public owner;
    address public nextOwner;
    bool public paused;

    mapping (address => bool) public claimedAddress;

    constructor(address _token) public {
        token = _token;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    event Pause();
    event Unpause();

    function claim(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature,
        uint256 amount
    ) external {
        require(!paused, "The contract is paused");

        address signer = recoverSigner(_ethSignedMessageHash, _signature);

        require(signer == owner, "InvalidSigner");
        require(_ethSignedMessageHash == hashedMessage(amount), "InvalidMessage");
        require(!claimedAddress[msg.sender], "AlreadyClaimed");

        sendToken(msg.sender, amount);
        claimedAddress[msg.sender] = true;
    }

    function setNextOwner(address _nextOwner) external onlyOwner {
        require(_nextOwner != address(0), "Owner cannot be the zero address");
        nextOwner = _nextOwner;
    }

    function getOwnership() external {
        require(nextOwner == msg.sender, "You are not the next owner");
        owner = nextOwner;
        nextOwner = address(0);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }

    function changeToken (address _token) external {
        token = _token;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid Signature Length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (r, s, v);
    }

    function sendToken(address claimer, uint256 amount) internal {
        ERC20(token).transfer(claimer, amount);
    }

    function hashedMessage(uint256 amount) internal returns (bytes32 msgHash){

        return keccak256(abi.encodePacked(msg.sender, amount));
    }

    function withdrawTokens() external onlyOwner {

        uint256 balance = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(owner, balance);
    }
}