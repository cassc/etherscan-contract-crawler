// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/OFTCore.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/IOFT.sol";

interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

contract IndirectOFT is OFTCore {
    using SafeERC20 for IERC20Burnable;

    IERC20Burnable private immutable BETS;

    constructor(
        IERC20Burnable _BETS,
        address _lzEndpoint
    ) OFTCore(_lzEndpoint) {
        BETS = _BETS;
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return BETS.totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(BETS);
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override returns (uint) {
        require(_from == _msgSender(), "IndirectOFT: owner is not send caller");
        BETS.burnFrom(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        BETS.mint(_toAddress, _amount);
        return _amount;
    }
}