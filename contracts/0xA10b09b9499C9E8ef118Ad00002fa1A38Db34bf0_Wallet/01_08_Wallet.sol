pragma solidity 0.8.6;

import "./WalletFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @dev Implementation of the generic wallet contract.
 * This implementation intends to allow receiving any ERC20 token and ether at the same
 * time it constraints sending (also called "collecting") to only one address.
 *
 * That address is specified by the `WalletFactory` contract.
 */
contract Wallet {
    using SafeERC20 for IERC20;
    using Address for address payable;
    
    WalletFactory public factory;

    /**
     * @dev This method is intended to be called only once by the factory immediately after contract creation.
     * The reason the code within is not included in a constructor is because `Wallet` contracts are cloned
     * from a template, which forces not to use constructors.
     *
     * Please note this method can only be called once in the contract's lifetime.
     */
    function setup() public {
        require(address(factory) == address(0), "Wallet: cannot call setup twice");

        factory = WalletFactory(msg.sender);
    }
    
    /**
     * @dev Gets the master address where funds will be transferred to.
     */
    function master() public view returns (address payable) {
        return factory.master();
    }

    /**
     * @dev Collects all available ether and sends it to the master address.
     */
    function collectEther() public returns (uint) {
        uint balance = address(this).balance;
        master().sendValue(balance);
        return balance;
    }

    /**
     * @dev Collects all available ERC20 tokens and sends them to the master address.
     */
    function collect(address _asset) public returns (uint) {
        uint balance;
        if (_asset == address(0)) {
            balance = collectEther();
        } else {
            IERC20 token = IERC20(_asset);
            balance = token.balanceOf(address(this));
            token.safeTransfer(master(), balance);
        }
        return balance;
    }

    /**
     * @dev Collects several tokens and ether at once and sends it all to the master address.
     */
    function collectMany(address[] calldata _assets) public returns (uint[] memory) {
        require(_assets.length > 0, "Wallet: at least one asset must be specified");

        uint[] memory values = new uint[](_assets.length);
        for (uint i = 0; i < _assets.length; i++) {
            values[i] = collect(_assets[i]);
        }
        return values;
    }

    /**
     * @dev Method to log whenever ether is received by this contract.
     */
    receive() external payable {
        factory.notifyEtherReceived(msg.sender, msg.value);
    }
}