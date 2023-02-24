// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract FundRaiser is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                keccak256(bytes("OGMGod")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    uint256 totalMinted = 0;

    uint256 public totalSupply = 10000;

    mapping(address => uint256) public mintedByAddress;

    event Mint(address indexed owner, uint256[] tokenIds);

    uint256 public privateSalePrice;
    uint256 public publicSalePrice;

    address public masterAddress;

    bool public saleStatus = false;

    function changeMasterAddress(address newMasterAddress) external onlyOwner {
        masterAddress = newMasterAddress;
    }

    function changePrivateSalePrice(
        uint256 _privateSalePrice
    ) external onlyOwner {
        privateSalePrice = _privateSalePrice;
    }

    function changePublicSalePrice(
        uint256 _publicSalePrice
    ) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function changeSaleStatus(bool newStatus) external onlyOwner {
        saleStatus = newStatus;
    }

    function changeTotalSupply(uint256 newTotalSupply) external onlyOwner {
        totalSupply = newTotalSupply;
    }

    function _validateWhitelisted(
        address minter,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 PAYORDER_TYPEHASH = keccak256("PrivateMinter(address minter)");
        bytes32 structHash = keccak256(abi.encode(PAYORDER_TYPEHASH, minter));
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

        address recoveredAddress = ECDSA.recover(digest, signature);
        return recoveredAddress;
    }

    function mint(
        uint256 amount,
        bytes memory signature
    ) public payable nonReentrant {
        require(saleStatus, "Not an active Sale");
        require(
            totalMinted + amount <= totalSupply,
            "Mint Will Exceed Collection Size"
        );

        if (_validateWhitelisted(msg.sender, signature) == masterAddress) {
            require(
                msg.value >= amount.mul(privateSalePrice),
                "Need to send more Eth"
            );
        } else {
            require(
                msg.value >= amount.mul(publicSalePrice),
                "Need to send more Eth"
            );
        }
        uint startingTokenId = totalMinted;
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 index = 0; index < amount; index++) {
            tokenIds[index] = startingTokenId + index + 1;
        }
        totalMinted += amount;
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        mintedByAddress[msg.sender] += amount;
        require(success, "Transfer failed.");
        emit Mint(msg.sender, tokenIds);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}