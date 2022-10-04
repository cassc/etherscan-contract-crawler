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

    event AddToken(address token);
    event ReceivedOnDestination(
        address token,
        uint256 amount,
        address accountAddress
    );

    function __AccumulatedDepositor_init(address _stargateRouter)
        public
        initializer
    {
        LogicUpgradeable.initialize();
        stargateRouter = _stargateRouter;
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
    function setStorage(address _storage) external {
        require(storageContract == address(0), "AD1");
        storageContract = _storage;
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
        require(msg.sender == address(stargateRouter), "AD5");

        address accountAddress = abi.decode(_payload, (address));

        IStorage(storageContract).depositOnBehalf(
            amountLD,
            _token,
            accountAddress
        );

        emit ReceivedOnDestination(_token, amountLD, accountAddress);
    }
}