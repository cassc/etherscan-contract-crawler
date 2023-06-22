//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/oft/extension/ProxyOFT.sol";

contract NpmBridgeProxy is ProxyOFT {
    using SafeERC20 for IERC20;

    constructor(address _lzEndpoint, address _token, address _contractOwner) ProxyOFT(_lzEndpoint, _token) {
        super.transferOwnership(_contractOwner);
    }

    function recoverEther(address sendTo) external onlyOwner {
        (bool success, ) = payable(sendTo).call{value: address(this).balance}("");
        require(success, "Recipient may have reverted");
    }

    function recoverToken(IERC20 malicious, address sendTo) external onlyOwner {
        malicious.safeTransfer(sendTo, malicious.balanceOf(address(this)));
    }
}