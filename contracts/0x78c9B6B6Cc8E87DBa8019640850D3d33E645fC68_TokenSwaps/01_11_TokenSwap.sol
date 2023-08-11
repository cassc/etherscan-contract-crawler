// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./utils/FundsManager.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title TokenSwaps
 * @dev This contract allowed 1:1 swap of one ERC20 token to another
 */
contract TokenSwaps is PausableUpgradeable, FundsManager {
    // token from user
    IERC20Upgradeable public tokenFrom;

    // token to user
    IERC20Upgradeable public tokenTo;

    // swapped amount
    uint256 public swapped;

    // wallet for tokenTo
    address public wallet;

    // Emit when user swapped tokens
    event Swapped(address indexed user, uint256 amount);

    // Emit when user swapped tokens to address
    event SwappedToAddress(address indexed user, address indexed to, uint256 amount);

    /**
     * @param _tokenFrom Token from user
     * @param _tokenTo Token to user
     * @param _wallet Wallet address for tokenTo
     **/
    function initialize(
        IERC20Upgradeable _tokenFrom,
        IERC20Upgradeable _tokenTo,
        address _wallet
    ) external virtual initializer {
        __Pausable_init();
        __Ownable_init();

        require(address(_tokenFrom) != address(0), "TokenSwaps: tokenFrom is the zero address");
        require(address(_tokenTo) != address(0), "TokenSwaps: tokenTo is the zero address");
        require(_wallet != address(0), "TokenSwaps: wallet is the zero address");
        tokenFrom = _tokenFrom;
        tokenTo = _tokenTo;
        wallet = _wallet;
    }

    /**
     * @notice Token must be pre-approved
     * @dev Swap token with ratio 1:1 for sender
     * @param _amount The amount of tokens to swap
     **/
    function swap(uint256 _amount) public {
        swapToAddress(_amount, msg.sender);

        emit Swapped(msg.sender, _amount);
    }

    /**
     * @notice Token must be pre-approved
     * @dev Swap token with ratio 1:1 from sender to _to address
     * @param _amount The amount of tokens to swap
     * @param _to Token recipient address
     **/
    function swapToAddress(uint256 _amount, address _to) public whenNotPaused {
        tokenFrom.transferFrom(msg.sender, wallet, _amount);
        tokenTo.transfer(_to, _amount);

        swapped += _amount;

        emit SwappedToAddress(msg.sender, _to, _amount);
    }

    /**
     * @dev Pauses token swaps.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses token swaps.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set a new wallet address.
     */
    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    receive() external payable {
        revert("TokenSwaps: sending msg.value is prohibited");
    }
}