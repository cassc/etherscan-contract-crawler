//SPDX-License-Identifier: MIT
pragma solidity = 0.8.4;
pragma experimental ABIEncoderV2;

import "./AAAService.sol";

/**
    Arbitrage As A Service Contract (AEX)
*/

contract IFlashBorrower {
    address internal constant TOKEN_ETH   = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant TOKEN_WETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant TOKEN_DAI   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant TOKEN_USDC  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address internal constant PROXY_DYDX  = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant ORACLE_USDC = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address internal constant ORACLE_DAI  = 0x773616E4d11A78F511299002da57A0a94577F1f4;

    uint256 internal constant FLAG_FLASH_DYDY_WETH     = 0x1;
    uint256 internal constant FLAG_FLASH_DYDY_USDC     = 0x2;
    uint256 internal constant FLAG_FLASH_DYDY_DAI      = 0x4;
    uint256 internal constant FLAG_EXIT_WETH           = 0x8;

    uint256 internal constant FLAG_WETH_ACCOUNTING     = 0x10;
    uint256 internal constant FLAG_USDC_ACCOUNTING     = 0x20;
    uint256 internal constant FLAG_DAI_ACCOUNTING      = 0x40;

    uint256 internal constant FLAG_RETURN_WETH         = 0x1000;
    uint256 internal constant FLAG_RETURN_USDC         = 0x2000;
    uint256 internal constant FLAG_RETURN_DAI          = 0x4000;
    uint256 internal constant FLAG_RETURN_CUSTOM       = 0x8000;
    uint256 internal constant FLAG_RETURN_CUSTOM_SHIFT = 0x100000000000000000000;

    uint256 internal constant WRAP_FLAG_TRANSFORM_ETH_TO_WETH_AFTER_ARB = 0x1;
    uint256 internal constant WRAP_FLAG_TRANSFORM_WETH_TO_ETH_AFTER_ARB = 0x2;
    uint256 internal constant WRAP_FLAG_PAY_COINBASE                    = 0x4;
    uint256 internal constant WRAP_FLAG_PAY_COINBASE_BIT_SHIFT          = 0x100000000000000000000000000000000;
}

// Do not send funds to this contract, use your own artbitage service contract to control your funds and this contract 
// This contract is completely permission-less and allows anyone to execute arbitrary logic with an API key
// Overall goal is to make a contract which allows to execute all types of nested flash loans opportunites
// This code is provided for informational purposes only and should not be considered as financial advice. Use it at your own risk.

// Third version of AAAS which is better gas optimised and performs internal call during flash-loan callbacks
contract AAAS is IFlashBorrower, AAAService {
    string public constant name = "Arbitrage As A Service Contract";
    //check calls against unique API key from UUID
    string private constant UUID = "ab084d3f-657a-4b9a-a90c-53b5e64c180c";
    mapping(address => uint256) public marketIdByToken;

    constructor() {
       marketIdByToken[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 0; //WETH
       marketIdByToken[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 2; //USDC
       marketIdByToken[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 3; //DAI
    }

    function arbCallback(
    address,
    uint256 wethToReturn,
    uint256 daiToReturn,
    uint256 usdcToReturn,
    bytes calldata data
    ) external payable emitAAAS {

    uint256 selfBalance = address(this).balance;
    if (selfBalance > 1) {
        msg.sender.call{value:(selfBalance == msg.value ? selfBalance : selfBalance - 1)}(new bytes(0));
    }

    if (wethToReturn > 0) {
        uint256 tokenBalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
        if (tokenBalance > 1) {
            IERC20Token(TOKEN_WETH).transfer(
                msg.sender,
                tokenBalance == wethToReturn ? tokenBalance : tokenBalance - 1
            );
        }
    }

    if (daiToReturn > 0) {
        uint256 tokenBalance = IERC20Token(TOKEN_DAI).balanceOf(address(this));
        if (tokenBalance > 1) {
            IERC20Token(TOKEN_DAI).transfer(
                msg.sender,
                tokenBalance == daiToReturn ? tokenBalance : tokenBalance - 1
            );
        }
    }

    if (usdcToReturn > 0) {
        uint256 tokenBalance = IERC20Token(TOKEN_USDC).balanceOf(address(this));
        if (tokenBalance > 1) {
            IERC20Token(TOKEN_USDC).transfer(
                msg.sender,
                tokenBalance == usdcToReturn ? tokenBalance : tokenBalance - 1
            );
        }
    }
    }

    function callFunction(
        address,
        Types.AccountInfo memory,
        bytes calldata data
    ) external emitAAAS {
    }
    function executeOperation(
        address,
        uint256,
        uint256,
        bytes calldata _params
    ) external emitAAAS {

    }
    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata,
        address,
        bytes calldata params
    ) external emitAAAS returns  (bool)
    {
        return true;
    }

    function uniswapV2Call(
        address,
        uint,
        uint,
        bytes calldata data
    ) external emitAAAS {

    }
    function uniswapV3FlashCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external emitAAAS {

    }
    function uniswapV3MintCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external emitAAAS {

    }
    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external emitAAAS {

    }

    // Function signature 0x00000000  is maintained and gas optimizations are preserved.
    function wfjizxua(
        uint256 actionFlags,
        uint256[] calldata actionData
    ) public payable emitAAAS returns (int256 ethProfitDelta) {
        int256[4] memory balanceDeltas;
        balanceDeltas[0] = int256(address(this).balance - msg.value);
        if ((actionFlags & (FLAG_WETH_ACCOUNTING | FLAG_USDC_ACCOUNTING | FLAG_DAI_ACCOUNTING)) > 0) {
            // In general ACCOUNTING flags should be used only during simulation and not production to avoid wasting gas on oracle calls
            if ((actionFlags & FLAG_WETH_ACCOUNTING) > 0) {
                balanceDeltas[1] = int256(IERC20Token(TOKEN_WETH).balanceOf(address(this)));
            }
            if ((actionFlags & FLAG_USDC_ACCOUNTING) > 0) {
                balanceDeltas[2] = int256(IERC20Token(TOKEN_USDC).balanceOf(address(this)));
            }
            if ((actionFlags & FLAG_DAI_ACCOUNTING) > 0) {
                balanceDeltas[3] = int256(IERC20Token(TOKEN_DAI).balanceOf(address(this)));
            }
        }

        if ((actionFlags & (FLAG_FLASH_DYDY_WETH | FLAG_FLASH_DYDY_USDC | FLAG_FLASH_DYDY_DAI)) > 0) {
            // This simple logic only supports single token flashloans
            // For multiple tokens or multiple providers you should use general purpose logic using 'AAAS' function
            if ((actionFlags & FLAG_FLASH_DYDY_WETH) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_WETH).balanceOf(PROXY_DYDX);
                wrapWithDyDx(
                    TOKEN_WETH,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_WETH).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_USDC) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_USDC).balanceOf(PROXY_DYDX);
                wrapWithDyDx(
                    TOKEN_USDC,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_USDC).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            } else if ((actionFlags & FLAG_FLASH_DYDY_DAI) > 0) {
                uint256 balanceToFlash = IERC20Token(TOKEN_DAI).balanceOf(PROXY_DYDX);
                wrapWithDyDx(
                    TOKEN_DAI,
                    balanceToFlash - 1,
                    IERC20Token(TOKEN_DAI).allowance(address(this), PROXY_DYDX) < balanceToFlash,
                    abi.encode(actionData)
                );
            }
        } else {
           
        }

        if ((actionFlags & FLAG_EXIT_WETH) > 0) {
            uint wethbalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
            if (wethbalance > 1) WETH9(TOKEN_WETH).withdraw(wethbalance - 1);
        }

        ethProfitDelta = int256(address(this).balance) - balanceDeltas[0];
        if ((actionFlags & (FLAG_WETH_ACCOUNTING | FLAG_USDC_ACCOUNTING | FLAG_DAI_ACCOUNTING)) > 0) {
            // In general ACCOUNTING flags should be used only during simulation and not production to avoid wasting gas on oracle calls
            if ((actionFlags & FLAG_WETH_ACCOUNTING) > 0) {
                ethProfitDelta += int256(IERC20Token(TOKEN_WETH).balanceOf(address(this))) - balanceDeltas[1];
            }
            if ((actionFlags & FLAG_USDC_ACCOUNTING) > 0) {
                ethProfitDelta += (int256(IERC20Token(TOKEN_USDC).balanceOf(address(this))) - balanceDeltas[2]) * IChainlinkAggregator(ORACLE_USDC).latestAnswer() / (1 ether);
            }
            if ((actionFlags & FLAG_DAI_ACCOUNTING) > 0) {
                ethProfitDelta += (int256(IERC20Token(TOKEN_DAI).balanceOf(address(this))) - balanceDeltas[3]) * IChainlinkAggregator(ORACLE_DAI).latestAnswer() / (1 ether);
            }
        }


        uint selfBalance = address(this).balance;
        if (selfBalance > 1 && msg.sender != address(this)) {
            msg.sender.call{value:selfBalance - 1}(new bytes(0));
        }
        if ((actionFlags & (FLAG_RETURN_WETH | FLAG_RETURN_USDC | FLAG_RETURN_DAI | FLAG_RETURN_CUSTOM)) > 0 && msg.sender != address(this)) {
            // Majority of simple atomic arbs should just need ETH
            if ((actionFlags & FLAG_RETURN_WETH) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_WETH).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_WETH).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_USDC) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_USDC).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_USDC).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_DAI) > 0) {
                uint tokenBalance = IERC20Token(TOKEN_DAI).balanceOf(address(this));
                if (tokenBalance > 1) IERC20Token(TOKEN_DAI).transfer(msg.sender, tokenBalance - 1);
            }
            if ((actionFlags & FLAG_RETURN_CUSTOM) > 0) {
                address tokenAddr = address(uint160(actionFlags / FLAG_RETURN_CUSTOM_SHIFT));
                if (tokenAddr != TOKEN_ETH) {
                    // We've already returned ETH above
                    uint tokenBalance = IERC20Token(tokenAddr).balanceOf(address(this));
                    if (tokenBalance > 1) IERC20Token(tokenAddr).transfer(msg.sender, tokenBalance - 1);
                }
            }
        }
    }

    // Executing DyDx flash-loans with generalised logic above is quite inefficient, this helper function attempts to decrease gas cost a bit
    function wrapWithDyDx(address requiredToken, uint256 requiredBalance, bool requiredApprove, bytes memory data) public emitAAAS {
        Types.ActionArgs[] memory operations = new Types.ActionArgs[](3);
        operations[0] = Types.ActionArgs({
            actionType: Types.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredBalance
            }),
            primaryMarketId: marketIdFromTokenAddress(requiredToken),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        operations[1] = Types.ActionArgs({
            actionType: Types.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: data
        });
        operations[2] = Types.ActionArgs({
            actionType: Types.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: requiredBalance + (requiredToken == TOKEN_WETH ? 1 : 2)
            }),
            primaryMarketId: marketIdFromTokenAddress(requiredToken),
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Types.AccountInfo[] memory accountInfos = new Types.AccountInfo[](1);
        accountInfos[0] = Types.AccountInfo({
            owner: address(this),
            number: 1
        });
        if (requiredApprove) {
          // Approval might be already set or can be set inside of callback function
          IERC20Token(requiredToken).approve(
            PROXY_DYDX,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
          );
        }
        ISoloMargin(PROXY_DYDX).operate(accountInfos, operations);
    }
    function marketIdFromTokenAddress(address tokenAddress) internal view returns (uint256) {
    return marketIdByToken[tokenAddress];
}
    function flashLoan() external emitAAAS {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

receive() external payable {}
}


interface ISoloMargin {
    function operate(Types.AccountInfo[] memory accounts, Types.ActionArgs[] memory actions) external;
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
}
interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}
interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IGasToken {
    function free(uint256 value) external returns (uint256);
}
interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}

library Types {
    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}