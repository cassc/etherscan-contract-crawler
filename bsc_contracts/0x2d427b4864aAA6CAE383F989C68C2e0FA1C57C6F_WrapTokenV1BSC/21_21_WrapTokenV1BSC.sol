// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./StakedTokenV1.sol";

contract WrapTokenV1BSC is StakedTokenV1 {
    /**
     * @dev ETH contract address on current chain.
     */
    address public constant _ETH_ADDRESS = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    /**
     * @dev Function to deposit eth to the contract for wBETH
     * @param amount The eth amount to deposit
     * @param referral The referral address
     */
    function deposit(uint256 amount, address referral) external {
        require(amount > 0, "zero ETH amount");
        _safeTransferFrom(_ETH_ADDRESS, msg.sender, address(this), amount);

        // ETH amount and exchangeRate are all scaled by 1e18
        uint256 wBETHUnit = 10 ** uint256(decimals);
        uint256 wBETHAmount = amount.mul(wBETHUnit).div(exchangeRate());

        _mint(msg.sender, wBETHAmount);

        emit DepositEth(msg.sender, amount, wBETHAmount, referral);
    }

    /**
     * @dev Function to supply eth to the contract
     * @param amount The eth amount to supply
     */
    function supplyEth(uint256 amount) external onlyOperator {
        require(amount > 0, "zero ETH amount");
        _safeTransferFrom(_ETH_ADDRESS, msg.sender, address(this), amount);

        emit SuppliedEth(msg.sender, amount);
    }

    /**
     * @dev Function to move eth to the ethReceiver
     * @param amount The eth amount to move
     */
    function moveToStakingAddress(uint256 amount) external onlyOperator {
        require(amount > 0, "move amount cannot be 0");

        address _ethReceiver = ethReceiver();
        require(_ethReceiver != address(0), "zero ethReceiver");

        require(amount <= IERC20(_ETH_ADDRESS).balanceOf(address(this)), "balance not enough");
        _safeTransfer(_ETH_ADDRESS, _ethReceiver, amount);

        emit MovedToStakingAddress(_ethReceiver, amount);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transferFrom failed');
    }
}