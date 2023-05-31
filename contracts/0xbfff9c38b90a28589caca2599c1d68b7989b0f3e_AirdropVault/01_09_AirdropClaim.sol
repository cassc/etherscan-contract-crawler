// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ControlledAccess.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


pragma solidity ^0.8.4;

/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.
    
    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.
**/

/**
 * @title ERC20 Claiming Vesting Vault for holders
 * @dev This vault is a claiming contract that allows users to register for
 * token vesting based on ETH sent into the vault.
 */

contract AirdropVault is Ownable, ReentrancyGuard {
    // ERC20 token being held by this contract
    IERC20 public token;
    bool public isAirdropLive;
    mapping(address => bool) public airdropped;

    receive() external payable {}

    constructor(address _token) {
        token = IERC20(_token);
    }

    /***********************/
    /***********************/
    /*** ADMIN FUNCTIONS ***/
    /***********************/
    /***********************/
    function setlive(bool _isLive) external onlyOwner {
        isAirdropLive = _isLive;
    }

    function setToken(address _tokenAddr) external onlyOwner {
        token = IERC20(_tokenAddr);
    }

    function withdrawETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /***********************/
    /***********************/
    /*** PUBLIC FUNCTIONS **/
    /***********************/
    /***********************/

    function claim(
        uint256 amount,
        bytes32 msgHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable nonReentrant {
        require(isAirdropLive, "Airdrops not open");

        // Security check.
        bytes32 calculatedMsgHash = keccak256(
            abi.encodePacked(msg.sender, amount)
        );
        require(calculatedMsgHash == msgHash, "Invalid hash");

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
            ),
            _v,
            _r,
            _s
        );

        require(owner() == signer, "Not Authorized by deployer");
        require(!airdropped[msg.sender], "Already Registered!");
        airdropped[msg.sender] = true;
        token.transfer(msg.sender, amount);
    }

}