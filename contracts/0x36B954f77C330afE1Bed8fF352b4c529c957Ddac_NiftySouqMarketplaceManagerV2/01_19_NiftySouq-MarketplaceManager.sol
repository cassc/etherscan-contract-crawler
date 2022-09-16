// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interface/NiftySouq-IERC721.sol";
import "./interface/NiftySouq-IERC1155.sol";
import "./interface/NiftySouq-INftV1.sol";

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
}

struct LazyMintAuctionData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}
struct CalculatePayout1155 {
    uint256 price;
    uint256 totalSupply;
    uint256 quantity;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 firstSaleQuantity;
}

contract NiftySouqMarketplaceManagerV2 is
    EIP712Upgradeable,
    AccessControlUpgradeable
{
    using SafeMath for uint256;
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public owner;

    NiftySouqINftV1 private _niftySouqErc721V1;
    NiftySouqINftV1 private _niftySouqErc1155V1;
    NiftySouqIERC721V2 private _niftySouqErc721V2;
    NiftySouqIERC1155V2 private _niftySouqErc1155V2;

    address public serviceFeeWallet;
    uint256 public serviceFeePercent;
    uint256 public constant PERCENT_UNIT = 1e4;

    string[] public cryptoTokens;
    uint256 public cryptoTokenCount;
    mapping(string => CryptoTokens) public cryptoTokenList;

    function initialize(
        string memory name_,
        string memory version_,
        address serviceFeeWallet_,
        uint256 serviceFeePercentage_,
        address weth_
    ) public initializer {
        __EIP712_init(name_, version_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        owner = msg.sender;
        serviceFeeWallet = serviceFeeWallet_;
        serviceFeePercent = serviceFeePercentage_;
        if (weth_ != address(0)) {
            cryptoTokenList["weth"] = CryptoTokens(weth_, 1, true);
            cryptoTokens.push("weth");
            cryptoTokenCount = cryptoTokenCount + 1;
        }
    }

    function setContractAddress(
        address niftySouqErc721V1_,
        address niftySouqErc1155V1_,
        address niftySouqErc721V2_,
        address niftySouqErc1155V2_
    ) external {
        if (niftySouqErc721V1_ != address(0))
            _niftySouqErc721V1 = NiftySouqINftV1(niftySouqErc721V1_);
        if (niftySouqErc1155V1_ != address(0))
            _niftySouqErc1155V1 = NiftySouqINftV1(niftySouqErc1155V1_);
        if (niftySouqErc721V2_ != address(0))
            _niftySouqErc721V2 = NiftySouqIERC721V2(niftySouqErc721V2_);
        if (niftySouqErc1155V2_ != address(0))
            _niftySouqErc1155V2 = NiftySouqIERC1155V2(niftySouqErc1155V2_);
    }

    function isAdmin(address caller_) public view returns (bool) {
        if (
            hasRole(DEFAULT_ADMIN_ROLE, caller_) || hasRole(ADMIN_ROLE, caller_)
        ) return true;
        else return false;
    }

    function verifyFixedPriceLazyMint(LazyMintSellData calldata lazyData_)
        external
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "LazyMintData(string uri,address[] creators,uint256[] royalties,address[] investors,uint256[] revenues,uint256 minPrice,uint256 quantity)"
                    ),
                    keccak256(abi.encodePacked(lazyData_.uri)),
                    keccak256(abi.encodePacked(lazyData_.creators)),
                    keccak256(abi.encodePacked(lazyData_.royalties)),
                    keccak256(abi.encodePacked(lazyData_.investors)),
                    keccak256(abi.encodePacked(lazyData_.revenues)),
                    lazyData_.minPrice,
                    lazyData_.quantity
                )
            )
        );
        return digest.toEthSignedMessageHash().recover(lazyData_.signature);
    }

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "LazyMintAuctionData(string uri,address[] creators,uint256[] royalties,address[] investors,uint256[] revenues,uint256 startTime,uint256 duration,uint256 startBidPrice,uint256 reservePrice)"
                    ),
                    keccak256(abi.encodePacked(lazyData_.uri)),
                    keccak256(abi.encodePacked(lazyData_.creators)),
                    keccak256(abi.encodePacked(lazyData_.royalties)),
                    keccak256(abi.encodePacked(lazyData_.investors)),
                    keccak256(abi.encodePacked(lazyData_.revenues)),
                    lazyData_.startTime,
                    lazyData_.duration,
                    lazyData_.startBidPrice,
                    lazyData_.reservePrice
                )
            )
        );
        return digest.toEthSignedMessageHash().recover(lazyData_.signature);
    }

    function getContractDetails(address contractAddress_, uint256 quantity_)
        public
        returns (ContractType contractType_, bool isERC1155_, address tokenAddress_)
    {
        if (contractAddress_ == address(0) && quantity_ > 1) {
            contractAddress_ = address(_niftySouqErc1155V2);
            return (ContractType.NIFTY_V2, true, contractAddress_);
        } else if (contractAddress_ == address(0) && quantity_ == 1) {
            contractAddress_ = address(_niftySouqErc721V2);
            return (ContractType.NIFTY_V2, false, contractAddress_);
        } else if (contractAddress_ == address(_niftySouqErc721V1))
            return (ContractType.NIFTY_V1, false, contractAddress_);
        else if (contractAddress_ == address(_niftySouqErc1155V1))
            return (ContractType.NIFTY_V1, true, contractAddress_);
        else if (contractAddress_ == address(_niftySouqErc721V2))
            return (ContractType.NIFTY_V2, false, contractAddress_);
        else if (contractAddress_ == address(_niftySouqErc1155V2))
            return (ContractType.NIFTY_V2, true, contractAddress_);
        else {
            bytes memory payload = abi.encodeWithSignature(
                "isCollectionContract()"
            );
            (bool success, bytes memory returnData) = contractAddress_.call(
                payload
            );
            bool approved = abi.decode(returnData, (bool));
            if (success && approved) return (ContractType.COLLECTOR, false, contractAddress_);
            else {
                if (_is721(contractAddress_))
                    return (ContractType.EXTERNAL, false, contractAddress_);
                else if (_is1155(contractAddress_))
                    return (ContractType.EXTERNAL, true, contractAddress_);
                else return (ContractType.UNSUPPORTED, true, contractAddress_);
            }
        }
    }

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        public
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        )
    {
        (contractType_, isERC1155_, contractAddress_) = getContractDetails(contractAddress_, 1);
        if (!isERC1155_ && contractType_ != ContractType.UNSUPPORTED) {
            address NftOwner = IERC721(contractAddress_).ownerOf(tokenId_);
            isOwner_ = NftOwner == address_ ? true : false;
            quantity_ = NftOwner == address_ ? 1 : 0;
        } else if (isERC1155_ && contractType_ != ContractType.UNSUPPORTED) {
            quantity_ = IERC1155(contractAddress_).balanceOf(
                address_,
                tokenId_
            );
            isOwner_ = quantity_ > 0 ? true : false;
        }
    }

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        )
    {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = isOwnerOfNFT(
                calculatePayout_.seller,
                calculatePayout_.tokenId,
                calculatePayout_.contractAddress
            );
        isOwner_ = isOwner;
        isTokenTransferable_ = _isNftTransferApproved(
            calculatePayout_.seller,
            calculatePayout_.contractAddress
        );
        if (contractType == ContractType.NIFTY_V2 && !isERC1155) {
            (recepientAddresses_, paymentAmount_) = _payoutNiftyV2Erc721(
                calculatePayout_.contractAddress,
                calculatePayout_.tokenId,
                calculatePayout_.seller,
                calculatePayout_.price
            );
        } else if (contractType == ContractType.NIFTY_V2 && isERC1155) {
            require(
                calculatePayout_.quantity <= quantity,
                "Insufficent quantity"
            );
            NiftySouqIERC1155V2.NftData memory nftData = NiftySouqIERC1155V2(
                calculatePayout_.contractAddress
            ).getNftInfo(calculatePayout_.tokenId);
            uint256 nftTotalSupply = NiftySouqIERC1155V2(
                calculatePayout_.contractAddress
            ).totalSupply(calculatePayout_.tokenId);
            (recepientAddresses_, paymentAmount_) = _payoutNiftyV2Erc1155(
                CalculatePayout1155(
                    calculatePayout_.price,
                    nftTotalSupply,
                    calculatePayout_.quantity,
                    calculatePayout_.seller,
                    nftData.creators,
                    nftData.royalties,
                    nftData.investors,
                    nftData.revenues,
                    nftData.firstSaleQuantity
                )
            );
        } else if (contractType == ContractType.NIFTY_V1) {
            if (calculatePayout_.quantity > quantity && isERC1155)
                revert("Insufficent quantity");
            (recepientAddresses_, paymentAmount_) = _payoutNiftyV1Nft(
                calculatePayout_.contractAddress,
                calculatePayout_.tokenId,
                calculatePayout_.seller,
                calculatePayout_.price,
                calculatePayout_.quantity
            );
        } else {
            (recepientAddresses_, paymentAmount_) = _payoutExternalNft(
                calculatePayout_.seller,
                calculatePayout_.price
            );
        }
    }

    function _payoutNiftyV2Erc721(
        address contractAddress_,
        uint256 tokenId_,
        address seller_,
        uint256 price_
    )
        internal
        view
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        NiftySouqIERC721V2.NftData memory nftData = NiftySouqIERC721V2(
            contractAddress_
        ).getNftInfo(tokenId_);
        uint256 j = 0;
        uint256 adminfee;
        uint256[] memory payoutFees;
        uint256 netfee;
        if (nftData.isFirstSale) {
            recepientAddresses_ = new address[](
                nftData.investors.length.add(2)
            );
            paymentAmount_ = new uint256[](nftData.investors.length.add(2));
            (adminfee, payoutFees, netfee) = _calculatePayout(
                price_,
                serviceFeePercent,
                nftData.revenues
            );
            for (uint256 i = 0; i < nftData.investors.length; i++) {
                recepientAddresses_[j] = nftData.investors[i];
                paymentAmount_[j] = payoutFees[i];
                j = j.add(1);
            }
        } else {
            recepientAddresses_ = new address[](nftData.creators.length.add(2));
            paymentAmount_ = new uint256[](nftData.creators.length.add(2));
            (adminfee, payoutFees, netfee) = _calculatePayout(
                price_,
                serviceFeePercent,
                nftData.royalties
            );
            for (uint256 i = 0; i < nftData.creators.length; i++) {
                recepientAddresses_[j] = nftData.creators[i];
                paymentAmount_[j] = payoutFees[i];
                j = j.add(1);
            }
        }
        recepientAddresses_[j] = serviceFeeWallet;
        paymentAmount_[j] = adminfee;
        j = j.add(1);

        recepientAddresses_[j] = seller_;
        paymentAmount_[j] = netfee;
        j = j.add(1);
    }

    function _payoutNiftyV2Erc1155(
        CalculatePayout1155 memory calculatePayout1155_
    )
        internal
        view
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        uint256 j = 0;
        uint256 adminfee;
        uint256 netfee;
        if (
            calculatePayout1155_.firstSaleQuantity.add(
                calculatePayout1155_.quantity
            ) <= calculatePayout1155_.totalSupply
        ) {
            CalculatePayout1155
                memory calculatePayout1155 = calculatePayout1155_;

            {
                recepientAddresses_ = new address[](
                    calculatePayout1155.investors.length.add(2)
                );
                paymentAmount_ = new uint256[](
                    calculatePayout1155.investors.length.add(2)
                );
            }
            (
                uint256 adminfee__,
                uint256[] memory payoutFees__,
                uint256 netfee__
            ) = _calculatePayout(
                    calculatePayout1155.price.mul(calculatePayout1155.quantity),
                    serviceFeePercent,
                    calculatePayout1155.revenues
                );
            for (uint256 i = 0; i < calculatePayout1155.investors.length; i++) {
                recepientAddresses_[j] = calculatePayout1155.investors[i];
                paymentAmount_[j] = payoutFees__[i];
                j = j.add(1);
            }
            adminfee = adminfee__;
            netfee = netfee__;
        } else if (
            calculatePayout1155_.firstSaleQuantity <=
            calculatePayout1155_.totalSupply
        ) {
            CalculatePayout1155
                memory calculatePayout1155 = calculatePayout1155_;

            uint256 investorBeneficiaryQuantity = calculatePayout1155
                .totalSupply
                .sub(calculatePayout1155.firstSaleQuantity);
            uint256 creatorBeneficiaryQuantity = (calculatePayout1155.quantity)
                .sub(investorBeneficiaryQuantity);
            {
                recepientAddresses_ = new address[](
                    (calculatePayout1155.investors.length)
                        .add(calculatePayout1155.creators.length)
                        .add(2)
                );
                paymentAmount_ = new uint256[](
                    (calculatePayout1155.investors.length)
                        .add(calculatePayout1155.creators.length)
                        .add(2)
                );
            }
            (
                uint256 adminfee1__,
                uint256[] memory payoutFees1__,
                uint256 netfee1__
            ) = _calculatePayout(
                    calculatePayout1155.price.mul(investorBeneficiaryQuantity),
                    serviceFeePercent,
                    calculatePayout1155.revenues
                );
            for (uint256 i = 0; i < calculatePayout1155.investors.length; i++) {
                recepientAddresses_[j] = calculatePayout1155.investors[i];
                paymentAmount_[j] = payoutFees1__[i];
                j = j.add(1);
            }

            (
                uint256 adminfee2__,
                uint256[] memory payoutFees2__,
                uint256 netfee2__
            ) = _calculatePayout(
                    calculatePayout1155.price.mul(creatorBeneficiaryQuantity),
                    serviceFeePercent,
                    calculatePayout1155.royalties
                );
            for (uint256 i = 0; i < calculatePayout1155.creators.length; i++) {
                recepientAddresses_[j] = calculatePayout1155.creators[i];
                paymentAmount_[j] = payoutFees2__[i];
                j = j.add(1);
            }
            adminfee = adminfee1__.add(adminfee2__);
            netfee = netfee1__.add(netfee2__);
        } else {
            CalculatePayout1155
                memory calculatePayout1155 = calculatePayout1155_;

            {
                recepientAddresses_ = new address[](
                    calculatePayout1155.creators.length.add(2)
                );
                paymentAmount_ = new uint256[](
                    calculatePayout1155.creators.length.add(2)
                );
            }
            (
                uint256 adminfee__,
                uint256[] memory payoutFees__,
                uint256 netfee__
            ) = _calculatePayout(
                    calculatePayout1155.price.mul(calculatePayout1155.quantity),
                    serviceFeePercent,
                    calculatePayout1155.royalties
                );
            for (uint256 i = 0; i < calculatePayout1155.creators.length; i++) {
                recepientAddresses_[j] = calculatePayout1155.creators[i];
                paymentAmount_[j] = payoutFees__[i];
                j = j.add(1);
            }
            adminfee = adminfee__;
            netfee = netfee__;
        }

        recepientAddresses_[j] = serviceFeeWallet;
        paymentAmount_[j] = adminfee;
        j = j.add(1);

        recepientAddresses_[j] = calculatePayout1155_.seller;
        paymentAmount_[j] = netfee;
        j = j.add(1);
    }

    function _payoutNiftyV1Nft(
        address contractAddress_,
        uint256 tokenId_,
        address seller_,
        uint256 price_,
        uint256 quantity_
    )
        internal
        view
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        uint256 j = 0;
        uint256 adminfee;
        uint256[] memory payoutFees;
        uint256 netfee;

        NiftySouqINftV1.TokenData memory tokenData = NiftySouqINftV1(
            contractAddress_
        ).getTokenData(tokenId_);

        if (tokenData.creators.length == tokenData.royalties.length) {
            recepientAddresses_ = new address[](
                tokenData.creators.length.add(2)
            );
            paymentAmount_ = new uint256[](tokenData.creators.length.add(2));
            (adminfee, payoutFees, netfee) = _calculatePayout(
                price_.mul(quantity_),
                serviceFeePercent,
                tokenData.royalties
            );
            for (uint256 i = 0; i < tokenData.creators.length; i++) {
                recepientAddresses_[j] = tokenData.creators[i];
                paymentAmount_[j] = payoutFees[i];
                j = j.add(1);
            }
        } else {
            recepientAddresses_ = new address[](2);
            paymentAmount_ = new uint256[](2);
        }

        recepientAddresses_[j] = serviceFeeWallet;
        paymentAmount_[j] = adminfee;
        j = j + 1;

        recepientAddresses_[j] = seller_;
        paymentAmount_[j] = price_.sub(netfee);
        j = j + 1;
    }

    function _payoutExternalNft(address seller_, uint256 price_)
        internal
        view
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        recepientAddresses_ = new address[](2);
        paymentAmount_ = new uint256[](2);
        uint256 serviceFee_ = _percent(price_, serviceFeePercent);

        recepientAddresses_[0] = serviceFeeWallet;
        paymentAmount_[0] = serviceFee_;

        recepientAddresses_[1] = seller_;
        paymentAmount_[1] = price_.sub(serviceFee_);
    }

    function _isNftTransferApproved(address seller_, address nftContract_)
        internal
        view
        returns (bool)
    {
        return IERC721(nftContract_).isApprovedForAll(seller_, msg.sender);
    }

    function _calculatePayout(
        uint256 price_,
        uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        serviceFee_ = _percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = _percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum.add(royalFee);
        }

        netFee_ = price_.sub(serviceFee_).sub(payoutSum);
    }

    function _percent(uint256 value_, uint256 percentage_)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    function _checkInterface(address tokenContract, bytes4 interfaceId)
        private
        returns (bool)
    {
        bytes memory payload = abi.encodeWithSignature(
            "supportsInterface(bytes4)",
            interfaceId
        );
        (bool success, bytes memory returnData) = tokenContract.call(payload);
        require(success == true, "invalid contract");

        bool result = abi.decode(returnData, (bool));
        return result;
    }

    function _is721(address tokenContract) internal returns (bool) {
        return _checkInterface(tokenContract, type(IERC721).interfaceId);
    }

    function _is1155(address tokenContract) internal returns (bool) {
        return _checkInterface(tokenContract, type(IERC1155).interfaceId);
    }
}