//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface IWETH is IERC20 {
    function withdraw(uint wad) external;
}

import "./Vault.sol";

contract EthVault is Vault {
    using SafeMath for uint256;
    using SafeERC20 for IWETH;

    constructor(IERC20Detailed underlying_, IERC20 reward_, address harvester_, string memory name_, string memory symbol_)
        Vault(underlying_, reward_, harvester_, name_, symbol_) {}


    receive() external payable {
        require(msg.sender == address(target));
    }

    function withdrawDividendETH(address user) internal {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            IWETH(address(target)).withdraw(_withdrawableDividend);
            payable(user).transfer(_withdrawableDividend);
        }
    }

    function claimETH() public {
        withdrawDividendETH(msg.sender);
    }
}