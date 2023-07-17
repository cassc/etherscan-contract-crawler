/*
██   ██ ██████   █████   ██████      ███████ ██   ██  ██████  ██████  
 ██ ██  ██   ██ ██   ██ ██    ██     ██      ██   ██ ██    ██ ██   ██ 
  ███   ██   ██ ███████ ██    ██     ███████ ███████ ██    ██ ██████  
 ██ ██  ██   ██ ██   ██ ██    ██          ██ ██   ██ ██    ██ ██      
██   ██ ██████  ██   ██  ██████      ███████ ██   ██  ██████  ██      
*/
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./LP.sol";

import "../interfaces/IFactory.sol";
import "../interfaces/IDao.sol";
import "../interfaces/ILP.sol";

contract Shop is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public factory = address(0);

    mapping(address => bool) public lps;

    struct PublicOffer {
        bool isActive;
        address currency;
        uint256 rate; // lpAmount = currencyAmount / rate. For example: 1 LP = 100 USDT. 530 USDT -> 530/100 = 5.3 LP
    }

    mapping(address => PublicOffer) public publicOffers; // publicOffers[dao]

    struct PrivateOffer {
        bool isActive;
        address recipient;
        address currency;
        uint256 currencyAmount;
        uint256 lpAmount;
    }

    mapping(address => mapping(uint256 => PrivateOffer)) public privateOffers; // privateOffers[dao][offerId]
    mapping(address => uint256) public numberOfPrivateOffers;

    event LpCreated(address indexed lp);

    modifier onlyDaoWithLp() {
        require(
            IFactory(factory).containsDao(msg.sender) &&
                IDao(msg.sender).lp() != address(0),
            "Shop: this function is only for DAO with LP"
        );
        _;
    }

    function setFactory(address _factory) external returns (bool) {
        require(
            factory == address(0),
            "Shop: factory address has already been set"
        );

        factory = _factory;

        return true;
    }

    function createLp(string memory _lpName, string memory _lpSymbol)
        external
        nonReentrant
        returns (bool)
    {
        require(
            IFactory(factory).containsDao(msg.sender),
            "Shop: only DAO can deploy LP"
        );

        LP lp = new LP(_lpName, _lpSymbol, msg.sender);

        lps[address(lp)] = true;

        emit LpCreated(address(lp));

        bool b = IDao(msg.sender).setLp(address(lp));

        require(b, "Shop: LP setting error");

        return true;
    }

    // DAO can use this to create/enable/disable/changeCurrency/changeRate
    function initPublicOffer(
        bool _isActive,
        address _currency,
        uint256 _rate
    ) external onlyDaoWithLp returns (bool) {
        publicOffers[msg.sender] = PublicOffer({
            isActive: _isActive,
            currency: _currency,
            rate: _rate
        });

        return true;
    }

    function createPrivateOffer(
        address _recipient,
        address _currency,
        uint256 _currencyAmount,
        uint256 _lpAmount
    ) external onlyDaoWithLp returns (bool) {
        privateOffers[msg.sender][
            numberOfPrivateOffers[msg.sender]
        ] = PrivateOffer({
            isActive: true,
            recipient: _recipient,
            currency: _currency,
            currencyAmount: _currencyAmount,
            lpAmount: _lpAmount
        });

        numberOfPrivateOffers[msg.sender]++;

        return true;
    }

    function disablePrivateOffer(uint256 _id)
        external
        onlyDaoWithLp
        returns (bool)
    {
        privateOffers[msg.sender][_id].isActive = false;

        return true;
    }

    function buyPublicOffer(address _dao, uint256 _lpAmount)
        external
        nonReentrant
        returns (bool)
    {
        require(
            IFactory(factory).containsDao(_dao),
            "Shop: only DAO can sell LPs"
        );

        PublicOffer memory publicOffer = publicOffers[_dao];

        require(publicOffer.isActive, "Shop: this offer is disabled");

        IERC20(publicOffer.currency).safeTransferFrom(
            msg.sender,
            _dao,
            (_lpAmount * publicOffer.rate) / 1e18
        );

        address lp = IDao(_dao).lp();

        bool b = ILP(lp).mint(msg.sender, _lpAmount);

        require(b, "Shop: mint error");

        return true;
    }

    function buyPrivateOffer(address _dao, uint256 _id)
        external
        nonReentrant
        returns (bool)
    {
        require(
            IFactory(factory).containsDao(_dao),
            "Shop: only DAO can sell LPs"
        );

        PrivateOffer storage offer = privateOffers[_dao][_id];

        require(offer.isActive, "Shop: this offer is disabled");

        offer.isActive = false;

        require(offer.recipient == msg.sender, "Shop: wrong recipient");

        IERC20(offer.currency).safeTransferFrom(
            msg.sender,
            _dao,
            offer.currencyAmount
        );

        address lp = IDao(_dao).lp();

        bool b = ILP(lp).mint(msg.sender, offer.lpAmount);

        require(b, "Shop: mint error");

        return true;
    }
}