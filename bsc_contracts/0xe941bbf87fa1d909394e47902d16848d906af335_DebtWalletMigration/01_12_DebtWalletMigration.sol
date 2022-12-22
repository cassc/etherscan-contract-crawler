// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DebtWalletMigration is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address[] private tokens;
    IERC20 public feeToken;
    uint256 public feeAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory tokens_,
        address feeToken_,
        uint256 feeAmount_
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        for (uint256 i = 0; i < tokens_.length; i++) {
            tokens.push(tokens_[i]);
        }
        feeToken = IERC20(feeToken_);
        feeAmount = feeAmount_;
    }

    function migrateAll(address oldAddress, address newAddress)
        external
        onlyOwner
        whenNotPaused
    {
        // fee to cover gas
        feeToken.transferFrom(oldAddress, owner(), feeAmount);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(oldAddress);
            if (balance == 0) {
                continue;
            }
            token.transferFrom(oldAddress, address(this), balance);
            token.transfer(newAddress, balance);
        }
    }

    function setTokens(address[] memory newTokens) external onlyOwner {
        delete tokens;
        for (uint256 i = 0; i < newTokens.length; i++) {
            tokens.push(newTokens[i]);
        }
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function addToken(address token) external onlyOwner {
        tokens.push(token);
    }

    function removeToken(address token) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                // to remove, move last token to this index and then pop the last one
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
            }
        }
    }

    function setFeeToken(address newFeeToken) external onlyOwner {
        feeToken = IERC20(newFeeToken);
    }

    function setFeeAmount(uint256 newFeeAmount) external onlyOwner {
        feeAmount = newFeeAmount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}