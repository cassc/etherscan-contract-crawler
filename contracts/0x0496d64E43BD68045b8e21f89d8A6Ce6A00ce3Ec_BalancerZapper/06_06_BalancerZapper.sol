// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IDepositor.sol";

interface IBalancerVault {
	struct JoinPoolRequest {
		address[] assets;
    	uint256[] maxAmountsIn;
    	bytes userData;
    	bool fromInternalBalance;
	}
	function joinPool(
		bytes32 _poolId, 
		address _sender, 
		address _recipient, 
		JoinPoolRequest memory _request
	) external payable;
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

contract BalancerZapper {
    using SafeERC20 for IERC20;

    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    address public constant DEPOSITOR = 0x3e0d44542972859de3CAdaF856B1a4FD351B4D2E; 

    constructor() {
        IERC20(BAL).safeApprove(BALANCER_VAULT, type(uint256).max);
        IERC20(BPT).safeApprove(DEPOSITOR, type(uint256).max);
    }

    /// @notice Zap token from BAL to the StakeDAO sdBal
	/// @dev User needs to approve the contract to transfer BAL tokens
	/// @param _lock Whether to lock the BPT directly to the locker
	/// @param _stake Whether to stake sdBal to the related gauge
	/// @param _minAmount min amount of BPT to obtain providing liquidity in BAL
    /// @param _user User to deposit for into the balancer depositor
    function zapFromBal(
        uint256 _amount, 
        bool _lock, 
        bool _stake, 
        uint256 _minAmount,
        address _user
    ) external {
        // transfer BAL here
        IERC20(BAL).safeTransferFrom(msg.sender, address(this), _amount);

        address[] memory assets = new address[](2);
        assets[0] = BAL;
        assets[1] = WETH;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = _amount;
        maxAmountsIn[1] = 0; // 0 WETH

		IBalancerVault.JoinPoolRequest memory pr = IBalancerVault.JoinPoolRequest(
			assets,
			maxAmountsIn, 
			abi.encode(IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, _minAmount), 
			false
		);
		IBalancerVault(BALANCER_VAULT).joinPool(
			bytes32(0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014), // poolId
			address(this),
			address(this),
			pr
		);
        // transfer BTP obtained to the Stake DAO balancer depositor and choose if lock/stake
        IDepositor(DEPOSITOR).deposit(IERC20(BPT).balanceOf(address(this)), _lock, _stake, _user);
    }
}