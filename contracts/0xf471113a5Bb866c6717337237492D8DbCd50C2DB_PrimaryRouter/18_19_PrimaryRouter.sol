// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IFrigg.sol";
import "../Interfaces/IRouterGater.sol";
import "../Interfaces/IPrimaryRouter.sol";
import "../Token/FriggToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A router contract for primary market activity for Frigg Asset-Backed Tokens (ABT)
/// @author Frigg team
/// @dev Inherits from the OpenZepplin AccessControl
contract PrimaryRouter is AccessControl, IPrimaryRouter {
    /// Add Frigg issued tokens to this router
    mapping(address => TokenData) public tokenData;
    address public routerGater;

    /// @notice TokenData Struct: Required attributes for added tokens
    /// @dev USDC-denominated price is always 6 decimals
    struct TokenData {
        address issuer; // address of the token issuer
        uint256 issuancePrice; // price = (1 * 10^18) / (USD * 10^6) e.g., 100USD = 10^18/10^8
        uint256 expiryPrice; // price = (1/(expirydigit) * 10^18) / (USD * 10^6) e.g., 200USD = 10^18/20^8
        address issuanceTokenAddress; // address of token accepted as a denominated token e.g. USDC
    }

    /// Allow microsite front-end to listen to events and show recent primary market activity
    event SuccessfulPurchase(address indexed _buyer, address _friggTokenAddress, uint256 _amount);

    event SuccessfulExpiration(address indexed _seller, address _friggTokenAddress, uint256 _amount);

    /// @notice Establish access control logic for this router
    /// @dev Set DEFAULT_ADMIN_ROLE to a multisig address controlled by Frigg
    /// @dev DEFAULT_ADMIN_ROLE is defined within OZ's AccessControl
    constructor(address _multisig, address _routerGater) {
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        routerGater = _routerGater;
    }

    ///  @dev Only allows DEFAULT_ADMIN_ROLE to add Frigg-issued tokens to this router
    ///  @notice Only Frigg controlled multisig address can add newly issued tokens
    ///  @param _outputTokenAddress Frigg-issued token address
    ///  @param _issuer Issuer address to receive issuance proceeds
    ///  @param _issuancePrice Price of token at issuance
    ///  @param _expiryPrice Price of token at expiry date
    ///  @param _issuanceTokenAddress Address of Accepted token to purchase Frigg-issued token
    function add(
        address _outputTokenAddress,
        address _issuer,
        uint256 _issuancePrice,
        uint256 _expiryPrice,
        address _issuanceTokenAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenData[_outputTokenAddress] = TokenData(_issuer, _issuancePrice, _expiryPrice, _issuanceTokenAddress);
    }

    /// @notice Buy widget logic for primary market
    /// @param friggTokenAddress Frigg-issued token address
    /// @param inputTokenAmount amount of tokens spent to buy Frigg-issued token
    /// @dev initially users can only buy Frigg-issued asset backed tokens with USDC
    /// i.e. inputToken is USDC and outputToken is the ABT
    /// @dev inputTokenAmount should be in the same number of decimals as issuanceTokenAddress implemented
    function buy(address friggTokenAddress, uint256 inputTokenAmount) external payable override {
        require(inputTokenAmount > 0, "You cannot buy with 0 token");

        /// Puts the gater require condition for potential gas return to users
        IRouterGater gater = IRouterGater(routerGater);
        require(gater.checkGatedStatus{value: msg.value}(msg.sender), "Your wallet is not eligible to buy");

        IERC20 inputToken = IERC20(tokenData[friggTokenAddress].issuanceTokenAddress);
        IFrigg outputToken = IFrigg(friggTokenAddress);

        /// check that primary market is active
        require(outputToken.isPrimaryMarketActive());

        inputToken.transferFrom(msg.sender, tokenData[friggTokenAddress].issuer, inputTokenAmount);

        /// if inputTokenAmount is 1 USDC * 10^6, outputTokenAmount is 1 ATT * 10^18, issuancePrice is 1 ATT:1 USDC * 10^12
        uint256 outputTokenAmount = inputTokenAmount * tokenData[friggTokenAddress].issuancePrice;

        outputToken.mint(msg.sender, outputTokenAmount);

        emit SuccessfulPurchase(msg.sender, friggTokenAddress, inputTokenAmount);
    }

    /// @notice Sell widget logic for primary market
    /// @notice At token expiry, token holders sell back tokens to issuers
    /// @notice Token holders redeem the value of token at expiry
    /// @param friggTokenAddress Frigg-issued token address
    /// @param inputFriggTokenAmount amount of Frigg tokens for sale
    /// i.e. inputToken is ABT and outputToken is USDC
    /// @dev inputFriggTokenAmount should be in 18 decimals
    function sell(address friggTokenAddress, uint256 inputFriggTokenAmount) external payable override {
        require(inputFriggTokenAmount > 0, "You cannot sell 0 token");

        /// Puts the gater require condition for potential gas return Øto users
        IRouterGater gater = IRouterGater(routerGater);
        require(gater.checkGatedStatus{value: msg.value}(msg.sender), "Your wallet is not eligible to sell");

        IFrigg inputToken = IFrigg(friggTokenAddress);
        IERC20 outputToken = IERC20(tokenData[friggTokenAddress].issuanceTokenAddress);

        require(inputToken.seeBondExpiryStatus());

        inputToken.burn(msg.sender, inputFriggTokenAmount);

        /// if inputFriggTokenAmount is 1 ATT * 10^18, expiryPrice is 1.5 USDC : 1 ATT * 10^12, outputTokenAmount is 1.5 USDC * 10^6
        uint256 outputTokenAmount = inputFriggTokenAmount / tokenData[friggTokenAddress].expiryPrice;

        /// Issuer smart contract address should give approval to router to transfer USDC to msg.sender prior to bond expiry
        outputToken.transferFrom(tokenData[friggTokenAddress].issuer, msg.sender, outputTokenAmount);

        emit SuccessfulExpiration(msg.sender, friggTokenAddress, inputFriggTokenAmount);
    }

    /// @notice Update routerGater address
    /// @dev Only routeradmin can update this address
    function updateRouterGaterAddress(address _routerGater) public onlyRole(DEFAULT_ADMIN_ROLE) {
        routerGater = _routerGater;
    }

    /// @notice Migrate existing tokens to new token contracts
    /// @dev Only routeradmin can update this address
    function migrateTokens(
        address[] calldata _holders,
        address _from,
        address _to
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        FriggToken fromToken = FriggToken(_from);
        FriggToken toToken = FriggToken(_to);

        require(tokenData[_from].issuer != address(0), "INVALID_FROM_TOKEN");
        require(tokenData[_to].issuer != address(0), "INVALID_TO_TOKEN");

        uint256 length = _holders.length;

        for (uint256 i = 0; i < length; ) {
            uint256 amount = fromToken.balanceOf(_holders[i]);

            require(amount > 0, "NO_BALANCE_FROM_TOKEN");

            toToken.mint(_holders[i], amount);

            unchecked {
                i++;
            }
        }
    }
}