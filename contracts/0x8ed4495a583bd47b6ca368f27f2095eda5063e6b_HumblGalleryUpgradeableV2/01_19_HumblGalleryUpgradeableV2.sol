// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./CommissionUpgradeable.sol"; /*  Commission fee calculation related contract */

contract HumblGalleryUpgradeableV2 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155SupplyUpgradeable,
    CommissionUpgradeable,
    ReentrancyGuardUpgradeable
{
    string public name;
    string public symbol;

    /* Execute once on contract deployment with commission fee, commission fee receiver, royaltyFraction and royalty receiver */
    function initialize(uint96 commissionPercentage, address commissionReceiver, string memory _name_, string memory _symbol_, string memory _uri_)
        public
        initializer
    {
        __ERC1155_init(_uri_);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC1155Supply_init();
        require(commissionPercentage >= 0, "H101");
        require(commissionPercentage <= 5000, "H102");
        require(commissionReceiver != address(0), "H103");
        _setDefaultCommission(commissionPercentage);
        _setCommissionReceiver(commissionReceiver);
        _setName(_name_);
        _setSymbol(_symbol_);
        setPaymentToken(0, address(0));
    }

    function _setName (string memory _name ) internal virtual {
        name = _name;
    }
    function _getName() internal view virtual returns(string memory) {
        return name;
    }

    function getName() public view returns (string memory) {
        return _getName();
    }

    function _setSymbol (string memory _symbol ) internal virtual {
        symbol = _symbol;
    }
    function _getSymbol() internal view virtual returns(string memory) {
        return symbol;
    }

    function getSymbol() public view returns (string memory) {
        return _getSymbol();
    }

    /* event trigger on buying */
    event safeSaleNFT(
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 quantity,
        uint256 transferAmount,
        uint256 commissionAmount,
        address commissionReceiver
    );
    event royaltyEvent(address royaltyReceiver, uint256 royaltyAmount);
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    mapping(bytes32 => bool) public executedHash;
    /* Map all humbleNFT to  HumblNFTs*/
    mapping(uint256 => HumblNFT) public HumblNFTs;
    //address[] public paymentTokens;
    mapping(uint8 => address) paymentTokens;
    address public admin;
    enum SaleKind {
        FixedPrice,
        Auction
    }
    /* define struct for holds token and sale data */
    struct HumblNFT {
        string tokenURI;
        address minter;
        uint96 commission;
        bool isCommissionChanged;
        uint8 ERC20TokenIndex;
        uint96[] royalty;
        address[] royaltyReceiver;
        mapping(address => uint256) onSale;
        mapping(address => uint256) salePrice;
        uint256 salt;
    }
    /* define struct for holds temporary  NFT as parameter */
    struct NFT {
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 quantity;
        uint256 saleAmount;
        address commissionReceiver;
        uint256 commissionAmount;
        address[] royaltyReceiver;
        uint256[] royaltyAmount;
        address ERC20Token;
    }
    /* Signature struct */
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Payload {
        uint256 quantitities;
        uint256 unitPrice;
        uint256 saleQuantity;
        uint256 buyLimit;
        uint256 tokenId;
        uint256 salt;
        string tokenURI;
        uint8 ERC20TokenIndex;
        address seller;
        address buyer;
        address[] royaltyReceiver;
        uint96[] royaltyPercentage;
        SaleKind saleKind;
    }

    /* Bid Accept */
    function safeTransferNFT(
        Payload memory sellerPayload,
        Payload memory buyerPayload,
        Signature memory sellerSig,
        Signature memory buyerSig
    ) public payable whenNotPaused nonReentrant {
        bytes32 sellerHash = _Hash(sellerPayload);
        bytes32 buyerHash = _Hash(buyerPayload);
        require(!executedHash[sellerHash], "H106");
        require(!executedHash[buyerHash], "H174");
        require(validateSignature(sellerPayload.seller, sellerHash, sellerSig), "H154");
        require(validateSignature(buyerPayload.buyer, buyerHash, buyerSig), "H155");
        require(_msgSender() == sellerPayload.seller || admin == _msgSender(), "H156");
        require(buyerPayload.ERC20TokenIndex == sellerPayload.ERC20TokenIndex, "H158");
        require(buyerPayload.tokenId == sellerPayload.tokenId, "H179");
        require(buyerPayload.seller == sellerPayload.seller, "H180");
        require(sellerPayload.saleKind == SaleKind.Auction, "H162");
        if (!_exists(sellerPayload.tokenId)) {
            _mint(sellerPayload);
            executedHash[sellerHash] = true;
        }
        address _token = getPaymentToken(sellerPayload.ERC20TokenIndex);
        _executeTransferNFT(
            sellerPayload.seller,
            buyerPayload.buyer,
            buyerPayload.tokenId,
            buyerPayload.unitPrice,
            1,
            _token
        );
        executedHash[buyerHash] = true;
    }

    /* Mint with Quantities, saleQauntity, unit price, currency,royaltyFraction */
    function mint(
        uint256[6] memory intData,
        string memory tokenURI,
        uint8 ERC20TokenIndex,
        address seller,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        SaleKind salekind
    ) public whenNotPaused returns (uint256) {
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            intData[3],
            intData[4],
            intData[5],
            tokenURI,
            ERC20TokenIndex,
            seller,
            address(0),
            royaltyReceiver,
            royaltyPercentage,
            salekind
        );
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        payload.tokenId = _mint(payload);
        executedHash[hash] = true;
        return payload.tokenId;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return HumblNFTs[tokenId].tokenURI;
    }

    /* Mint and buy with Quantities, saleQauntity, unit price, currency,royaltyFraction */
    function lazyMint(
        uint256[6] memory intData,
        string calldata tokenURI,
        uint8 ERC20TokenIndex,
        address seller,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        uint256 quantity,
        Signature memory sig,
        SaleKind salekind
    ) public payable whenNotPaused nonReentrant returns (uint256 tokenId) {
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            intData[3],
            intData[4],
            intData[5],
            tokenURI,
            ERC20TokenIndex,
            seller,
            address(0),
            royaltyReceiver,
            royaltyPercentage,
            salekind
        );
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        require(payload.saleKind == SaleKind.FixedPrice, "H162");
        address buyer = _msgSender();
        require(validateSignature(seller, hash, sig), "H107");
        payload.tokenId = _mint(payload);
        _safeTransferNFT(payload, buyer, quantity);
        executedHash[hash] = true;
        return payload.tokenId;
    }

    /* mint and transfer */
    function transferWithMint(
        uint256[6] memory intData,
        string calldata tokenURI,
        uint8 ERC20TokenIndex,
        address seller,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        uint256 quantity,
        address to
    ) public whenNotPaused returns (uint256 tokenId) {
        require(royaltyPercentage.length == royaltyReceiver.length, "H105");
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            intData[3],
            intData[4],
            intData[5],
            tokenURI,
            ERC20TokenIndex,
            seller,
            address(0),
            royaltyReceiver,
            royaltyPercentage,
            SaleKind.FixedPrice
        );
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        payload.tokenId = _mint(payload);
        safeTransferFrom(payload.seller, to, payload.tokenId, quantity, "");
        executedHash[hash] = true;
        return payload.tokenId;
    }

    /* Buy token */
    function safeBuyNFT(
        Payload memory payload,
        Signature memory sig,
        uint256 quantity
    ) public payable whenNotPaused nonReentrant {
        bytes32 hash = _Hash(payload);
        address buyer = _msgSender();
        require(buyer != address(0), "H181");
        require(validateSignature(payload.seller, hash, sig), "H107");
        require(payload.saleKind == SaleKind.FixedPrice, "H162");
        if (!executedHash[hash]) {
            HumblNFT storage nft = HumblNFTs[payload.tokenId];
            require(payload.salt >= nft.salt, "H161");
            _addOnSale(payload.tokenId, payload.seller, payload.unitPrice, payload.saleQuantity);
            executedHash[hash] = true;
        }
        _safeTransferNFT(payload, buyer, quantity);
    }

    /* Add token on sale */
    function addOnSale(
        uint256 tokenId,
        uint256 unitPrice,
        uint256 saleQuantity
    ) public whenNotPaused {
        address account = _msgSender();
        _addOnSale(tokenId, account, unitPrice, saleQuantity);
    }

    function _addOnSale(
        uint256 tokenId,
        address account,
        uint256 unitPrice,
        uint256 saleQuantity
    ) internal {
        require(_exists(tokenId), "H108");
        require(unitPrice >= 1, "H109");
        require(saleQuantity >= 1, "H110");
        uint256 quantity = balanceOf(account, tokenId);
        HumblNFT storage nft = HumblNFTs[tokenId];
        require(saleQuantity <= quantity, "H111");
        nft.salePrice[account] = unitPrice;
        nft.onSale[account] = saleQuantity;
        nft.salt = block.timestamp;
    }

    function validateSignature(
        address seller,
        bytes32 hash,
        Signature memory sig
    ) public pure returns (bool) {
        bytes32 _hash = hash.toEthSignedMessageHash();
        return _hash.recover(sig.v, sig.r, sig.s) == seller;
    }

    /* Invalidate signature */
    function cancelHash(Payload memory payload, Signature memory sig) public whenNotPaused {
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        require(validateSignature(_msgSender(), hash, sig), "H107");
        executedHash[hash] = true;
    }

    /* Genrate signature */
    function _Hash(Payload memory payload) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    payload.quantitities,
                    payload.unitPrice,
                    payload.saleQuantity,
                    payload.buyLimit,
                    payload.tokenId,
                    payload.tokenURI,
                    payload.ERC20TokenIndex,
                    payload.seller,
                    payload.buyer,
                    payload.royaltyReceiver,
                    payload.royaltyPercentage,
                    payload.salt,
                    payload.saleKind,
                    address(this)
                )
            );
    }

    /* Mint with Quantities, saleQauntity, unit price, currency,royaltyFraction */
    function _mint(Payload memory payload) internal returns (uint256) {
        require(!_exists(payload.tokenId), "H173");
        require(payload.royaltyPercentage.length == payload.royaltyReceiver.length, "H105");
        require(bytes(payload.tokenURI).length >= 1, "H116");
        require(payload.quantitities >= 1, "H117");
        require(payload.saleQuantity <= payload.quantitities, "H118");
        uint256 totalFee;
        for (uint256 i = 0; i < payload.royaltyPercentage.length; ++i) {
            totalFee = totalFee.add(payload.royaltyPercentage[i]);
        }
        require(totalFee <= 5000, "H176");
        _mint(payload.seller, payload.tokenId, payload.quantitities, "");
        if (bytes(payload.tokenURI).length > 0) {
            emit URI(payload.tokenURI, payload.tokenId);
        }
        HumblNFT storage newNFT = HumblNFTs[payload.tokenId];
        newNFT.tokenURI = payload.tokenURI;
        newNFT.minter = payload.seller;
        newNFT.ERC20TokenIndex = payload.ERC20TokenIndex;
        newNFT.royalty = payload.royaltyPercentage;
        newNFT.royaltyReceiver = payload.royaltyReceiver;
        newNFT.salt = payload.salt;
        newNFT.onSale[payload.seller] = payload.saleQuantity;
        newNFT.salePrice[payload.seller] = payload.unitPrice;
        return payload.tokenId;
    }

    /* Set commission fee by plateform owner */
    function setCommission(uint256 tokenId, uint96 commissionPercentage) public virtual onlyOwner {
        require(_exists(tokenId), "H120");
        require(commissionPercentage >= 0, "H121");
        require(commissionPercentage <= 5000, "H122");
        HumblNFT storage nft = HumblNFTs[tokenId];
        nft.commission = commissionPercentage;
        nft.isCommissionChanged = true;
    }

    /* Set commission fee receiver*/
    function setCommissionReceiver(address commissionReceiver) public virtual onlyOwner {
        _setCommissionReceiver(commissionReceiver);
    }

    /* Return Commission fee */
    function getCommissionBalance(address receiver) public view onlyOwner returns (uint256) {
        return _getCommissionBalance(receiver);
    }

    /* Set commission fee in percentage beetween 0 to 100 */
    function setDefaultCommission(uint96 commissionPercentage) public virtual onlyOwner {
        require(commissionPercentage >= 0, "H123");
        require(commissionPercentage <= 5000, "H124");
        _setDefaultCommission(commissionPercentage);
    }

    /* Return default commission fee */
    function getDefaultCommission() public view returns (uint256) {
        return _getDefaultCommission();
    }

    /* Return commission fee receiver */
    function getCommissionReceiver() public view returns (address) {
        return _getCommissionReceiver();
    }

    /* Pause contract for execution - stopped state */
    function pause() public onlyOwner {
        _pause();
    }

    /* Unpause contract return to normal state */
    function unpause() public onlyOwner {
        _unpause();
    }

    /* Get royalties receiver and percentage */
    function getRoyalties(uint256 tokenId) public view returns (uint96[] memory, address[] memory) {
        require(_exists(tokenId), "H126");
        return (HumblNFTs[tokenId].royalty, HumblNFTs[tokenId].royaltyReceiver);
    }

    /* Set ERC20 payment token */
    function setPaymentToken(uint8 index, address token) public virtual onlyOwner {
        paymentTokens[index] = token;
    }

    /* Get ERC20 payment token */
    function getPaymentToken(uint8 index) public view returns (address) {
        return paymentTokens[index];
    }

    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "H138");
        admin = _admin;
    }

    /* To check only token minter is allowed */
    modifier tokenMinterOnly(uint256 tokenId) {
        HumblNFT storage nft = HumblNFTs[tokenId];
        require(nft.minter == _msgSender(), "H104");
        _;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return HumblNFTs[tokenId].minter != address(0);
    }

    /* Token minter can add more quantity - only original owner */
    function addOnSupply(uint256 tokenId, uint256 quantity)
        public
        tokenMinterOnly(tokenId)
        whenNotPaused
    {
        address account = _msgSender();
        require(account != address(0), "H125");
        require(_exists(tokenId), "H126");
        _mint(account, tokenId, quantity, "");
    }

    /* Token minter can burn quantity - only original owner */
    function burnSupply(uint256 tokenId, uint256 quantity) public virtual whenNotPaused {
        address account = _msgSender();
        require(account != address(0), "H127");
        require(_exists(tokenId), "H128");
        require(balanceOf(account, tokenId) >= quantity, "H129");
        _burn(account, tokenId, quantity);
        uint256 balance = balanceOf(account, tokenId);
        HumblNFT storage nft = HumblNFTs[tokenId];
        if (nft.onSale[account] > balance) {
            nft.onSale[account] = balance;
        }
    }

    /* Get quantity from sale */
    function getQunatityFromSale(uint256 tokenId) public view returns (uint256) {
        address account = _msgSender();
        require(account != address(0), "H127");
        require(_exists(tokenId), "H131");
        HumblNFT storage nft = HumblNFTs[tokenId];
        return nft.onSale[account];
    }

    function _safeTransferNFT(
        Payload memory payload,
        address to,
        uint256 quantity
    ) internal {
        require(payload.seller != address(0), "H138");
        require(quantity >= 1, "H139");
        HumblNFT storage nft = HumblNFTs[payload.tokenId];
        require(nft.onSale[payload.seller] >= quantity, "H140");
        if (payload.buyLimit > 0) {
            require(quantity <= payload.buyLimit, "H141");
        }
        payload.unitPrice = nft.salePrice[payload.seller];
        address ERC20Token = paymentTokens[nft.ERC20TokenIndex];
        _executeTransferNFT(
            payload.seller,
            to,
            payload.tokenId,
            payload.unitPrice,
            quantity,
            ERC20Token
        );
        nft.onSale[payload.seller] = (nft.onSale[payload.seller]).sub(quantity);
    }

    function _executeTransferNFT(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity,
        address ERC20Token
    ) internal {
        require(_exists(tokenId), "H143");
        require(balanceOf(seller, tokenId) >= quantity, "H144");
        HumblNFT storage nft = HumblNFTs[tokenId];
        uint256 saleAmount = quantity.mul(unitPrice);
        if (ERC20Token == address(0)) {
            require(msg.value == saleAmount, "H145");
        } else {
            require(IERC20Upgradeable(ERC20Token).balanceOf(buyer) >= saleAmount, "H146");
        }
        uint256[] memory royaltyAmount = new uint256[](nft.royalty.length);
        address commissionReceiver;
        uint256 commissionAmount;
        if (nft.minter != seller) {
            if (nft.royalty.length > 0) {
                for (uint256 i = 0; i < nft.royalty.length; i++) {
                    royaltyAmount[i] = (saleAmount * nft.royalty[i]) / 10000;
                }
            }
        }
        if (nft.isCommissionChanged) {
            if (nft.commission > 0) {
                (commissionReceiver, commissionAmount) = _getCommission(nft.commission, saleAmount);
            }
        } else {
            (commissionReceiver, commissionAmount) = _getCommission(
                _getDefaultCommission(),
                saleAmount
            );
        }
        NFT memory _data = NFT(
            tokenId,
            seller,
            buyer,
            quantity,
            saleAmount,
            commissionReceiver,
            commissionAmount,
            nft.royaltyReceiver,
            royaltyAmount,
            ERC20Token
        );
        _executeFundTransfer(_data);
        _safeTransferFrom(seller, buyer, tokenId, quantity, "");
    }

    /* Execute funds transfer */
    function _executeFundTransfer(NFT memory _data) internal {
        /* Commission calculation and pay*/
        if (_data.commissionAmount > 0) {
            if (_data.ERC20Token == address(0)) {
                _setCommissionBalance(_data.commissionReceiver, _data.commissionAmount);
                payable(_data.commissionReceiver).transfer(_data.commissionAmount);
            } else {
                _transferWithTokens(
                    _data.ERC20Token,
                    _data.buyer,
                    _data.commissionReceiver,
                    _data.commissionAmount
                );
            }
        }
        /* Royalty calculation on secondary sale and pay*/
        uint256 totalRoyaltyAmount = 0;
        if (_data.royaltyAmount.length > 0) {
            if (_data.ERC20Token == address(0)) {
                for (uint256 i = 0; i < _data.royaltyAmount.length; i++) {
                    totalRoyaltyAmount = totalRoyaltyAmount.add(_data.royaltyAmount[i]);
                    payable(_data.royaltyReceiver[i]).transfer(_data.royaltyAmount[i]);
                    emit royaltyEvent(_data.royaltyReceiver[i], _data.royaltyAmount[i]);
                }
            } else {
                for (uint256 i = 0; i < _data.royaltyAmount.length; i++) {
                    totalRoyaltyAmount = totalRoyaltyAmount.add(_data.royaltyAmount[i]);
                    _transferWithTokens(
                        _data.ERC20Token,
                        _data.buyer,
                        _data.royaltyReceiver[i],
                        _data.royaltyAmount[i]
                    );
                    emit royaltyEvent(_data.royaltyReceiver[i], _data.royaltyAmount[i]);
                }
            }
        }
        uint256 _transferAbleAmount = (_data.saleAmount).sub(
            ((totalRoyaltyAmount).add(_data.commissionAmount)),
            "H148"
        );

        if (_data.ERC20Token == address(0)) {
            payable(_data.seller).transfer(_transferAbleAmount);
        } else {
            _transferWithTokens(_data.ERC20Token, _data.buyer, _data.seller, _transferAbleAmount);
        }
        emit safeSaleNFT(
            _data.seller,
            _data.buyer,
            _data.tokenId,
            _data.quantity,
            _transferAbleAmount,
            _data.commissionAmount,
            _data.commissionReceiver
        );
    }

    function _transferWithTokens(
        address ERC20Token,
        address from,
        address to,
        uint256 price
    ) internal {
        if (price > 0) {
            require(IERC20Upgradeable(ERC20Token).transferFrom(from, to, price), "H175");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}