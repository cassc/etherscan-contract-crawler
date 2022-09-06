// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IERC165 {

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
    */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
*/

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
    */
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function lastTokenId()external returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function contractOwner() external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mintAndTransfer(address from, address to, uint256 itemId, uint256 fee, string memory _tokenURI, bytes memory data)external returns(uint256);

}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);
    function lastTokenId()external returns(uint256);
    function mintAndTransfer(address from, address to, uint256 itemId, uint256 fee, uint256 _supply, string memory _tokenURI, uint256 qty, bytes memory data)external returns(uint256);
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
    */

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */

    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
    */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
    */

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

contract TransferProxy {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
    
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external  {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }

    function erc721mintAndTransfer(IERC721 token, address from, address to, uint256 tokenId, uint256 fee, string memory tokenURI, bytes calldata data) external returns(uint256){
        return token.mintAndTransfer(from, to,tokenId, fee, tokenURI, data);
    }

    function erc1155mintAndTransfer(IERC1155 token, address from, address to, uint256 tokenId, uint256 fee , uint256 supply, string memory tokenURI, uint256 qty, bytes calldata data) external returns(uint256) {
        return token.mintAndTransfer(from, to, tokenId, fee, supply, tokenURI, qty, data);
    }  
}

contract Trade {

    enum BuyingAssetType {ERC1155, ERC721 , LazyMintERC1155, LazyMintERC721}
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event BuyAndTransferAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    TransferProxy public transferProxy;
    TransferProxy public DeprecatedProxy;
    address public owner;
    mapping(uint256 => bool) private usedNonce;

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }



    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint256 supply;
        string tokenURI;
        uint256 fee;
        uint qty;
        bool isDeprecatedProxy;
        bool isErc20Payment;
    }

    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, TransferProxy _transferProxy, TransferProxy _deprecatedProxy) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        DeprecatedProxy = _deprecatedProxy;
        owner = msg.sender;
    }

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }

    function verifySellerSign(address seller, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, sign.nonce));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSign(address buyer, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, uint qty, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount,qty, sign.nonce));
        require(buyer == getSigner(hash, sign), "buyer sign verification failed");
    }


    function verifyOwnerSign(address buyingAssetAddress,address seller,string memory tokenURI, Sign memory sign) internal view {
        address _owner = IERC721(buyingAssetAddress).contractOwner();
        bytes32 hash = keccak256(abi.encodePacked(this, seller, tokenURI, sign.nonce));
        require(_owner == getSigner(hash, sign), "Owner sign verification failed");
    }


    function getFees( Order memory order, bool _import) internal view returns(Fee memory){
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint royaltyPermille;
        uint price = order.amount * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = order.amount - price;
        uint sellerFee = price * sellerFeePermille / 1000;
        platformFee = buyerFee + sellerFee;
        if(order.nftType == BuyingAssetType.ERC721 && ! _import) {
            royaltyPermille = ((IERC721(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC721(order.nftAddress).getCreator(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.ERC1155 && ! _import)  {
            royaltyPermille = ((IERC1155(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC1155(order.nftAddress).getCreator(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721) {
            royaltyPermille = order.fee;
            tokenCreator = order.seller;
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155) {
            royaltyPermille = order.fee;
            tokenCreator = order.seller;
        }
        if(_import) {
            royaltyPermille = 0;
            tokenCreator = address(0);
        }
        royaltyFee = price * royaltyPermille / 1000;
        assetFee = price - (royaltyFee + sellerFee);
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeAsset(Order memory order, Fee memory fee, bool isTransferAsset) internal virtual {
        TransferProxy previousTransferProxy = transferProxy;
        
        if(order.isDeprecatedProxy){
            transferProxy = DeprecatedProxy;
        }
        if(order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress), order.seller, order.buyer, order.tokenId);
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {
            transferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress), order.seller, order.buyer, order.tokenId, order.qty, ""); 
        }
        if(order.nftType == BuyingAssetType.LazyMintERC721){
            transferProxy.erc721mintAndTransfer(IERC721(order.nftAddress), order.seller, order.buyer, order.tokenId, order.fee,order.tokenURI,"" );
        }
        if(order.nftType == BuyingAssetType.LazyMintERC1155){
            transferProxy.erc1155mintAndTransfer(IERC1155(order.nftAddress), order.seller, order.buyer, order.tokenId, order.fee, order.supply,order.tokenURI,order.qty,"" );
        }
        if(fee.platformFee > 0) {
            
            if (order.isErc20Payment){
                if (!isTransferAsset) {
                    transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, owner, fee.platformFee);
                } else {
                    transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), msg.sender, owner, fee.platformFee);
                }
            }else{
                payable(owner).transfer(fee.platformFee);
            }
        }
        if(fee.royaltyFee > 0) {
            if (order.isErc20Payment){
                if (!isTransferAsset) {
                transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, fee.tokenCreator, fee.royaltyFee);
                } else {
                    transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), msg.sender, fee.tokenCreator, fee.royaltyFee);
                }
            }else{
                payable(fee.tokenCreator).transfer(fee.royaltyFee);
            }
        }
        if (order.isErc20Payment){
            if (!isTransferAsset) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, order.seller, fee.assetFee);
            } else {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address),  msg.sender, order.seller, fee.assetFee);
            }
        }else{
            payable(order.seller).transfer(fee.assetFee);
        }
        if(order.isDeprecatedProxy){
            transferProxy = previousTransferProxy;
        }
    }

    function mintAndBuyAsset(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external returns(bool){
        require(!usedNonce[sign.nonce] && !usedNonce[ownerSign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        if(isShared) {
            verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        }
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee, false);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;

    }

    function mintAndTransferAsset(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external returns(bool){
        require(!usedNonce[sign.nonce] && !usedNonce[ownerSign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        if(isShared) {
            verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        }
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        tradeAsset(order, fee, true);
        emit BuyAsset(order.seller , order.tokenId, order.qty, order.buyer);
        return true;

    }

    function mintAndExecuteBid(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external returns(bool){
        require(!usedNonce[sign.nonce] && !usedNonce[ownerSign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        if(isShared) {
            verifyOwnerSign(order.nftAddress,order.seller, order.tokenURI, ownerSign);
        }
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty,sign);
        order.seller = msg.sender;
        tradeAsset(order, fee, false);
        emit ExecuteBid(order.seller , order.tokenId, order.qty, msg.sender);
        return true;

    }

    function buyAsset(Order memory order, bool _import, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee, false);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function buyAndTransferAsset(Order memory order, bool _import, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        tradeAsset(order, fee, true);
        emit BuyAsset(order.seller , order.tokenId, order.qty, order.buyer);
        return true;
    }

    function executeBid(Order memory order, bool _import, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty, sign);
        order.seller = msg.sender;
        tradeAsset(order, fee, false);
        emit ExecuteBid(msg.sender , order.tokenId, order.qty, order.buyer);
        return true;
    }

    function buyAssetWithEth(Order memory order, bool _import, Sign memory sign) external payable returns (bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        require(msg.value >= fee.price, "Paid Invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee, false);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function mintAndBuyAssetWithEth(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external payable returns (bool){
        require(!usedNonce[sign.nonce] && !usedNonce[ownerSign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require(msg.value >= fee.price, "Paid Invalid amount");
        if(isShared) {
            verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        }
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee, false);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;

    }

    function buyAndTransferAssetWithEth(Order memory order, bool _import, Sign memory sign) external payable returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order, _import);
        require(msg.value >= fee.price, "Paid Invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        tradeAsset(order, fee, true);
        emit BuyAsset(order.seller , order.tokenId, order.qty, order.buyer);
        return true;
    }

    function mintAndTransferAssetWithEth(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external payable returns(bool){
        require(!usedNonce[sign.nonce] && !usedNonce[ownerSign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        usedNonce[ownerSign.nonce] = true;
        Fee memory fee = getFees(order, false);
        require(msg.value >= fee.price, "Paid Invalid amount");
        if(isShared) {
            verifyOwnerSign(order.nftAddress, order.seller, order.tokenURI, ownerSign);
        }
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        tradeAsset(order, fee, true);
        emit BuyAsset(order.seller , order.tokenId, order.qty, order.buyer);
        return true;
    }
}