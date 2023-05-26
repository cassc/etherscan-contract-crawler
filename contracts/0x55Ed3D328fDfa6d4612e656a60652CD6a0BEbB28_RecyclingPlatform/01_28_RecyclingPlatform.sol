// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/RawToken.sol";
import "./RecyclingToken.sol";


contract RecyclingPlatform is Context, AccessControlEnumerable {

    // default ETH/RUB = 227135.00, 1 RCL = 1 RUB
    uint256 private ethRclPrice = 227135000000000000000000;


    RecyclingToken private  rcl;

    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");

    uint256 public constant TAKE_RCL_FUNCTION = 1;

    mapping(address => bool) private registeredContracts;
    mapping(uint256 => bool) usedNonces;

    struct TokenToSale {
        RawToken rawToken;
        uint256 tokenId;
        uint256 price;
        uint256 timestamp;
        address owner;
    }

    TokenToSale[]  private  tokensToSale;
    // address(rawToken) => tokenId => i in tokensSale array;
    mapping(address => mapping(uint256 => uint256)) private arrayIndex;

    constructor(RecyclingToken recyclingToken) {
        rcl = recyclingToken;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BACKEND_ROLE, _msgSender());
    }

    //////////////// Registered Contracts /////////


    function addResourceContract(RawToken rawToken) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RecyclingPlatform: must have admin role to change price");
        registeredContracts[address(rawToken)] = true;
    }


    function delResourceContract(RawToken rawToken) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RecyclingPlatform: must have admin role to change price");
        registeredContracts[address(rawToken)] = false;
    }

    function getTokenName(RawToken rawToken) public view returns (string memory){
        require(registeredContracts[address(rawToken)], 'RecyclingPlatform: Unknown Raw Token');
        return rawToken.name();
    }

    //////////////// RCL-Token //////////////////

    function setExchangePrice(uint256 newPrice) public {
        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to change price");
        ethRclPrice = newPrice;
    }

    function getExchangePrice() public view returns (uint256) {
        return ethRclPrice;
    }

    function buyRCL() public payable {
        uint256 amount = msg.value * ethRclPrice / 1000000000000000000;
        require(amount > 0, 'RecyclingPlatform: too small amount');
        require(rcl.balanceOf(address(this)) >= amount, 'RecyclingPlatform: not enough RCL tokens');
        rcl.transfer(msg.sender, amount);
    }

    function sendETH() public payable {
        // Функция для непосредственного получения эфира
    }

    function getETH(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RecyclingPlatform: must have admin role to withdraw Ether");
        payable(msg.sender).transfer(amount);
    }

    /*
    // Функция моментального обмена токенов на эфир
    // Вместо нее используем ручной обмен по инициативе администратора

        function sellRCL(uint256 amount) public {
            uint256 ethValue = amount * 1000000000000000000 / ethRclPrice;
            require(amount > 0 && ethValue > 0, 'RecyclingPlatform: too small amount');
            bool result = rcl.transferFrom(address(msg.sender), address(this), amount);
            if (result) {
                payable (msg.sender).transfer(ethValue);

            }
        }
    */

    function exchangeRCL(address client, uint256 amountRCL) public payable {
        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to exchange RCL");
        require(rcl.balanceOf(client) >= amountRCL, 'RecyclingPlatform: not enough RCL tokens');
        bool result = rcl.transferFrom(client, address(this), amountRCL);
        if (result) {
            payable(client).transfer(msg.value);
        }
    }

    function exchangeRCLplatform(address client, uint256 amountRCL, uint256 ethValue) public {

        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to exchange RCL");
        require(rcl.balanceOf(client) >= amountRCL, 'RecyclingPlatform: not enough RCL tokens');
        bool result = rcl.transferFrom(client, address(this), amountRCL);
        if (result) {
            payable(client).transfer(ethValue);
        }

    }


    function getRclAddress() public view returns (address) {
        return address(rcl);
    }

    function getEthereumAmount(uint256 amountRCL) public view returns (uint256){
        return amountRCL * 1000000000000000000 / ethRclPrice;
    }

    function sendRCL(address recipient, uint256 amount) public {
        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to send RCL");
        rcl.transfer(recipient, amount);
    }


    function takeRCL(uint256 amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {

        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        bytes32 message = prefixed(keccak256(abi.encodePacked(TAKE_RCL_FUNCTION, msg.sender, amount, nonce, this)));

        require(hasRole(BACKEND_ROLE, ecrecover(message, v, r, s)), "RecyclingPlatform: signature error");

        rcl.transfer(msg.sender, amount);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


    function burnRCL(uint256 amount) public {
        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to burn RCL");
        rcl.burn(amount);
    }

    /////////////// Raw-Token ////////////////////

    event BuyNFT(address indexed rawToken, uint256 indexed tokenId, bool isResource, uint256 purchase_date);

    function buyRawToken(RawToken rawToken, bool isResource) public {

        require(registeredContracts[address(rawToken)], 'RecyclingPlatform: Unknown Raw Token');

        (uint256 tokensToSaleF, uint256 tokensToSaleR) = rawToken.getTotalTokens();
        if (isResource) {
            require(tokensToSaleR > 0, 'RecyclingPlatform: No NFTokens for sale');
        } else {
            require(tokensToSaleF > 0, 'RecyclingPlatform: No NFTokens for sale');
        }
        (uint256 base_price,
        uint256 deposit_price,
        uint256 benefits_period,
        uint256 interest_rate_future,
        uint256 interest_rate_resource) = rawToken.getPurchaseRules();

        bool result = rcl.transferFrom(address(msg.sender), address(this), base_price);
        if (result) {
            (uint256 tokenId, uint256 purchase_date) = rawToken.mintToken(isResource,
                address(tx.origin),
                base_price,
                deposit_price,
                benefits_period,
                interest_rate_future,
                interest_rate_resource
            );
            emit BuyNFT(address(rawToken), tokenId, isResource, purchase_date);
        }
    }

    function buyRawTokens(RawToken rawToken, bool isResource, uint256 total) public {
        require(registeredContracts[address(rawToken)], 'RecyclingPlatform: Unknown Raw Token');
        for (uint256 i = 0; i < total; i++) {
            buyRawToken(rawToken, isResource);
        }
    }


    function futureToResource(RawToken rawToken, uint256 tokenId) public {
        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to change token type");
        require(registeredContracts[address(rawToken)], 'RecyclingPlatform: Unknown Raw Token');
        uint256 dividends = rawToken.calcDividends(tokenId);

        rcl.transferFrom(address(this), rawToken.ownerOf(tokenId), dividends);

        rawToken.futureToResource(tokenId);
    }


    function batchFutureToResource(RawToken rawToken, uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            futureToResource(rawToken, tokenIds[i]);
        }
    }

    function redemptionOverdue(RawToken rawToken, uint256 tokenId) public {
//        require(hasRole(BACKEND_ROLE, _msgSender()), "RecyclingPlatform: must have backend role to change token type");
        require(registeredContracts[address(rawToken)], 'RecyclingPlatform: Unknown Raw Token');
        RawToken.ResourceToken memory info = rawToken.getTokenInfo(tokenId);
        require(block.timestamp - info.purchase_date
            > info.benefits_period, "RecyclingPlatform: token has not expired yet");

        uint256 amount = rawToken.calcDividends(tokenId) + info.deposit_price;

        rcl.transferFrom(address(this), rawToken.ownerOf(tokenId), amount);

        rawToken.burn(tokenId);
    }



    ///////////////// Secondary Sales Market //////////////////


    function putTokenForSale(RawToken rawToken, uint256 tokenId, uint256 price) public {
        rawToken.transferFrom(msg.sender, address(this), tokenId);
        TokenToSale memory token = TokenToSale(rawToken, tokenId, price, block.timestamp, msg.sender);
        arrayIndex[address(rawToken)][tokenId] = tokensToSale.length;
        tokensToSale.push(token);
    }

    function batchTokensForSale(RawToken rawToken, uint256[] calldata tokenIds, uint256 price) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            putTokenForSale(rawToken, tokenIds[i], price);
        }
    }

    function getTokensForSale() public view returns (TokenToSale[] memory){
        return tokensToSale;
    }

    function changeTokenSalePrice(RawToken rawToken, uint256 tokenId, uint256 price) public {
        uint256 i = arrayIndex[address(rawToken)][tokenId];
        TokenToSale memory token = tokensToSale[i];
        require(token.owner == msg.sender, 'RecyclingPlatform: you are not the owner of this token');
        tokensToSale[i].price = price;
    }

    function reclaimTokenToSale(RawToken rawToken, uint256 tokenId) public {
        uint256 i = arrayIndex[address(rawToken)][tokenId];
        TokenToSale memory token = tokensToSale[i];
        require(token.owner == msg.sender, 'RecyclingPlatform: you are not the owner of this token');

        rawToken.transfer(msg.sender, tokenId);
        removeFromPlatform(i);
    }

    function removeFromPlatform(uint256 i) internal {
        require(i < tokensToSale.length, 'RecyclingPlatform: removed token does not exists');
        if (tokensToSale.length > i + 1) {
            TokenToSale memory lastToken = tokensToSale[tokensToSale.length - 1];
            arrayIndex[address(lastToken.rawToken)][lastToken.tokenId] = i;
            tokensToSale[i] = lastToken;
        }
        tokensToSale.pop();
    }

    function buyTokenForSale(RawToken rawToken, uint256 tokenId) public {
        uint256 i = arrayIndex[address(rawToken)][tokenId];
        TokenToSale memory token = tokensToSale[i];
        require(rcl.balanceOf(msg.sender) >= token.price, 'RecyclingPlatform: not enough RCL');

        rcl.transferFrom(msg.sender, token.owner, token.price);
        rawToken.transfer(msg.sender, tokenId);
        removeFromPlatform(i);
    }


}