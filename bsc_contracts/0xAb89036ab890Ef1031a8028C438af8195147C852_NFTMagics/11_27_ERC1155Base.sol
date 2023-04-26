// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../Recoverable.sol';
import '../interfaces/IMarketplace.sol';
import '../interfaces/ILottery.sol';
import '../interfaces/enums/TokenType.sol';
import '../interfaces/enums/Network.sol';
import '../interfaces/enums/Environment.sol';
import '../interfaces/IDistributedRewardsPot.sol';
import '../Literals.sol';

abstract contract ERC1155Base is
    ERC1155URIStorage,
    Recoverable,
    Ownable,
    Literals
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct ItemDetails {
        address creator;
        uint256 royalty;
        TokenType mintTokenType;
    }

    struct TakenBurnFee {
        uint256 price;
        TokenType tokenType;
    }

    Counters.Counter internal _nftIds;
    Network internal _network;
    Environment internal _env;

    address internal _profit;
    address internal _marketplace;
    address internal _lottery;

    IERC20 internal _ayraToken;
    IERC20 internal _ithdToken;

    address public distributed;

    uint256 internal _distributedFee;
    uint256 internal _distributedFeeAYRA;
    uint256 internal _distributedFeeITHD;

    uint256 internal _distributedParticipationFee;
    uint256 internal _distributedParticipationFeeAYRA;
    uint256 internal _distributedParticipationFeeITHD;

    uint256 internal _lotteryFee;
    uint256 internal _lotteryFeeAYRA;
    uint256 internal _lotteryFeeITHD;

    mapping(uint256 => ItemDetails) public itemDetails;

    mapping(address => mapping(uint256 => TakenBurnFee)) internal _takenBurnFee;

    mapping(TokenType => mapping(uint256 => uint256)) internal _prices;

    mapping(TokenType => bool) internal _areTicketsAwardedForMintCurrency;

    modifier onlyNativeToken(TokenType tokenType) {
        require(tokenType == TokenType.Native, 'Call in wrong context!');
        _;
    }

    function changeProfitAddress(address newProfitAddress) external onlyOwner {
        _profit = newProfitAddress;
    }

    function setMarketplaceContract(address marketplace) external onlyOwner {
        _marketplace = marketplace;
    }

    function setDistributedContract(address _distributed) external onlyOwner {
        distributed = _distributed;
    }

    function changeLotteryFee(
        uint256 newFee,
        uint256 lotteryFeeAYRA,
        uint256 lotteryFeeITHD
    ) external onlyOwner {
        _lotteryFee = newFee;

        if (_network == Network.Binance) {
            _lotteryFeeAYRA = lotteryFeeAYRA;
            _lotteryFeeITHD = lotteryFeeITHD;
        }
    }

    function setTicketsAwardingEnabledForMintCurrency(
        TokenType tokenType,
        bool flag
    ) external onlyOwner {
        _areTicketsAwardedForMintCurrency[tokenType] = flag;
    }

    function changeDistributedFee(
        uint256 newFee,
        uint256 newFeeAYRA,
        uint256 newFeeITHD
    ) external onlyOwner {
        _distributedFee = newFee;

        if (_network == Network.Binance) {
            _distributedFeeAYRA = newFeeAYRA;
            _distributedFeeITHD = newFeeITHD;
        }
    }

    function changeDistributedEntryFee(
        uint256 newFee,
        uint256 newFeeAYRA,
        uint256 newFeeITHD
    ) external onlyOwner {
        _distributedParticipationFee = newFee;

        if (_network == Network.Binance) {
            _distributedParticipationFeeAYRA = newFeeAYRA;
            _distributedParticipationFeeITHD = newFeeITHD;
        }
    }

    function changeTokenPrice(
        TokenType tokenType,
        uint256 count,
        uint256 price
    ) external virtual onlyOwner onlyNativeToken(tokenType) {
        _prices[tokenType][count] = price;
    }

    function payBurnFeeNative(uint256 id) external payable {
        LastPurchase memory _lastPurchase = IMarketplace(_marketplace)
            .getLastPurchaseDetails(_msgSender(), id);

        TakenBurnFee storage takenBurnFee = _takenBurnFee[_msgSender()][id];

        require(
            _lastPurchase.tokenType == TokenType.Native,
            'Call in wrong context!'
        );
        require(
            _lastPurchase.tokenType != takenBurnFee.tokenType ||
                _lastPurchase.price != takenBurnFee.price,
            'Already paid!'
        );

        uint256 feeAmount = (_lastPurchase.price * _TWENTY) / _ONE_HUNDRED;

        takenBurnFee.price = _lastPurchase.price;
        takenBurnFee.tokenType = _lastPurchase.tokenType;

        payable(itemDetails[id].creator).transfer(feeAmount);
    }

    function recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        bool flag = _recoverFunds(_token, _to, _amount);

        return flag;
    }

    function changeLotteryAddress(address newAddress) external onlyOwner {
        _lottery = newAddress;
    }

    function getDistributedParticipationFees()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tempArray = new uint256[](_THREE);

        tempArray[_ZERO] = _distributedParticipationFee;
        tempArray[_ONE] = _distributedParticipationFeeAYRA;
        tempArray[_TWO] = _distributedParticipationFeeITHD;

        return tempArray;
    }

    function getMarketplaceAddress() external view returns (address) {
        return _marketplace;
    }

    function getProfitAddress() external view returns (address) {
        return _profit;
    }

    function getLotteryAddress() external view returns (address) {
        return _lottery;
    }

    function getTokenMintPrice(
        TokenType tokenType,
        uint256 count
    ) external view virtual onlyNativeToken(tokenType) returns (uint256) {
        return _prices[tokenType][count];
    }

    function createItemWithNative(
        uint256 count,
        string calldata url,
        address to,
        uint256 royalty,
        bool participateInDistributed
    ) public payable returns (uint256) {
        require(_prices[TokenType.Native][count] != _ZERO, 'Invalid quantity!');
        require(
            msg.value >=
                (
                    participateInDistributed
                        ? _prices[TokenType.Native][count] +
                            _distributedParticipationFee
                        : _prices[TokenType.Native][count]
                ),
            _INSUFFICIENT_VALUE
        );

        if (participateInDistributed) {
            address userAddress = _msgSender();
            _validateDistributedParticipation(userAddress, TokenType.Native);
        }

        _handleNativeFunding(msg.value, participateInDistributed);

        uint256 id = _createItem(
            count,
            url,
            to,
            royalty,
            TokenType.Native,
            participateInDistributed
        );

        return id;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            'ERC1155: caller is not token owner nor approved'
        );

        if (_shouldTakeBurnFee(from, to, id)) _takeBurnFee(id);

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            'ERC1155: caller is not token owner nor approved'
        );

        for (uint256 i = _ZERO; i < ids.length; i++) {
            if (_shouldTakeBurnFee(from, to, ids[i])) _takeBurnFee(ids[i]);
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _purchaseLotteryTicketsForUser(
        address userAddress,
        uint256 count
    ) internal {
        if (_network == Network.Binance) {
            ILottery(_lottery).purchaseTickets(
                userAddress,
                TokenType.AYRA,
                count
            );
        } else if (_network == Network.Polygon) {
            ILottery(_lottery).purchaseTickets(
                userAddress,
                TokenType.Native,
                count
            );
        }
    }

    function _createItem(
        uint256 count,
        string calldata url,
        address to,
        uint256 royalty,
        TokenType _mintTokenType,
        bool participateInDistributed
    ) internal returns (uint256) {
        require(count <= _TWENTY, 'can not mint over twenty');
        require(
            royalty >= _ONE && royalty <= _TEN,
            'royalty should be between one and ten percent'
        );

        _nftIds.increment();
        uint256 id = _nftIds.current();
        _mint(to, id, count, '');

        _setURI(id, url);

        itemDetails[id].creator = _msgSender();
        itemDetails[id].royalty = royalty;
        itemDetails[id].mintTokenType = _mintTokenType;

        if (_areTicketsAwardedForMintCurrency[_mintTokenType]) {
            _purchaseLotteryTicketsForUser(_msgSender(), count);
        }

        if (participateInDistributed) {
            IDistributedRewardsPot(distributed).noteUserMintParticipation(
                _msgSender(),
                _mintTokenType
            );
        }

        return id;
    }

    function _handleNativeFunding(
        uint256 totalAmount,
        bool participateInDistributed
    ) internal {
        uint256 nftAmount;
        uint256 amountToDistributed;

        if (participateInDistributed) {
            nftAmount = totalAmount - _distributedParticipationFee;

            amountToDistributed = _distributedParticipationFee;
        } else {
            nftAmount = totalAmount;
        }

        amountToDistributed =
            amountToDistributed +
            (
                _distributedFee > _ZERO
                    ? (nftAmount * _distributedFee) /
                        (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
                    : _ZERO
            );
        uint256 amountToLottery = _lotteryFee > _ZERO
            ? (nftAmount * _lotteryFee) / (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
            : _ZERO;
        uint256 remainingAmount = totalAmount -
            amountToDistributed -
            amountToLottery;

        address bridgeAdmin = IMarketplace(_marketplace).bridgeAdmin();
        uint256 bridgeAdminBalance = bridgeAdmin.balance;
        uint256 minBridgeAdminBalance = _network == Network.Binance
            ? 1 ether
            : 2 ether;

        if (amountToDistributed > _ZERO) {
            payable(distributed).transfer(amountToDistributed);
        }

        if (amountToLottery > _ZERO) {
            payable(_lottery).transfer(amountToLottery);
        }

        if (remainingAmount > _ZERO) {
            if (
                bridgeAdmin != _ZERO_ADDRESS &&
                bridgeAdminBalance < minBridgeAdminBalance
            ) {
                payable(bridgeAdmin).transfer(remainingAmount);
            } else {
                payable(_profit).transfer(remainingAmount);
            }
        }

        if (amountToLottery > _ZERO) {
            ILottery(_lottery).noteCollection(
                TokenType.Native,
                amountToLottery
            );
        }

        if (amountToDistributed > _ZERO) {
            IDistributedRewardsPot(distributed).addMintCollection(
                TokenType.Native,
                amountToDistributed
            );
        }
    }

    function _handleAYRAFunding(
        uint256 totalAmount,
        bool participateInDistributed
    ) internal {
        uint256 nftAmount;
        uint256 amountToDistributed;

        if (participateInDistributed) {
            nftAmount = totalAmount - _distributedParticipationFeeAYRA;

            amountToDistributed = _distributedParticipationFeeAYRA;
        } else {
            nftAmount = totalAmount;
        }

        amountToDistributed =
            amountToDistributed +
            (
                _distributedFeeAYRA > _ZERO
                    ? (nftAmount * _distributedFeeAYRA) /
                        (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
                    : _ZERO
            );
        uint256 amountToLottery = _lotteryFeeAYRA > _ZERO
            ? (nftAmount * _lotteryFeeAYRA) /
                (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
            : _ZERO;
        uint256 remainingAmount = totalAmount -
            amountToDistributed -
            amountToLottery;

        if (amountToLottery > _ZERO) {
            _ayraToken.safeTransferFrom(
                _msgSender(),
                _lottery,
                amountToLottery
            );
        }

        if (amountToDistributed > _ZERO) {
            _ayraToken.safeTransferFrom(
                _msgSender(),
                distributed,
                amountToDistributed
            );
        }

        if (remainingAmount > _ZERO) {
            _ayraToken.safeTransferFrom(_msgSender(), _profit, remainingAmount);
        }

        if (amountToLottery > _ZERO) {
            ILottery(_lottery).noteCollection(TokenType.AYRA, amountToLottery);
        }

        if (amountToDistributed > _ZERO) {
            IDistributedRewardsPot(distributed).addMintCollection(
                TokenType.AYRA,
                amountToDistributed
            );
        }
    }

    function _handleITHDFunding(
        uint256 totalAmount,
        bool participateInDistributed
    ) internal {
        uint256 nftAmount;
        uint256 amountToDistributed;

        if (participateInDistributed) {
            nftAmount = totalAmount - _distributedParticipationFeeITHD;

            amountToDistributed =
                amountToDistributed +
                _distributedParticipationFeeITHD;
        } else {
            nftAmount = totalAmount;
        }

        amountToDistributed =
            amountToDistributed +
            (
                _distributedFeeITHD > _ZERO
                    ? (nftAmount * _distributedFeeITHD) /
                        (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
                    : _ZERO
            );
        uint256 amountToLottery = _lotteryFeeITHD > _ZERO
            ? (nftAmount * _lotteryFeeITHD) /
                (_ONE_HUNDRED * _PERCENTAGE_PRECISION)
            : _ZERO;
        uint256 remainingAmount = totalAmount -
            amountToDistributed -
            amountToLottery;

        // Since this address will be excluded from fees, we transfer the amount to
        // this address first and then distribute it.
        _ithdToken.safeTransferFrom(_msgSender(), address(this), totalAmount);

        if (amountToLottery > _ZERO) {
            _ithdToken.safeTransfer(_lottery, amountToLottery);
        }

        if (amountToDistributed > _ZERO) {
            _ithdToken.safeTransfer(distributed, amountToDistributed);
        }

        if (remainingAmount > _ZERO) {
            _ithdToken.safeTransfer(_profit, remainingAmount);
        }

        if (amountToDistributed > _ZERO) {
            IDistributedRewardsPot(distributed).addMintCollection(
                TokenType.ITHD,
                amountToDistributed
            );
        }

        if (amountToLottery > _ZERO) {
            ILottery(_lottery).noteCollection(TokenType.ITHD, amountToLottery);
        }
    }

    function _takeBurnFee(uint256 id) internal virtual {
        LastPurchase memory _lastPurchase = IMarketplace(_marketplace)
            .getLastPurchaseDetails(_msgSender(), id);
        require(
            _lastPurchase.tokenType == TokenType.Native,
            'Call in wrong context!'
        );

        require(_checkBurnFeePaid(id), 'Please pay burn fee first!');

        _takenBurnFee[_msgSender()][id] = TakenBurnFee({
            price: _ZERO,
            tokenType: TokenType.Native
        });
    }

    function _validateDistributedParticipation(
        address userAddress,
        TokenType tokenType
    ) internal view {
        UserInfoDistributed memory user = IDistributedRewardsPot(distributed)
            .getUserInfoForCurrentMonth(userAddress, tokenType);

        require(
            !user.hasParticipatedUsingMint,
            'Already entered in distributed using this currency'
        );
    }

    function _shouldTakeBurnFee(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool) {
        return
            from != itemDetails[id].creator &&
            (to == _ZERO_ADDRESS || to == _DEAD_ADDRESS);
    }

    function _checkBurnFeePaid(uint256 id) internal view returns (bool) {
        LastPurchase memory _lastPurchase = IMarketplace(_marketplace)
            .getLastPurchaseDetails(_msgSender(), id);
        TakenBurnFee memory takenBurnFee = _takenBurnFee[_msgSender()][id];

        require(
            _lastPurchase.tokenType == TokenType.Native,
            'Call in wrong context!'
        );

        return
            _lastPurchase.tokenType == takenBurnFee.tokenType &&
            _lastPurchase.price == takenBurnFee.price;
    }
}