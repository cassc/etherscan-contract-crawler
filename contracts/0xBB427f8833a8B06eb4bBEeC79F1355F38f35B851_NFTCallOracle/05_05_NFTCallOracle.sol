// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracleGetter.sol";

/**
 * @title NFTCallOracle
 * @author NFTCall
 */
contract NFTCallOracle is IOracleGetter, Ownable, Pausable {
    // asset address
    mapping(address => uint256) private _addressIndexes;
    mapping(address => bool) private _emergencyAdmin;
    address[] private _addressList;
    address private _operator;

    // price
    struct Price {
        uint32 v1;
        uint32 v2;
        uint32 v3;
        uint32 v4;
        uint32 v5;
        uint32 v6;
        uint32 v7;
        uint32 v8;
    }
    Price[50] private _prices;
    struct UpdateInput {
        uint16 price; // Retain two decimals. If floor price is 10.3 ,the input price is 1030
        uint16 vol; // Retain one decimal. If volatility is 3.56% , the input vol is 36
        uint256 index; // 1 ~ 8
    }
    uint16 private constant VOL_LIMIT = 300; // 30%

    // Event
    event SetAssetData(uint256[] indexes, UpdateInput[][] inputs);
    event ChangeOperator(
        address indexed oldOperator,
        address indexed newOperator
    );
    event SetEmergencyAdmin(address indexed admin, bool enabled);
    event ReplaceAsset(address indexed oldAsset, address indexed newAsset);

    /**
     * @dev Constructor
     * @param newOperator The address of the operator
     * @param assets The addresses of the assets
     */
    constructor(address newOperator, address[] memory assets) {
        require(newOperator != address(0));
        _setOperator(newOperator);
        _addAssets(assets);
    }

    function _addAssets(address[] memory addresses) private {
        uint256 index = _addressList.length + 1;
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (_addressIndexes[addr] == 0) {
                _addressIndexes[addr] = index;
                _addressList.push(addr);
                index++;
            }
        }
    }

    function _setOperator(address newOperator) private {
        address oldOperator = _operator;
        _operator = newOperator;
        emit ChangeOperator(oldOperator, newOperator);
    }

    function pack(uint16 a, uint16 b) private pure returns (uint32) {
        return (uint32(a) << 16) | uint32(b);
    }

    function unpack(uint32 c) private pure returns (uint16 a, uint16 b) {
        a = uint16(c >> 16);
        b = uint16(c);
    }

    function operator() external view returns (address) {
        return _operator;
    }

    function isEmergencyAdmin(address admin) external view returns (bool) {
        return _emergencyAdmin[admin];
    }

    function getAddressList() external view returns (address[] memory) {
        return _addressList;
    }

    function getIndexes(
        address asset
    ) public view returns (uint256 OuterIndex, uint256 InnerIndex) {
        uint256 index = _addressIndexes[asset];
        OuterIndex = (index - 1) / 8;
        InnerIndex = index % 8;
        if (InnerIndex == 0) {
            InnerIndex = 8;
        }
    }

    function addAssets(address[] memory assets) external onlyOwner {
        require(assets.length > 0);
        _addAssets(assets);
    }

    function replaceAsset(
        address oldAsset,
        address newAsset
    ) external onlyOwner {
        uint256 index = _addressIndexes[oldAsset];
        require(index != 0, "invalid index");
        _addressList[index - 1] = newAsset;
        emit ReplaceAsset(oldAsset, newAsset);
    }

    function setPause(bool val) external {
        require(
            _emergencyAdmin[_msgSender()],
            "caller is not the emergencyAdmin"
        );
        if (val) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "invalid operator");
        _setOperator(newOperator);
    }

    function setEmergencyAdmin(address admin, bool enabled) external onlyOwner {
        require(admin != address(0), "invalid admin");
        _emergencyAdmin[admin] = enabled;
        emit SetEmergencyAdmin(admin, enabled);
    }

    function _getPriceByIndex(
        address asset
    ) private view returns (uint16, uint16) {
        uint256 index = _addressIndexes[asset];
        if (index == 0) {
            return unpack(0);
        }
        (uint256 OuterIndex, uint256 InnerIndex) = getIndexes(asset);
        Price memory cachePrice = _prices[OuterIndex];
        uint32 value = 0;
        if (InnerIndex == 1) {
            value = cachePrice.v1;
        } else if (InnerIndex == 2) {
            value = cachePrice.v2;
        } else if (InnerIndex == 3) {
            value = cachePrice.v3;
        } else if (InnerIndex == 4) {
            value = cachePrice.v4;
        } else if (InnerIndex == 5) {
            value = cachePrice.v5;
        } else if (InnerIndex == 6) {
            value = cachePrice.v6;
        } else if (InnerIndex == 7) {
            value = cachePrice.v7;
        } else if (InnerIndex == 8) {
            value = cachePrice.v8;
        }
        return unpack(value);
    }

    function _getAsset(
        address asset
    ) private view returns (uint256 price, uint256 vol) {
        (uint16 p, uint16 v) = _getPriceByIndex(asset);
        price = uint256(p) * 1e16;
        vol = uint256(v) * 10;
    }

    function getAssetPrice(
        address asset
    ) external view returns (uint256 price) {
        (price, ) = _getAsset(asset);
    }

    function getAssetVol(address asset) external view returns (uint256 vol) {
        (, vol) = _getAsset(asset);
    }

    function getAssets(
        address[] memory assets
    ) external view returns (uint256[2][] memory prices) {
        prices = new uint256[2][](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            (uint256 price, uint256 vol) = _getAsset(assets[i]);
            prices[i] = [price, vol];
        }
        return prices;
    }

    function _setAssetPrice(
        uint256 index,
        UpdateInput[] memory inputs
    ) private {
        Price storage cachePrice = _prices[index];
        for (uint256 i = 0; i < inputs.length; i++) {
            UpdateInput memory input = inputs[i];
            require(input.vol >= VOL_LIMIT, "invalid vol");
            uint256 InnerIndex = input.index;
            uint32 value = pack(input.price, input.vol);
            if (InnerIndex == 1) {
                cachePrice.v1 = value;
            } else if (InnerIndex == 2) {
                cachePrice.v2 = value;
            } else if (InnerIndex == 3) {
                cachePrice.v3 = value;
            } else if (InnerIndex == 4) {
                cachePrice.v4 = value;
            } else if (InnerIndex == 5) {
                cachePrice.v5 = value;
            } else if (InnerIndex == 6) {
                cachePrice.v6 = value;
            } else if (InnerIndex == 7) {
                cachePrice.v7 = value;
            } else if (InnerIndex == 8) {
                cachePrice.v8 = value;
            }
        }
        _prices[index] = cachePrice;
    }

    function batchSetAssetPrice(
        uint256[] memory indexes,
        UpdateInput[][] memory inputs
    ) external whenNotPaused {
        require(_operator == _msgSender(), "caller is not the operator");
        require(indexes.length == inputs.length, "length must be equal");

        for (uint256 i = 0; i < indexes.length; i++) {
            _setAssetPrice(indexes[i], inputs[i]);
        }
        emit SetAssetData(indexes, inputs);
    }
}