// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {ICollection} from "./interfaces/ICollection.sol";
import {Transfers} from "./Transfers.sol";
import {Auth} from "../security/Auth.sol";

/**
 * @author Jonatã Oliveira
 * @title Validator
 * @dev Validate marketplace functions and receive/handle platform funds.
 */
contract Validator is Initializable, ReentrancyGuardUpgradeable, Transfers, Auth {
    using SafeMath for uint256;

    struct Services {
        bool swap;
        bool offer;
        bool collectionOffer;
    }

    address public MARKETPLACE;
    IFeeManager private feeManager;
    Services public services;
    mapping(address => bool) public allowedCurrencies;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _feeManager, address _pool) public initializer {
        __Auth_init(msg.sender);
        __ReentrancyGuard_init();
        __Transfers_init(_feeManager, _pool);
        feeManager = IFeeManager(_feeManager);
        allowedCurrencies[address(0)] = true;
    }

    function setMarketplace(address _marketplace) external authorized {
        require(_marketplace != address(0), "Invalid address");
        MARKETPLACE = _marketplace;
    }

    function setServices(bool swap, bool offer, bool collectionOffer) external authorized {
        services = Services(swap, offer, collectionOffer);
    }

    function setCurrency(address currency, bool enabled) external authorized {
        allowedCurrencies[currency] = enabled;
    }

    function buy(
        bytes calldata _signature,
        address _seller,
        address _collection,
        address _currency,
        uint256 _price,
        uint256 _endTime,
        bytes32 _salt,
        uint256 _token_id,
        bool _completed,
        address _SENDER
    ) external payable onlyMarketplace swapActive {
        bytes32 message = keccak256(abi.encodePacked(_seller, _collection, _currency, _price, _token_id, _endTime, _salt));
        bytes32 signedMessage = getSignedMessageHash(message);

        require(recoverSigner(signedMessage, _signature) == _seller, "Invalid Order");
        require(!_completed, "Order completed or canceled");
        require(_seller != _SENDER, "Owner cannot buy");
        require(block.timestamp < _endTime, "Expired order");

        if (_currency == address(0)) {
            require(msg.value >= _price, "Insufficient amount");
        }

        // Transfer value to contract
        if (_currency != address(0)) {
            require(allowedCurrencies[_currency], "Invalid currency");
            IERC20 token = IERC20(_currency);
            require(token.transferFrom(_SENDER, address(this), _price), "Insufficient token");
        }

        // Transfer platform fee, royalties and seller amount
        _transferFeesAndFunds(_collection, _token_id, _currency, _seller, _price);

        // Transfer NFT token to buyer
        _transferNFT(_collection, _seller, _SENDER, _token_id);
    }

    function acceptOffer(
        bytes calldata _signature,
        address _offerer,
        address _collection,
        uint256 _price,
        uint256 _endTime,
        bytes32 _salt,
        uint256 _token_id,
        bool _completed,
        address _SENDER
    ) external onlyMarketplace offerActive nonReentrant {
        bytes32 message = keccak256(abi.encodePacked(_offerer, _collection, _price, _token_id, _endTime, _salt));
        bytes32 signedMessage = getSignedMessageHash(message);

        require(recoverSigner(signedMessage, _signature) == _offerer, "Invalid Offer");
        require(!_completed, "Offer completed or canceled");
        require(_offerer != _SENDER, "Offerer is the seller");
        require(block.timestamp < _endTime, "Expired offer");

        // Transfer platform fee and seller amount
        _transferFeesAndFundsPool(_collection, _token_id, _offerer, _SENDER, _price);

        // Transfer NFT token to offerrer
        _transferNFT(_collection, _SENDER, _offerer, _token_id);
    }

    function acceptCollectionOffer(
        bytes calldata _signature,
        address _offerer,
        address _collection,
        uint256 _price,
        uint8 _amount,
        uint256 _endTime,
        bytes32 _salt,
        uint256 _token_id,
        uint8 _iteration,
        address _SENDER
    ) external onlyMarketplace colOfferActive nonReentrant {
        bytes32 message = keccak256(abi.encodePacked(_offerer, _collection, _price, _amount, _endTime, _salt));
        bytes32 signedMessage = getSignedMessageHash(message);

        require(recoverSigner(signedMessage, _signature) == _offerer, "Invalid Offer");
        require(_iteration < _amount, "Offer completed or canceled");
        require(_offerer != _SENDER, "Offerer is the seller");
        require(block.timestamp < _endTime, "Expired offer");

        // Transfer platform fee and seller amount
        _transferFeesAndFundsPool(_collection, _token_id, _offerer, _SENDER, _price);

        // Transfer NFT token to offerrer
        _transferNFT(_collection, _SENDER, _offerer, _token_id);
    }

    function recoverSigner(bytes32 message, bytes calldata sig) private pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Invalid signature");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function getSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    modifier onlyMarketplace() {
        _onlyMarketplace();
        _;
    }

    function _onlyMarketplace() private view {
        require(msg.sender == MARKETPLACE && MARKETPLACE != address(0), "!MARKETPLACE");
    }

    modifier swapActive() {
        _serviceActive(services.swap);
        _;
    }
    modifier offerActive() {
        _serviceActive(services.offer);
        _;
    }
    modifier colOfferActive() {
        _serviceActive(services.collectionOffer);
        _;
    }

    function _serviceActive(bool _service) private pure {
        require(_service, "Service disabled");
    }
}