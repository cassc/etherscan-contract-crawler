/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./WrappedBackedToken.sol";
import "./WhitelistControllerAggregator.sol";

error ZeroAddressNotAllowed();

/**
 * @dev
 * TransparentUpgradeableProxy contract, renamed as WrappedBackedTokenProxy.
 */
contract WrappedBackedTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

/**
 * @dev
 *
 * WrappedBackedTokenFactory contract, which is responsible for deploying instances of wrapped Backed tokens.
 * 
 */
contract WrappedBackedTokenFactory is Ownable {
    ProxyAdmin public immutable proxyAdmin;
    WrappedBackedToken public implementation;
    
    WhitelistControllerAggregator public whitelistControllerAggregator;

    event NewWrappedToken(address indexed newToken);
    event NewImplementation(address indexed newImplementation);
    event NewController(address indexed newController);

    /**
     * 
     * Constructor of contract, which initializes shared ProxyAdmin, shared WhitelistAggregator and Controller.
     * Additionally creates implementation contract for future wrapped tokens.
     * 
     * @param proxyAdminOwner- The address of the account that will be set as owner of the deployed ProxyAdmin and will have the
     *      timelock admin role for the timelock contract
     */
    constructor(address proxyAdminOwner) {
        if(proxyAdminOwner == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        implementation = new WrappedBackedToken();

        proxyAdmin = new ProxyAdmin();
        
        WhitelistControllerAggregator whitelistControllerAggregatorImplementation = new WhitelistControllerAggregator();
        TransparentUpgradeableProxy proxyAggregator = new TransparentUpgradeableProxy(
            address(whitelistControllerAggregatorImplementation),
            address(proxyAdmin),
            abi.encodeWithSelector(
                WhitelistControllerAggregator.initialize.selector
            )
        );
        whitelistControllerAggregator = WhitelistControllerAggregator(address(proxyAggregator));

        WhitelistController whitelistControllerImplementation = new WhitelistController();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(whitelistControllerImplementation),
            address(proxyAdmin),
            abi.encodeWithSelector(
                WhitelistController.initialize.selector
            )
        );
        WhitelistController(address(proxy)).transferOwnership(proxyAdminOwner);
        whitelistControllerAggregator.add(address(proxy));

        proxyAdmin.transferOwnership(proxyAdminOwner);
        whitelistControllerAggregator.transferOwnership(proxyAdminOwner);
    }

    /**
     * @dev Deploys and configures new instance of Wrapped BackedFi Token. Callable only by the factory owner
     *
     * Emits a { NewWrappedToken } event
     * 
     * @param token         The token address that the newly created token will be wrapping
     * @param tokenOwner    The address of the account to which the owner role will be assigned
     */
    function deployWrappedToken(
        address token, address tokenOwner
    ) external onlyOwner returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(IERC20Metadata(token).name()));

        WrappedBackedTokenProxy proxy = new WrappedBackedTokenProxy{salt: salt}(
            address(implementation),
            address(proxyAdmin),
            abi.encodeWithSelector(
                WrappedBackedToken.initialize.selector,
                token
            )
        );

        WrappedBackedToken(address(proxy)).setWhitelistController(address(whitelistControllerAggregator));
        WrappedBackedToken(address(proxy)).transferOwnership(tokenOwner);

        emit NewWrappedToken(address(proxy));

        return address(proxy);
    }

    /**
     * @dev Update the implementation for future deployments
     *
     * Emits a { NewImplementation } event
     *
     * @param newImplementation - the address of the new implementation
     */
    function updateImplementation(
        address newImplementation
    ) external onlyOwner {
        if(newImplementation == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        implementation = WrappedBackedToken(newImplementation);

        emit NewImplementation(newImplementation);
    }

    /**
     * @dev Update the controller for future deployments
     *
     * Emits a { NewController } event
     *
     * @param newController - the address of the new controller
     */
    function updateController(
        address newController
    ) external onlyOwner {
        if(newController == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        whitelistControllerAggregator = WhitelistControllerAggregator(newController);

        emit NewController(newController);
    }
}