/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ManageableUpgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function circulatingSupply() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burnFrom(address to, uint256 amount) external;
}

contract BridgeV2 is Initializable, OwnableUpgradeable, ManageableUpgradeable {
    IERC20Mintable public TOKEN;
    IUniswapV2Router02 public ROUTER;
    uint256 public PRECISION;
    uint256 public TX_TIMEOUT;

    mapping(string => bool) public processed;
    mapping(uint256 => bool) public supportedChains;

    uint256 public nBridge;

    uint256 public fee;
    uint256 public minGasWithSwap;
    uint256 public minGas;

    address payable OPERATOR;

    event Request(
        string indexed filterId,
        string id,
        address indexed user,
        uint256 amount,
        uint256 timeout,
        uint256 nativePercentage
    );

    event Processed(
        string indexed filterId,
        string id,
        address indexed user,
        uint256 amount,
        uint256 nativeReceived
    );

    function initialize(
        address token,
        address router,
        uint256 precision,
        uint256 tx_timeout,
        uint256[] memory suppChains,
        uint256 fee_,
        uint256 minGas_,
        uint256 minGasWithSwap_
    ) public initializer {
        __Ownable_init();
        TOKEN = IERC20Mintable(token);
        ROUTER = IUniswapV2Router02(router);
        PRECISION = precision;
        TX_TIMEOUT = tx_timeout;

        fee = fee_;
        minGas = minGas_;
        minGasWithSwap = minGasWithSwap_;

        for (uint8 i = 0; i < suppChains.length; i++) {
            supportedChains[suppChains[i]] = true;
        }

        nBridge = 0;

        TOKEN.approve(address(this), type(uint256).max);
        TOKEN.approve(address(ROUTER), type(uint256).max);
    }

    function getCurrentChainId() public view returns (uint256) {
        uint256 srcChainId;
        assembly {
            srcChainId := chainid()
        }
        return srcChainId;
    }

    function request(
        uint256 amount,
        uint256 nativePercentage,
        uint256 destChainID
    ) public payable {
        require(
            msg.value >= (nativePercentage == 0 ? minGas : minGasWithSwap),
            "BRIDGE: Not enough gas provided."
        );

        (bool sent, ) = OPERATOR.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        uint256 srcChainID = getCurrentChainId();
        require(supportedChains[srcChainID], "BRIDGE: Invalid source chain");
        require(
            supportedChains[srcChainID],
            "BRIDGE: Invalid destination chain"
        );
        require(
            destChainID != srcChainID,
            "BRIDGE: Destination chain must be different from source chain"
        );
        TOKEN.burnFrom(msg.sender, amount);
        nBridge++;
        string memory id = string.concat(
            Strings.toString(srcChainID),
            "-",
            Strings.toString(destChainID),
            "-",
            Strings.toString(nBridge)
        );
        amount -= (amount * fee) / PRECISION;
        emit Request(
            id,
            id,
            msg.sender,
            amount,
            block.timestamp + TX_TIMEOUT,
            nativePercentage
        );
    }

    function processBridge(
        string memory id,
        address user,
        uint256 amount,
        uint256 timeout,
        uint256 nativePercentage
    ) public onlyManager {
        require(!processed[id], "PROC: Already processed.");
        require(timeout >= block.timestamp, "PROC: Timeout.");
        processed[id] = true;
        uint256 amountToSwap = (amount * nativePercentage) / PRECISION;

        uint256 nativeReceived = 0;

        if (amountToSwap > 0) {
            TOKEN.mint(address(this), amountToSwap);

            address[] memory path = new address[](2);
            path[0] = address(TOKEN);
            path[1] = ROUTER.WETH();

            nativeReceived = ROUTER.getAmountsOut(amountToSwap, path)[1];

            ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                user,
                block.timestamp
            );
        }

        TOKEN.mint(user, amount - amountToSwap);

        emit Processed(id, id, user, amount, nativeReceived);
    }

    function updateToken(address value) public onlyOwner {
        TOKEN = IERC20Mintable(value);
    }

    function updateRouter(address value) public onlyOwner {
        ROUTER = IUniswapV2Router02(value);
    }

    function updatePrecision(uint256 value) public onlyOwner {
        PRECISION = value;
    }

    function updateTxTimeout(uint256 value) public onlyOwner {
        TX_TIMEOUT = value;
    }

    function updateFee(uint256 value) public onlyOwner {
        fee = value;
    }

    function updateMinGas(uint256 value) public onlyOwner {
        minGas = value;
    }

    function updateMinGasWithSwap(uint256 value) public onlyOwner {
        minGasWithSwap = value;
    }

    function executeApprovals() public onlyOwner {
        TOKEN.approve(address(this), type(uint256).max);
        TOKEN.approve(address(ROUTER), type(uint256).max);
    }

    function withdrawEth() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function updateOperator(address payable value) public onlyOwner {
        OPERATOR = value;
    }

    function updateSupportedChain(
        uint256 chainId,
        bool value
    ) public onlyOwner {
        supportedChains[chainId] = value;
    }
}