// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./StandardToken.sol";

contract KToken is StandardToken {
    address private underlying_;

    constructor(string memory name, string memory symbol, uint8 decimals, address _underlying) StandardToken(name, symbol, decimals) {
        underlying_ = _underlying;
    }

    /// @return The address of the underlying token.
    function underlying() public view returns (address) {
        return underlying_;
    }
}

contract kEther is KToken {
    constructor() KToken("kEther", "kETH", 18, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {}
}

contract kWrappedEther is KToken {
    constructor(address _underlying) KToken("kWrappedEther", "kwETH", 18, _underlying) {}
}

contract kUSDC is KToken {
    constructor(address _underlying) KToken("kUSDCoin", "kUSDC", 6, _underlying) {}
}

contract kWBTC is KToken {
    constructor(address _underlying) KToken("kWrappedBitcoin", "kWBTC", 8, _underlying) {}
}

contract kBTC is KToken {
    constructor(address _underlying) KToken("kBitcoin", "kBTC", 8, _underlying) {}
}

contract kDAI is KToken {
    constructor(address _underlying) KToken("kDAI", "kDAI", 18, _underlying) {}
}