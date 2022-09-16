// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./DefxPair.sol";
import "./DefxStat.sol";

contract DefxFactory is IDefxFactory {
    using SafeMath for uint256;

    address public creator;

    address public statAddress;

    mapping(address => string) public encKeys;

    mapping(address => mapping(string => address)) public getPair;

    mapping(address => bool) public isPair;

    mapping(address => bool) public allowedCoins;

    event PairCreated(address cryptoAddress, string fiatAddress, address pair);

    address public WETH;
    address public DEFX_COIN;
    address public PANCAKE_ROUTER;

    constructor(
        address _weth,
        address _defx_coin,
        address _pancake_router
    ) {
        creator = msg.sender;
        WETH = _weth;
        DEFX_COIN = _defx_coin;
        PANCAKE_ROUTER = _pancake_router;

        // deploy DefxStat
        statAddress = address(new DefxStat());
    }

    function setAllowedCoin(address _coinAddress) public {
        require(msg.sender == creator, "Defx: FORBIDDEN");
        allowedCoins[_coinAddress] = true;
    }

    function setEncKey(string memory _key) external {
        encKeys[msg.sender] = _key;
    }

    function createPair(address cryptoAddress, string memory fiatCode) external returns (address pair) {
        require(getPair[cryptoAddress][fiatCode] == address(0), "Defx: PAIR_EXISTS"); // single check is sufficient
        require(allowedCoins[cryptoAddress], "Defx: FORBIDDEN");

        bytes memory bytecode = type(DefxPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(cryptoAddress, fiatCode));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDefxPair(pair).initialize(cryptoAddress, fiatCode);
        getPair[cryptoAddress][fiatCode] = pair;
        isPair[pair] = true;
        emit PairCreated(cryptoAddress, fiatCode, pair);

        // allow crypto to pay fees
        TransferHelper.safeApprove(cryptoAddress, PANCAKE_ROUTER, MAX_UINT);
    }

    function buyDefxSendRewards(address feeToken) external {
        uint256 balance = IERC20(feeToken).balanceOf(address(this));

        // pay rewards
        uint256 rewards = balance.mul(200).div(10000);
        TransferHelper.safeTransfer(feeToken, msg.sender, rewards);

        // buy $DeFX Token for the rest
        uint256 amountIn = balance.sub(rewards);

        address[] memory path;
        path = new address[](3);
        path[0] = feeToken;
        path[1] = WETH;
        path[2] = DEFX_COIN;

        IPancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
    }

    function burnFees() external {
        IDefxToken(DEFX_COIN).burnAll();
    }
}