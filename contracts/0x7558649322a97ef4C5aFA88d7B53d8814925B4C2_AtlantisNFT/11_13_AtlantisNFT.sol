// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract AtlantisNFT is ERC721A, Ownable, PaymentSplitter, EIP712 {
    error NotEnoughFund();
    error ExceedBatchSize();
    error ExceedStageSupply();
    error SizeNotMatched();
    error InvalidSignature();

    string public constant contractURI = "ipfs://QmVsqU1eruYMEYPDmK1Vut28w54FZGDCjk6p7wTazjvYYs";

    uint256 private constant BATCH_SIZE = 5;

    uint256 private constant TOTAL_SHARES = 10;

    uint256 private constant CREATOR_SHARES = 3;

    address private constant GALLERY_WALLET_ADDRESS =
        0xd1ba56E563944f0312ddD1F4c44adbECd0d28b97;

    uint256 private constant GALLERY_SHARES = 1;

    struct SaleInfo {
        uint32 stageSupply;
        uint224 mintPrice;
    }
    SaleInfo public saleInfo;

    struct CreatorInfo {
        address account;
        uint8 hasGallery;
        uint32 tokenId;
    }

    string private __baseURI;

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory initBaseURI,
        SaleInfo memory initSaleInfo
    )
        ERC721A("Atlantis-P", "AT-P")
        PaymentSplitter(payees, shares)
        EIP712("Atlantis", "1.0")
    {
        __baseURI = initBaseURI;
        saleInfo = initSaleInfo;
    }

    function mint(
        uint256 amount,
        CreatorInfo[] calldata creatorInfos,
        bytes[] calldata signatures
    ) external payable {
        if (amount > BATCH_SIZE) revert ExceedBatchSize();
        if (msg.value < amount * saleInfo.mintPrice) revert NotEnoughFund();
        uint256 nextId = _nextTokenId();
        if (nextId + amount > saleInfo.stageSupply) revert ExceedStageSupply();
        if (creatorInfos.length != amount || signatures.length != amount)
            revert SizeNotMatched();
        _safeMint(msg.sender, amount);
        uint256 creatorRewards = (saleInfo.mintPrice * CREATOR_SHARES) / TOTAL_SHARES;
        for (uint256 i = 0; i < amount; ++i) {
            CreatorInfo calldata creatorInfo = creatorInfos[i];
            _verify(creatorInfo, signatures[i], nextId + i);
            if (creatorInfo.hasGallery == 0) {
                Address.sendValue(payable(creatorInfo.account), creatorRewards);
            } else {
                uint256 galleryReward = (creatorRewards * GALLERY_SHARES) /
                    CREATOR_SHARES;
                Address.sendValue(
                    payable(GALLERY_WALLET_ADDRESS),
                    galleryReward
                );
                Address.sendValue(
                    payable(creatorInfo.account),
                    creatorRewards - galleryReward
                );
            }
        }
    }

    function updateSaleInfo(SaleInfo calldata newSaleInfo) external onlyOwner {
        saleInfo = newSaleInfo;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _verify(
        CreatorInfo calldata creatorInfo,
        bytes calldata signature,
        uint256 tokenId
    ) private view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "CreatorInfo(address account,uint8 hasGallery,uint32 tokenId)"
                    ),
                    creatorInfo.account,
                    creatorInfo.hasGallery,
                    tokenId
                )
            )
        );
        if (owner() != ECDSA.recover(digest, signature)) {
            revert InvalidSignature();
        }
    }
}