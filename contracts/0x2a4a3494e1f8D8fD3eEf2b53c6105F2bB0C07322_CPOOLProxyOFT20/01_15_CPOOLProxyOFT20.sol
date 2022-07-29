// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OFTCore.sol";
import "../interfaces/ICPOOL.sol";
import "./CPOOLCore.sol";

contract CPOOLProxyOFT20 is OFTCore {
    using SafeERC20 for ICPOOL;
    ICPOOL public immutable token;

    constructor(address _proxyToken, address _layerZeroEndpoint)
        OFTCore(_layerZeroEndpoint)
    {
        token = ICPOOL(_proxyToken);
    }

    function circulatingSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            return token.totalSupply() - token.balanceOf(address(this));
        }
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override {
        require(
            _from == _msgSender(),
            "CPOOLProxyOFT20: owner is not send caller"
        );
        token.safeTransferFrom(_from, address(this), _amount);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override {
        token.safeTransfer(_toAddress, _amount);
    }
}