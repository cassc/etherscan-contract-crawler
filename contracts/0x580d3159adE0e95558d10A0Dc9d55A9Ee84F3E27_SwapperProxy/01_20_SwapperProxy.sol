// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./SwapperStorage.sol";
import "./proxy/BaseProxy.sol";

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract SwapperProxy is
    SwapperStorage,
    BaseProxy,
    ERC165Storage
{
    constructor() {
        bytes4 OnApproveSelector= bytes4(keccak256("onApprove(address,address,uint256,bytes)"));

        _registerInterface(OnApproveSelector);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function initialize(
        address _wton,
        address _ton,
        address _tos,
        address _uniswapRouter,
        address _weth
    )
        external onlyOwner
    {
        wton = _wton;
        ton = _ton;
        tos = _tos;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        _WETH = IWETH(_weth);
    }

}