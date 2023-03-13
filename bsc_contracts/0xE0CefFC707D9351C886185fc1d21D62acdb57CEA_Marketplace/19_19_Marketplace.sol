// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol" ;
import "@openzeppelin/contracts/security/Pausable.sol" ;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol" ;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol" ;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol" ;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol" ;
import "../Common/MyMath.sol" ;

contract Marketplace is Pausable, ReentrancyGuard, AccessControlEnumerable, IERC721Receiver, EIP712 {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // payments
    struct Payment {
        // token names
        string name ;

        // ERC20 token address
        address tokenAddr;

        // pay fee rate 1 / 1000000
        uint256 feeRate;

        // decimal
        uint256 decimal ;

        // status
        bool enabled ;
    }

    // shop
    struct Goods {
        // seller
        address owner ;

        // price
        uint256 price ;

        // nft contract addr
        uint256 contractIndex ;

        // payment index
        uint256 paymentIndex ;

        // token id
        uint256 tokenId ;

        // timestamp
        uint64 timestamp ;
    }

    // payment fee wallet
    address public feeAddr ;

    // support nft
    IERC721 [] public supportNfts;

    // support payments
    Payment [] public payments ;

    // pause single nft
    mapping(address => bool) public nftHasPause ;

    // goods list
    Goods [] public goodsList ;

    // goods index record
    // (contractIndex => (tokenId => goodIndex))
    mapping(uint256 => mapping(uint256 => uint256)) public nftIndexs ;

    ///////////////////////////////////////////////
    //              events
    ///////////////////////////////////////////////
    event AddNFTEvent(address [] nft, uint256 startIndex) ;
    event AddPaymentEvent(Payment [] payments, uint256 startIndex) ;
    event EditPaymentEvent(uint256 index, Payment payment) ;
    event ShelvesEvent(uint256 [] contractIndex, uint256 [] paymentIndex, uint256 [] price, uint256[] tokenId, address owner) ;
    event EditPriceEvent(uint256 [] contractIndex, uint256 [] paymentIndex, uint256 [] price, uint256[] tokenId) ;
    event CancleEvent(uint256 [] contractIndex, uint256 [] tokenId) ;
    event BuyerEvent(uint256 [] contractIndex, uint256 [] tokenId, uint256 [] price, address owner) ;

    constructor(address managerAddr, address _feeAddr) EIP712("Marketplace",  "v1.0.0") {
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, managerAddr);
        feeAddr = _feeAddr ;
    }

    function addNfts(address [] memory newNfts) external onlyRole(MANAGER_ROLE) {
        uint256 startIndex = supportNfts.length ;
        for(uint256 i = 0; i < newNfts.length; i++) {
            supportNfts.push(IERC721(newNfts[i])) ;
        }
        emit AddNFTEvent(newNfts, startIndex) ;
    }

    function addPayment(Payment [] memory _payments) external onlyRole(MANAGER_ROLE)  {
        uint256 startIndex = payments.length ;
        for(uint256 i = 0; i < _payments.length; i++) {
            payments.push(_payments[i]) ;
        }
        emit AddPaymentEvent(_payments, startIndex) ;
    }

    function editPayment(uint256 index, Payment memory payment) external onlyRole(MANAGER_ROLE)  {
        payments[index] = payment ;
        emit EditPaymentEvent(index, payment) ;
    }

    function setNftHasPause(address nft, bool paused) external onlyRole(MANAGER_ROLE) {
        nftHasPause[nft] = paused ;
    }

    function setFeeAddr(address newFeeAddr) external onlyRole(MANAGER_ROLE) {
        feeAddr = newFeeAddr ;
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function shelves(uint256 [] memory paymentIndex, uint256 [] memory contractIndex, uint256 [] memory price, uint256 [] memory tokenId) external nonReentrant whenNotPaused {
        require(paymentIndex.length == contractIndex.length && contractIndex.length == price.length && price.length == tokenId.length && tokenId.length > 0, "parameter invalid") ;

        for(uint256 i = 0; i < paymentIndex.length; i++) {
            require(supportNfts.length > contractIndex[i], "Currently nft does not support") ;
            require(payments.length > paymentIndex[i], "The current payment does not support") ;
            require(payments[paymentIndex[i]].enabled, "The current payment has been disabled") ;
            require(nftHasPause[address (supportNfts[contractIndex[i]])] == false, "Currently nft has suspended trading") ;
            require(price[i] > 0, "nft price must be greater than 0") ;

            // transfer nft
            supportNfts[contractIndex[i]].safeTransferFrom(_msgSender(), address(this), tokenId[i]) ;

            // record goods
            goodsList.push(Goods({
                owner: _msgSender(),
                price: price[i],
                contractIndex: contractIndex[i],
                paymentIndex: paymentIndex[i],
                tokenId: tokenId[i],
                timestamp: uint64(block.timestamp)
            })) ;

            // record goods index
            nftIndexs[contractIndex[i]][tokenId[i]] = goodsList.length - 1 ;
        }
        emit ShelvesEvent(contractIndex, paymentIndex, price, tokenId, _msgSender()) ;
    }

    function editPrice(uint256 [] memory paymentIndex, uint256 [] memory contractIndex, uint256 [] memory price, uint256 [] memory tokenId) external nonReentrant whenNotPaused {
        require(paymentIndex.length == contractIndex.length && contractIndex.length == price.length && price.length == tokenId.length && tokenId.length > 0, "parameter invalid") ;

        for(uint256 i = 0; i < contractIndex.length; i++) {
            require(supportNfts.length > contractIndex[i], "Currently nft does not support") ;
            require(payments.length > paymentIndex[i], "The current payment does not support") ;
            require(payments[paymentIndex[i]].enabled, "The current payment has been disabled") ;
            require(nftHasPause[address (supportNfts[contractIndex[i]])] == false, "Currently nft has suspended trading") ;
            require(price[i] > 0, "nft price must be greater than 0") ;

            uint256 goodsIndex = nftIndexs[contractIndex[i]][tokenId[i]] ;

            Goods memory goods = goodsList[goodsIndex] ;
            require(goods.owner == _msgSender(), "You do not have permission to modify the current product price") ;
            require(goods.tokenId == tokenId[i], "The tokenId of nft does not match") ;
            goodsList[goodsIndex].price = price[i] ;
            goodsList[goodsIndex].paymentIndex = paymentIndex[i] ;
        }
        emit EditPriceEvent(contractIndex, paymentIndex, price, tokenId) ;
    }

    function cancle(uint256 [] memory contractIndex, uint256 [] memory tokenId) external nonReentrant {
        require(contractIndex.length == tokenId.length && tokenId.length > 0, "parameter invalid") ;
        for(uint256 i = 0; i < contractIndex.length; i++) {
            uint256 goodsIndex = nftIndexs[contractIndex[i]][tokenId[i]] ;
            Goods memory goods = goodsList[goodsIndex] ;
            require(goods.owner == _msgSender(), "You do not have permission to remove the current product") ;
            require(goods.tokenId == tokenId[i], "The tokenId of nft does not match") ;

            delete nftIndexs[contractIndex[i]][tokenId[i]] ;
            goodsList[goodsIndex] = goodsList[goodsList.length - 1] ;
            nftIndexs[goodsList[goodsIndex].contractIndex][goodsList[goodsIndex].tokenId] = goodsIndex ;
            goodsList.pop() ;

            // transfer nft
            supportNfts[contractIndex[i]].safeTransferFrom(address(this), _msgSender(), tokenId[i]) ;
        }
        emit CancleEvent(contractIndex, tokenId) ;
    }

    function Buyer(uint256 [] memory contractIndex, uint256 [] memory tokenId, uint256 [] memory lockPrice) payable external nonReentrant whenNotPaused {
        require(contractIndex.length == tokenId.length && tokenId.length == lockPrice.length && lockPrice.length > 0, "parameter invalid") ;
        uint256 totalBnb = 0 ;
        for(uint256 i = 0; i < contractIndex.length; i++) {
            uint256 goodsIndex = nftIndexs[contractIndex[i]][tokenId[i]] ;
            Goods memory goods = goodsList[goodsIndex] ;
            require(goods.tokenId == tokenId[i], "The tokenId of nft does not match") ;
            require(lockPrice[i] == goods.price, "nft price has changed") ;

            // check pay
            Payment memory payment = payments[goods.paymentIndex] ;
            require(payment.enabled, "The current payment has been disabled") ;
            uint256 backOwner = lockPrice[i] ;

            if(payment.tokenAddr == address(0x00)) {
                totalBnb = MyMath.add(totalBnb, lockPrice[i], "bnb price cal invalid");
            }

            if(feeAddr != address(0x0)) {
                uint256 fee = (backOwner * payment.feeRate) / 1000000;
                backOwner = lockPrice[i] - fee ;
                _transferBuyerToken(payment, _msgSender(), feeAddr, fee) ;
            }

            _transferBuyerToken(payment, _msgSender(), goods.owner, backOwner) ;

            delete nftIndexs[contractIndex[i]][tokenId[i]] ;
            goodsList[goodsIndex] = goodsList[goodsList.length - 1] ;
            nftIndexs[goodsList[goodsIndex].contractIndex][goodsList[goodsIndex].tokenId] = goodsIndex ;
            goodsList.pop() ;

            // transfer nft
            supportNfts[contractIndex[i]].safeTransferFrom(address(this), _msgSender(), tokenId[i]) ;

        }

        require(msg.value == totalBnb, "Pay BNB amount failed") ;
        emit BuyerEvent(contractIndex, tokenId, lockPrice, _msgSender()) ;
    }

    function _transferBuyerToken(Payment memory payment, address from, address to, uint256 amount) private {
        if(amount < 1) {
            return ;
        }
        if(payment.tokenAddr == address(0x0)) {
            // transfer bnb
            (bool sent, ) = payable(to).call{value: amount}("");
            require(sent, "transfer bnb failed") ;
        } else {
            // transfer erc20
            bool isOk = IERC20(payment.tokenAddr).transferFrom(from, to, amount) ;
            require(isOk, "transfer erc20 token failed") ;
        }
    }

    function backGoods(uint256 goodsIndex) external onlyRole(MANAGER_ROLE) nonReentrant {
        Goods memory goods = goodsList[goodsIndex] ;
        // transfer nft
        supportNfts[goods.contractIndex].safeTransferFrom(address(this), goods.owner, goods.tokenId) ;
        delete nftIndexs[goods.contractIndex][goods.tokenId] ;
        goodsList[goodsIndex] = goodsList[goodsList.length - 1] ;
        nftIndexs[goodsList[goodsIndex].contractIndex][goodsList[goodsIndex].tokenId] = goodsIndex ;
        goodsList.pop() ;
    }

    function getAllGoodsInfoByPage(uint256 page, uint256 limit) external view returns(Goods [] memory, uint256 ) {
        uint256 startIndex = page * limit ;
        uint256 len = goodsList.length - startIndex ;

        if(len > limit) {
            len = limit ;
        }

        if(startIndex >= goodsList.length) {
            len = 0 ;
        }

        Goods[] memory goodsInfo = new Goods[] (len) ;
        for(uint256 i = 0 ;i < len; i++) {
            Goods memory src = goodsList[startIndex + i] ;
            goodsInfo[i] = Goods({
                owner: src.owner,
                price: src.price,
                contractIndex: src.contractIndex,
                paymentIndex: src.paymentIndex,
                tokenId: src.tokenId,
                timestamp: src.timestamp
            }) ;
        }

        return (goodsInfo, goodsList.length);
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from != address(0x0));
        return IERC721Receiver.onERC721Received.selector;
    }
}