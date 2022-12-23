// SPDX-License-Identifer: MIT

/// @notice executor contract to burn Norcal Editiosn and mint new editions
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC1155.sol";


interface ExchangeContract {
    function mintExternal(address to, uint256 tokenId) external returns (bool);
}

interface BurnContract is IERC1155 {
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) external;
}

contract BurnAndExchange is Ownable, ReentrancyGuard {

    ExchangeContract public exchangeContract;
    BurnContract public burnContract;
    BurnContract public ratContract;

    constructor(address exchangeAddress, address burnAddress, address ratAddress) Ownable() ReentrancyGuard() {
        exchangeContract = ExchangeContract(exchangeAddress);
        burnContract = BurnContract(burnAddress);
        ratContract = BurnContract(ratAddress);
    }

    /// @notice function to burn set 1
    /// @dev tokens 1 - 3
    function burnAndExchangeSetOne() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](3);
        uint256[] memory tokens = new uint256[](3);
        uint256[] memory burnAmounts = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 1;
            burnAmounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        require(
            balances[0] >= 1 &&
            balances[1] >= 1 &&
            balances[2] >= 1, 
            "msg.sender does not own enough supply of set 1"
        );

        burnContract.burn(msg.sender, tokens, burnAmounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 1);

        require(tf, "mint external failed");
    }

    /// @notice function to burn set 2
    /// @dev tokens 4-6
    function burnAndExchangeSetTwo() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](3);
        uint256[] memory tokens = new uint256[](3);
        uint256[] memory burnAmounts = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 4;
            burnAmounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        require(
            balances[0] >= 1 &&
            balances[1] >= 1 &&
            balances[2] >= 1, 
            "msg.sender does not own enough supply of set 2"
        );

        burnContract.burn(msg.sender, tokens, burnAmounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 1);

        require(tf, "mint external failed");
    }

    /// @notice function to burn set 3
    /// @dev tokens 7-9
    function burnAndExchangeSetThree() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](3);
        uint256[] memory tokens = new uint256[](3);
        uint256[] memory burnAmounts = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 7;
            burnAmounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        require(
            balances[0] >= 1 &&
            balances[1] >= 1 &&
            balances[2] >= 1, 
            "msg.sender does not own enough supply of set 3"
        );

        burnContract.burn(msg.sender, tokens, burnAmounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 1);

        require(tf, "mint external failed");
    }

    /// @notice function to burn set 4
    /// @dev tokens 10-12
    function burnAndExchangeSetFour() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](3);
        uint256[] memory tokens = new uint256[](3);
        uint256[] memory burnAmounts = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 10;
            burnAmounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        require(
            balances[0] >= 1 &&
            balances[1] >= 1 &&
            balances[2] >= 1, 
            "msg.sender does not own enough supply of set 4"
        );

        burnContract.burn(msg.sender, tokens, burnAmounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 1);

        require(tf, "mint external failed");
    }

    /// @notice function to burn set 5
    /// @dev tokens 13-15
    function burnAndExchangeSetFive() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](3);
        uint256[] memory tokens = new uint256[](3);
        uint256[] memory burnAmounts = new uint256[](3);
        for (uint256 i; i < 3; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 13;
            burnAmounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        require(
            balances[0] >= 1 &&
            balances[1] >= 1 &&
            balances[2] >= 1, 
            "msg.sender does not own enough supply of set 5"
        );

        burnContract.burn(msg.sender, tokens, burnAmounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 1);

        require(tf, "mint external failed");
    }

    /// @notice function to burn all sets and get a token for it
    /// @dev tokens 1 - 15
    function burnAndExchangeAll() external nonReentrant {
        require(burnContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        address[] memory sender = new address[](15);
        uint256[] memory tokens = new uint256[](15);
        uint256[] memory amounts = new uint256[](15);
        for (uint256 i; i < 15; i++) {
            sender[i] = msg.sender;
            tokens[i] = i + 1;
            amounts[i] = 1;
        }
        uint256[] memory balances = burnContract.balanceOfBatch(sender, tokens);
        bool hasEnoughSupply = true;
        for (uint256 i; i < 15; i++) {
            hasEnoughSupply = hasEnoughSupply && balances[i] > 0;
        }
        require(hasEnoughSupply, "msg.sender does not own enough supply of all sets");

        burnContract.burn(msg.sender, tokens, amounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 2);

        require(tf, "mint external failed");
    }

    /// @notice function to burn 3 rats and get a token for it
    function burnAndExchangeRats() external nonReentrant {
        require(ratContract.isApprovedForAll(msg.sender, address(this)), "contract is not approved for all tokens");
        require(ratContract.balanceOf(msg.sender, 1) >= 3, "msg.sender does not own enough supply");

        uint256[] memory tokens = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = 1;
        amounts[0] = 3;

        ratContract.burn(msg.sender, tokens, amounts);

        bool tf = exchangeContract.mintExternal(msg.sender, 3);

        require(tf, "mint external failed");
    }
}