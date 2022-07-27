/* Copyright (C) 2022 Bright Union */

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./interfaces/IRcaController.sol";
import "../../IDistributor.sol";
import "../AbstractDistributor.sol";

contract EaseDistributor is
    AbstractDistributor,
    IDistributor,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IRcaController internal vaultController;
    address brightProtocol;

    //* Initializer
    //*
    //* @dev Initializes the contract
    //* @param _brightProtocol address of the Bright Treasury contract for referral rewards
    //* @param _vaultController address of the Vault Controller contract aka Ease RcaController

    function __EaseDistributor_init(
        address _vaultController,
        address _brightProtocol
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        vaultController = IRcaController(_vaultController);
        brightProtocol = _brightProtocol;
    }

    //*********************************** NOT IMPLEMENTED ************************************

    function getCoverCount(address _userAddr, bool _isActive)
        external
        view
        override
        returns (uint256)
    {
        revert("Unavailable - For Ease use getEaseCoverCount");
    }

    function getCover(
        address _owner,
        uint256 _coverId,
        bool _isActive,
        uint256 _loopLimit
    ) public view override returns (IDistributor.Cover memory) {
        revert("Unavailable - For Ease use getEaseCover");
    }

    function getQuote(
        uint256 _sumAssured,
        uint256 _coverPeriod,
        address _contractAddress,
        address _coverAsset,
        address _nexusCoverable,
        bytes calldata _data
    ) public view override returns (IDistributor.CoverQuote memory) {
        revert("getQuote not implemented");
    }

    //****************************************************************************************

    //* @dev Checks if the Vault Contract has active RcaShield
    //* @return bool
    function isShieldedVault(address _vault) public view returns (bool) {
        return vaultController.activeShields(_vault);
    }

    //* @dev checks if Vault underlying token matches the token of the cover
    //* @param _token address of the ERC20 Token
    //* @param _vault address of the Vault contract
    //* @return bool
    function isTokenMatchingVault(address _token, address _vault)
        public
        returns (bool)
    {
        return IRcaShield(_vault).uToken() == IERC20(_token);
    }

    //* @dev Buys the cover
    //* Cover on ease is a wrapped token, so technically we are wrapping tokens not buying cover
    //* @param _vault address of the Vault contract
    //* @param _token address of the ERC20 Token to wrap into token with cover
    //* @param _amount uint256 amount of tokens to wrap
    //* @param _user address of the user who is buying the cover
    //* @param _uAmount uint256 amount of underlying tokens receive
    //* @param _expiry uint256 date of expiry of the cover
    //* @param _v uint8 version of the cover
    //* @param _r bytes32 random number used to generate the cover
    //* @param _s bytes32 signature of the cover
    //* @param _newCumLiqForCover uint256 of the new cumulative liquidation for the cover
    //* @param _liqForClaimsProof bytes32[] of the proof of the new cumulative liquidation for the cover
    function buyCover(
        address _vault,
        address _token,
        uint256 _amount, //
        address _user,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof
    ) external payable nonReentrant {
        require(_vault == address(_vault), "Invalid vault address");
        require(_token == address(_token), "Invalid token address");
        require(_user == address(_user), "Invalid wallet address");
        require(isShieldedVault(_vault), "Vault is not shielded");
        require(
            isTokenMatchingVault(_token, _vault),
            "Token is not matching underlying vault token"
        );

        IERC20Upgradeable underlyingToken = IERC20Upgradeable(_token);
        uint256 tokenBalance = underlyingToken.balanceOf(_user);

        require(tokenBalance >= _amount, "Insufficient token balance");

        underlyingToken.transferFrom(_user, address(this), _amount);

        underlyingToken.approve(_vault, _amount);

        IRcaShield(_vault).mintTo(
            _user,
            brightProtocol,
            _amount,
            _expiry,
            _v,
            _r,
            _s,
            _newCumLiqForClaims,
            _liqForClaimsProof
        );

        require(
            underlyingToken.balanceOf(address(this)) == 0,
            "Vault token balance mismatch"
        );

        emit BuyCoverEvent(
            _vault, //_productAddress
            0, //_productId
            _expiry, //_period
            _token, //_asset
            _amount, //_amount
            _amount //_price
        );
    }

    //* @dev get an array of ease covers
    //* @param _user address of the user who is buying the cover
    //* @param _vaultTokenAddrs address[] of the vault tokens
    function getEaseCovers(
        address _userAddr,
        address[] calldata _vaultTokenAddrs
    ) external view returns (uint256[] memory) {
        uint256[] memory _tokenBalances = new uint256[](
            _vaultTokenAddrs.length
        );
        for (uint256 i = 0; i < _vaultTokenAddrs.length; i++) {
            IERC20 vaultToken = IERC20(_vaultTokenAddrs[i]);
            _tokenBalances[i] = vaultToken.balanceOf(_userAddr);
        }
        return _tokenBalances;
    }

    //* @dev supportsInterface
    //* @param _interfaceID bytes4
    //* @return bool
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IDistributor).interfaceId ||
            supportsInterface(interfaceId);
    }
}