// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Booking is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private totalOffers;
    Counters.Counter private unavailableOffers;
    struct SellOffer {
        address payable seller;
        uint256 offerId;
        uint256 rdgBalanceAmount;
        uint256 pricePerTokens;
    }
    mapping(uint256 => SellOffer) public sellOffers;
    IERC20 public rdg;
    IERC20 public dai;
    uint256 public listingFee = 0.001 ether;

    constructor(address _rdg, address _dai) {
        rdg = IERC20(_rdg);
        dai = IERC20(_dai);
    }

    event ChangeListingFee(uint256 amount);
    event RemovedAllOffers(address indexed owner);
    event RemovedOfferId(address indexed owner, uint256 offerId);
    event ListedOffer(
        address indexed owner,
        uint256 rdgAmount,
        uint256 unitPrice
    );
    event BoughtOffer(
        address indexed buyer,
        address indexed seller,
        uint256 buyingAmount,
        uint256 rdgPrice
    );
    event UpdatePriceOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldRdgPrice,
        uint256 newRdgPrice
    );

    event AddRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );
    event RemoveRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );

    function setListingFee(uint256 _amount) public onlyOwner {
        listingFee = _amount;
        emit ChangeListingFee(_amount);
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unPauseContract() public onlyOwner {
        _unpause();
    }

    function withdrawDevBalance() public onlyOwner {
        require(address(this).balance > 0, "Nao tem saldo disponivel");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Falha ao enviar ether");
    }

    function listToken(uint256 _amount, uint256 _pricePerTokens)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= listingFee, "Nao foi enviado taxa de operacao.");
        require(_amount > 0, "Quantidade minima deve ser maior que zero");
        require(
            rdg.allowance(msg.sender, address(this)) >= _amount,
            "Quantidade nao aprovada para listagem"
        );
        IERC20(rdg).safeTransferFrom(msg.sender, address(this), _amount);
        totalOffers.increment();
        sellOffers[totalOffers.current()] = SellOffer({
            offerId: totalOffers.current(),
            pricePerTokens: _pricePerTokens,
            rdgBalanceAmount: _amount,
            seller: payable(msg.sender)
        });
        emit ListedOffer(msg.sender, _amount, _pricePerTokens);
    }

    function buyToken(uint256 _offerId, uint256 _amount) public whenNotPaused {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller != msg.sender,
            "Dono da oferta nao pode comprar suas proprias moedas."
        );
        uint256 rdgPriceForAmount = (offer.pricePerTokens * _amount) / 1 ether;
        require(
            dai.allowance(msg.sender, address(this)) >= rdgPriceForAmount,
            "dai autorizado insuficiente para realizar a compra"
        );
        require(
            offer.rdgBalanceAmount >= _amount,
            "Valor solicitado superior ao disponivel da oferta"
        );
        require(
            rdg.balanceOf(address(this)) >= _amount,
            "Contrato nao tem RDG Coin"
        );
        offer.rdgBalanceAmount -= _amount;
        IERC20(dai).safeTransferFrom(
            msg.sender,
            offer.seller,
            rdgPriceForAmount
        );
        IERC20(rdg).safeTransfer(msg.sender, _amount);
        if (offer.rdgBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
        emit BoughtOffer(
            msg.sender,
            offer.seller,
            _amount,
            offer.pricePerTokens
        );
    }

    function getOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgBalanceAmount > 0) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function getMyOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgBalanceAmount > 0 && offer.seller == msg.sender) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function updatePriceOffer(uint256 _offerId, uint256 _updatedPricePerToken)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];

        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );
        emit UpdatePriceOffer(
            msg.sender,
            _offerId,
            offer.pricePerTokens,
            _updatedPricePerToken
        );
        offer.pricePerTokens = _updatedPricePerToken;
    }

    function removeListedRdgAmountOffer(uint256 _offerId, uint256 _tokenAmount)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );

        require(
            rdg.balanceOf(address(this)) >= _tokenAmount,
            "RDG Coin insuficiente no contrato"
        );
        uint256 oldAmount = offer.rdgBalanceAmount;
        offer.rdgBalanceAmount -= _tokenAmount;
        uint256 newAmount = offer.rdgBalanceAmount;
        IERC20(rdg).safeTransfer(msg.sender, _tokenAmount);

        emit RemoveRdgAmountOffer(msg.sender, _offerId, oldAmount, newAmount);

        if (offer.rdgBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
    }

    function removeListedOffers() public returns (SellOffer[] memory) {
        uint256 totalOffersCount = totalOffers.current() -
            unavailableOffers.current();
        uint256 rdgIndex = 0;
        uint256 rdgAmount = 0;

        SellOffer[] memory offers = new SellOffer[](totalOffersCount);

        for (uint256 i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.seller == msg.sender && offer.rdgBalanceAmount > 0) {
                unavailableOffers.increment();
                offers[rdgIndex] = offer;
                rdgAmount += offer.rdgBalanceAmount;
                offer.rdgBalanceAmount = 0;
                rdgIndex++;
            }
        }

        require(rdgAmount > 0, "Nao tem nehuma oferta com saldo para saque");
        require(
            rdg.balanceOf(address(this)) >= rdgAmount,
            "Saldo insuficiente do contrato"
        );
        IERC20(rdg).safeTransfer(msg.sender, rdgAmount);
        emit RemovedAllOffers(msg.sender);
        return offers;
    }

    receive() external payable {}

    fallback() external payable {}
}