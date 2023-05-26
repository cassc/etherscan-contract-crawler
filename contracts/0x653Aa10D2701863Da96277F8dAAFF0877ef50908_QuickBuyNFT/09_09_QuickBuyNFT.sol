// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract QuickBuyNFT is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    address public finance;
    address public orderSinger;
    address public qualification;
    address public vault;
    uint256 public totalPay;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public BUYNFT_HASH;

    event BuyNft(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed count,
        uint256 pay,
        uint256[] tokenIds,
        string orderId
    );

    function initialize(address _finance, address _orderSinger, address _qualification, address _vault) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();

        uint256 chainId = block.chainid;

        finance = _finance;
        orderSinger = _orderSinger;
        qualification = _qualification;
        vault = _vault;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("QuickBuyNFT")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        BUYNFT_HASH = keccak256("buyNft(address from,address nftContract,uint256 price,uint256 expiration,uint256[] tokenIds,string orderId)");
    }

    function setFinance(address _newFinance) external onlyOwner {
        finance = _newFinance;
    }

    function setSinger(address _newSinger) external onlyOwner {
        orderSinger = _newSinger;
    }

    function setQualification(address _newQualification) external onlyOwner {
        qualification = _newQualification;
    }

    function setVault(address _newVault) external onlyOwner {
        vault = _newVault;
    }

    function checkBuyParas(
        address nftContract, 
        uint256[] memory tokenIds, 
        bytes memory signature, 
        uint256 price, 
        uint256 pay,
        uint256 expiration,
        string memory orderId
    ) internal view {
        require(tokenIds.length > 0, "invalid tokenid");
        require(price * tokenIds.length == pay, "check the pay");
        require(signature.length == 65, "invalid signature");
        require(expiration >= block.timestamp, "expiration order");

        if (qualification != address(0)) {
            require(IERC721(qualification).balanceOf(_msgSender()) > 0, "no qualifications");
        }
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        //buyNft(address from,address nftContract,uint256 price,uint256 expiration,uint256[] tokenIds,string orderId)
        bytes32 hashStruct = keccak256(
            abi.encode(
                BUYNFT_HASH,
                _msgSender(),
                nftContract,
                price,
                expiration,
                keccak256(abi.encodePacked(tokenIds)),
                keccak256(bytes(orderId))
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == orderSinger, "wrong signature");
    }

    function buyNft(
        address nftContract,
        uint256 price, 
        uint256 expiration,
        uint256[] memory tokenIds, 
        string memory orderId, 
        bytes memory signature
    ) external payable nonReentrant {
        checkBuyParas(nftContract, tokenIds, signature, price, msg.value, expiration, orderId);
        //transfer ETH
        payable(address(finance)).transfer(msg.value);
        totalPay += msg.value;
        uint256 tokenCount = tokenIds.length;

        //transfer nfts
        for (uint i = 0; i < tokenCount; i++) {
            IERC721(nftContract).safeTransferFrom(vault, _msgSender(), tokenIds[i]);
        }
        emit BuyNft(_msgSender(), nftContract, tokenCount, msg.value, tokenIds, orderId);
    }

    receive() external payable {
    }
}