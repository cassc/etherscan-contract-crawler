// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "@ankr.com/contracts/earn/CertificateToken.sol";
import "@ankr.com/contracts/interfaces/IEarnConfig.sol";

import "../interfaces/ICertToken.sol";

contract aBNBc is CertificateToken, ICertToken {
    bool airdroped;

    modifier airDrop() {
        require(!airdroped, "CertificateToken: snapshot already airdroped");
        _;
    }

    function initialize(IEarnConfig earnConfig, uint256 initSupply)
        external
        initializer
    {
        __Ownable_init();
        __ERC20_init("Ankr Reward Bearing BNB", "ankrBNB");
        __CertificateToken_init(earnConfig);
        _mint(address(this), initSupply);
        airdroped = false;
    }

    function balanceWithRewardsOf(address account)
        public
        view
        override
        returns (uint256)
    {
        uint256 shares = this.balanceOf(account);
        return sharesToBonds(shares);
    }

    function distributeSnapshot(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external airDrop onlyGovernance {
        require(
            receivers.length == amounts.length,
            "wrong length of input arrays"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _transfer(address(this), receivers[i], amounts[i]);
        }
    }

    function finalizeAirdrop() external airDrop onlyGovernance {
        airdroped = true;
        emit AirDropFinished();
    }
}