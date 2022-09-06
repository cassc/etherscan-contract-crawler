//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INFT.sol";

contract Sale is Initializable, EIP712Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public nft;
    using ECDSA for bytes32;
    address payable public paymentReceiver;
    bool public isSaleEnabled;

    mapping(address => bool) listOfTokens;
    mapping(address => bool) managers;

    struct NFTVoucher {
        uint256 tokenId;
        uint256 price;
        address currency;
        bytes uri;
    }

    event NFTRedeem(address redeemer, uint256 tokenId, uint256 amount, address currency);

    function initialize(address _nft, string memory hiddenName, string memory version_, address payable _paymentReceiver) public initializer {
        __EIP712_init(hiddenName, version_);
        __Ownable_init();
        __ReentrancyGuard_init();
        paymentReceiver = _paymentReceiver;
        nft = _nft;
        listOfTokens[address(0)] = true;
        managers[msg.sender] = true;
    }

    function toggleIsSaleEnabled() external onlyOwner {
        isSaleEnabled = !isSaleEnabled;
    }

    function changeListOfTokens(address _address, bool _value) external onlyOwner {
        listOfTokens[_address] = _value;
    }

    function changePaymentReceiver(address payable _paymentReceiver) external onlyOwner {
        require(_paymentReceiver != address(0), "Zero address is not allowed");
        paymentReceiver = _paymentReceiver;
    }

    function changeManager(address _address, bool _value) external onlyOwner {
        managers[_address] = _value;
    }

    function redeem(NFTVoucher calldata voucher, bytes memory signature) public payable nonReentrant returns (uint256) {
        address signer = _verify(voucher, signature);
        require(managers[signer], "Signature invalid or unauthorized");
        require(isSaleEnabled, "sale not enabled");
        require(listOfTokens[voucher.currency], "Token not listed");

        if (voucher.currency == address(0)) {
            require(msg.value >= voucher.price, "Insufficient funds to redeem");
            paymentReceiver.transfer(msg.value);
        } else {
            IERC20 token = IERC20(voucher.currency);
            require(token.balanceOf(msg.sender) >= voucher.price, "Insufficient funds to redeem");
            require(token.allowance(msg.sender, address(this)) >= voucher.price, "Insufficient allowance to redeem");
            token.transferFrom(msg.sender, paymentReceiver, voucher.price);
        }
        INFT nftInstance = INFT(nft);
        nftInstance.mint(msg.sender, voucher.uri, voucher.tokenId);
        emit NFTRedeem(msg.sender, voucher.tokenId, voucher.price, voucher.currency);
        return voucher.tokenId;
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("NFTVoucher(uint256 tokenId,uint256 price,address currency,bytes uri)"),
                voucher.tokenId,
                voucher.price,
                voucher.currency,
                keccak256(voucher.uri)
            )));
    }

    function _verify(NFTVoucher calldata voucher, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return digest.toEthSignedMessageHash().recover(signature);
    }
}