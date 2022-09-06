// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Assets.sol";
import "../interfaces/IVersioned.sol";

contract AssetViewer is IVersioned {
    using ERC165Checker for address;

    string public constant VERSION = '0.1.0';

    uint internal constant GAS_AMOUNT_FOR_EXTERNAL_CALLS = 200000;

    struct Asset {
        address addr;
        Assets.AssetType assetType;
        uint8 decimals;
        string name;
        string symbol;
        uint userBalance;
    }

    function checkAssets(address _user, address[] memory _assets) public view returns (Asset[] memory _result) {
        _result = new Asset[](_assets.length);
        for (uint i=0; i<_assets.length; i++) {
            Assets.AssetType assetType;
            uint8 decimals;
            string memory name;
            string memory symbol;
            uint userBalance;

            if (Address.isContract(_assets[i])) {
                if (_assets[i].supportsInterface(type(IERC721).interfaceId)) {
                    assetType = Assets.AssetType.ERC721;
                } else {
                    assetType = Assets.AssetType.ERC20;
                }

                try IERC20Metadata(_assets[i]).balanceOf{gas: GAS_AMOUNT_FOR_EXTERNAL_CALLS}(_user) // both for erc20/721
                    returns (uint balance)
                {
                    userBalance = balance;

                    try IERC20Metadata(_assets[i]).name{gas: GAS_AMOUNT_FOR_EXTERNAL_CALLS}() // both for erc20/721
                        returns (string memory _name)
                    {
                        name = _name;

                        try IERC20Metadata(_assets[i]).symbol{gas: GAS_AMOUNT_FOR_EXTERNAL_CALLS}() // both for erc20/721
                            returns (string memory _symbol)
                        {
                            symbol = _symbol;
                        } catch (bytes memory) {
                            assetType = Assets.AssetType.Unknown;
                        }
                    } catch (bytes memory) {
                        assetType = Assets.AssetType.Unknown;
                    }
                } catch (bytes memory) {
                    assetType = Assets.AssetType.Unknown;
                }

                if (assetType == Assets.AssetType.ERC20) {
                    try IERC20Metadata(_assets[i]).decimals{gas: GAS_AMOUNT_FOR_EXTERNAL_CALLS}()
                        returns (uint8 _decimals)
                    {
                        decimals = _decimals;
                    } catch (bytes memory) {
                        assetType = Assets.AssetType.Unknown;
                    }
                }
            }

            _result[i] = Asset(_assets[i], assetType, decimals, name, symbol, userBalance);
        }
    }
}