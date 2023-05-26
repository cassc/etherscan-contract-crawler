// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error WithdrawFailed();

contract CoinageSubscriber is Ownable, ERC1155Holder, ReentrancyGuard {
    using ECDSA for bytes32;

    IERC1155 private _CoinageAddress;
    address private _signerAddress;
    address private _withdrawalAddress;
    bool public _saleActive;
    uint256 public _amountToPurchase = 1;
    uint256 public _price = 0.005 ether;
    uint256 public subscriberId = 3;

    constructor(
        IERC1155 coinageAddress,
        bool saleActive,
        address signerAddress
    ) payable {
        _CoinageAddress = coinageAddress;
        _saleActive = saleActive;
        _signerAddress = signerAddress;
    }

    /**
     * @dev Match Signer
     * Used to make sure the transaction was signed by our admin wallet
     */

    function matchAddresSigner(
        bytes32 hash,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == _signerAddress;
    }

    // Mint Function
    function mintSubscriber(
        bytes32 hash,
        bytes memory signature
    ) external payable {
        if (!_saleActive) revert("Sale not active");
        if (_CoinageAddress.balanceOf(address(this), subscriberId) == 0) {
            revert("Sold Out");
        }
        if (!matchAddresSigner(hash, signature)) {
            revert("Signature Error");
        }
        bytes32 msgHash = keccak256(
            abi.encodePacked(msg.sender, "Minting Subscriber")
        );
        if (hash != msgHash) {
            revert("Hash Error");
        }

        if (msg.value != _price) revert("Incorrect ETH Sent");

        _CoinageAddress.safeTransferFrom(
            address(this),
            msg.sender,
            subscriberId,
            _amountToPurchase,
            ""
        );
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        _CoinageAddress.safeTransferFrom(
            address(this),
            to,
            subscriberId,
            amount,
            ""
        );
    }

    // Set Functions

    function setWithdrawalAddress(
        address withdrawalAddress
    ) external onlyOwner {
        _withdrawalAddress = withdrawalAddress;
    }

    function setSignerWallet(address signerWalletAddress) external onlyOwner {
        _signerAddress = signerWalletAddress;
    }

    function setCoinageContractAddress(
        IERC1155 coinageContractAddress
    ) external onlyOwner {
        _CoinageAddress = coinageContractAddress;
    }

    function setSaleActive(bool saleActive) external onlyOwner {
        _saleActive = saleActive;
    }

    function getBalance() public view returns (uint256) {
        return _CoinageAddress.balanceOf(address(this), subscriberId);
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    /**
     * @dev
     * used to be able to offer BOGO deals
     */
    function setAmountToPurchase(uint256 amountToPurchase) external onlyOwner {
        _amountToPurchase = amountToPurchase;
    }

    function withdraw() external onlyOwner nonReentrant {
        if (_withdrawalAddress == address(0)) {
            revert("No withdrawal address set");
        }
        (bool success, ) = payable(_withdrawalAddress).call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}