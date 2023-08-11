// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interface/IRoyaltyInfo.sol";
import "./interface/ITransferProxy.sol";

contract Trade is AccessControl {
    enum BuyingAssetType {
        ERC1155,
        ERC721,
        LazyERC1155,
        LazyERC721
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    event ExecuteBid(
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    event SignerChanged(
        address indexed previousSigner,
        address indexed newSigner
    );
    // buyer platformFee
    uint8 private buyerFeePermille;
    //seller platformFee
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    //contract owner
    address public owner;
    //contract signer
    address public signer;

    mapping(uint256 => bool) private usedNonce;
    mapping (uint256 => Asset1155) users;

    struct Asset1155 {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 supply;
        bool status;
    }


    /** Fee Struct
        @param platformFee  uint256 (buyerFee + sellerFee) value which is transferred to current contract owner.
        @param assetFee  uint256  assetvalue which is transferred to current seller of the NFT.
        @param royaltyFee  uint256 value, transferred to Minter of the NFT.
        @param price  uint256 value, the combination of buyerFee and assetValue.
        @param royalityReceiver address value, it's store the royalityReceiver of NFT.
     */
    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint96[] royaltyFee;
        uint256 price;
        address[] royalityReceiver;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    /** Order Params
        @param seller address of user,who's selling the NFT.
        @param buyer address of user, who's buying the NFT.
        @param erc20Address address of the token, which is used as payment token(WETH/WBNB/WMATIC...)
        @param nftAddress address of NFT contract where the NFT token is created/Minted.
        @param nftType an enum value, if the type is ERC721/ERC1155 the enum value is 0/1.
        @param uintprice the Price Each NFT it's not including the buyerFee.
        @param amout the price of NFT(assetFee + buyerFee).
        @param tokenId 
        @param qty number of quantity to be transfer.
        @param isOwnCollection boolean, whether collection is own or not
     */
    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        bool skipRoyalty;
        uint256 amount;
        uint256 tokenId;
        uint256 supply;
        uint256 qty;
        string tokenURI;
        uint96[] royaltyFee;
        address[] receivers;
        bool isOwnCollection;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        address _signer,
        ITransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = _signer;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("SIGNER_ROLE", signer);
    }

    /**
        returns the buyerservice Fee in multiply of 1000.
     */

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    /**
        returns the sellerservice Fee in multiply of 1000.
     */

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    /** 
        @param _buyerFee  value for buyerservice in multiply of 1000.
    */

    function setBuyerServiceFee(uint8 _buyerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    /** 
        @param _sellerFee  value for buyerservice in multiply of 1000.
    */

    function setSellerServiceFee(uint8 _sellerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    /**
        transfers the contract ownership to newowner address.    
        @param newOwner address of newOwner
     */

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }


    function changeSigner(address newSigner)
        external
        onlyRole("SIGNER_ROLE")
        returns (bool)
    {
        require(
            newSigner != address(0),
            "Ownable: new signer is the zero address"
        );
        _revokeRole("SIGNER_ROLE", signer);
        emit SignerChanged(signer, newSigner);
        signer = newSigner;
        _setupRole("SIGNER_ROLE", newSigner);
        return true;
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function buyAsset(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        updateNonce(order, sign.nonce);
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.supply,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function executeBid(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    function mintAndBuyAsset(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.supply,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

    function mintAndExecuteBid(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    function updateNonce(Order calldata order, uint256 nonce) internal {
        if(order.nftType == BuyingAssetType.ERC721) {
            usedNonce[nonce] = true;
        }
        if(order.nftType == BuyingAssetType.ERC1155) {
            if(users[nonce].status) {
                require(users[nonce].nftAddress == order.nftAddress && users[nonce].seller == order.seller && users[nonce].tokenId == order.tokenId, "Nonce: Invalid Data");
                require(users[nonce].supply >= order.qty, "Invalid Quantity");
                users[nonce].supply -= order.qty;
                if(users[nonce].supply == 0)
                    usedNonce[nonce] = true;
            } else if(!users[nonce].status) {
                require(order.supply >= order.qty, "Invalid Quantity");
                users[nonce] = Asset1155(order.seller, order.nftAddress, order.tokenId, order.supply - order.qty, true);
            }
        }
    }

    /**
        returns the signer of given signature.
     */
    function getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    function verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 supply,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                supply,
                sign.nonce
            )
        );
        require(
            seller == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function verifyBuyerSign(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            buyer == getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    function verifyOwnerSign(
        address seller,
        string memory tokenURI,
        address assetAddress,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                this,
                assetAddress,
                seller,
                tokenURI,
                sign.nonce
            )
        );
        require(
            signer == getSigner(hash, sign),
            "owner sign verification failed"
        );
    }


    /**
        it retuns platformFee, assetFee, royaltyFee, price and tokencreator.
     */

    function getFees(
        Order calldata order
    ) internal view returns (Fee memory) {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royalty;
        uint96[] memory _royaltyFee;
        address[] memory _royalityReceiver;
        uint256 price = (order.amount * 1000) / (1000 + buyerFeePermille);
        uint256 buyerFee = order.amount - price;
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        if(!order.skipRoyalty && ((order.nftType == BuyingAssetType.ERC721) || (order.nftType == BuyingAssetType.ERC1155))) {   
            if(order.isOwnCollection){
                address _ownCollectionRoyaltyReceiver;
                _royaltyFee = new uint96[](1);
                _royalityReceiver = new address[](1);
                (_ownCollectionRoyaltyReceiver,royalty) = IERC2981(order.nftAddress).royaltyInfo(order.tokenId, price);
                _royaltyFee[0] = uint96(royalty);
                _royalityReceiver[0] = _ownCollectionRoyaltyReceiver;
            }
            else{
            (_royaltyFee, _royalityReceiver, royalty) = IRoyaltyInfo(order.nftAddress)
                .royaltyInfo(order.tokenId, price);
            }
        }
        if(!order.skipRoyalty && ((order.nftType == BuyingAssetType.LazyERC721) || (order.nftType == BuyingAssetType.LazyERC1155))) {
                _royaltyFee = new uint96[](order.royaltyFee.length);
                _royalityReceiver = new address[](order.receivers.length);
                for(uint256 i = 0; i < order.receivers.length; i++) {
                    royalty += uint96(price * order.royaltyFee[i] / 1000);
                    (_royalityReceiver[i], _royaltyFee[i]) = (order.receivers[i], uint96(price * order.royaltyFee[i] / 1000));
                }
        }
        assetFee = price - royalty - sellerFee;
        return Fee(platformFee, assetFee, _royaltyFee, price, _royalityReceiver);
    }

    /** 
        transfers the NFTs and tokens...
        @param order ordervalues(seller, buyer,...).
        @param fee Feevalues(platformFee, assetFee,...).
    */

    function tradeAsset(
        Order calldata order,
        Fee memory fee,
        address buyer,
        address seller
    ) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(
                IERC721(order.nftAddress),
                seller,
                buyer,
                order.tokenId
            );
        }
        if (order.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(order.nftAddress),
                seller,
                buyer,
                order.tokenId,
                order.qty,
                ""
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC721) {
            transferProxy.mintAndSafe721Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC1155) {
            transferProxy.mintAndSafe1155Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers,
                order.supply,
                order.qty
            );
        }

        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                owner,
                fee.platformFee
            );
        }

        for(uint96 i = 0; i < fee.royalityReceiver.length; i++) {
            if (fee.royaltyFee[i] > 0 && (!order.skipRoyalty)) {
                transferProxy.erc20safeTransferFrom(
                    IERC20(order.erc20Address),
                    buyer,
                    fee.royalityReceiver[i],
                    fee.royaltyFee[i]
                );
            }
        }

        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }

     /* returns the current nonce supply.  */
    function getNonceQuantity(uint256 nonce) external view returns(uint256) {
         return users[nonce].supply;
     }
}