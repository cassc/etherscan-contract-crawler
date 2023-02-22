// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "SafeERC20.sol";
import {ERC4626Upgradeable} from "ERC4626Upgradeable.sol";
import {IERC20} from "IERC20.sol";
import {IERC20MetadataUpgradeable} from "IERC20MetadataUpgradeable.sol";
import {OwnableUpgradeable} from "OwnableUpgradeable.sol";
import {Initializable} from "Initializable.sol";
import {UUPSUpgradeable} from "UUPSUpgradeable.sol";

enum Status {
    Mint,
    Redeem,
    Recover
}

contract PortfolioDebtToken is Initializable, ERC4626Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    event Recovered(IERC20 token, uint256 balance);

    uint256 public mintDeadline;
    uint256 public redeemDeadline;

    function initialize(
        IERC20MetadataUpgradeable _asset,
        string memory _name,
        string memory _symbol,
        uint256 _mintDeadline,
        uint256 _redeemDeadline
    ) external initializer {
        __ERC4626_init_unchained(_asset);
        __ERC20_init_unchained(_name, _symbol);
        __Ownable_init_unchained();

        require(block.timestamp < _mintDeadline, "PDT: current time must be before mint deadline");
        require(_mintDeadline < _redeemDeadline, "PDT: mint deadline must be before redeem deadline");
        mintDeadline = _mintDeadline;
        redeemDeadline = _redeemDeadline;
    }

    function status() public view returns (Status) {
        assert(mintDeadline < redeemDeadline);
        if (block.timestamp < mintDeadline) {
            return Status.Mint;
        } else if (block.timestamp < redeemDeadline) {
            return Status.Redeem;
        } else {
            return Status.Recover;
        }
    }

    function mintShares(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
        require(status() == Status.Mint, "PDT: share minting only allowed during Status.Mint");
        require(addresses.length == amounts.length, "PDT: addresses and amounts lengths differ");
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

    function maxDeposit(address) public pure virtual override returns (uint256) {
        return 0;
    }

    function maxMint(address) public pure virtual override returns (uint256) {
        return 0;
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        if (status() != Status.Redeem) {
            return 0;
        }
        return super.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        if (status() != Status.Redeem) {
            return 0;
        }
        return super.maxRedeem(owner);
    }

    function recover(IERC20 token, address receiver) external onlyOwner {
        require(status() == Status.Recover, "PDT: token recovery only allowed during Status.Recover");
        uint256 totalAssetsBefore = totalAssets();

        uint256 balance = token.balanceOf(address(this));
        emit Recovered(token, balance);
        token.safeTransfer(receiver, balance);

        if (address(token) != asset()) {
            // A PDT refactor may make it possible to change `asset`'s ERC20
            // allowance, which could let a reentrant non-asset `token` transfer `asset`s
            // *from* PDT.
            //
            // For simplicity, we also disallow reentrant `asset` transfers *to* PDT.
            assert(totalAssets() == totalAssetsBefore);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {
        revert("PDT: Ether transfers disallowed");
    }

    fallback() external payable {
        revert("PDT: Calling fallback method disallowed");
    }

    function _transfer(address, address, uint256) internal virtual override {
        revert("PDT: Transfers disallowed");
    }
}