// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/LogicUpgradeable.sol";
import "../Interfaces/IStorage.sol";

contract AccumulatedDepositor is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) private tokensAdd;
    address private storageContract;
    address private stargateRouter;
    uint256 stargateReserveGas;
    uint256 stargateExitGas;

    event AddToken(address token);
    event SetStargateReserveGas(uint256 stargateReserveGas);
    event SetStargateExitGas(uint256 stargateExitGas);
    event ReceivedOnDestination(
        address token,
        uint256 amount,
        address accountAddress,
        uint8 successFlag
    ); // succesFlag : 0 - success, 1 - dstGasForCall is below reservedGas, 2 - error on depositOnBehalf

    function __AccumulatedDepositor_init() public initializer {
        LogicUpgradeable.initialize();
        stargateExitGas = 60000;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier isUsedToken(address _token) {
        require(tokensAdd[_token], "AD2");
        _;
    }

    /*** User function ***/

    /**
     * @notice set Storage address
     * @param _storage storage address
     */
    function setStorage(address _storage) external onlyOwner {
        require(storageContract == address(0), "AD1");
        storageContract = _storage;
    }

    /**
     * @notice set stargateReserveGas
     * @param _stargateReserveGas Stargate sgReceive reservedGas
     */
    function setStargateReserveGas(uint256 _stargateReserveGas)
        external
        onlyOwner
    {
        stargateReserveGas = _stargateReserveGas;

        emit SetStargateReserveGas(_stargateReserveGas);
    }

    /**
     * @notice set stargateExitGas
     * @param _stargateExitGas Stargate sgReceive exitGas
     */
    function setStargateExitGas(uint256 _stargateExitGas) external onlyOwner {
        stargateExitGas = _stargateExitGas;

        emit SetStargateExitGas(_stargateExitGas);
    }

    /**
     * @notice set stargateRouter
     * @param _stargateRouter StargateRouter address
     */
    function setStargateRouter(address _stargateRouter) external onlyOwner {
        stargateRouter = _stargateRouter;
    }

    /**
     * @notice Add token
     * @param _token Address of Token
     */
    function addStargateToken(address _token) external onlyOwner {
        require(_token != address(0), "AD3");
        require(!tokensAdd[_token], "AD4");
        require(storageContract != address(0), "AD1");

        IERC20Upgradeable(_token).safeApprove(
            storageContract,
            type(uint256).max
        );

        tokensAdd[_token] = true;

        emit AddToken(_token);
    }

    /// @param '_chainId' The remote chainId sending the tokens
    /// @param '_srcAddress' The remote Bridge address
    /// @param '_nonce' The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16, /*_chainId*/
        bytes memory, /*_srcAddress*/
        uint256, /*_nonce*/
        address _token,
        uint256 amountLD,
        bytes memory _payload
    ) external isUsedToken(_token) {
        require(
            msg.sender == address(stargateRouter) || msg.sender == owner(),
            "AD5"
        );
        address accountAddress = abi.decode(_payload, (address));
        require(accountAddress != address(0), "AD3");

        // Normal case
        uint8 successFlag = 0;

        if (gasleft() < stargateReserveGas) {
            IERC20Upgradeable(_token).safeTransfer(accountAddress, amountLD);
            successFlag = 1;
        } else {
            try
                IStorage(storageContract).depositOnBehalf{
                    gas: gasleft() - stargateExitGas
                }(amountLD, _token, accountAddress) // exitGas = 30000
            {} catch (bytes memory) {
                IERC20Upgradeable(_token).safeTransfer(
                    accountAddress,
                    amountLD
                );
                successFlag = 2;
            }
        }

        // Send dust BNB to user
        if (address(this).balance > 0)
            accountAddress.call{value: (address(this).balance)}("");

        emit ReceivedOnDestination(
            _token,
            amountLD,
            accountAddress,
            successFlag
        );
    }
}