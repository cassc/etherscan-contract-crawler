// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./Memory.sol";

/**
@title Memory Minter
@author @sammdec
@notice The contract that mints memories
@dev It is the only contract that can mint memories and can be used to update mint logic in the future
*/
contract Minter is Ownable {
    // @notice The memory contract
    Memory public mem;

    // @notice The address of the allowlist signer
    address public allowlistSigner;

    // @notice The address of the verify signer
    address public verifySigner;

    // @notice The various minting states
    // @dev 0 = closed, 1 = allowlist, 2 = public
    uint256 public mintingState = 0;

    // @notice The price of a mint
    uint256 public constant PRICE = 0.05 ether;

    // @notice The address to send funds to when calling withdraw functions
    address public beneficiary;

    constructor() {}

    // @notice The public mint function, mints a memory from a design ID
    // @dev Will only work if mintingState is 2
    // @param designId The design ID to mint from
    // @param verifySignature The signature of the design ID
    function mintMemory(
        string calldata designId,
        bytes memory verifySignature
    ) external payable returns (string memory) {
        require(mintingState == 2, "Public mint is not active");
        require(verifySigner != address(0), "Verify signer address not set");
        require(address(mem) != address(0), "Memory contract address not set");
        require(
            isValidVerifySignature(designId, verifySignature),
            "Invalid verify signature provided"
        );
        require(msg.value == PRICE, "Incorrect amount sent");

        mem.mintFromMinter(msg.sender, designId);

        return designId;
    }

    // @notice The allowlist mint function, mints a memory from a design ID
    // @dev Will only work if mintingState is 1
    // @param designId The design ID to mint from
    // @param verifySignature The signature of the design ID
    // @param allowlistSignature The signature of the allowlist signer
    // @return string The design ID of the minted memory
    function allowlistMintMemory(
        string calldata designId,
        bytes memory verifySignature,
        bytes memory allowlistSignature
    ) external payable returns (string memory) {
        require(mintingState == 1, "Allowlist mint is not active");
        require(verifySigner != address(0), "Verify signer address not set");
        require(
            allowlistSigner != address(0),
            "Allowlist signer address not set"
        );
        require(address(mem) != address(0), "Memory contract address not set");
        require(
            isValidAllowlistSignature(allowlistSignature),
            "Invalid allowlist signature provided"
        );

        require(
            isValidVerifySignature(designId, verifySignature),
            "Invalid verify signature provided"
        );
        require(msg.value == PRICE, "Incorrect amount sent");

        mem.mintFromMinter(msg.sender, designId);

        return designId;
    }

    // @notice The function to check if a design ID signature is valid
    // @param designId The design ID to check
    // @param signature The signature to check
    // @return bool Whether the signature is valid
    function isValidVerifySignature(
        string memory designId,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(designId));
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hash);

        address recoveredSigner = ECDSA.recover(messageDigest, signature);
        return recoveredSigner == verifySigner;
    }

    // @notice The function to check if an allowlist signature is valid
    // @param signature The signature to check
    // @return bool Whether the signature is valid
    function isValidAllowlistSignature(
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hashed = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hashed);

        address recoveredSigner = ECDSA.recover(messageDigest, signature);
        return recoveredSigner == allowlistSigner;
    }

    /**
     * @dev Admin functions
     */

    // @notice The function to set the memory contract address
    // @param _mem The address of the memory contract
    function setMemory(Memory _mem) external onlyOwner {
        mem = Memory(_mem);
    }

    // @notice The function to set the allowlist signer address
    // @param _allowlistSigner The address of the allowlist signer
    function setAllowlistSigner(address _allowlistSigner) external onlyOwner {
        allowlistSigner = _allowlistSigner;
    }

    // @notice The function to set the verify signer address

    function setVerifySigner(address _verifySigner) external onlyOwner {
        verifySigner = _verifySigner;
    }

    // @notice The function to set the minting state, this determins if minting is open or not
    // @param _mintingState The state to set the minting to
    function setMintState(uint256 _mintingState) external onlyOwner {
        mintingState = _mintingState;
    }

    // @notice The function to set the beneficiary address
    // @param _beneficiary The address to send funds to when calling withdraw functions
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    // @notice The function to withdraw funds from the contract
    // @dev Will only work if beneficiary address is set
    function withdraw() external {
        require(beneficiary != address(0), "Beneficiary address not set");
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Withdraw unsuccessful");
    }

    // @notice The function to withdraw ERC20 tokens from the contract
    // @dev Will only work if beneficiary address is set
    // @param _erc20Token The address of the ERC20 token to withdraw
    function withdrawERC20(IERC20 _erc20Token) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary address not set");
        _erc20Token.transfer(beneficiary, _erc20Token.balanceOf(address(this)));
    }
}