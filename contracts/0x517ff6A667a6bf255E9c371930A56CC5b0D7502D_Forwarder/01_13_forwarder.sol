// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// Contract will act as a hot wallet for different ERC20 tokens and ETH
contract Forwarder is Initializable , AccessControlUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant FLUSH_ROLE = keccak256("FLUSH");

    // Address to which any funds sent to this contract will be forwarded
    address public vault;
    event ReceivedETH(
        address from,
        uint value
    );
    event FlushedETH(
        address to,
        uint value
    );
    event FlushedTokens(
        address tokenContractAddress, // The contract address of the token
        uint value // Amount of token sent
    );
    // Create the contract, and set the destination address to that of the creator
    function initialize(address _vault, address _admin, address _flusher) initializer public {
        require(_vault != address(0), "VAULT address must not be address zero");
        require(_admin != address(0), "ADMIN address must not be address zero");
        require(_flusher != address(0), "FLUSHER address must not be address zero");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(FLUSH_ROLE, _flusher);
        vault = _vault;
    }
    function changeVault(address _newVault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newVault != address(0), "VAULT address must not be address zero");
        vault = _newVault;
    }

    /**
     * Execute a token transfer of the full balance from the forwarder token to the main wallet contract
     * @param tokenContractAddress the address of the erc20 token contract
    */
    function flushTokens(address tokenContractAddress) external onlyRole(FLUSH_ROLE) {
        IERC20Upgradeable instance = IERC20Upgradeable(tokenContractAddress);
        uint256 forwarderBalance = instance.balanceOf(address(this));
        require(forwarderBalance != 0, "Forwarder balance must NOT be ZERO");
        instance.safeTransfer(vault, forwarderBalance);
        emit FlushedTokens(tokenContractAddress, forwarderBalance);
    }
    // Nameless function so contract is able to receive ETH
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }
    // Flush Ether from forwarder contract to the main wallet contract
    function flushETH() external onlyRole(FLUSH_ROLE){
        (bool success, ) = vault.call{value: address(this).balance}("");
        require(success, "Couldn't flush ETH!");
        emit FlushedETH(vault, address(this).balance);
    }
}