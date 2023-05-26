// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@chocolate-factory/contracts/admin-manager/AdminManagerUpgradable.sol";
import "@chocolate-factory/contracts/payments/CustomPaymentSplitterUpgradeable.sol";
import "../interfaces/IERC721Token.sol";

contract ReRollManager is
    Initializable,
    EIP712Upgradeable,
    AdminManagerUpgradable,
    CustomPaymentSplitterUpgradeable
{
    uint256 public price;
    address public signer;
    uint256 public executions;
    IERC721Token public token;

    struct ReRollRequest {
        address account;
        uint256 tokenId;
    }

    event ReRoll(uint256 indexed tokenId, uint256 index);

    bytes32 private constant RE_ROLL_REQUEST_TYPE_HASH =
        keccak256("ReRollRequest(address account,uint256 tokenId)");

    function initialize(
        uint256 price_,
        address signer_,
        address tokenAddress_,
        address[] memory shareholders_,
        uint256[] memory shares_
    ) public initializer {
        __AdminManager_init_unchained();
        __EIP712_init_unchained("", "");
        setPrice(price_);
        setSigner(signer_);
        setToken(tokenAddress_);
        __CustomPaymentSplitter_init(shareholders_, shares_);
    }

    function reRollMinted(uint256 tokenId) external payable {
        require(token.ownerOf(tokenId) == msg.sender);
        _executeReRoll(tokenId);
    }

    function reRollAssigned(
        ReRollRequest calldata request_,
        bytes calldata signature_
    ) external payable onlyAuthorized(request_, signature_) {
        require(request_.account == msg.sender);
        require(request_.tokenId >= token.totalSupply());
        _executeReRoll(request_.tokenId);
    }

    function _executeReRoll(uint256 tokenId) internal {
        require(tx.origin == msg.sender, "Only EOA allowed");
        require(msg.value >= price, "Invalid payment");
        uint256 extraPayment = msg.value - price;
        if (extraPayment > 0) {
            payable(msg.sender).transfer(extraPayment);
        }

        executions++;
        emit ReRoll(tokenId, executions);
    }

    modifier onlyAuthorized(
        ReRollRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = hashTypedData(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized re-roll request");
        _;
    }

    function hashTypedData(
        ReRollRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RE_ROLL_REQUEST_TYPE_HASH,
                    request_.account,
                    request_.tokenId
                )
            );
    }

    function setPrice(uint256 price_) public onlyAdmin {
        price = price_;
    }

    function setSigner(address signer_) public onlyAdmin {
        signer = signer_;
    }

    function setToken(address tokenAddress_) public onlyAdmin {
        token = IERC721Token(tokenAddress_);
    }

    function withdraw() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _EIP712NameHash() internal pure override returns (bytes32) {
        return keccak256(bytes("STEADY-STACK"));
    }

    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes("0.1.0"));
    }
}