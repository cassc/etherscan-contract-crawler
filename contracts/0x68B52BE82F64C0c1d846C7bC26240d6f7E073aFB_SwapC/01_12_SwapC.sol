//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
pragma abicoder v2;

// import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

interface IWETH9 {
    function withdraw(uint256 wad) external;
}

contract SwapC is BaseRelayRecipient, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    address public signer;
    address public paymaster;
    mapping(address => uint256) walletToAmountWithdrawn;

    string public override versionRecipient = "2.2.5";

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // mainnet
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FORWARDER = 0xAa3E82b4c4093b4bA13Cb5714382C99ADBf750cA;

    // goerli
    // address public constant USDC = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C;
    // address public constant WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    // address public constant FORWARDER = 0x7A95fA73250dc53556d264522150A940d4C50238;

    // rinkeby
    // address public constant USDC = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
    // address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant FORWARDER = 0x83A54884bE4657706785D7309cf46B58FE5f6e8a;

    
    uint24 public poolFee = 3000;
    uint256 public paymasterFee = 33000;

    constructor(address _signer, address _paymaster) {
        signer = _signer;
        paymaster = _paymaster;
        _setTrustedForwarder(FORWARDER);
        IERC20(USDC).approve(address(swapRouter), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function updatePaymaster(address _paymaster) external onlyOwner {
        paymaster = _paymaster;
    }

    function updateForwarder(address _forwarder) external onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

    function updatePoolFee(uint24 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    function updatePaymasterFee(uint256 _paymasterFee) external onlyOwner {
        paymasterFee = _paymasterFee;
    }

    function collectEth(uint256 totalAmountUSDC, bytes calldata signature) public {
        address sender = _msgSender();

        require(totalAmountUSDC > walletToAmountWithdrawn[sender], "Already collected");

        string memory message = string(abi.encodePacked("swapc|", Strings.toHexString(uint256(uint160(sender)), 20), "|", totalAmountUSDC.toString()));
        bytes32 hashedMessage = keccak256(abi.encodePacked(message));
        address recoveredAddress = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage)).recover(signature);
        require(recoveredAddress == signer, "Unauthorized signature");

        uint256 usdcToConvert = totalAmountUSDC - walletToAmountWithdrawn[sender];
        walletToAmountWithdrawn[sender] = totalAmountUSDC;

        uint256 ethAmount = swapToEth(usdcToConvert);

        uint256 ethForPaymaster = ethAmount * paymasterFee / 100000;
        (bool ret, ) = paymaster.call{value: ethForPaymaster}("");
        require(ret);
        payable(sender).transfer(ethAmount - ethForPaymaster);
    }

    function swapToEth(
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDC,
            tokenOut: WETH9,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
        IWETH9(WETH9).withdraw(amountOut);
    }

    /**
     * @dev Accept direct ether transfers
     */
    receive() external payable {}

    function _msgData() internal override (Context, BaseRelayRecipient) virtual view returns (bytes calldata ret) {
        return BaseRelayRecipient._msgData();
    }

    function _msgSender() internal override (Context, BaseRelayRecipient) virtual view returns (address ret) {
        return BaseRelayRecipient._msgSender();
    }
}