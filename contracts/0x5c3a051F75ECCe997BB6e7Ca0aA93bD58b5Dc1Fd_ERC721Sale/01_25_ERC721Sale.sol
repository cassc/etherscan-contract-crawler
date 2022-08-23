// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../proxy/ServiceFeeProxy.sol";
import "../proxy/TransferProxy.sol";
import "../tokens/HasSecondarySale.sol";
import "../tokens/HasAffiliateFees.sol";
import "./ERC721SaleNonceHolder.sol";
import "../interfaces/IIkonictoken.sol";
import "../interfaces/IIkonicERC721Token.sol";

contract ERC721Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce
    );

    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        address buyer
    );

    event Sell(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint8[] accCurIds,
        uint256 expSaleDate
    );

    event UpdatePriceAndCurrency(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId
    );

    event UpdateExpSaleDate(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate
    );

    event Withdrawn(
        address receiver,
        uint256 amount,
        uint256 balance
    );

    struct SaleInfo {
        address owner;
        uint256 price;
        uint8 currencyId;
        uint8[] accCurIds; // acceptable currency Id lists
        uint256 expSaleDate;
    }

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    TransferProxy private transferProxy;
    ServiceFeeProxy private serviceFeeProxy;
    ERC721SaleNonceHolder private nonceHolder;

    /// @dev token address -> token id -> sale info
    mapping(address => mapping(uint256 => SaleInfo)) public saleInfos;

    /// @dev token address -> token id -> latestSalePrice
    mapping(address => mapping(uint256 => uint256)) public latestSalePrices;

    /// @dev currencyType -> currency Address 
    mapping(uint8 => address) public supportCurrencies;

    string[] public supportCurrencyName = ["ETH"];

    constructor(
        TransferProxy _transferProxy,
        ERC721SaleNonceHolder _nonceHolder,
        ServiceFeeProxy _serviceFeeProxy
    ) {
        require(
            address(_transferProxy) != address(0x0) && 
            address(_nonceHolder) != address(0x0) &&
            address(_serviceFeeProxy) != address(0x0)
        );
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
        serviceFeeProxy = _serviceFeeProxy;
    }

    /**
     * @notice list token on sale list
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _expSaleDate approve sale date of token
     * @param _price price of token
     * @param _currencyId currency Index
     * @param _accCurrencyIds acceptable currency id list
     * @param _signature signature from frontend
     */
    function sell(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate,
        uint256 _price,
        uint8 _currencyId,
        uint8[] memory _accCurrencyIds,
        bytes memory _signature
    ) external nonReentrant {
        require(
            _token.ownerOf(_tokenId) == msg.sender,
            "ERC721Sale.sell: Caller is not the owner of the token"
        );
        require(_expSaleDate >= _getNow(), "ERC721Sale.sell: Approved sale date invalid");
        require(_price > 0, "ERC721Sale.sell: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC721Sale.sell: Base currency is not supported");
        unchecked {
            for (uint256 index = 0; index < _accCurrencyIds.length; index++) {
                require(isCurrencyValid(_accCurrencyIds[index]), "ERC721Sale.sell: Acceptable currencies are not supported");
            }
        }

        require(
            keccak256(abi.encodePacked(address(_token), _tokenId, _price, uint256(_currencyId))).toEthSignedMessageHash().recover(_signature) == _token.getSignerAddress(),
            "ERC721Sale.verifySignature: Incorrect signature"
        );

        saleInfos[address(_token)][_tokenId] = SaleInfo({
            owner: msg.sender,
            price: _price,
            currencyId: _currencyId,
            accCurIds: _accCurrencyIds, 
            expSaleDate: _expSaleDate
        });

        emit Sell(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId,
            _accCurrencyIds,
            _expSaleDate
        );
    }

    /**
     * @notice buy token
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _price price of token     
     * @param _currencyId currency Index
     * @param _signature signature from frontend
     */
    function buy(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId,
        bytes memory _signature
    ) external nonReentrant payable {
        address owner = _token.ownerOf(_tokenId);
        address saleOwner = saleInfos[address(_token)][_tokenId].owner;
        require(owner == saleOwner, "ERC721Sale.buy: Token ownership changed");
        
        require(
            saleInfos[address(_token)][_tokenId].expSaleDate >= _getNow(),
            "ERC721Sale.buy: Token sale expired"
        );

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            owner,
            _price,
            _currencyId,
            _signature
        );
        verifyOpenAndModifyState(address(_token), _tokenId, owner, nonce);

        require(isCurrencyValid(_currencyId), "ERC721Sale.buy: Currency is not supported");

        require(isCurrencyAcceptable(_token, _tokenId, _currencyId), "ERC721Sale.buy: Buying currency is not acceptable");

        uint256 buyerServiceFeeBps = serviceFeeProxy.getBuyServiceFeeBps();
        uint256 buyerServiceFee = _price.mul(buyerServiceFeeBps).div(10000);
        uint256 price = _price.add(buyerServiceFee);

        if (_currencyId == 0) {
            require(msg.value >= price, "ERC721Sale.buy: Insufficient funds");
            // return change if any
            if (msg.value > price) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value - price}("");
                require(sent, "ERC721Sale.buy: Change transfer failed");
            }
        } else {
            if (msg.value > 0) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value}("");
                require(sent, "ERC721Sale.buy: Change transfer failed");
            }
            IERC20(supportCurrencies[_currencyId]).transferFrom(msg.sender, address(this), price);
        }       
        
        distributePayment(_token, _tokenId, owner, _price, _currencyId);
        transferProxy.erc721safeTransferFrom(_token, owner, msg.sender, _tokenId);
        
        // Remove from sale info list
        delete saleInfos[address(_token)][_tokenId];

        // Update latest sale price list
        latestSalePrices[address(_token)][_tokenId] = _price;

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            SecondarySale.setSecondarySale(_tokenId);
        }

        emit Buy(
            address(_token),
            _tokenId,
            owner,
            price,
            _currencyId,
            msg.sender
        );
    }
    
    /**
     * @notice Send payment to seller, service fee recipient and royalty recipient
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _owner owner of token     
     * @param _currencyId currency Index
     */
    function distributePayment(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        address _owner,
        uint256 _price,
        uint8 _currencyId
    ) internal {
        // address that should collect Ikonic service fee 
        address serviceFeeRecipient = serviceFeeProxy.getServiceFeeRecipient();

        // uint256 tokenPrice = saleInfos[address(_token)][_tokenId].price;
        uint256 sellerServiceFee = _price.mul(serviceFeeProxy.getSellServiceFeeBps()).div(10000);
        uint256 buyerServiceFee = _price.mul(serviceFeeProxy.getBuyServiceFeeBps()).div(10000);

        uint256 ownerReceivingAmount = _price.sub(sellerServiceFee);
        uint256 totalServiceFeeAmount = sellerServiceFee.add(buyerServiceFee);
        

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            bool isSecondarySale = SecondarySale.checkSecondarySale(_tokenId);

            if(isSecondarySale) {
                (address receiver, uint256 royaltyAmount) = _token.royaltyInfo(_tokenId, _price);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(receiver).call{value: royaltyAmount}("");
                    require(royaltySent, "ERC721Sale.distributePayment: Royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(receiver, royaltyAmount);
                }
                ownerReceivingAmount = ownerReceivingAmount.sub(royaltyAmount);
                uint256 fee = checkFee(_token, _tokenId, _price, _currencyId);
                ownerReceivingAmount = ownerReceivingAmount.sub(fee);
            }
        }

        if (_token.supportsInterface(_INTERFACE_ID_FEES)) {
            uint256 sumAffFee = distributeFee(_token, _tokenId, _price, _currencyId);
            ownerReceivingAmount = ownerReceivingAmount.sub(sumAffFee);
        }

        if ( _currencyId == 0 ) {
            (bool serviceFeeSent, ) = payable(serviceFeeRecipient).call{value: totalServiceFeeAmount}("");
            require(serviceFeeSent, "ERC721Sale.distributePayment: ServiceFee transfer failed");
            (bool ownerReceivingAmountSent, ) = payable(_owner).call{value: ownerReceivingAmount}("");
            require(ownerReceivingAmountSent, "ERC721Sale.distributePayment: ownerReceivingAmount transfer failed");
        } else {
            IERC20(supportCurrencies[_currencyId]).transfer(serviceFeeRecipient, totalServiceFeeAmount);
            IERC20(supportCurrencies[_currencyId]).transfer(_owner, ownerReceivingAmount);
        }
    }

    function distributeFee(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) internal returns(uint) {
        HasAffiliateFees withFees = HasAffiliateFees(address(_token));
        address [] memory recipients = withFees.getFeeRecipients(_tokenId);
        uint256[] memory fees = withFees.getFeeBps(_tokenId);
        require(fees.length == recipients.length);
        uint256 sumFee;
        unchecked{
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 current = _price.mul(fees[i]).div(10000);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(recipients[i]).call{value: current}("");
                    require(royaltySent, "ERC721Sale.distributePayment: Affiliate royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(recipients[i], current);
                }
                sumFee = sumFee.add(current);
            }
        }
        return sumFee;
    }

    function checkFee(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) internal returns(uint) {
        if (_token.supportsInterface(_INTERFACE_ID_FEES)) {
            HasAffiliateFees AffiliateSale = HasAffiliateFees(address(_token));
            bool isAffiliateSale = AffiliateSale.checkAffiliateSale(_tokenId);
            address affiliateRecipient = AffiliateSale.getAffiliateFeeRecipient();
            uint256 affiliateAmount = _price.mul(AffiliateSale.getAffiliateFee()).div(10000);
            if (isAffiliateSale) {
                if ( _currencyId == 0 ) {
                    (bool Sent, ) = payable(affiliateRecipient).call{value: affiliateAmount}("");
                    require(Sent, "ERC721Sale.distributePayment: Affiliate Royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(affiliateRecipient, affiliateAmount);
                }
                return affiliateAmount;
            } else {
                AffiliateSale.setAffiliateSale(_tokenId);
            }
        }
        return 0;
    }

    /**
     * @notice Cancel listing of token
     * @param _token ERC721 Token
     * @param _tokenId token Id
     */
    function cancel(
        IIkonicERC721Token _token, 
        uint256 _tokenId
    ) external {
        require(
            saleInfos[address(_token)][_tokenId].owner == msg.sender,
            "ERC721Sale.cancel: Token owner can only cancel the sale"
        );

        uint256 nonce = nonceHolder.getNonce(
            address(_token),
            _tokenId, msg.sender
        );

        nonceHolder.setNonce(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1)
        );

        delete saleInfos[address(_token)][_tokenId];
        
        emit CloseOrder(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1)
        );
    }

    /**
     * @notice Recover signer address from signature and verify it's correct
     * @param token ERC721 Token
     * @param tokenId token Id
     * @param owner owner address of token
     * @param price price of token
     * @param currencyId currency index
     * @param signature signature 
     */
    function verifySignature(
        IIkonicERC721Token token,
        uint256 tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        bytes memory signature
    ) internal view returns (uint256 nonce) {
        nonce = nonceHolder.getNonce(address(token), tokenId, owner);
        require(
            keccak256(abi.encodePacked(address(token), tokenId, price, uint256(currencyId), nonce)).toEthSignedMessageHash().recover(signature) == token.getSignerAddress(),
            "ERC721Sale.verifySignature: Incorrect signature"
        );
    }

    /**
     * @notice Modify state by setting nonce and closing order
     * @param token ERC721 Token
     * @param tokenId token Id
     * @param owner owner address of token
     * @param nonce nonce value of token
     */
    function verifyOpenAndModifyState(
        address token,
        uint256 tokenId,
        address owner,
        uint256 nonce
    ) internal {
        nonceHolder.setNonce(token, tokenId, owner, nonce.add(1));
        emit CloseOrder(token, tokenId, owner, nonce.add(1));
    }
    
    /**
     * @notice update price and currency of token
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _price price of token
     * @param _currencyId currency index
     */
     function updatePriceAndCurrency(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) external {
        require(
            _token.ownerOf(_tokenId) == msg.sender,
            "ERC721Sale.updatePriceAndCurrency: Token owner can only update price and currency"
        );
        require(_price > 0, "ERC721Sale.updatePriceAndCurrency: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC721Sale.updatePriceAndCurrency: Currency is not supported");

        saleInfos[address(_token)][_tokenId].price = _price;
        saleInfos[address(_token)][_tokenId].currencyId = _currencyId;

        emit UpdatePriceAndCurrency(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId
        );
    }

    /**
     * @notice update expiration date
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _expSaleDate expiration date
     */
     function updateExpSaleDate(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate
    ) external {
        require(
            _token.ownerOf(_tokenId) == msg.sender,
            "ERC721Sale.updateExpSaleDate: Token owner can only update expiration date"
        );
        require(_expSaleDate >= _getNow(), "ERC721Sale.updateExpSaleDate: Approved sale date invalid");

        saleInfos[address(_token)][_tokenId].expSaleDate = _expSaleDate;
        emit UpdateExpSaleDate(
            address(_token),
            _tokenId,
            msg.sender,
            _expSaleDate
        );
    }

    /**
     * @notice Get Sale info with token address and token id
     * @param _token ERC721 Token Interface
     * @param _tokenId Id of token
     */
    function getSaleInfo(
        IIkonicERC721Token _token,
        uint256 _tokenId
    ) external view returns (SaleInfo memory) {
        return saleInfos[address(_token)][_tokenId];
    }

    /**
     * @notice Get Sale price with token address and token id
     * @param _token ERC721 Token Interface
     * @param _tokenId Id of token
     */
    function getSalePrice(
        IIkonicERC721Token _token,
        uint256 _tokenId
    ) external view returns (uint256) {
        if(saleInfos[address(_token)][_tokenId].price != 0) {
            return saleInfos[address(_token)][_tokenId].price;
        }

        if(latestSalePrices[address(_token)][_tokenId] != 0) {
            return latestSalePrices[address(_token)][_tokenId];
        }

        return 0;
    }

    /**
     * @notice send / withdraw amount to receiver
     * @param receiver recipient address
     * @param amount amount to withdraw
     * @param curId currency index
    */
    function withdrawTo(address receiver, uint256 amount, uint8 curId) external onlyOwner {
        require(receiver != address(0) && receiver != address(this), "ERC721Sale.withdrawTo: Invalid withdrawal recipient address");
        if (curId == 0) {    
            require(amount > 0 && amount <= address(this).balance, "ERC721Sale.withdrawTo: Invalid withdrawal amount");
            (bool sent, ) = payable(receiver).call{value: amount}("");
            require(sent, "ERC721Sale.withdrawTo: Transfer failed");
        } else {
            require(amount > 0 && amount <= IERC20(supportCurrencies[curId]).balanceOf(address(this)), "ERC721Sale.withdrawTo: Invalid withdrawal amount");
            IERC20(supportCurrencies[curId]).transfer(receiver, amount);
        }
        emit Withdrawn(receiver, amount, address(this).balance);
    }

    /// @notice returns current block timestamp
    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice returns currency name by index
     * @param currencyIndex index of currency
     */
    function getCurrencyName(uint8 currencyIndex) external view returns (string memory) {
        require(isCurrencyValid(currencyIndex), "ERC721Sale.getCurrencyName: Currency is not supported");
        return supportCurrencyName[currencyIndex];
    }

    /// @notice returns count of supporting currency names
    function getCurrencyNameCount() external view returns (uint) {
        return supportCurrencyName.length;
    }

    /**
     * @notice add new currency
     * @param curName name of new currency
     * @param curAddress address of new currency
     */
    function addSupportCurrency(string memory curName, address curAddress) external onlyOwner {
        uint8 i = 0;
        uint256 curLength = supportCurrencyName.length;
        unchecked {
            for (i = 1; i < curLength; i++) {   
                require(supportCurrencies[i] != curAddress, "ERC721Sale.addSupportCurrency: This currency already exists");
            }
        }
        supportCurrencies[i] = curAddress;
        supportCurrencyName.push(curName);
    }

    /**
     * @notice update currency
     * @param curIndex index of currency
     * @param curAddress address of currency
     */
    function updateCurrencyAddress(uint8 curIndex, address curAddress) external onlyOwner {
        require(isCurrencyValid(curIndex), "ERC721Sale.updateCurrencyAddress: Currency is not supported");
        supportCurrencies[curIndex] = curAddress;
    }

    /**
     * @notice check if currency is added to currency supporting list or not
     * @param curIndex index of currency
     */
    function isCurrencyValid(uint8 curIndex) public view returns (bool) {
        return (curIndex == 0 || supportCurrencies[curIndex] != address(0x0)) ? true : false;
    }

    /**
     * @notice check if currency is added to acceptable list
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     * @param _currencyId index of currency
     */
    function isCurrencyAcceptable(
        IIkonicERC721Token _token,
        uint256 _tokenId,
        uint8 _currencyId
    ) internal view returns (bool) {
        uint8 listedCurId = saleInfos[address(_token)][_tokenId].currencyId;
        if (listedCurId == _currencyId) {
            return true;    
        }
        uint8[] memory accCurIds = saleInfos[address(_token)][_tokenId].accCurIds;
        unchecked {
            for (uint256 index = 0; index < accCurIds.length; index++) {
                if (accCurIds[index] == _currencyId) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @notice returns acceptable currency id list
     * @param _token ERC721 Token
     * @param _tokenId Id of token
     */
    function getAcceptableCurrencyIds(IIkonicERC721Token _token, uint256 _tokenId) external view returns (uint8[] memory) {
        return saleInfos[address(_token)][_tokenId].accCurIds;
    }
}