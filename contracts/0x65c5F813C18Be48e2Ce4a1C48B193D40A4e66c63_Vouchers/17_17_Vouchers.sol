// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vouchers is ERC1155, Ownable, ERC1155Supply, EIP712 {
    modifier ownerOrMinter() {
        require(msg.sender == owner() || isMinter[msg.sender], "Vouchers: Owner or Minter only");
        _;
    }

    error PaymentTokenTransferError(address from, address to, uint256 amount);
    error BalanceBelowThenTransferredAmount();
    event MintedWithNonce(address minter, uint256 indexed nonce, uint256[] ids, uint256[] amounts, address ptFromAccount, address[] ptFromAccountReceivers, uint256[] fromAccountAmounts);

    mapping(uint256 => bool) public isNonceUsed;
    address public signer;
    mapping(address => bool) public isMinter;
    mapping(uint256 => bool) public isVoucherUsed;
    string public name;
    string public symbol;

    constructor(string memory startUri, address signerRole)
        ERC1155(startUri)
        EIP712("TravelCard", "1")
    {
        signer = signerRole;
        name = "TravelCard Collection";
        symbol = "TCC";

    }

    function receivePayment(
        address ptFromAccount,
        address[] memory ptFromAccountReceivers,
        uint256[] memory fromAccountAmounts
    ) internal {
        if (
            (ptFromAccountReceivers.length != 0) &&
            (fromAccountAmounts.length != 0) &&
            (ptFromAccountReceivers.length == fromAccountAmounts.length)
        ) {
            if (ptFromAccount == address(0)) {
                uint256 sum;
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    sum += fromAccountAmounts[i];
                }
                require(msg.value >= sum, "Vouchers: Not enough BNB");
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    if (ptFromAccountReceivers[i] != address(this)) {
                        Address.sendValue(
                            payable(ptFromAccountReceivers[i]),
                            fromAccountAmounts[i]
                        );
                    }
                }
            } else {
                for (uint256 i = 0; i < ptFromAccountReceivers.length; i++) {
                    if (
                        IERC20(ptFromAccount).balanceOf(msg.sender) <
                        fromAccountAmounts[i]
                    ) {
                        revert BalanceBelowThenTransferredAmount();
                    }
                    if (
                        !IERC20(ptFromAccount).transferFrom(
                            msg.sender,
                            ptFromAccountReceivers[i],
                            fromAccountAmounts[i]
                        )
                    )
                        revert PaymentTokenTransferError(
                            msg.sender,
                            ptFromAccountReceivers[i],
                            fromAccountAmounts[i]
                        );
                }
            }
        }
    }

    function batchMintWithSignature(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        address ptFromAccount,
        address[] memory ptFromAccountReceivers,
        uint256[] memory fromAccountAmounts,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Vouchers: Transaction overdue");
        require(!isNonceUsed[nonce], "Vouchers: Nonce already used");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "BatchMintData(address to,uint256[] ids,uint256[] amounts,bytes data,address ptFromAccount,address[] ptFromAccountReceivers,uint256[] fromAccountAmounts,uint256 nonce,uint256 deadline)"
                    ),
                    to,
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts)),
                    keccak256(abi.encodePacked(data)),
                    ptFromAccount,
                    keccak256(abi.encodePacked(ptFromAccountReceivers)),
                    keccak256(abi.encodePacked(fromAccountAmounts)),
                    nonce,
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "Vouchers: Signature Mismatch"
        );
        isNonceUsed[nonce] = true;
        receivePayment(ptFromAccount, ptFromAccountReceivers, fromAccountAmounts);
        _mintBatch(to, ids, amounts, data);
        emit MintedWithNonce(msg.sender, nonce, ids, amounts, ptFromAccount, ptFromAccountReceivers, fromAccountAmounts);
    }

    function batchRedeemWithSignature(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Vouchers: Transaction overdue");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "RedeemData(address redeemer,uint256[] ids,uint256[] amounts,uint256 deadline)"
                    ),
                    msg.sender,
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts)),
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "Vouchers: Signature Mismatch"
        );
        _burnBatch(msg.sender, ids, amounts);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public ownerOrMinter {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public ownerOrMinter {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setStatusForMinter(address minter, bool newStatus) external onlyOwner {
        isMinter[minter] = newStatus;
    }

    function withdrawTokens(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Vouchers: transfer error"
        );
    }

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }
}