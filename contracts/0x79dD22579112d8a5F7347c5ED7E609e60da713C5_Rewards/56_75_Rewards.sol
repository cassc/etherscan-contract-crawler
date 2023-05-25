// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Rewards is Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public claimedAmounts;
    
    event SignerSet(address newSigner);
    event Claimed(uint256 cycle, address recipient, uint256 amount);

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 chainId;
        uint256 cycle;
        address wallet;
        uint256 amount;
    }

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant RECIPIENT_TYPEHASH =
        keccak256("Recipient(uint256 chainId,uint256 cycle,address wallet,uint256 amount)");

    bytes32 private immutable domainSeparator;

    IERC20 public immutable tokeToken;
    address public rewardsSigner;

    constructor(IERC20 token, address signerAddress) public {
        require(address(token) != address(0), "Invalid TOKE Address");
        require(signerAddress != address(0), "Invalid Signer Address");
        tokeToken = token;
        rewardsSigner = signerAddress;

        domainSeparator = _hashDomain(
            EIP712Domain({
                name: "TOKE Distribution",
                version: "1",
                chainId: _getChainID(),
                verifyingContract: address(this)
            })
        );
    }

    function _hashDomain(EIP712Domain memory eip712Domain) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashRecipient(Recipient memory recipient) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RECIPIENT_TYPEHASH,
                    recipient.chainId,
                    recipient.cycle,
                    recipient.wallet,
                    recipient.amount
                )
            );
    }

    function _hash(Recipient memory recipient) private view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, _hashRecipient(recipient)));
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid Signer Address");
        rewardsSigner = newSigner;
    }

    function getClaimableAmount(
        Recipient calldata recipient
    ) external view returns (uint256) {
        return recipient.amount.sub(claimedAmounts[recipient.wallet]);
    }

    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s // bytes calldata signature
    ) external {        
        address signatureSigner = _hash(recipient).recover(v, r, s);
        require(signatureSigner == rewardsSigner, "Invalid Signature");
        require(recipient.chainId == _getChainID(), "Invalid chainId");        
        require(recipient.wallet == msg.sender, "Sender wallet Mismatch");

        uint256 claimableAmount = recipient.amount.sub(claimedAmounts[recipient.wallet]);

        require(claimableAmount > 0, "Invalid claimable amount");
        require(tokeToken.balanceOf(address(this)) >= claimableAmount, "Insufficient Funds");

        claimedAmounts[recipient.wallet] = claimedAmounts[recipient.wallet].add(claimableAmount);

        tokeToken.safeTransfer(recipient.wallet, claimableAmount);

        emit Claimed(recipient.cycle, recipient.wallet, claimableAmount);
    }
}