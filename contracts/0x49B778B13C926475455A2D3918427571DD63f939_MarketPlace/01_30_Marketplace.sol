// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./AccessControl.sol";
import "./ERC721/ERC721.sol";

contract MarketPlace is
    Initializable,
    PausableUpgradeable,
    GenericAccessControl,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    EIP712Upgradeable
{
    //EIP-2981 InterfaceId
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address public feeAddress;
    ///@dev FeesPercent has two decimal points
    uint256 public feePercent;
    //Name of the token
    string public name;
    //Symbol of the token
    string public symbol;

    IERC20 weth;

    struct MarketplaceVoucher {
        //Owner of the tokenId
        address owner;
        uint256 minPrice;
        //1= Fixed Auction, 2= Unlimited Auction, 3= TimedAuction
        uint256 auctionType;
        uint256 quantity;
        uint256 endTime;
        address tokenContract;
        uint256 salt;
        bytes signature;
    }

    struct AuctionDetails {
        uint256 totalListedQuantity;
        uint256 quantityLeft;
    }

    //Salt -> AuctionDetails
    mapping(uint256 => AuctionDetails) public auctionDetails;

    modifier OnlySeller(address seller) {
        require(seller == msg.sender, "Only Seller can call this function");
        _;
    }

    modifier AuctionTimeIsOver(uint256 endTime) {
        require(
            endTime <= block.timestamp,
            "Cannot finalise auction before endtime"
        );
        _;
    }

    event LogOrderFinalised721(
        uint256 auctionType,
        uint256 tokenId,
        address buyer,
        address seller
    );
    event LogOrderFinalised1155(
        uint256 auctionType,
        uint256 tokenId,
        address buyer,
        address seller,
        uint256 quantity
    );

    event LogFeeAddressUpdated(address newAddress, address senderAddress);
    event LogFeeUpdated(
        address feeAddress,
        uint256 feePercent,
        address senderAddress
    );
    event RoyaltiesPaid(uint256 tokenId, uint256 value);

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory signDomain,
        string memory signVersion,
        address _feeAddress,
        address[] memory _whitelistAddresses,
        uint256 _feePercent,
        address _wethAddr
    ) public initializer {
        name = _name;
        symbol = _symbol;
        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(signDomain, signVersion);
        __GenericAccessControl_init(_whitelistAddresses);

        feeAddress = _feeAddress;
        feePercent = _feePercent;
        weth = IERC20(_wethAddr);
    }

    /// @notice Transfers royalties to the rightsowner if applicable
    /// @param tokenId - the NFT assed queried for royalties
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @return netSaleAmount - the value that will go to the seller after
    ///         deducting royalties
    function _deduceRoyalties721(
        uint256 tokenId,
        uint256 grossSaleValue,
        address buyer,
        GenericERC721 tokenContract721
    ) internal returns (uint256 netSaleAmount) {
        // Get amount of royalties to pays and recipient
        (address royaltiesReceiver, uint256 royaltiesAmount) = tokenContract721
            .royaltyInfo(tokenId, grossSaleValue);
        // Deduce royalties from sale value
        uint256 netSaleValue = grossSaleValue - royaltiesAmount;
        // Transfer royalties to rightholder if not zero
        if (royaltiesAmount > 0) {
            weth.transferFrom(buyer, royaltiesReceiver, royaltiesAmount);
        }
        // Broadcast royalties payment
        emit RoyaltiesPaid(tokenId, royaltiesAmount);
        return netSaleValue;
    }

    function updateFeePercent(uint256 _feePercent) public OnlyAdmin {
        require(feeAddress == _msgSender(), "You are not a fee owner");
        feePercent = _feePercent;
        emit LogFeeUpdated(feeAddress, feePercent, _msgSender());
    }

    function updateFeeAddress(address _newFeeAddress) public OnlyAdmin {
        require(feeAddress == _msgSender(), "You are not a fee address owner");
        feeAddress = _newFeeAddress;
        emit LogFeeAddressUpdated(feeAddress, _msgSender());
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _hash(MarketplaceVoucher memory voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "MarketplaceVoucher(address owner,uint256 minPrice,uint256 auctionType,uint256 quantity,uint256 endTime,address tokenContract,uint256 salt)"
                        ),
                        voucher.owner,
                        voucher.minPrice,
                        voucher.auctionType,
                        voucher.quantity,
                        voucher.endTime,
                        voucher.tokenContract,
                        voucher.salt
                    )
                )
            );
    }

    function verifySignatureAndQuantityAvailable(
        address _owner,
        uint256[] memory otherParams,
        bytes memory signature,
        address tokenAddr,
        uint256 quantity
    ) internal returns (address) {
        MarketplaceVoucher memory voucher = MarketplaceVoucher({
            owner: _owner,
            minPrice: otherParams[1],
            auctionType: otherParams[2],
            quantity: otherParams[3],
            endTime: otherParams[4],
            tokenContract: tokenAddr,
            salt: otherParams[5],
            signature: signature
        });
        bytes32 digest = _hash(voucher);
        address seller = ECDSA.recover(digest, voucher.signature);
        require(seller == voucher.owner, "The seller is not the owner");
        if (auctionDetails[otherParams[5]].totalListedQuantity == 0) {
            auctionDetails[otherParams[5]] = AuctionDetails({
                totalListedQuantity: otherParams[3],
                quantityLeft: otherParams[3]
            });
        }
        require(
            quantity <= auctionDetails[otherParams[5]].quantityLeft,
            "Cannot buy more than available"
        );
        auctionDetails[otherParams[5]].quantityLeft -= quantity;
        return seller;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function finaliseFixedPriceAuction721(
        address _owner,
        /**
				0:_tokenId,1:_minPrice,2:_auctionType,3:_quantity,4:endTime,5:salt
				 */
        uint256[] memory otherParams,
        bytes memory signature,
        address tokenContract
    ) public {
        require(otherParams[2] == 1, "Auction needs to be Fixed Price");
        require(otherParams[3] == 1, "Cannot have more than one copy for 721");

        address seller = verifySignatureAndQuantityAvailable(
            _owner,
            otherParams,
            signature,
            tokenContract,
            1
        );
        GenericERC721 tokenContract721 = GenericERC721(tokenContract);
        uint256 feeAmt = (otherParams[1] * feePercent) / 100;
        uint256 netSalePrice = _deduceRoyalties721(
            otherParams[0],
            otherParams[1],
            _msgSender(),
            tokenContract721
        );
        weth.transferFrom(_msgSender(), feeAddress, feeAmt);
        weth.transferFrom(_msgSender(), seller, netSalePrice);
        tokenContract721.safeTransferFrom(seller, _msgSender(), otherParams[0]);
        emit LogOrderFinalised721(
            otherParams[2],
            otherParams[0],
            _msgSender(),
            seller
        );
    }

    //For Unlimited and TimedAuctions
    function finaliseERC721Auction(
        address buyer,
        address owner,
        /**
				0:_tokenId,1:_minPrice,2:_auctionType,3:_quantity,4:endTime,5:salt
				 */
        uint256[] memory otherParams,
        bytes memory signature,
        uint256 bidAmount,
        address tokenContract
    )
        public
        OnlySeller(owner)
        AuctionTimeIsOver(otherParams[4])
        returns (bool)
    {
        require(
            otherParams[2] == 2 || otherParams[2] == 3,
            "Only Unlimited and Timed Auctions can be Finalised"
        );
        require(otherParams[3] == 1, "Cannot have more than one copy for 721");
        address seller = verifySignatureAndQuantityAvailable(
            owner,
            otherParams,
            signature,
            tokenContract,
            1
        );
        GenericERC721 tokenContract721 = GenericERC721(tokenContract);
        uint256 feeAmt = (bidAmount * feePercent) / (100 + feePercent);

        uint256 netSalePrice = _deduceRoyalties721(
            otherParams[0],
            bidAmount - feeAmt,
            buyer,
            tokenContract721
        );
        weth.transferFrom(buyer, feeAddress, feeAmt);

        //Transfer amount to seller after deducting loyalties
        weth.transferFrom(buyer, seller, netSalePrice);

        //Transfer NFT to the bidder
        tokenContract721.safeTransferFrom(seller, buyer, otherParams[0]);
        emit LogOrderFinalised721(
            otherParams[2],
            otherParams[0],
            buyer,
            seller
        );
        return true;
    }
}