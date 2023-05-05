// Altura Lazy Minter
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAlturaNFTV3.sol";

contract AlturaLazyMinter is UUPSUpgradeable, OwnableUpgradeable, EIP712Upgradeable {
    bytes32 private constant MINTREQUEST_TYPEHASH =
        keccak256(
            "MintRequest(address buyer,uint256 saleId,uint256 itemId,address collection,uint256 amount,uint256 maxAmount,uint256 price,address paymentToken,address paymentRecipient,uint256 fee,address feeRecipient,uint256 expiration)"
        );

    address public allowedSigner;
    mapping(uint256 => mapping(address => uint256)) private purchasedAmounts;

    struct MintRequest {
        uint256 saleId;
        uint256 itemId;
        address collection;
        uint256 amount;
        uint256 maxAmount;
        uint256 price;
        address paymentToken;
        address paymentRecipient;
        uint256 fee;
        address feeRecipient;
        uint256 expiration;
    }

    event ItemMinted(MintRequest mintRequest);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory version, address signerAddress) public initializer {
        __Ownable_init();
        __EIP712_init("AlturaLazyMinter", version);

        __AlturaLazyMinter_init_unchained(signerAddress);
    }

    function __AlturaLazyMinter_init_unchained(address signerAddress) internal onlyInitializing {
        allowedSigner = signerAddress;
    }

    function mint(
        MintRequest calldata mintRequest,
        bytes calldata signature
    ) external payable isAuthorized(mintRequest, signature) {
        if (mintRequest.maxAmount > 0) {
            mapping(address => uint256) storage currentSaleAmounts = purchasedAmounts[mintRequest.saleId];
            uint256 newAmount = currentSaleAmounts[msg.sender] + mintRequest.amount;

            require(newAmount <= mintRequest.maxAmount, "Reached limit per wallet");
            currentSaleAmounts[msg.sender] = newAmount;
        }

        if (mintRequest.price > 0) {
            if (mintRequest.paymentToken == address(0x0)) {
                require(msg.value == mintRequest.price + mintRequest.fee, "Insufficient payment");

                (bool successPayment, ) = mintRequest.paymentRecipient.call{value: mintRequest.price}("");
                (bool successFee, ) = mintRequest.feeRecipient.call{value: mintRequest.fee}("");
                require(successPayment && successFee, "Payment failed");
            } else {
                IERC20 targetPaymentToken = IERC20(mintRequest.paymentToken);

                bool successPayment = targetPaymentToken.transferFrom(
                    msg.sender,
                    mintRequest.paymentRecipient,
                    mintRequest.price
                );
                bool successFee = targetPaymentToken.transferFrom(
                    msg.sender,
                    mintRequest.feeRecipient,
                    mintRequest.fee
                );
                require(successPayment && successFee, "Payment failed");
            }
        }

        IAlturaNFTV3 targetCollection = IAlturaNFTV3(mintRequest.collection);
        require(targetCollection.mint(msg.sender, mintRequest.itemId, mintRequest.amount, "0x0"), "Mint failed");
        emit ItemMinted(mintRequest);
    }

    function setAllowedSigner(address signerAddress) external onlyOwner {
        allowedSigner = signerAddress;
    }

    modifier isAuthorized(MintRequest calldata mintRequest, bytes calldata signature) {
        bytes32 digest = _getRequestHash(mintRequest);

        require(block.timestamp < mintRequest.expiration, "Request expired");
        require(ECDSA.recover(digest, signature) == allowedSigner, "Unauthorized");
        _;
    }

    function _getRequestHash(MintRequest calldata mintRequest) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MINTREQUEST_TYPEHASH,
                        msg.sender,
                        mintRequest.saleId,
                        mintRequest.itemId,
                        mintRequest.collection,
                        mintRequest.amount,
                        mintRequest.maxAmount,
                        mintRequest.price,
                        mintRequest.paymentToken,
                        mintRequest.paymentRecipient,
                        mintRequest.fee,
                        mintRequest.feeRecipient,
                        mintRequest.expiration
                    )
                )
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}