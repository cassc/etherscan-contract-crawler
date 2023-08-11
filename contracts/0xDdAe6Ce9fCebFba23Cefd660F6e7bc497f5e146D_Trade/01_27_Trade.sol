// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interface/ITransferProxy.sol";
import "./interface/ISokuNFT721.sol";
import "./interface/ISokuNFT1155.sol";
import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);
}

contract Trade is AccessControl, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum BuyingAssetType {
        ERC1155,
        ERC721,
        LazyERC1155,
        LazyERC721
    }

    event SignerChanged(
        address indexed previousSigner,
        address indexed newSigner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    event ExecuteBid(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    // buyer platformFee
    uint8 private buyerFeePermille;
    // seller platformFee
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    IUniswapV2Router02 public sushiswapRouter;

    address public signer;

    mapping(uint256 => bool) public usedNonce;
    mapping(uint256 => Asset1155) public users;
    mapping(uint256 => SignOrder) public onSale;

    //mapping of input address of referral to output address referred by
    mapping(address => address) public addressRefBy;
    //mapping of input user address (arg1) and then token address (arg2) to count ref rewards
    mapping(address => mapping(address => uint256)) public addressRefRewards;

    struct Referral {
        address referrer;
        uint256 referralFee;
    }

    struct SignOrder {
        address user;
        address assetAddress;
        uint256 tokenId;
        uint256 qty;
        address paymentAssetAddress;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool status;
    }

    struct Asset1155 {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 supply;
        bool initialize;
    }

    /** Fee Struct
        @param platformFee  uint256 (buyerFee + sellerFee) value which is transferred to current contract owner.
        @param assetFee  uint256  assetvalue which is transferred to current seller of the NFT.
        @param royaltyFee  uint256 value, transferred to Minter of the NFT.
        @param price  uint256 value, the combination of buyerFee and assetValue.
        @param tokenCreator address value, it's store the creator of NFT.
    */
    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
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
        @param amount the price of NFT(assetFee + buyerFee).
        @param tokenId
        @param qty number of quantity to be transfer.
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
        string tokenURI;
        uint256 supply;
        uint96 royaltyFee;
        uint256 qty;
    }

    uint256 refReward;
    uint256 refRewardRefBy1;
    uint256 refRewardRefBy2;
    uint256 refRewardRefBy3; 

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        address _routerAddress,
        ITransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        sushiswapRouter = IUniswapV2Router02(_routerAddress);
        signer = _msgSender();
        _setupRole("ADMIN_ROLE", _msgSender());
        _setupRole("SIGNER_ROLE", _msgSender());
    }

    receive() external payable {}

    fallback() external payable {}

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
        @param _transferProxy  address for a new transferProxy.
    */

    function setTransferProxy(
        address _transferProxy
    ) external onlyRole("ADMIN_ROLE") {
        transferProxy = ITransferProxy(_transferProxy);
    }

    /**
        @param _buyerFee  value for buyerservice in multiply of 1000.
    */

    function setBuyerServiceFee(
        uint8 _buyerFee
    ) external onlyRole("ADMIN_ROLE") {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
    }

    /**
        @param _sellerFee  value for buyerservice in multiply of 1000.
    */

    function setSellerServiceFee(
        uint8 _sellerFee
    ) external onlyRole("ADMIN_ROLE") {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
    }

    /**
        transfers the contract ownership to newowner address.
        @param newOwner address of newOwner
     */

    function transferOwnership(
        address newOwner
    ) public override onlyRole("ADMIN_ROLE") {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner());
        _transferOwnership(newOwner);
        _setupRole("ADMIN_ROLE", newOwner);
    }

    /**
        transfers the contract ownership to newowner address.
        @param newSigner address of newOwner
     */

    function changeSigner(address newSigner) external onlyRole("SIGNER_ROLE") {
        require(newSigner != address(0), " new Signer is the zero address");
        _revokeRole("SIGNER_ROLE", signer);
        signer = newSigner;
        _setupRole("SIGNER_ROLE", newSigner);
        emit SignerChanged(signer, newSigner);
    }

    function putOnSale(SignOrder memory signOrder, uint256 nonce) external {
        require(!onSale[nonce].status, "Already In Sale");
        signOrder.user = _msgSender();
        signOrder.status = true;
        onSale[nonce] = signOrder;
    }

    function removeFromSale(uint256 nonce) external {
        require(onSale[nonce].status, "Not In Sale");
        require(onSale[nonce].user == _msgSender(), "Invalid User");
        delete onSale[nonce];
    }

    function pause() external onlyRole("ADMIN_ROLE") {
        transferProxy.pause();
    }

    function unpause() external onlyRole("ADMIN_ROLE") {
        transferProxy.unpause();
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function buyAsset(
        Order memory order,
        Sign calldata sign,
        Referral memory referral,
        bool isWertPurchase
    ) external payable {
        if (isWertPurchase) {
            uint[] memory amounts = _swapETHforToken(
                order.amount,
                order.erc20Address
            );
            require(
                amounts[1] >= order.amount,
                "Trade: insufficient swapped amount"
            );
        }
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        require(
            ((onSale[sign.nonce].startTime <= block.timestamp &&
                block.timestamp <= onSale[sign.nonce].endTime) ||
                onSale[sign.nonce].startTime == onSale[sign.nonce].endTime) &&
                onSale[sign.nonce].status,
            "Sale Not Eligible"
        );
        if (
            order.nftType == BuyingAssetType.ERC721 ||
            order.nftType == BuyingAssetType.LazyERC721
        ) {
            usedNonce[sign.nonce] = true;
            onSale[sign.nonce].status = false;
        } else if (
            order.nftType == BuyingAssetType.ERC1155 ||
            order.nftType == BuyingAssetType.LazyERC1155
        ) {
            if (users[sign.nonce].initialize) {
                require(
                    users[sign.nonce].nftAddress == order.nftAddress &&
                        users[sign.nonce].seller == order.seller &&
                        users[sign.nonce].tokenId == order.tokenId,
                    "Nonce: Invalid Data"
                );
                require(
                    users[sign.nonce].supply >= order.qty,
                    "Invalid Quantity"
                );
                users[sign.nonce].supply -= order.qty;
                if (users[sign.nonce].supply == 0) {
                    usedNonce[sign.nonce] = true;
                    onSale[sign.nonce].status = false;
                }
            } else if (!users[sign.nonce].initialize) {
                require(
                    onSale[sign.nonce].qty >= order.qty,
                    "Invalid Quantity"
                );
                users[sign.nonce] = Asset1155(
                    order.seller,
                    order.nftAddress,
                    order.tokenId,
                    onSale[sign.nonce].qty - order.qty,
                    true
                );
            }
        }
        Fee memory fee = getFees(order);
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(sign);
        tradeAsset(order, fee, referral, isWertPurchase);
        emit BuyAsset(order.seller, order.tokenId, order.qty, order.buyer);
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function executeBid(
        Order memory order,
        Sign calldata sign,
        Referral memory referral
    ) external {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order);
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        tradeAsset(order, fee, referral, false);
        emit ExecuteBid(order.seller, order.tokenId, order.qty, order.buyer);
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function mintAndBuyAsset(
        Order memory order,
        Sign calldata sign,
        Sign calldata ownerSign,
        Referral memory referral,
        bool isWertPurchase
    ) external payable {
        if (isWertPurchase) {
            uint[] memory amounts = _swapETHforToken(
                order.amount,
                order.erc20Address
            );
            require(
                amounts[1] >= order.amount,
                "Trade: insufficient swapped amount"
            );
        }
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        require(
            (onSale[sign.nonce].startTime <= block.timestamp &&
                block.timestamp <= onSale[sign.nonce].endTime) ||
                (onSale[sign.nonce].startTime == onSale[sign.nonce].endTime &&
                    onSale[sign.nonce].status),
            "Sale Not Eligible"
        );
        usedNonce[sign.nonce] = true;
        onSale[sign.nonce].status = false;
        Fee memory fee = getFees(order);
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
        verifySellerSign(sign);
        tradeAsset(order, fee, referral, isWertPurchase);
        emit BuyAsset(order.seller, order.tokenId, order.qty, order.buyer);
    }

    /**
        excuting the NFT order.
        @param order ordervalues(seller, buyer,...).
        @param sign Sign value(v, r, f).
    */

    function mintAndExecuteBid(
        Order memory order,
        Sign calldata sign,
        Sign calldata ownerSign,
        Referral memory referral
    ) external {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order);
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
        tradeAsset(order, fee, referral, false);
        emit ExecuteBid(order.seller, order.tokenId, order.qty, order.buyer);
    }

    /**
        returns the signer of given signature.
     */
    function getSigner(
        bytes32 hash,
        Sign memory sign
    ) internal pure returns (address) {
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

    function verifySellerSign(Sign memory sign) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                onSale[sign.nonce].assetAddress,
                onSale[sign.nonce].tokenId,
                onSale[sign.nonce].paymentAssetAddress,
                onSale[sign.nonce].amount,
                onSale[sign.nonce].qty,
                sign.nonce
            )
        );
        require(
            onSale[sign.nonce].user == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function verifyOwnerSign(
        address seller,
        string memory tokenURI,
        address assetAddress,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(this, assetAddress, seller, tokenURI, sign.nonce)
        );
        require(
            signer == getSigner(hash, sign),
            "owner sign verification failed"
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

    /**
        it retuns platformFee, assetFee, royaltyFee, price and tokencreator.
     */

    function getFees(Order memory order) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint256 price = (order.amount * 1000) / (1000 + buyerFeePermille);
        uint256 buyerFee = order.amount - price;
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        if (
            !order.skipRoyalty &&
            ((order.nftType == BuyingAssetType.ERC721) ||
                (order.nftType == BuyingAssetType.ERC1155))
        ) {
            (tokenCreator, royaltyFee) = IERC2981(order.nftAddress).royaltyInfo(
                order.tokenId,
                price
            );
        }
        if (
            !order.skipRoyalty &&
            ((order.nftType == BuyingAssetType.LazyERC721) ||
                (order.nftType == BuyingAssetType.LazyERC1155))
        ) {
            (tokenCreator, royaltyFee) = (
                order.seller,
                uint96((price * order.royaltyFee) / 1000)
            );
        }
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeAsset(
        Order memory order,
        Fee memory fee,
        Referral memory referral,
        bool isWertPurchase
    ) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(
                IERC721(order.nftAddress),
                order.seller,
                order.buyer,
                order.tokenId
            );
        }
        if (order.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(order.nftAddress),
                order.seller,
                order.buyer,
                order.tokenId,
                order.qty,
                ""
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC721) {
            transferProxy.mintAndSafe721Transfer(
                ILazyMint(order.nftAddress),
                order.seller,
                order.buyer,
                order.tokenURI,
                order.royaltyFee
            );
        }
        if (order.nftType == BuyingAssetType.LazyERC1155) {
            transferProxy.mintAndSafe1155Transfer(
                ILazyMint(order.nftAddress),
                order.seller,
                order.buyer,
                order.tokenURI,
                order.royaltyFee,
                order.supply,
                order.qty
            );
        }
        require(
            order.buyer != referral.referrer,
            "Buyer cannot be the referrer"
        );
        address erc20TokenFrom = isWertPurchase ? address(this) : _msgSender();
        if(isWertPurchase){
            IERC20(order.erc20Address).approve(address(transferProxy), type(uint).max);
        }
        refReward = 0;
        refRewardRefBy1 = 0;
        refRewardRefBy2 = 0;
        refRewardRefBy3 = 0;        
        if (fee.platformFee > 0) {
            if (addressRefBy[order.buyer] == address(0)) {
                if (referral.referrer != address(0)) {
                    if (
                        order.buyer != addressRefBy[referral.referrer] ||
                        order.buyer !=
                        addressRefBy[addressRefBy[referral.referrer]] ||
                        order.buyer !=
                        addressRefBy[
                            addressRefBy[addressRefBy[referral.referrer]]
                        ]
                    ) {
                        addressRefBy[order.buyer] = referral.referrer;
                    }
                    refReward = fee.platformFee.div(10);
                    addressRefRewards[referral.referrer][
                        order.erc20Address
                    ] += refReward;
                }
            } else {
                //addressRefBy[order.buyer] != address(0) is TRUE
                refRewardRefBy1 = fee.platformFee.div(10);
                addressRefRewards[addressRefBy[order.buyer]][
                    order.erc20Address
                ] += refRewardRefBy1;
                if (addressRefBy[addressRefBy[order.buyer]] != address(0)) {
                    refRewardRefBy2 = fee.platformFee.mul(100).div(1667);
                    addressRefRewards[addressRefBy[addressRefBy[order.buyer]]][
                        order.erc20Address
                    ] += refRewardRefBy2;
                    if (
                        addressRefBy[addressRefBy[addressRefBy[order.buyer]]] !=
                        address(0)
                    ) {
                        refRewardRefBy3 = fee.platformFee.div(25);
                        addressRefRewards[
                            addressRefBy[
                                addressRefBy[addressRefBy[order.buyer]]
                            ]
                        ][order.erc20Address] += refRewardRefBy3;
                    }
                }
            }
            uint256 ownerRewards = fee
                .platformFee
                .sub(refReward)
                .sub(refRewardRefBy1)
                .sub(refRewardRefBy2)
                .sub(refRewardRefBy3);
            
            if (erc20TokenFrom != address(this)) {
                // transfer the rewards to the contract itself for referrers to withdraw later
                transferProxy.erc20safeTransferFrom(
                    IERC20(order.erc20Address),
                    erc20TokenFrom,
                    address(this),
                    fee.platformFee.sub(ownerRewards)
                );
            }
            
            // transfer the remaining platform fee to the contract owner directly
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                erc20TokenFrom,
                owner(),
                ownerRewards
            );
        }

        if (fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                erc20TokenFrom,
                fee.tokenCreator,
                fee.royaltyFee
            );
        }

        if (referral.referrer != address(0) && referral.referralFee > 0) {
            uint256 referralFeeAmnt = fee
                .assetFee
                .mul(referral.referralFee)
                .div(1000);
            addressRefRewards[referral.referrer][
                order.erc20Address
            ] += referralFeeAmnt;
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                erc20TokenFrom,
                address(this),
                referralFeeAmnt
            );
        }

        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            erc20TokenFrom,
            order.seller,
            fee.assetFee.mul(1000 - referral.referralFee).div(1000)
        );
    }

    function _swapETHforToken(
        uint _amountOutMin,
        address _tokenAddress
    ) internal returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = sushiswapRouter.WETH();
        path[1] = _tokenAddress;

        if (path[0] == path[1]) {
            IWETH(_tokenAddress).deposit{value: msg.value}();
            amounts = new uint[](2);
            amounts[0] = msg.value;
            amounts[1] = msg.value;
        } else {
            amounts = sushiswapRouter.swapETHForExactTokens{value: msg.value}(
                _amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function withdraw(address tokenAddress) public {
        require(
            addressRefRewards[_msgSender()][tokenAddress] > 0,
            "No rewards to withdraw."
        );
        uint256 amount = addressRefRewards[_msgSender()][tokenAddress];
        addressRefRewards[_msgSender()][tokenAddress] = 0;
        IERC20(tokenAddress).safeTransfer(_msgSender(), amount);
    }

    function withdrawAmountETH(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Trade: Withdrawal amount exceeds balance");
        (bool sent, ) = _msgSender().call{value: amount}("");
        require(sent, "Trade: Failed to withdraw Ether");
    }

    function withdrawAmountERC20(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(amount <= contractBalance, "Trade: Withdrawal amount exceeds balance");
        token.safeTransfer(_msgSender(), amount);
    }
}