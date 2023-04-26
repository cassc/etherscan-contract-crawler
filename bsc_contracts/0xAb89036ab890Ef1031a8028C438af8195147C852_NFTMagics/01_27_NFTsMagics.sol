// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './ERC1155Base.sol';

contract NFTMagics is ERC1155Base {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(
        Environment env,
        address profitAddress,
        IERC20 ayraToken,
        IERC20 ithdToken,
        address marketplace,
        address _distributed,
        address _owner
    ) ERC1155('NFTS MAGICS') {
        _transferOwnership(_owner);

        _env = env;
        _network = Network.Binance;

        _profit = profitAddress;
        _ayraToken = ayraToken;
        _ithdToken = ithdToken;
        _marketplace = marketplace;
        distributed = _distributed;

        // Set Fee Values for Binance
        _distributedFee = 10 * _PERCENTAGE_PRECISION;
        _distributedFeeAYRA = 10 * _PERCENTAGE_PRECISION;
        _distributedFeeITHD = 10 * _PERCENTAGE_PRECISION;

        _lotteryFeeAYRA = 10 * _PERCENTAGE_PRECISION;

        if (_network == Network.Binance) {
            _areTicketsAwardedForMintCurrency[TokenType.Native] = true;
            _areTicketsAwardedForMintCurrency[TokenType.AYRA] = true;
            _areTicketsAwardedForMintCurrency[TokenType.ITHD] = true;

            _distributedParticipationFee = 0.006 ether;

            if (_env == Environment.Development) {
                _distributedParticipationFeeAYRA = 10 ether;
                _distributedParticipationFeeITHD = 10 ether;
            } else {
                _distributedParticipationFeeAYRA = 500 ether;
                _distributedParticipationFeeITHD = 200 ether;
            }
        } else {
            _areTicketsAwardedForMintCurrency[TokenType.Native] = true;

            if (_env == Environment.Development) {
                _distributedParticipationFee = 0.0021 ether;
            } else {
                _distributedParticipationFee = 1.62 ether;
            }
        }

        _setInitialPrices();
    }

    function changeTokenPrice(
        TokenType tokenType,
        uint256 count,
        uint256 price
    ) external override onlyOwner {
        _prices[tokenType][count] = price;
    }

    function getTokenMintPrice(
        TokenType tokenType,
        uint256 count
    ) external view override returns (uint256) {
        return _prices[tokenType][count];
    }

    function createItemWithAYRA(
        uint256 count,
        string calldata url,
        uint256 amount,
        address to,
        uint256 royalty,
        bool participateInDistributed
    ) public returns (uint256) {
        require(count <= _TWENTY, 'can not mint over twenty');
        require(_prices[TokenType.AYRA][count] != _ZERO, 'Invalid quantity!');
        require(
            amount >=
                (
                    participateInDistributed
                        ? _prices[TokenType.AYRA][count] +
                            _distributedParticipationFee
                        : _prices[TokenType.AYRA][count]
                ),
            _INSUFFICIENT_VALUE
        );

        if (participateInDistributed) {
            address userAddress = _msgSender();
            _validateDistributedParticipation(userAddress, TokenType.AYRA);
        }

        _handleAYRAFunding(amount, participateInDistributed);

        uint256 id = _createItem(
            count,
            url,
            to,
            royalty,
            TokenType.AYRA,
            participateInDistributed
        );
        return id;
    }

    function createItemWithITHD(
        uint256 count,
        string calldata url,
        uint256 amount,
        address to,
        uint256 royalty,
        bool participateInDistributed
    ) public returns (uint256) {
        require(count <= _TWENTY, 'can not mint over twenty');
        require(_prices[TokenType.ITHD][count] != _ZERO, 'Invalid quantity!');
        require(
            amount >=
                (
                    participateInDistributed
                        ? _prices[TokenType.ITHD][count] +
                            _distributedParticipationFee
                        : _prices[TokenType.ITHD][count]
                ),
            _INSUFFICIENT_VALUE
        );

        if (participateInDistributed) {
            address userAddress = _msgSender();
            _validateDistributedParticipation(userAddress, TokenType.ITHD);
        }

        _handleITHDFunding(amount, participateInDistributed);

        uint256 id = _createItem(
            count,
            url,
            to,
            royalty,
            TokenType.ITHD,
            participateInDistributed
        );
        return id;
    }

    function _takeBurnFee(uint256 id) internal override {
        LastPurchase memory _lastPurchase = IMarketplace(_marketplace)
            .getLastPurchaseDetails(_msgSender(), id);

        uint256 feeAmount = (_lastPurchase.price * _TWENTY) / _ONE_HUNDRED;

        _takenBurnFee[_msgSender()][id] = TakenBurnFee({
            price: 0,
            tokenType: TokenType.Native
        });

        if (_lastPurchase.tokenType == TokenType.Native) {
            require(_checkBurnFeePaid(id), 'Please pay burn fee first!');
        } else if (_lastPurchase.tokenType == TokenType.AYRA) {
            _ayraToken.safeTransferFrom(
                _msgSender(),
                itemDetails[id].creator,
                feeAmount
            );
        } else if (_lastPurchase.tokenType == TokenType.ITHD) {
            _ithdToken.safeTransferFrom(_msgSender(), address(this), feeAmount);
            _ithdToken.safeTransfer(itemDetails[id].creator, feeAmount);
        }
    }

    function _setInitialPrices() private {
        _prices[TokenType.Native][_ONE] = 1_300_000 gwei;
        _prices[TokenType.Native][_FIVE] = 1_700_000 gwei;
        _prices[TokenType.Native][_TEN] = 2_200_000 gwei;
        _prices[TokenType.Native][_TWENTY] = 2_900_000 gwei;

        _prices[TokenType.AYRA][_ONE] = 20 ether;
        _prices[TokenType.AYRA][_FIVE] = 28 ether;
        _prices[TokenType.AYRA][_TEN] = 36 ether;
        _prices[TokenType.AYRA][_TWENTY] = 48 ether;

        _prices[TokenType.ITHD][_ONE] = 10 ether;
        _prices[TokenType.ITHD][_FIVE] = 14 ether;
        _prices[TokenType.ITHD][_TEN] = 18 ether;
        _prices[TokenType.ITHD][_TWENTY] = 24 ether;
    }
}