// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
pragma abicoder v2;

import "ERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "ECDSA.sol";
import "AccessControl.sol";

contract CateniumLaunchpad is AccessControl, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using ECDSA for bytes32;

    bytes32 public constant SIGNER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct PlacedToken {
        address owner;
        uint256 price;
        uint256 initialVolume;
        uint256 volume;
        uint256 collectedAmount; // in _pricingToken
        bool isActive;
    }

    mapping (uint256 => bool) public nonces;
    mapping (ERC20 => PlacedToken) public placedTokens;


    uint256 internal _feePercent;
    ERC20 private _pricingToken;
    address private _feeCollector;

    event TokenPlaced(ERC20 token, uint256 nonce);
    event RoundFinished(ERC20 token);
    event TokensBought(ERC20 token, address buyer, uint256 amount);
    event FundsCollected(ERC20 token);

    constructor(ERC20 pricingToken_, uint256 feePercent_, address feeCollector_) {
        _feePercent = feePercent_;
        _pricingToken = pricingToken_;
        _feeCollector = feeCollector_;
        _setRoleAdmin(SIGNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
    }

    function feeCollector() public view returns(address) {
        return _feeCollector;
    }

    function setFeeCollector(address feeCollector_) public onlyRole(ADMIN_ROLE) {
        _feeCollector = feeCollector_;
    }

    function feePercent() public view returns(uint256) {
        return _feePercent;
    }

    function setFeePercent(uint256 feePercent_) public onlyRole(ADMIN_ROLE) {
        _feePercent = feePercent_;
    }

    function pricingToken() public view returns(ERC20) {
        return _pricingToken;
    }

    function setPricingToken(ERC20 pricingToken_) public onlyRole(ADMIN_ROLE) {
        _pricingToken = pricingToken_;
    }

    function placeTokens(uint256 nonce, uint256 price, ERC20 token, uint256 initialVolume, bytes memory signature) public {
        address sender = msg.sender;

        require(!nonces[nonce], "Crypton: Invalid nonce");
        require(!placedTokens[token].isActive, "Crypton: This token was already placed");
        require(initialVolume > 0, "Crypton: initial Volume must be >0");

        address signer = keccak256(abi.encodePacked(sender, address(token), initialVolume, price, nonce))
        .toEthSignedMessageHash().recover(signature);

        require(hasRole(SIGNER_ROLE, signer), "Crypton: Invalid signature");
        
        token.safeTransferFrom(sender, address(this), initialVolume);

        placedTokens[token] = PlacedToken ({
                                            owner: sender,
                                            price: price,
                                            initialVolume: initialVolume,
                                            volume: initialVolume,
                                            collectedAmount: 0,
                                            isActive: true
                                        });
        
        nonces[nonce] = true;

        emit TokenPlaced(token, nonce);
    }

    function _sendCollectedFunds(address sender, ERC20 token) private {
        PlacedToken storage placedToken = placedTokens[token];
        require (sender == placedToken.owner, "Crypton: You are not the owner of this token");

        _pricingToken.safeTransfer(placedToken.owner, placedToken.collectedAmount);
        placedToken.collectedAmount = 0;

        emit FundsCollected(token);
    }

    function getCollectedFunds(ERC20 token) public nonReentrant{
        _sendCollectedFunds(msg.sender, token);
    }

    function finishRound(ERC20 token) public nonReentrant {
        address sender = msg.sender;
        PlacedToken storage placedToken = placedTokens[token];

        require(sender == placedToken.owner, "Crypton: You are not the owner of this token");

        _sendCollectedFunds(sender, token);
        
        token.safeTransfer(sender, placedToken.volume); 
        delete placedTokens[token];

        emit RoundFinished(token);
    }

    function buyTokens(ERC20 token, uint256 volume) public nonReentrant {
        address sender = msg.sender;
        PlacedToken storage placedToken = placedTokens[token];

        require(placedToken.isActive == true, "Crypton: Round isn't active");

        _pricingToken.safeTransferFrom(sender, address(this), volume);

        uint256 tokensAmount = volume * (10 ** token.decimals()) / placedToken.price;
        require(tokensAmount <= placedToken.volume, "Crypton: Not enough volume");

        token.safeTransfer(sender, tokensAmount);

        uint256 fee = volume * _feePercent / 100;
        placedToken.collectedAmount += volume - fee;
        placedToken.volume -= tokensAmount;
        _pricingToken.safeTransfer(_feeCollector, fee);

        emit TokensBought(token, sender, tokensAmount);
    }
}