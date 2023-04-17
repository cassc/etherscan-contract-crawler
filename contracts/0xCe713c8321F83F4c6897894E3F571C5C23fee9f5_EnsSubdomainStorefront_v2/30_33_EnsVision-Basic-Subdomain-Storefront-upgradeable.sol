// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ens-contracts/wrapper/NameWrapper.sol";
import {CANNOT_UNWRAP, PARENT_CANNOT_CONTROL, CAN_EXTEND_EXPIRY, CANNOT_APPROVE} from "ens-contracts/wrapper/INameWrapper.sol";
import "./structs/SaleConfig.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IStorefront.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 *
 * @title EnsVision Subdomain Storefront v2
 * @author hodl.esf.eth
 * @dev This contract allows users sell and mint subdomains.
 * @dev This contract is upgradable.
 * @notice Developed by EnsVision.
 */
contract EnsSubdomainStorefront_v2 is
    IStorefront,
    OwnableUpgradeable,
    ReentrancyGuard
{
    event ConfigureSubdomain(uint256 indexed id, SaleConfig config);
    event DisableSales(address indexed owner, bool isDisabled);
    event PurchaseSubdomain(
        bytes32 indexed _ens,
        address _buyer,
        address _seller,
        string _label
    );

    mapping(uint256 => SaleConfig) public saleConfigs;
    mapping(uint256 => uint256) public dailyRenewalPrice;
    mapping(address => bool) public isSalesDisabled;

    uint256 public visionPercentFee;

    NameWrapper public  nameWrapper;
    IBaseRegistrar public baseRegistrar;
    IPriceOracle public priceOracle;

    function init(
        NameWrapper _wrapper,
        IPriceOracle _oracle,
        IBaseRegistrar _registrar
    ) external {
        nameWrapper = _wrapper;
        priceOracle = _oracle;
        baseRegistrar = _registrar;
        visionPercentFee = 50;
        _transferOwnership(msg.sender);
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice configure sale settings for an ens
     * @param _ids ids of the domains to configure
     * @param _configs sale configs for the domains
     */
    function setUpDomains(
        uint256[] calldata _ids,
        SaleConfig[] calldata _configs
    ) public {
        for (uint256 i; i < _ids.length; ) {
            uint256 id = _ids[i];
            require(
                msg.sender == nameWrapper.ownerOf(id),
                "not owner of domain"
            );

            SaleConfig memory config = _configs[i];

            require(msg.sender == config.owner, "owner mismatch in config");

            (, uint32 parentFuses, ) = nameWrapper.getData(id);

            saleConfigs[id] = config;
            require(
                (parentFuses & CANNOT_UNWRAP != 0 &&
                    parentFuses & PARENT_CANNOT_CONTROL != 0) ||
                    config.dailyRent == 0,
                "cannot rent subs on unwrappable domain"
            );

            require(
                (parentFuses & CANNOT_APPROVE != 0 &&
                    nameWrapper.getApproved(id) == address(this)) ||
                    config.dailyRent == 0,
                "renewal contract approval incorrect"
            );

            emit ConfigureSubdomain(id, config);

            unchecked {
                ++i;
            }
        }
    }

    function purchaseDomains(
        uint256[] calldata _ids,
        string[] calldata _labels,
        address[] calldata _mintTo,
        address _resolver,
        uint64[] calldata _duration
    ) public payable nonReentrant {
        uint256 accumulatedPrice;

        for (uint256 i; i < _ids.length; ) {
            {
                SaleConfig memory config = saleConfigs[_ids[i]];
                uint256 duration;
                if (config.dailyRent > 0) {
                    duration = getDuration(
                        block.timestamp,
                        _ids[i],
                        _duration[i]
                    );
                } else {
                    duration = type(uint64).max;
                }

                {
                    address owner = nameWrapper.ownerOf(_ids[i]);
                    uint256 price;
                    // owner of the domain can always mint their own subdomains
                    if (owner != msg.sender) {
                        require(
                            (config.isForSale && !isSalesDisabled[owner]),
                            "domain not for sale"
                        );
                        // but users can't mint subdomains from legacy configs
                        require(owner == config.owner, "owner changed");

                        if (config.price > 0 || config.dailyRent > 0) {
                            price = getPrice(config, duration);

                            uint256 commission = getCommission(price);
                            uint256 payment = price - commission;

                            // send the funds minus commission to the owner
                            payable(owner).call{value: payment, gas: 10_000}(
                                ""
                            );

                            accumulatedPrice += price;
                        }
                    }
                }

                uint256 subdomainId = uint256(
                    keccak256(
                        abi.encodePacked(
                            _ids[i],
                            keccak256(abi.encodePacked(_labels[i]))
                        )
                    )
                );

                // check if the subdomain already exists
                require(
                    nameWrapper.ownerOf(subdomainId) == address(0),
                    "subdomain already exists"
                );

                if (config.dailyRent > 0) {
                    dailyRenewalPrice[subdomainId] = config.dailyRent;
                }

                mintSubdomain(
                    _ids[i],
                    _labels[i],
                    _mintTo[i],
                    _resolver,
                    config,
                    uint64(duration)
                );

                emit PurchaseSubdomain(
                    bytes32(_ids[i]),
                    _mintTo[i],
                    config.owner,
                    _labels[i]
                );
            }

            unchecked {
                ++i;
            }
        }

        require(msg.value >= accumulatedPrice, "not enough funds");

        uint256 excess = msg.value - accumulatedPrice;

        // send any excess funds back to the user
        if (excess > 0) {
            payable(msg.sender).call{value: excess}("");
        }
    }

    function mintSubdomain(
        uint256 _parent,
        string calldata _label,
        address _mintTo,
        address _resolver,
        SaleConfig memory _config,
        uint64 _duration
    ) internal {
        uint64 expiry = getExpiry(_parent, _config, _duration);
        uint32 fuses = getFuses(_parent, _config);

        nameWrapper.setSubnodeRecord(
            bytes32(_parent),
            _label,
            _mintTo,
            _resolver,
            0,
            fuses,
            expiry
        );
    }

    function renewSubdomain(
        uint256[] calldata _ids,
        string[] calldata _labels,
        uint64[] calldata _durations
    ) public payable nonReentrant {
        uint256 accumulatedPrice;
        for (uint256 i; i < _ids.length; ) {
            uint256 subdomainId = uint256(
                keccak256(
                    abi.encodePacked(
                        _ids[i],
                        keccak256(abi.encodePacked(_labels[i]))
                    )
                )
            );

            uint256 duration;
            {
                (, , uint64 currentExpiry) = nameWrapper.getData(subdomainId);

                duration = getDuration(currentExpiry, _ids[i], _durations[i]);

                nameWrapper.extendExpiry(bytes32(_ids[i]), keccak256(abi.encodePacked(_labels[i])), _durations[i]);
            }
            uint256 payment = getRenewalPrice(subdomainId, duration);
            uint256 commission = getCommission(payment);

            accumulatedPrice += payment;

            if (payment > 0) {
                // current owner of the domain gets the funds - commission
                address owner = nameWrapper.ownerOf(_ids[i]);
                payable(owner).call{value: payment - commission, gas: 80_000}(
                    ""
                ); // prevent any malicious gas griefing
            }

            unchecked {
                ++i;
            }
        }

        require(msg.value >= accumulatedPrice, "not enough funds");
        uint256 excess = msg.value - accumulatedPrice;

        if (excess > 0) {
            payable(msg.sender).call{value: excess}("");
        }
    }

    function getDuration(
        uint256 _currentExpiry,
        uint256 _parentId,
        uint256 _duration
    ) private view returns (uint256) {
        (, , uint64 maxExpiry) = nameWrapper.getData(_parentId);

        if (_currentExpiry + _duration > (maxExpiry - 90 days)) {
            return maxExpiry - _currentExpiry - 90 days;
        } else {
            return _duration;
        }
    }

    function updatePriceOracle(IPriceOracle _priceOracle) public onlyOwner {
        priceOracle = _priceOracle;
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "transfer failed");
    }

    /**
     *
     * @dev update commission. 0 = 0%, 10 = 1%, 100 = 10%
     * @dev max commission is 10%
     */

    function updateVisionFee(uint256 _visionPercent) public onlyOwner {
        require(
            (_visionPercent <= 100 && _visionPercent > 5) ||
                _visionPercent == 0,
            "vision percent must 0, 0.5 - 10%"
        );

        visionPercentFee = _visionPercent;
    }

    /**
     * @dev disable global sales for the calling address
     */
    function setGlobalSalesDisabled(bool _isDisabled) public {
        isSalesDisabled[msg.sender] = _isDisabled;

        emit DisableSales(msg.sender, _isDisabled);
    }

    function getPrice(
        SaleConfig memory _config,
        uint256 _duration
    ) private view returns (uint256) {
        uint256 dollarValue = priceOracle.getWeiValueOfDollar();
        uint256 fixedPrice = (dollarValue * _config.price) / 1 ether;

        if (_config.dailyRent == 0) {
            return fixedPrice;
        } else {
            uint256 duration = (_duration + (1 days - 1)) / 1 days;
            uint256 variablePrice = (dollarValue *
                _config.dailyRent *
                duration) / 1 ether;

            return (fixedPrice + variablePrice);
        }
    }

    function getRenewalPrice(
        uint256 _subdomainId,
        uint256 _duration
    ) private view returns (uint256) {
        uint256 dollarValue = priceOracle.getWeiValueOfDollar();
        uint256 duration = (_duration + (1 days - 1)) / 1 days;
        uint256 variablePrice = (dollarValue *
            dailyRenewalPrice[_subdomainId] *
            duration) / 1 ether;

        return variablePrice;
    }

    function getExpiry(
        uint256 _parentId,
        SaleConfig memory _config,
        uint64 _expiry
    ) private view returns (uint64) {
        if (_config.dailyRent == 0) {
            return type(uint64).max;
        } else {
            return uint64(block.timestamp) + _expiry;
        }
    }

    function getFuses(
        uint256 _parentId,
        SaleConfig memory _config
    ) private view returns (uint32) {
        (, uint32 parentFuses, ) = nameWrapper.getData(_parentId);

        if (CANNOT_UNWRAP & parentFuses != 0) {
            if (_config.dailyRent == 0) {
                return PARENT_CANNOT_CONTROL | CAN_EXTEND_EXPIRY;
            } else {
                return PARENT_CANNOT_CONTROL;
            }
        }

        return uint32(0);
    }

    function getConfigDataWithEthPrice(
        uint256 _parentId,
        uint64 _duration
    ) external view returns (SaleConfig memory, uint256) {
        //
        SaleConfig memory config = saleConfigs[_parentId];
        uint256 ethPrice = getPrice(config, _duration);
        return (config, ethPrice);
    }

    function getPrices(
        uint256[] calldata _ids,
        uint64[] calldata _durations
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](_ids.length);

        for (uint256 i; i < _ids.length; ) {
            SaleConfig memory config = saleConfigs[_ids[i]];
            address owner = nameWrapper.ownerOf(_ids[i]);

            if (
                // if any of these conditions are true then
                // the subdomain is not for sale so set price to max
                owner != config.owner ||
                !config.isForSale ||
                isSalesDisabled[owner] ||
                !nameWrapper.isApprovedForAll(owner, address(this))
            ) {
                prices[i] = type(uint256).max;
            } else {
                prices[i] = getPrice(config, _durations[i]);
            }

            unchecked {
                ++i;
            }
        }

        return prices;
    }

    

    function getCommission(uint256 _price) private view returns (uint256) {
        return (_price * visionPercentFee) / 1000;
    }
}