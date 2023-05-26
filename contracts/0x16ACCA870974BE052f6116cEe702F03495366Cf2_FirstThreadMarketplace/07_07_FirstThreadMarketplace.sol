// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../lib/solady/src/utils/LibString.sol";
import "../../lib/solady/src/utils/ECDSA.sol";
import "../../lib/solmate/src/auth/Owned.sol";
import "../../lib/solmate/src/tokens/ERC1155.sol";

/// @title First Thread ERC1155 Merchandise Marketplace
/// @author BlockLineChef & ET
/// @notice Implement permissioned burn functions for First Thread Receipt Issuer compatibility

contract FirstThreadMarketplace is ERC1155, Owned {
    using ECDSA for bytes32;
    using LibString for uint256;

    string public name;
    string public symbol;
    string public baseURI;

    address public signer;
    address public receiptContract;

    constructor(
        address _owner,
        address _signer,
        address _receiptContract,
        string memory _name,
        string memory _symbol
    ) Owned(_owner) {
        signer = _signer;
        receiptContract = _receiptContract;
        name = _name;
        symbol = _symbol;
    }

    modifier onlyReceiptContract() {
        require(msg.sender == receiptContract, "FirstThreadItems: Only receipt contract can call this function");
        _;
    }

    /// @notice Mints a single item (tokenID) of variable amount from the store, pay in ETH
    /// @param tokenID Token ID to mint
    /// @param amount Amount of Token ID to mint
    /// @param messageHash Message hash
    /// @param expiry Expiry for signature
    /// @param signature Signature
    function mintSingleEther(uint tokenID, uint amount, bytes32 messageHash, uint expiry, bytes calldata signature) external payable {
        require(block.timestamp < expiry, "Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenID, amount, msg.value, expiry));
        require(hash == messageHash, "FirstThreadItems: Invalid message hash");
        require(verifyAddressSigner(hash, signature), "FirstThreadItems: Invalid signature");
        _mint(msg.sender, tokenID, amount, "");
    }

    /// @notice Mints a variable amount of items (tokenIDs) of variable amounts from the store, pay in ETH
    /// @param tokenIDs Token IDs to mints
    /// @param amounts Amounts of each Token ID to mint
    /// @param messageHash Message hash
    /// @param expiry Expiry for signature
    /// @param signature Signature
    function mintBatchEther(uint[] calldata tokenIDs, uint[] calldata amounts, bytes32 messageHash, uint expiry, bytes calldata signature) external payable {
        require(block.timestamp < expiry, "Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenIDs, amounts, msg.value, expiry));
        require(hash == messageHash, "FirstThreadItems: Invalid message hash");
        require(verifyAddressSigner(hash, signature), "FirstThreadItems: Invalid signature");
        _batchMint(msg.sender, tokenIDs, amounts, "");
    }

    /// @notice Mints a single item (tokenID) of variable amount from the store, pay in ERC20
    /// @dev Must approve this contract to spend ERC20 paymentTokenAmount first
    /// @param tokenID Token ID to mint
    /// @param amount Amount of Token ID to mint
    /// @param paymentTokenAddress ERC20 payment token address
    /// @param paymentTokenAmount ERC20 payment token amount
    /// @param expiry Expiry for signature
    /// @param messageHash Message hash
    /// @param signature Signature
    function mintSingleERC20(uint tokenID, uint amount, address paymentTokenAddress, uint paymentTokenAmount, uint256 expiry, bytes32 messageHash, bytes calldata signature) external {
        require(block.timestamp < expiry, "Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenID, amount, paymentTokenAddress, paymentTokenAmount, expiry));
        require(hash == messageHash, "FirstThreadItems: Invalid message hash");
        require(verifyAddressSigner(hash, signature), "FirstThreadItems: Invalid signature");
        IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), paymentTokenAmount);
        _mint(msg.sender, tokenID, amount, "");
    }

    /// @notice Mints a variable amount of items (tokenIDs) of variable amounts from the store, pay in ERC20
    /// @dev Must approve this contract to spend ERC20 paymentTokenAmount first
    /// @param tokenIDs Token IDs to mints
    /// @param amounts Amounts of each Token ID to mint
    /// @param paymentTokenAddress ERC20 payment token address
    /// @param paymentTokenAmount ERC20 payment token amount
    /// @param expiry Expiry for signature
    /// @param messageHash Message hash
    /// @param signature Signature
    function mintBatchERC20(uint[] calldata tokenIDs, uint[] calldata amounts, address paymentTokenAddress, uint paymentTokenAmount, uint256 expiry, bytes32 messageHash, bytes calldata signature) external {
        require(block.timestamp < expiry, "Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenIDs, amounts, paymentTokenAddress, paymentTokenAmount, expiry));
        require(hash == messageHash, "FirstThreadItems: Invalid message hash");
        require(verifyAddressSigner(hash, signature), "FirstThreadItems: Invalid signature");
        IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this), paymentTokenAmount);
        _batchMint(msg.sender, tokenIDs, amounts, "");
    }

    function burnSingle(address from, uint id, uint amount) external onlyReceiptContract{
        require(balanceOf[from][id] >= amount, "FirstThreadItems: Not enough balance");
        _burn(from, id, amount);
    }

    function burnBatch(address from, uint[] calldata ids, uint[] calldata amounts) external onlyReceiptContract{
        for(uint i = 0; i < ids.length; i++){
            require(balanceOf[from][ids[i]] >= amounts[i], "FirstThreadItems: Not enough balance");
        }
        _batchBurn(from, ids, amounts);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function verifyAddressSigner(bytes32 messageHash, bytes calldata signature) internal view returns (bool) {
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint) public view virtual override returns (string memory) {
        return baseURI;
    }

    function setReceiptContract(address _receiptContract) external onlyOwner {
        receiptContract = _receiptContract;
    }

    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}