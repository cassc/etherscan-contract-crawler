// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC1155SaleNonceHolder.sol";
import "../tokens/HasSecondarySale.sol";
import "../tokens/HasAffiliateFees.sol";
import "../proxy/TransferProxy.sol";
import "../proxy/ServiceFeeProxy.sol";
import "../interfaces/IIkonictoken.sol";
import "../interfaces/IIkonicERC1155Token.sol";

contract ERC1155Sale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 orderId;

    event CloseOrder(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 nonce,
        uint256 orderId
    );

    event Buy(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        address buyer,
        uint256 buyingAmount,
        uint256 orderId
    );

    event Sell(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint8[] accCurIds,
        uint256 expSaleDate,
        uint256 orderId
    );

    event UpdatePriceAndCurrency(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint256 orderId
    );

    event UpdateExpSaleDate(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
    );

    event UpdateSaleAmount(
        address indexed token,
        uint256 indexed tokenId,
        address owner,
        uint256 expSaleDate,
        uint256 orderId
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
        uint256 amount;
        uint256 orderId;
        uint256 expSaleDate;
    }

    bytes constant EMPTY = "";
    bytes4 private constant _INTERFACE_ID_HAS_SECONDARY_SALE = 0x5595380a;
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /// @dev token address -> order ID -> token id -> sale info
    mapping(address => mapping(uint256 => mapping(uint256 => SaleInfo))) public saleInfos;

    /// @dev token address -> token id -> latestListingPrice
    mapping(address => mapping(uint256 => uint256)) public latestListingPrices;

    /// @dev token address -> token id -> latestSalePrice
    mapping(address => mapping(uint256 => uint256)) public latestSalePrices;

    /// @dev currencyType -> currency Address 
    mapping(uint8 => address) public supportCurrencies;

    string[] public supportCurrencyName = ["ETH"];

    TransferProxy private transferProxy;
    ServiceFeeProxy private serviceFeeProxy;
    ERC1155SaleNonceHolder private nonceHolder;

    constructor(
        TransferProxy _transferProxy,
        ERC1155SaleNonceHolder _nonceHolder,
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
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _expSaleDate approve sale date of token
     * @param _price price of token
     * @param _currencyId currency Index
     * @param _accCurrencyIds acceptable currency id list
     * @param _amount amount of token for sell
     * @param _signature signature from frontend
     */
     function sell(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate,
        uint256 _price,
        uint8 _currencyId,
        uint8[] memory _accCurrencyIds,
        uint256 _amount,
        bytes memory _signature
    ) external nonReentrant {
        require(
            _token.balanceOf(msg.sender, _tokenId) >= _amount,
            "ERC1155Sale.sell: Sell amount exceeds balance"
        );
        
        require(_expSaleDate >= _getNow(), "ERC1155Sale.sell: Approved sale date invalid");
        require(_price > 0, "ERC1155Sale.sell: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC1155Sale.sell: Base currency is not supported");
        unchecked {
            for (uint256 index = 0; index < _accCurrencyIds.length; index++) {
                require(isCurrencyValid(_accCurrencyIds[index]), "ERC1155Sale.sell: Acceptable currencies are not supported");
            }
        }

        require(
            keccak256(abi.encodePacked(address(_token), _tokenId, _price, uint256(_currencyId), _amount))
                .toEthSignedMessageHash()
                .recover(_signature) == _token.getSignerAddress(),
            "ERC1155Sale.sell: Incorrect signature"
        );
        orderId++;

        saleInfos[address(_token)][orderId][_tokenId] = SaleInfo({
            owner: msg.sender,
            price: _price,
            currencyId: _currencyId,
            accCurIds: _accCurrencyIds,
            expSaleDate: _expSaleDate,
            amount: _amount,
            orderId: orderId
        });

        // Update the latest listing price with the _price value
        latestListingPrices[address(_token)][_tokenId] = _price;
        
        emit Sell(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId,
            _accCurrencyIds,
            _expSaleDate,
            orderId
        );
    }

    /**
     * @notice buy token
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _orderId Id of order list
     * @param _price price of token
     * @param _currencyId currency Index
     * @param _amount buying Amount
     * @param _signature signature from frontend
     */

    function buy(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _amount,
        bytes memory _signature
    ) external nonReentrant payable {
        require(
            saleInfos[address(_token)][_orderId][_tokenId].amount > 0,
            "ERC1155Sale.buy: Doesn't listed for sale"
        );
        require(
            saleInfos[address(_token)][_orderId][_tokenId].expSaleDate >= _getNow(),
            "ERC1155Sale.buy: Token sale expired"
        );

        require(
            saleInfos[address(_token)][_orderId][_tokenId].amount >= _amount,
            "ERC1155Sale.buy: Buying amount exceeds balance"
        );

        require(isCurrencyValid(_currencyId), "ERC1155Sale.buy: Currency is not supported");
        require(isCurrencyAcceptable(_token, _tokenId, _orderId, _currencyId), "ERC1155Sale.buy: Buying currency is not acceptable");

        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;

        uint256 nonce = verifySignature(
            _token,
            _tokenId,
            _owner,
            _price,
            _currencyId,
            _amount,
            _signature
        );
        verifyOpenAndModifyState(address(_token), _tokenId, _orderId, _owner, nonce);

        uint256 price = _price.mul(_amount).add(_price.mul(_amount).mul(serviceFeeProxy.getBuyServiceFeeBps()).div(10000));

        if (_currencyId == 0) {    
            require(msg.value >= price, "ERC1155Sale.buy: Insufficient funds");
            // return change if any
            if (msg.value > price) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value - price}("");
                require(sent, "ERC1155Sale.buy: Change transfer failed");
            }
        } else {
            if (msg.value > 0) {
                (bool sent, ) = payable(msg.sender).call{value: msg.value}("");
                require(sent, "ERC1155Sale.buy: Change transfer failed");
            }
            IERC20(supportCurrencies[_currencyId]).transferFrom(msg.sender, address(this), price);
        }
            
        distributePayment(_token, _tokenId, _orderId, _price, _currencyId, _amount);
        transferProxy.erc1155safeTransferFrom(
            _token,
            _owner,
            msg.sender,
            _tokenId,
            _amount,
            EMPTY
        );
        
        // Remove from sale info list
        saleInfos[address(_token)][_orderId][_tokenId].amount = saleInfos[address(_token)][_orderId][_tokenId].amount.sub(_amount);
        if(saleInfos[address(_token)][_orderId][_tokenId].amount == 0) {
            delete saleInfos[address(_token)][_orderId][_tokenId];
            delete latestListingPrices[address(_token)][_tokenId];
        }

        // Update latest sale price list
        latestSalePrices[address(_token)][_tokenId] = _price;

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            SecondarySale.setSecondarySale(_tokenId);
        }

        emit Buy(
            address(_token),
            _tokenId,
            _owner,
            price,
            _currencyId,
            msg.sender,
            _amount,
            _orderId
        );
    }

    /**
     * @notice Send payment to seller, service fee recipient and royalty recipient
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _orderId order index
     * @param _price price of token     
     * @param _currencyId currency Index
     * @param _amount buying amount
     */
    function distributePayment(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _amount
    ) internal {
        // uint256 sellerServiceFeeBps = serviceFeeProxy.getSellServiceFeeBps();
        // uint256 buyerServiceFeeBps = serviceFeeProxy.getBuyServiceFeeBps();

        uint256 tokenPrice = _price.mul(_amount);
        uint256 sellerServiceFee = tokenPrice.mul(serviceFeeProxy.getSellServiceFeeBps()).div(10000);

        uint256 ownerReceivingAmount = tokenPrice.sub(sellerServiceFee);
        uint256 totalServiceFeeAmount = sellerServiceFee.add(tokenPrice.mul(serviceFeeProxy.getBuyServiceFeeBps()).div(10000));

        if (_token.supportsInterface(_INTERFACE_ID_HAS_SECONDARY_SALE)) {
            HasSecondarySale SecondarySale = HasSecondarySale(address(_token));
            bool isSecondarySale = SecondarySale.checkSecondarySale(_tokenId);
            if(isSecondarySale) {
                (address receiver, uint256 royaltyAmount) = _token.royaltyInfo(_tokenId, tokenPrice);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(receiver).call{value: royaltyAmount}("");
                    require(royaltySent, "ERC1155Sale.distributePayment: Royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(receiver, royaltyAmount);
                }
                ownerReceivingAmount = ownerReceivingAmount.sub(royaltyAmount);
                uint256 fee = checkFee(_token, _tokenId, tokenPrice, _currencyId);
                ownerReceivingAmount = ownerReceivingAmount.sub(fee);
            }
        }

        if (_token.supportsInterface(_INTERFACE_ID_FEES)) {
            uint256 sumAffFee = distributeFee(_token, _tokenId, tokenPrice, _currencyId);
            ownerReceivingAmount = ownerReceivingAmount.sub(sumAffFee);
        }
        
        if ( _currencyId == 0) {
            // address that should collect Ikonic service fee
            (bool serviceFeeSent, ) = payable(serviceFeeProxy.getServiceFeeRecipient()).call{value: totalServiceFeeAmount}("");
            require(serviceFeeSent, "ERC1155Sale.distributePayment: ServiceFee transfer failed");

            (bool ownerReceivingAmountSent, ) = payable(saleInfos[address(_token)][_orderId][_tokenId].owner).call{value: ownerReceivingAmount}("");
            require(ownerReceivingAmountSent, "ERC1155Sale.distributePayment: ownerReceivingAmount transfer failed");
        } else {
            IERC20(supportCurrencies[_currencyId]).transfer(serviceFeeProxy.getServiceFeeRecipient(), totalServiceFeeAmount);
            IERC20(supportCurrencies[_currencyId]).transfer(saleInfos[address(_token)][_orderId][_tokenId].owner, ownerReceivingAmount);
        }
    }

    function distributeFee(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId
    ) internal returns(uint) {
        HasAffiliateFees withFees = HasAffiliateFees(address(_token));
        address [] memory recipients = withFees.getFeeRecipients(_tokenId);
        uint256[] memory fees = withFees.getFeeBps(_tokenId);
        require(fees.length == recipients.length);
        uint256 sumFee;
        unchecked {
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 current = _price.mul(fees[i]).div(10000);
                if ( _currencyId == 0 ) {
                    (bool royaltySent, ) = payable(recipients[i]).call{value: current}("");
                    require(royaltySent, "ERC1155Sale.distributePayment: Affiliate royalty transfer failed");
                } else {
                    IERC20(supportCurrencies[_currencyId]).transfer(recipients[i], current);
                }
                sumFee = sumFee.add(current);
            }
        }
        return sumFee;
    }

    function checkFee(
        IIkonicERC1155Token _token,
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
                    require(Sent, "ERC1155Sale.distributePayment: Affiliate Royalty transfer failed");
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
     * @param _token ERC1155 Token
     * @param _tokenId token Id
     * @param _orderId order Id
     */
    function cancel(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;

        require(
            _owner == msg.sender,
            "ERC1155Sale.cancel: Caller is not the owner of the token"
        );

        uint256 nonce = nonceHolder.getNonce(
            address(_token),
            _tokenId,
            msg.sender
        );

        nonceHolder.setNonce(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1)
        );

        delete saleInfos[address(_token)][_orderId][_tokenId];
        
        emit CloseOrder(
            address(_token),
            _tokenId,
            msg.sender,
            nonce.add(1),
            _orderId
        );
    }

    /**
     * @notice Recover signer address from signature and verify it's correct
     * @param token ERC1155 Token
     * @param tokenId token Id
     * @param owner owner address of token
     * @param price price of token
     * @param currencyId currency index
     * @param amount buying amount of ERC1155 token
     * @param signature signature 
     */
    function verifySignature(
        IIkonicERC1155Token token,
        uint256 tokenId,
        address owner,
        uint256 price,
        uint8 currencyId,
        uint256 amount,
        bytes memory signature
    ) internal view returns (uint256 nonce) {
        nonce = nonceHolder.getNonce(address(token), tokenId, owner);
        require(
            keccak256(abi.encodePacked(address(token), tokenId, price, uint256(currencyId), amount, nonce))
                .toEthSignedMessageHash()
                .recover(signature) == token.getSignerAddress(),
            "ERC1155Sale.verifySignature: Incorrect signature"
        );
    }

    /**
     * @notice Modify state by setting nonce and closing order
     * @param _token ERC1155 Token
     * @param _tokenId token Id
     * @param _orderId order Id 
     * @param _owner owner address of token
     * @param _nonce nonce value of token
     */
    function verifyOpenAndModifyState(
        address _token,
        uint256 _tokenId,
        uint256 _orderId,
        address _owner,
        uint256 _nonce
    ) internal {
        nonceHolder.setNonce(_token, _tokenId, _owner, _nonce.add(1));
        emit CloseOrder(_token, _tokenId, _owner, _nonce.add(1), _orderId);
    }

    /**
     * @notice update price and currency of token
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _price price of token
     * @param _orderId Id of order list
     */
     function updatePriceAndCurrency(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _price,
        uint8 _currencyId,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updatePriceAndCurrency: Caller is not the owner of the token"
        );

        require(_price > 0, "ERC1155Sale.updatePriceAndCurrency: Price should be positive");
        require(isCurrencyValid(_currencyId), "ERC1155Sale.updatePriceAndCurrency: Currency is not supported");

        saleInfos[address(_token)][_orderId][_tokenId].price = _price;
        saleInfos[address(_token)][_orderId][_tokenId].currencyId = _currencyId;

        emit UpdatePriceAndCurrency(
            address(_token),
            _tokenId,
            msg.sender,
            _price,
            _currencyId,
            _orderId
        );
    }

    /**
     * @notice update expiration date
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _expSaleDate expiration date
     * @param _orderId Id of order list
     */
     function updateExpSaleDate(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _expSaleDate,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updateExpSaleDate: Caller is not the owner of the token"
        );

        require(_expSaleDate >= _getNow(), "ERC1155Sale.updateExpSaleDate: Approved sale date invalid");

        saleInfos[address(_token)][_orderId][_tokenId].expSaleDate = _expSaleDate;
        emit UpdateExpSaleDate(
            address(_token),
            _tokenId,
            msg.sender,
            _expSaleDate,
            _orderId
        );
    }

    /**
     * @notice update sale amount
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _amount amount of token for sell
     * @param _orderId Id of order list
     */
     function updateSaleAmount(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _orderId
    ) external {
        address _owner = saleInfos[address(_token)][_orderId][_tokenId].owner;
        require(
            _owner == msg.sender,
            "ERC1155Sale.updateSaleAmount: Caller is not the owner of the token"
        );
        
        require(_amount != 0, "ERC1155Sale.updateSaleAmount: Amount should be positive");
        
        require(
            _token.balanceOf(msg.sender, _tokenId) >= _amount,
            "ERC1155Sale.updateSaleAmount: Selling amount exceeds balance"
        );


        saleInfos[address(_token)][_orderId][_tokenId].amount = _amount;
        emit UpdateSaleAmount(
            address(_token),
            _tokenId,
            msg.sender,
            _amount,
            _orderId
        );
    }

    /**
     * @notice Get Sale info with owner address and token id
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     * @param _orderId Id of order list
     */
    function getSaleInfo(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external view returns(SaleInfo memory) {
        return saleInfos[address(_token)][_orderId][_tokenId];
    }

    /**
     * @notice Get Sale price with token address and token id
     * @param _token ERC1155 Token Interface
     * @param _tokenId Id of token
     */
    function getSalePrice(
        IIkonicERC1155Token _token,
        uint256 _tokenId
    ) external view returns (uint256) {
        if(latestListingPrices[address(_token)][_tokenId] != 0) {
            return latestListingPrices[address(_token)][_tokenId];
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
        require(receiver != address(0) && receiver != address(this), "ERC1155Sale.withdrawTo: Invalid withdrawal recipient address");
        if (curId == 0) {    
            require(amount > 0 && amount <= address(this).balance, "ERC1155Sale.withdrawTo: Invalid withdrawal amount");
            (bool sent, ) = payable(receiver).call{value: amount}("");
            require(sent, "ERC1155Sale.withdrawTo: Transfer failed");
        } else {
            require(amount > 0 && amount <= IERC20(supportCurrencies[curId]).balanceOf(address(this)), "ERC1155Sale.withdrawTo: Invalid withdrawal amount");
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
     * @param curIndex index of currency
     */
    function getCurrencyName(uint8 curIndex) external view returns (string memory) {
        require(isCurrencyValid(curIndex), "ERC1155Sale.getCurrencyName: Currency is not supported");
        return supportCurrencyName[curIndex];
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
                require(supportCurrencies[i] != curAddress, "ERC1155Sale.addSupportCurrency: This currency already exists");
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
        require(isCurrencyValid(curIndex), "ERC1155Sale.updateCurrencyAddress: Currency is not supported");
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
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     * @param _currencyId index of currency
     */
    function isCurrencyAcceptable(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId,
        uint8 _currencyId
    ) internal view returns (bool) {
        uint8 listedCurId = saleInfos[address(_token)][_orderId][_tokenId].currencyId;
        if (listedCurId == _currencyId) {
            return true;    
        }
        uint8[] memory accCurIds = saleInfos[address(_token)][_orderId][_tokenId].accCurIds;
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
     * @param _token ERC1155 Token
     * @param _tokenId Id of token
     */
    function getAcceptableCurrencyIds(
        IIkonicERC1155Token _token,
        uint256 _tokenId,
        uint256 _orderId
    ) external view returns (uint8[] memory) {
        return saleInfos[address(_token)][_orderId][_tokenId].accCurIds;
    }
}