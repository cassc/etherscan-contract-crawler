// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ERC721JumpStart.sol";

contract EliteTokenDistributorDuel is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ClaimableTokens {
        // token address + amount
        mapping(address => uint256) claimable;
    }

    address[] public feeCollectorsGroup1;
    address[] public feeCollectorsGroup2;
    address[] public registeredPayoutTokens;
    mapping(address => bool) public isRegisteredPayoutToken;
    mapping(address => uint256) public feeRates;
    // holder => address => ClaimableTokens
    mapping(address => ClaimableTokens) private availableClaim;

    constructor() {}

    function initialize(
        address[] memory _feeCollectors,
        address[] memory _feeCollectors2,
        uint256[] memory _feeRates,
        address owner
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(owner);

        // set initial fee collectors / rates
        for (uint256 i = 0; i < _feeCollectors.length; i++) {
            feeCollectorsGroup1.push(_feeCollectors[i]);
            feeCollectorsGroup2.push(_feeCollectors2[i]);
            feeRates[_feeCollectors[i]] = _feeRates[i];
        }
    }

    function getFeeCollectors() public view returns (address[] memory a, address[] memory b) {
        return (feeCollectorsGroup1, feeCollectorsGroup2);
    }

    function getRegisteredTokens() public view returns (address[] memory a) {
        return registeredPayoutTokens;
    }

    function getAvailableClaim(address holder)
        public
        view
        returns (address[] memory a, uint256[] memory b)
    {
        ClaimableTokens storage claimableTokens = availableClaim[holder];
        address[] memory tokens = registeredPayoutTokens;
        uint256[] memory amounts = new uint256[](tokens.length);
        for(uint256 i = 0; i < registeredPayoutTokens.length; i++) {
            address token = registeredPayoutTokens[i];
            uint256 amount = claimableTokens.claimable[token];
            if(amount > 0) {
                amounts[i] = amount;
            }else{
                amounts[i] = 0;
            }
        }

        return (tokens, amounts);
    }

    function registerToken(IERC20Upgradeable _token) public onlyOwner {
        require(
            IERC20Upgradeable(_token).totalSupply() > 0,
            "Token must have a supply"
        );

        registeredPayoutTokens.push(address(_token));
        isRegisteredPayoutToken[address(_token)] = true;
    }

    function unregisterToken(IERC20Upgradeable _token) public onlyOwner {
        for (uint256 i = 0; i < registeredPayoutTokens.length; i++) {
            if (registeredPayoutTokens[i] == address(_token)) {
                registeredPayoutTokens[i] = registeredPayoutTokens[
                    registeredPayoutTokens.length - 1
                ];
                registeredPayoutTokens.pop();
                isRegisteredPayoutToken[address(_token)] = false;
                break;
            }
        }
    }

    // feecollectors must be erc721JumpStart contracts
    function setFees(
        address[] memory _feeCollectorGroup1,
        address[] memory _feeCollectorGroup2,
        uint256[] memory _feeRates
    ) public onlyOwner {
        require(
            _feeCollectorGroup1.length == _feeRates.length && _feeCollectorGroup2.length == _feeRates.length,
            "Fee collectors and rates must be the same length"
        );

        uint256 totalRate;
        for (uint256 i = 0; i < _feeRates.length; i++) {
            totalRate = totalRate + _feeRates[i];
        }
        require(totalRate == 10000, "Total rate must be 10000 100%");

        // set feeRates to 0 for existing fee collectors
        for (uint256 i = 0; i < feeCollectorsGroup1.length; i++) {
            feeRates[feeCollectorsGroup1[i]] = 0;            
        }

        // clear existing fee collectors
        delete feeCollectorsGroup1;
        delete feeCollectorsGroup2;

        // set new fee collectors / rates
        for (uint256 i = 0; i < _feeCollectorGroup1.length; i++) {
            feeCollectorsGroup1.push(_feeCollectorGroup1[i]);            
            feeCollectorsGroup2.push(_feeCollectorGroup2[i]);
            feeRates[_feeCollectorGroup1[i]] = _feeRates[i];            
        }
    }

    function depositToken(IERC20Upgradeable token, uint256 amount) public {
        require(
            isRegisteredPayoutToken[address(token)],
            "Token must be registered"
        );

        // loop through fee collectors and transfer tokens
        for (uint256 i = 0; i < feeCollectorsGroup1.length; i++) {
            uint256 feeAmount = amount.mul(feeRates[feeCollectorsGroup1[i]]).div(10000);
            calculateAndDistribute(feeCollectorsGroup1[i], feeCollectorsGroup2[i], feeAmount, address(token));
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function claimPayout() public nonReentrant {
        
        ClaimableTokens storage claim = availableClaim[msg.sender];
        for (uint256 i = 0; i < registeredPayoutTokens.length; i++) {
            address token = registeredPayoutTokens[i];
            uint256 amount = claim.claimable[token];
            if (amount > 0) {
                claim.claimable[token] = 0;
                IERC20Upgradeable(token).transfer(msg.sender, amount);
            }
        }
    }

    function calculateAndDistribute(
        address feeCollector,
        address feeCollector2,
        uint256 amount,
        address token
    ) internal {        
        
        // feeCollector must be erc721JumpStart contract
        uint256 totalMinted = ERC721JumpStart(feeCollector).totalSupply();
        uint256 totalMinted2 = ERC721JumpStart(feeCollector2).totalSupply();
    
        if(feeCollector == feeCollector2) {
            totalMinted2 = 0;
        }
        uint256 amountPerHolder = amount.div(totalMinted + totalMinted2);

        for (uint256 i = 0; i < totalMinted; i++) {
            address owner = ERC721JumpStart(feeCollector).ownerOf(i);

            availableClaim[owner].claimable[token] = availableClaim[owner]
                .claimable[token]
                .add(amountPerHolder);
        }

        for (uint256 i = 0; i < totalMinted2; i++) {
            address owner = ERC721JumpStart(feeCollector2).ownerOf(i);

            availableClaim[owner].claimable[token] = availableClaim[owner]
                .claimable[token]
                .add(amountPerHolder);
        }
    }
}