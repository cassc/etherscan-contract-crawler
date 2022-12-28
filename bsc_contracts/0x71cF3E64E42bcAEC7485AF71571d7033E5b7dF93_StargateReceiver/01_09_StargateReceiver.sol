// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../helpers/Ownable.sol";

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId, // the remote chainId sending the tokens
        bytes memory _srcAddress, // the remote Bridge address
        uint256 _nonce,
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

contract StargateReceiver is
    Ownable,
    Pausable,
    ReentrancyGuard,
    IStargateReceiver
{
    using SafeERC20 for IERC20;
    address public stargateRouter;
    address public NATIVE_TOKEN_ADDRESS;
    uint256 public defaultGas;
    mapping(address => bool) public blockList;

    event UpdateStargateRouterAddress(address indexed stargateRouterAddress);
    event PayloadExecuted(
        address indexed toAddress,
        uint256 amount,
        address token
    );
    event AddressBlocked(address indexed blockedAddress);
    event AddressUnblocked(address indexed unblockedAddress);
    error StargateRouterOnly();
    error AddressBlockedError();
    error PayloadExectionFailed();


    constructor(
        address _stargateRouter,
        address _nativeTokenAddress,
        address _owner,
        uint256 _defaultGas
    ) Ownable(_owner) {
        stargateRouter = _stargateRouter;
        NATIVE_TOKEN_ADDRESS = _nativeTokenAddress;
        defaultGas = _defaultGas;
    }

    modifier onlyStargateRouter() {
        if(msg.sender != stargateRouter) revert StargateRouterOnly();
        _;
    }

    modifier notBlocked(address _address) {
        if(blockList[_address]) revert AddressBlockedError();
        _;
    }

    function blockAddress(address _address) external onlyOwner {
        blockList[_address] = true;
        emit AddressBlocked(_address);
    }

    function unblockAddress(address _address) external onlyOwner {
        blockList[_address] = false;
        emit AddressUnblocked(_address);
    }

    function setDefaultGas(uint256 _defaultGas) external onlyOwner {
        defaultGas = _defaultGas;
    }

    function setPause() public onlyOwner returns (bool) {
        _pause();
        return paused();
    }

    function setUnPause() public onlyOwner returns (bool) {
        _unpause();
        return paused();
    }

    function updateStargateRouterAddress(address newStargateRouter)
        external
        onlyOwner
    {
        stargateRouter = newStargateRouter;
        emit UpdateStargateRouterAddress(newStargateRouter);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }

    function sgReceive(
        uint16, // the remote chainId sending the tokens
        bytes memory, // the remote Bridge address
        uint256,
        address token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external override onlyStargateRouter nonReentrant whenNotPaused {
        (address payable toAddress, bytes memory dataPayload) = abi.decode(
            payload,
            (address, bytes)
        );
        perfomAction(token, amountLD, toAddress, dataPayload);
    }

    function perfomAction(
        address token,
        uint256 amountLD,
        address payable toAddress,
        bytes memory dataPayload
    ) private notBlocked(toAddress) {
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = toAddress.call{
                gas: gasleft() - defaultGas,
                value: amountLD
            }(dataPayload);
            if(!success) {
               revert PayloadExectionFailed();
            }
        } else {
            IERC20(token).safeIncreaseAllowance(toAddress, amountLD);
            (bool success, ) = toAddress.call{gas: gasleft() - defaultGas}(
                dataPayload
            );
            IERC20(token).safeDecreaseAllowance(toAddress, 0);
            if(!success) {
               revert PayloadExectionFailed();
            }
        }
        emit PayloadExecuted(toAddress, amountLD, token);
    }

    receive() external payable {}
}