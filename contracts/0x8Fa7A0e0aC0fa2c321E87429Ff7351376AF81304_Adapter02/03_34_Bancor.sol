// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";
import "./IBancor.sol";
import "./IContractRegistry.sol";

contract Bancor {
    using SafeMath for uint256;

    struct BancorData {
        IERC20[] path;
    }

    bytes32 public constant BANCOR_NETWORK = 0x42616e636f724e6574776f726b00000000000000000000000000000000000000;

    address public immutable affiliateAccount;
    uint256 public immutable affiliateCode;

    constructor(address _affiliateAccount, uint256 _affiliateCode) public {
        affiliateAccount = _affiliateAccount;
        affiliateCode = _affiliateCode;
    }

    function swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address registry,
        bytes calldata payload
    ) internal {
        BancorData memory data = abi.decode(payload, (BancorData));

        address bancorNetwork = IContractRegistry(registry).addressOf(BANCOR_NETWORK);

        _swapOnBancor(fromToken, toToken, fromAmount, 1, data.path, bancorNetwork);
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        IERC20[] memory path,
        address bancorNetwork
    ) private {
        Utils.approve(bancorNetwork, address(fromToken), fromAmount);

        if (address(fromToken) == Utils.ethAddress()) {
            IBancor(bancorNetwork).convert2{ value: fromAmount }(
                path,
                fromAmount,
                toAmount,
                affiliateAccount,
                affiliateCode
            );
        } else {
            IBancor(bancorNetwork).claimAndConvert2(path, fromAmount, toAmount, affiliateAccount, affiliateCode);
        }
    }
}