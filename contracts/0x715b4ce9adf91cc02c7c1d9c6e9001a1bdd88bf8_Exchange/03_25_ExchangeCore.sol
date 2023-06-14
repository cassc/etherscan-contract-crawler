// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


import "./lib/ReentrancyGuarded.sol";
import "./lib/EIP712.sol";
import "./lib/EIP1271.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MoneyHandler.sol";
import "./FarmV2.sol";


contract ExchangeCore is ReentrancyGuarded, EIP712, Ownable{

    using SafeERC20 for IERC20;
    bytes4 constant internal EIP_1271_MAGICVALUE = 0x20c13b0b;
    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";
    MoneyHandler public moneyHand;
    IERC20 public token;
    FarmV2 public farm;
    /* Struct definitions. */

    /* An order, convenience struct. */
    struct Order {
        /* Order maker address. */
        address maker;
        /* Order maker address. */
        address target;
        /* token address */
        address token;
        /*distribution percentage */
        uint256 percent;
        /* Order price. */
        uint256 price;
        /* NFT tokenId */
        uint256 tokenId;
        /* Order listing timestamp. */
        uint256 listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;

    }


    /* Constants */

    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,address target,address moneyHandler,uint256 price,uint256 tokenId,uint256 listingTime,uint256 expirationTime,uint256 salt)"
    );

    /* Variables */

    /* Trusted proxy registry contracts. */
    mapping(address => bool) public registries;

    mapping(address => address) public orders;

    /* Order fill status, by maker address then by hash. */
    mapping(address => mapping(bytes32 => uint)) public fills;

  
    mapping(address => mapping(bytes32 => bool)) public approved;

    /* Events */

    event OrderApproved     (bytes32 indexed hash, address indexed maker, uint amount, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderFillChanged  (bytes32 indexed hash, address indexed maker, uint newFill);
    event OrdersMatched     (bytes32 firstHash, bytes32 secondHash, address indexed firstMaker, address indexed secondMaker);


    /* Functions */
    function addFarmAddress(address _token) internal onlyOwner{
        //token = IERC20(_token);
        farm = FarmV2(_token);

    }
    
    function addMoneyHandAdd(address  _contract) internal onlyOwner{
        moneyHand = MoneyHandler(_contract);
    }

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {

        /* Per EIP 712. */
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            order.target,
            order.token,
            order.percent,
            order.price,
            order.tokenId,
            order.listingTime,
            order.expirationTime,
            order.salt
        ));
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function exists(address what)
        internal
        view
        returns (bool)
    {
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }
 

    function validateOrderParameters(Order memory order, bytes32 hash_)
        internal
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (order.listingTime > block.timestamp || (order.expirationTime != 0 && order.expirationTime <= block.timestamp)) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(bytes32 hash, address maker, bytes memory signature)
        internal
        view
        returns (bool)
    {
        /* Memoized authentication. If order has already been partially filled, order must be authenticated. */
        if (fills[maker][hash] > 0) {
            return true;
        }

        /* Order authentication. Order must be either: */

        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }

        /* (b): previously approved */
        if (approved[maker][hash]) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);


        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));

    
        if (ecrecover(keccak256(abi.encodePacked(personalSignPrefix,"32",calculatedHashToSign)), v, r, s)==maker) {
            return true;
        }
        
        return false;
    }

    function atomicMatch(Order memory seller, Order memory buyer, bytes memory signatures)
        internal
        reentrancyGuard
      
    {
        IERC1155 collection = IERC1155(seller.target);
        //IERC20 token_ = IERC20(buyer.target);

        require(seller.price == buyer.price, "price is not equal");

         /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(seller);

        /* Check first order validity. */
        require(validateOrderParameters(seller, firstHash), "First order has invalid parameters");

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(buyer);

        /* Check second order validity. */
        require(validateOrderParameters(buyer, secondHash), "Second order has invalid parameters");

        require(fills[seller.maker][firstHash]==0, "this order already filled");

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");
         {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi.decode(signatures, (bytes, bytes));

            /* Check first order authorization. */
            require(validateOrderAuthorization(firstHash, seller.maker, firstSignature), "First order failed authorization");

            /* Check second order authorization. */
            require(validateOrderAuthorization(secondHash, buyer.maker, secondSignature), "Second order failed authorization");
        }

      

        require(collection.isApprovedForAll(seller.maker, address(this)), "Seller must be approve");
        require(collection.balanceOf(seller.maker, seller.tokenId) > 0, "Seller must be have enough funds");

        if(address(farm)==seller.token){

            farm = FarmV2(seller.token);

            require(farm.rewardedStones(buyer.maker) >= seller.price, "Buyer must be have enough funds");

            farm.sell(seller.price, buyer.maker, seller.maker);
            collection.safeTransferFrom(seller.maker,buyer.maker, seller.tokenId, 1, "");
            
        
        }
        else{

            IERC20 token_ = IERC20(seller.token);
            require(token_.balanceOf(buyer.maker) >= seller.price, "Buyer must be have enough funds");
            
            uint256 sellmul= SafeMath.mul(seller.price,seller.percent);
            uint256 sellAmount= SafeMath.div(sellmul,10**18);

            uint256 sharePerc = SafeMath.sub(10**18,seller.percent);
            uint256 sharemul = SafeMath.mul(seller.price,sharePerc);
            uint256 shareAmount = SafeMath.div(sharemul,10**18);

            token_.safeTransferFrom(buyer.maker, address(this), seller.price);
            collection.safeTransferFrom(seller.maker,buyer.maker, seller.tokenId, 1, "");
            token_.transfer(seller.maker, sellAmount);
            token_.transfer(address(moneyHand),shareAmount);
            moneyHand.updateCollecMny(seller.target,shareAmount);
            
        }

        
        
        
        
        // Price will transfer to money transfer contract
   
      
        
       // moneyHand.updateRecieved(seller.target, shareAmount);
        
        fills[seller.maker][firstHash] = seller.price;

        /* LOGS */

        /* Log match event. */
        emit OrdersMatched(firstHash, secondHash, buyer.maker, seller.maker);


    }




}