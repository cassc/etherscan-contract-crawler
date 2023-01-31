/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ILooksRare.sol";
import "./IThirdExchangeOfferCheckerFeature.sol";


contract ThirdExchangeOfferCheckerFeature is IThirdExchangeOfferCheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;

    constructor(address looksRare) {
        LOOKS_RARE = looksRare;
    }

    function getSeaportOfferCheckInfo(
        address account,
        address erc20Token,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    )
        external
        override
        view
        returns (SeaportOfferCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (erc20Token == address(0)) {
            info.balance = 0;
            info.allowance = 0;
        } else {
            info.balance = balanceOf(erc20Token, account);
            info.allowance = allowanceOf(erc20Token, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(SEAPORT).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getLooksRareOfferCheckInfo(address account, address erc20Token, uint256 accountNonce)
        external
        override
        view
        returns (LooksRareOfferCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        try ILooksRare(LOOKS_RARE).userMinOrderNonce(account) returns (uint256 minNonce) {
            if (accountNonce < minNonce) {
                info.isExecutedOrCancelled = true;
            }
        } catch {}

        if (erc20Token == address(0)) {
            info.balance = 0;
            info.allowance = 0;
        } else {
            info.balance = balanceOf(erc20Token, account);
            info.allowance = allowanceOf(erc20Token, account, LOOKS_RARE);
        }
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        if (conduitKey == 0x0000000000000000000000000000000000000000000000000000000000000000) {
            conduit = SEAPORT;
            exists = true;
        } else {
            try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
                try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                    conduit = _conduit;
                    exists = _exists;
                } catch {
                }
            } catch {
            }
        }
        return (conduit, exists);
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }
}