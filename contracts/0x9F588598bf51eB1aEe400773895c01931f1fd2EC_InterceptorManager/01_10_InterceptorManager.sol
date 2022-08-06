// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IInterceptor} from "./interfaces/IInterceptor.sol";
import {IInterceptorManager} from "./interfaces/IInterceptorManager.sol";

/**
 * @title InterceptorManager
 * @notice It allows adding/removing inteceptor for trading on the Bend exchange.
 */
contract InterceptorManager is IInterceptorManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelistedInterceptors;

    event CollectionInterceptorRemoved(address indexed interceptor);
    event CollectionInterceptorWhitelisted(address indexed interceptor);

    function addCollectionInterceptor(address interceptor) external override onlyOwner {
        require(interceptor != address(0), "Interceptor: can not be null address");
        require(!_whitelistedInterceptors.contains(interceptor), "Interceptor: already whitelisted");
        _whitelistedInterceptors.add(interceptor);
        emit CollectionInterceptorWhitelisted(interceptor);
    }

    function removeCollectionInterceptor(address interceptor) external override onlyOwner {
        require(_whitelistedInterceptors.contains(interceptor), "Interceptor: not whitelisted");
        _whitelistedInterceptors.remove(interceptor);

        emit CollectionInterceptorRemoved(interceptor);
    }

    function isInterceptorWhitelisted(address interceptor) external view override returns (bool) {
        return _whitelistedInterceptors.contains(interceptor);
    }

    function viewCountWhitelistedInterceptors() external view override returns (uint256) {
        return _whitelistedInterceptors.length();
    }

    function viewWhitelistedInterceptors(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedInterceptors.length() - cursor) {
            length = _whitelistedInterceptors.length() - cursor;
        }

        address[] memory whitelistedInterceptors = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedInterceptors[i] = _whitelistedInterceptors.at(cursor + i);
        }

        return (whitelistedInterceptors, cursor + length);
    }
}