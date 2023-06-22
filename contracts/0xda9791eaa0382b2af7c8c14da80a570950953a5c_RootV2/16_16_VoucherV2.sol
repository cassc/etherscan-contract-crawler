pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract VoucherV2 is EIP712Upgradeable {
    mapping(address => uint256) public nonces;

    enum RedeemType {
        swap,
        fcfs
    }

    enum RefundType {
        refund,
        refundPolicy
    }

    enum OfferingType {
        ido,
        ino
    }

    struct RefundVoucher {
        uint256 projectId;
        RefundType refundType;
        OfferingType offeringType;
        address investorAddr;
        address token;
        uint256 nonce;
        uint256 expireTime;
        bytes signature;
    }

    struct RedeemIdoVoucher {
        uint256 projectId;
        RedeemType redeemType;
        address token;
        address investorAddr;
        uint256 amount;
        uint256 fee;
        uint256 nonce;
        uint256 expireTime;
        bytes signature;
    }

    struct RedeemInoVoucher {
        uint256 projectId;
        RedeemType redeemType;
        address token;
        address investorAddr;
        uint256[] boxIDs;
        uint256[] boxCounts;
        uint256 amount;
        uint256 nonce;
        uint256 expireTime;
        bytes signature;
    }

    struct ReturnProjectTokensVoucher {
        uint256 projectId;
        address investorAddr;
        uint256 nonce;
        uint256 expireTime;
        bytes signature;
    }

    modifier validateVoucher(
        uint256 nonce,
        address investorAddr,
        uint256 expireTime
    ) {
        require(
            nonce == nonces[msg.sender],
            "_isCorrectVoucher: invalid nonce"
        );
        require(investorAddr == msg.sender, "_isCorrectVoucher: wrong caller");
        require(
            expireTime >= block.timestamp,
            "_isCorrectVoucher: voucher is expired"
        );
        _;
    }

    function _hashReturnProjectTokens(
        ReturnProjectTokensVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ReturnProjectTokensVoucher(uint256 projectId,address investorAddr,uint256 nonce,uint256 expireTime)"
                        ),
                        voucher.projectId,
                        voucher.investorAddr,
                        voucher.nonce,
                        voucher.expireTime
                    )
                )
            );
    }

    function _verifyReturnProjectTokens(
        ReturnProjectTokensVoucher calldata voucher
    )
        internal
        validateVoucher(voucher.nonce, voucher.investorAddr, voucher.expireTime)
        returns (address)
    {
        nonces[msg.sender] += 1;
        bytes32 digest = _hashReturnProjectTokens(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashRedeemIdo(RedeemIdoVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "RedeemIdoVoucher(uint256 projectId,uint8 redeemType,address token,address investorAddr,uint256 amount,uint256 fee,uint256 nonce,uint256 expireTime)"
                        ),
                        voucher.projectId,
                        voucher.redeemType,
                        voucher.token,
                        voucher.investorAddr,
                        voucher.amount,
                        voucher.fee,
                        voucher.nonce,
                        voucher.expireTime
                    )
                )
            );
    }

    function _verifyRedeemIdo(RedeemIdoVoucher calldata voucher)
        internal
        validateVoucher(voucher.nonce, voucher.investorAddr, voucher.expireTime)
        returns (address)
    {
        nonces[msg.sender] += 1;
        bytes32 digest = _hashRedeemIdo(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashRedeemIno(RedeemInoVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "RedeemInoVoucher(uint256 projectId,uint8 redeemType,address token,address investorAddr,uint256[] boxIDs,uint256[] boxCounts,uint256 amount,uint256 nonce,uint256 expireTime)"
                        ),
                        voucher.projectId,
                        voucher.redeemType,
                        voucher.token,
                        voucher.investorAddr,
                        keccak256(abi.encodePacked(voucher.boxIDs)),
                        keccak256(abi.encodePacked(voucher.boxCounts)),
                        voucher.amount,
                        voucher.nonce,
                        voucher.expireTime
                    )
                )
            );
    }

    function _verifyRedeemIno(RedeemInoVoucher calldata voucher)
        internal
        validateVoucher(voucher.nonce, voucher.investorAddr, voucher.expireTime)
        returns (address)
    {
        nonces[msg.sender] += 1;
        bytes32 digest = _hashRedeemIno(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashRefund(RefundVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "RefundVoucher(uint256 projectId,uint8 refundType,uint8 offeringType,address investorAddr,address token,uint256 nonce,uint256 expireTime)"
                        ),
                        voucher.projectId,
                        voucher.refundType,
                        voucher.offeringType,
                        voucher.investorAddr,
                        voucher.token,
                        voucher.nonce,
                        voucher.expireTime
                    )
                )
            );
    }

    function _verifyRefund(RefundVoucher calldata voucher)
        internal
        validateVoucher(voucher.nonce, voucher.investorAddr, voucher.expireTime)
        returns (address)
    {
        nonces[msg.sender] += 1;
        bytes32 digest = _hashRefund(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}