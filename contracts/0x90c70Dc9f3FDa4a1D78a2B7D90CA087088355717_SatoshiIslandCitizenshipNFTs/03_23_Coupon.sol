pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Coupon is EIP712 {
    address public immutable SIGNER;

    //tracking the receipts associated with token ids
    mapping(uint256 => uint256) public receipts;

    modifier onlyWithCoupon(
        uint256 id,
        uint256 expiresAt,
        bytes memory signature
    ) {
        require(receipts[id] == 0, "Coupon: already used");

        require(
            verifySignature(msg.sender, id, expiresAt, signature),
            "Coupon: Invalid signature"
        );

        require(expiresAt > block.timestamp, "Coupon: invalid expiration");
        _;
    }

    constructor(
        address signerAccount,
        string memory domainSeparator,
        string memory signatureVersion
    ) EIP712(domainSeparator, signatureVersion) {
        require(
            signerAccount != address(0),
            "Coupon: Rejected nullish signerAccount"
        );
        SIGNER = signerAccount;
    }

    function chainId() external view returns (uint256) {
        return block.chainid;
    }

    function isUsed(uint256 receiptId) external view returns (bool) {
        return receipts[receiptId] != 0;
    }

    function verifySignature(
        address account,
        uint256 id,
        uint256 expiresAt,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "CouponReceipt(address account,uint256 id,uint256 expiresAt)"
                    ),
                    account,
                    id,
                    expiresAt
                )
            )
        );

        return ECDSA.recover(digest, signature) == SIGNER;
    }
}