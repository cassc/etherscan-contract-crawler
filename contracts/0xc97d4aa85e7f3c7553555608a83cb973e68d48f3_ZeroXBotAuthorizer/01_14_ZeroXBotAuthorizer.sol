// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "DEXBaseACL.sol";
import "ACLUtils.sol";

contract ZeroXBotAuthorizer is DEXBaseACL {
    bytes32 public constant NAME = "ZeroXBotAuthorizer";
    uint256 public constant VERSION = 1;

    address public immutable ROUTER;
    address public immutable WTOKEN = getWrappedTokenAddress();

    constructor(address _owner, address _caller) DEXBaseACL(_owner, _caller) {
        address router;
        if (block.chainid == 10) {
            // Optimism
            router = 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10;
        } else {
            router = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
        }
        // Immutable variables cannot be initialized inside an if statement.
        ROUTER = router;
    }

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = ROUTER;
    }

    // TransformERC20Feature https://etherscan.io/address/0x44A6999Ec971cfCA458AFf25A808F272f6d492A2#code
    // https://openchain.xyz/trace/ethereum/0x84465f777bbc77e00e21633705e4b0d1ae234f53ffdbd57a4d997177e3fda7e1

    struct Transformation {
        uint32 deploymentNonce;
        bytes data;
    }

    function transformERC20(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    ) external view {
        _swapInOutTokenCheck(inputToken, outputToken);
    }

    // UniswapFeature https://etherscan.io/address/0xf9b30557AfcF76eA82C04015D80057Fa2147Dfa9#code
    // https://openchain.xyz/trace/ethereum/0x0786b1f01fe9d7c26dd7e24302128643ded36ee5911c90e99dcb7745fad5a7c8
    function sellToUniswap(
        address[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    ) external view {
        _swapInOutTokenCheck(tokens[0], tokens[tokens.length - 1]);
    }

    // UniswapV3Feature https://etherscan.io/address/0x0e992C001E375785846EEb9cd69411B53f30f24B#code

    function _checkZxRecipient(address recipient) internal pure {
        // 0x00..00 for msg.sender
        require(recipient == address(0) || recipient == _txn().from, "Invalid recipient");
    }

    /// @dev Minimum size of an encoded swap path:
    ///      sizeof(address(inputToken) | uint24(fee) | address(outputToken))
    uint256 private constant SINGLE_HOP_PATH_SIZE = 20 + 3 + 20;
    /// @dev How many bytes to skip ahead in an encoded path to start at the next hop:
    ///      sizeof(address(inputToken) | uint24(fee))
    uint256 private constant PATH_SKIP_HOP_SIZE = 20 + 3;

    function _decodePath(bytes memory encodedPath) internal pure returns (address inputToken, address outputToken) {
        uint256 size = encodedPath.length;
        require(size >= SINGLE_HOP_PATH_SIZE && (size - 20) % PATH_SKIP_HOP_SIZE == 0, "Invalid encodedPath");

        assembly {
            let p := add(encodedPath, 32)
            inputToken := shr(96, mload(p))
            p := add(p, sub(size, 20))
            outputToken := shr(96, mload(p))
        }
    }

    // https://openchain.xyz/trace/ethereum/0xf07699d9512402fbc680b1457ca4608bd34f763bf555c887131d9745a645a2ee

    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) external view {
        _checkZxRecipient(recipient);
        (address inputToken, address outputToken) = _decodePath(encodedPath);
        _swapInOutTokenCheck(inputToken, outputToken);
    }

    // https://openchain.xyz/trace/ethereum/0xcbbee04f54a9a681bed88a79c8e881efa63aa0b6ea0a10823bc22572d4fe10c4
    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    ) external view {
        _checkZxRecipient(recipient);
        (address inputToken, address outputToken) = _decodePath(encodedPath);
        require(inputToken == WTOKEN, "InToken not WToken");
        _swapInOutTokenCheck(ETH_ADDRESS, outputToken);
    }

    // https://openchain.xyz/trace/ethereum/0xb1d932e24d27ce5f6d48d1900226138248444df9dba23f9a7323055ee5892773
    function sellTokenForEthToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payable recipient
    ) external view {
        _checkZxRecipient(recipient);
        (address inputToken, address outputToken) = _decodePath(encodedPath);
        require(outputToken == WTOKEN, "InToken not WToken");
        _swapInOutTokenCheck(inputToken, ETH_ADDRESS);
    }

    // PancakeSwapFeature https://bscscan.com/address/0xCE93A169c1D3B98D1d02987435c1a35215086E7c#code
    // https://openchain.xyz/trace/binance/0xdba0367ca64c2f1c3446643a5d1a64759814ee2d353fd2c6781af4fb5195c713

    function sellToPancakeSwap(
        address[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        uint8 fork
    ) external view {
        _swapInOutTokenCheck(tokens[0], tokens[tokens.length - 1]);
    }
}