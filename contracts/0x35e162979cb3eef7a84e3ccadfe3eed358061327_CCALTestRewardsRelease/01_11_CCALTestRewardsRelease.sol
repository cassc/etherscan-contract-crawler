// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CCALTestRewardsRelease is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    mapping(address => bool) public claimedMap;

    bytes32 private merkleRoot;

    address public TOKEN;

    function initialize(address _token) public initializer {
        TOKEN = _token;
        __Ownable_init();
    }

    function setRoot(bytes32 _root) external onlyOwner {
        require(_root != bytes32(0), "bad root");
        merkleRoot = _root;
    }

    event ClaimToken(address indexed user, uint amount);
    function claimToken(uint _amount, bytes32[] calldata proofData) external nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _amount));

        require(!claimedMap[msg.sender], "already claimed");
        require(MerkleProofUpgradeable.verify(proofData, merkleRoot, leaf), "verify failed");

        claimedMap[msg.sender] = true;
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TOKEN), _msgSender(), _amount);

        emit ClaimToken(_msgSender(), _amount);
    }

    event WithdrawToken(address indexed user, address receipt, uint256 amount);
    function withdrawToken(address receipt, uint amount) external onlyOwner {
        require(amount > 0, "bad amount");

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TOKEN), receipt, amount);

        emit WithdrawToken(_msgSender(), receipt, amount);
    }

    function withdrawETH(address receipt) external onlyOwner {
        require(receipt != address(0), "bad receipt");
        uint256 amount = address(this).balance;

        (bool success, ) = receipt.call{ value: amount, gas: 30_000 }(new bytes(0));
        require(success, "failed");
    }

    function getClaimed(address user) external view returns(bool) {
        return claimedMap[user];
    }

    fallback() external payable {}

    receive() external payable {}
}