// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

// solhint-disable not-rely-on-time, max-states-count

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../../../interface/module/router/IBaseRouter.sol";

abstract contract Router is Initializable, BaseRelayRecipient, IBaseRouter {
    address internal _gameFiCore;
    address internal _gameFiShops;
    address internal _gameFiMarketpalce;

    // solhint-disable-next-line func-name-mixedcase
    function __Router_init(
        address gameFiCore_,
        address gameFiShops_,
        address gameFiMarketpalce_
    ) internal onlyInitializing {
        __Router_init_unchained(gameFiCore_, gameFiShops_, gameFiMarketpalce_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Router_init_unchained(
        address gameFiCore_,
        address gameFiShops_,
        address gameFiMarketpalce_
    ) internal onlyInitializing {
        _gameFiCore = gameFiCore_;
        _gameFiShops = gameFiShops_;
        _gameFiMarketpalce = gameFiMarketpalce_;
    }

    function _getRandomSalt() internal view returns (uint256) {
        return (
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        block.number,
                        block.gaslimit,
                        msg.sender,
                        msg.data,
                        gasleft()
                    )
                )
            )
        );
    }

    uint256[47] private __gap;
}