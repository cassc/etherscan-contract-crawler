// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PhoenixMarketingClaim is Ownable {
    address public Phoenix = 0x79415D5D8B87d04ac5Bdf4074cDC6B31BcDCdBf3;
    mapping(address => bool) public userclaim;
    uint256 public userClaimedAmount;
    bytes32 private _merkleRoot;
    uint256 public MaxClaimAmount = 10000;
    uint256 public SingleClaimAmount = 10_000 * 10 ** 18;
    bool public IsCanClaim;

    constructor () {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function claimPhoenix(bytes32[] calldata _merkleProof) external payable callerIsUser  {
        require(isWhitelistAddress(msg.sender, _merkleProof), "Caller is not in whitelist");
        require(IsCanClaim, "Claim not begin.");
        require(IERC20(Phoenix).balanceOf(address(this)) > 0, "claim has ended.");
        require(!userclaim[msg.sender], "Invalid quantity");
        require(userClaimedAmount + 1 <= MaxClaimAmount, "Invalid quantity");
        userclaim[msg.sender] = true;
        userClaimedAmount++;
        IERC20(Phoenix).transfer(msg.sender, SingleClaimAmount);
    }

    function isWhitelistAddress(address _address, bytes32[] calldata _signature) public view returns (bool) {
        return MerkleProof.verify(_signature, _merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    receive() external payable {}


    function changeIsCanClaim(bool IsCanClaim_) external onlyOwner {
        IsCanClaim = IsCanClaim_;
    }


    function changePhoenix(address Phoenix_) external onlyOwner {
        Phoenix = Phoenix_;
    }

    function changeMaxClaimAmount(uint256 MaxClaimAmount_) external onlyOwner {
        MaxClaimAmount = MaxClaimAmount_;
    }

    function changeSingleClaimAmount(uint256 SingleClaimAmount_) external onlyOwner {
        SingleClaimAmount = SingleClaimAmount_;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function withdrawEth() external payable onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken() external payable onlyOwner {
        uint256 selfbalance = IERC20(Phoenix).balanceOf(address(this));
        if (selfbalance > 0) {
            bool success =  IERC20(Phoenix).transfer(msg.sender, selfbalance);
            require(success, "payMent  Transfer failed.");
        }
    }
}