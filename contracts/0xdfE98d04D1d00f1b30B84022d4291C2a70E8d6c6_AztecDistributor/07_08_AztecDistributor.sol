// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Ownable} from "oz/access/Ownable.sol";
import {ERC4626Migrator} from "./ERC4626Migrator.sol";

/**
 * @title AztecDistributor
 * @notice Contract to be used to distribute and set up the Aztec ERC4626 migration contracts.
 */
contract AztecDistributor is Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    ERC20 constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address public constant eulerMultisig = 0xcAD001c30E96765aC90307669d578219D4fb1DCe;

    address public constant weweth4626 = 0x3c66B18F67CA6C1A71F829E2F6a0c987f97462d0;
    address public constant wewsteth4626 = 0x60897720AA966452e8706e74296B018990aEc527;
    address public constant wedai4626 = 0x4169Df1B7820702f566cc10938DA51F6F597d264;

    address public weweth4626Migrator;
    address public wewsteth4626Migrator;
    address public wedai4626Migrator;

    /** 
     * @notice Admin function to distribute and set up the Aztec ERC4626 migration contracts.
     * @dev Only owner can call this function
     */
    function distribute() external nonReentrant onlyOwner {
        // check balances
        require(WETH.balanceOf(address(this)) >= 709317925561782833751, "WETH balance incorrect");
        require(DAI.balanceOf(address(this)) >= 327140818443534621219584, "DAI balance incorrect");
        require(USDC.balanceOf(address(this)) >= 25215772580, "USDC balance incorrect");

        // deploy migrators
        weweth4626Migrator = address(new ERC4626Migrator(ERC20(weweth4626)));
        wewsteth4626Migrator = address(new ERC4626Migrator(ERC20(wewsteth4626)));
        wedai4626Migrator = address(new ERC4626Migrator(ERC20(wedai4626)));

        // transfer assets to migrators
        // WETH        
        WETH.safeTransfer(weweth4626Migrator, 375853222858287897925);
        WETH.safeTransfer(wewsteth4626Migrator, 281939966842142630806);
        WETH.safeTransfer(wedai4626Migrator, 51524735861352305020);

        // DAI
        DAI.safeTransfer(weweth4626Migrator, 173345303296992109902679);
        DAI.safeTransfer(wewsteth4626Migrator, 130032060632940826941040);
        DAI.safeTransfer(wedai4626Migrator, 23763454513601684375865);

        // USDC
        USDC.safeTransfer(weweth4626Migrator, 13361327904);
        USDC.safeTransfer(wewsteth4626Migrator, 10022775161);
        USDC.safeTransfer(wedai4626Migrator, 1831669515);
    }

    /**
     * @notice Admin function to recover funds from the contract
     * @dev Only owner can call this function
     * @param _token - The token to recover
     * @param _amount - The amount of the token to recover
     * @param _to - The address to send the recovered funds to
     */
    function adminRecover(address _token, uint256 _amount, address _to) external onlyOwner {
        ERC20(_token).safeTransfer(_to, _amount);
    }
}