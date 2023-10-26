// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "@gooddollar/bridge-contracts/contracts/messagePassingBridge/IMessagePassingBridge.sol";

import "../utils/DAOUpgradeableContract.sol";
import "./ExchangeHelper.sol";

// import "hardhat/console.sol";

/***
 * @dev DistributionHelper receives funds and distributes them to recipients
 * recipients can be on other blockchains and get their funds via fuse/multichain bridge
 * accounts with ADMIN_ROLE can update the recipients, defaults to Avatar
 */
contract DistributionHelper is
	DAOUpgradeableContract,
	AccessControlEnumerableUpgradeable
{
	bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

	error FEE_LIMIT(uint256 fee);

	//IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438); //@mean-finance/uniswap-v3-oracle

	address public constant CELO_TOKEN =
		0x3294395e62F4eB6aF3f1Fcf89f5602D90Fb3Ef69;

	address public constant FUSE_TOKEN =
		0x970B9bB2C0444F5E81e9d0eFb84C8ccdcdcAf84d;

	address public constant USDC_TOKEN =
		0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	address public constant WETH_TOKEN =
		0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	enum TransferType {
		FuseBridge,
		LayerZeroBridge,
		AxelarBridge,
		Contract
	}

	struct DistributionRecipient {
		uint32 bps; //share out of each distribution
		uint32 chainId; //for multichain bridge
		address addr; //recipient address
		TransferType transferType;
	}

	struct FeeSettings {
		uint128 axelarBaseFeeUSD;
		uint128 bridgeExecuteGas;
		uint128 targetChainGasPrice;
		uint128 maxFee;
		uint128 minBalanceForFees;
		uint8 percentageToSellForFee;
	}

	DistributionRecipient[] public distributionRecipients;

	address public fuseBridge;
	IMessagePassingBridge public mpbBridge;
	FeeSettings public feeSettings; //previously anyGoodDollar_unused; //kept for storage layout upgrades

	IStaticOracle public STATIC_ORACLE;

	event Distribution(
		uint256 distributed,
		uint256 startingBalance,
		uint256 incomingAmount,
		DistributionRecipient[] distributionRecipients
	);
	event RecipientUpdated(DistributionRecipient recipient, uint256 index);
	event RecipientAdded(DistributionRecipient recipient, uint256 index);

	receive() external payable {}

	function initialize(INameService _ns) external initializer {
		__AccessControlEnumerable_init();
		setDAO(_ns);
		_setupRole(DEFAULT_ADMIN_ROLE, avatar); //this needs to happen after setDAO for avatar to be non empty
		_setupRole(GUARDIAN_ROLE, avatar);
		updateAddresses();
	}

	function updateAddresses() public {
		fuseBridge = nameService.getAddress("BRIDGE_CONTRACT");
		mpbBridge = IMessagePassingBridge(
			nameService.getAddress("MPBBRIDGE_CONTRACT")
		);
		STATIC_ORACLE = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438); //@mean-finance/uniswap-v3-oracle
		_setupRole(GUARDIAN_ROLE, avatar);
		_setupRole(GUARDIAN_ROLE, 0xE0c5daa7CC6F88d29505f702a53bb5E67600e7Ec); //guardians on ethereum
	}

	function setFeeSettings(
		FeeSettings memory _feeData
	) external onlyRole(GUARDIAN_ROLE) {
		feeSettings = _feeData;
	}

	function getTargetChainRefundAddress(
		uint256 chainId
	) public pure returns (address) {
		if (chainId == 122) return 0xf96dADc6D71113F6500e97590760C924dA1eF70e; //avatar on fuse
		if (chainId == 42220) return 0x495d133B938596C9984d462F007B676bDc57eCEC; //avatar on celo

		revert("refund chainId");
	}

	function getTargetChainGasInEth(
		uint256 gasCostWei,
		uint256 chainId
	) public view returns (uint256 quote) {
		address baseToken;
		if (chainId == 122) baseToken = FUSE_TOKEN;
		else if (chainId == 42220) baseToken = CELO_TOKEN;
		else revert("baseToken chainId");

		uint24[] memory fees = new uint24[](1);
		fees[0] = 3000;
		(quote, ) = STATIC_ORACLE.quoteSpecificFeeTiersWithTimePeriod(
			uint128(gasCostWei),
			baseToken,
			WETH_TOKEN,
			fees,
			60 //last 1 minute
		);
	}

	function getAxelarFee(
		uint256 targetChainId
	) public view returns (uint256 feeInEth) {
		uint256 executeFeeInEth = getTargetChainGasInEth(
			feeSettings.bridgeExecuteGas * feeSettings.targetChainGasPrice,
			targetChainId
		);

		uint24[] memory fees = new uint24[](1);
		fees[0] = 500;
		(uint256 baseFeeInEth, ) = STATIC_ORACLE
			.quoteSpecificFeeTiersWithTimePeriod(
				uint128(feeSettings.axelarBaseFeeUSD) / 1e12, //reduce to usdc 6 decimals
				USDC_TOKEN,
				WETH_TOKEN,
				fees,
				60 //last 1 minute
			);

		feeInEth = ((baseFeeInEth + executeFeeInEth) * 110) / 100; //add 10%
	}

	/**
	 * @notice this is usually called by reserve, but can be called by anyone anytime to trigger distribution
	 * @param _amount how much was sent, informational only
	 */
	function onDistribution(uint256 _amount) external virtual {
		//we consider the actual balance and not _amount
		// console.log("onDistribution amount: %s", _amount);
		uint256 toDistribute = nativeToken().balanceOf(address(this));
		if (toDistribute == 0) return;

		if (address(this).balance < feeSettings.minBalanceForFees) {
			uint256 gdToSellfForFee = (toDistribute *
				feeSettings.percentageToSellForFee) / 100;
			toDistribute -= gdToSellfForFee;
			buyNativeWithGD(gdToSellfForFee);
		}

		uint256 totalDistributed;
		for (uint256 i = 0; i < distributionRecipients.length; i++) {
			DistributionRecipient storage r = distributionRecipients[i];
			if (r.bps > 0) {
				uint256 toTransfer = (toDistribute * r.bps) / 10000;
				totalDistributed += toTransfer;
				if (toTransfer > 0) distribute(r, toTransfer);
			}
		}

		emit Distribution(
			totalDistributed,
			toDistribute,
			_amount,
			distributionRecipients
		);
	}

	/**
	 * @notice add or update a recipient details, if address exists it will update, otherwise add
	 * to "remove" set recipient bps to 0. only ADMIN_ROLE can call this.
	 */
	function addOrUpdateRecipient(
		DistributionRecipient memory _recipient
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		for (uint256 i = 0; i < distributionRecipients.length; i++) {
			if (distributionRecipients[i].addr == _recipient.addr) {
				distributionRecipients[i] = _recipient;
				emit RecipientUpdated(_recipient, i);
				return;
			}
		}
		//if reached here then add new one
		emit RecipientAdded(_recipient, distributionRecipients.length);
		distributionRecipients.push(_recipient);
	}

	/**
	 * @notice internal function that takes care of sending the G$s according to the transfer type
	 * @param _recipient data about the recipient
	 * @param _amount how much to send
	 */
	function distribute(
		DistributionRecipient storage _recipient,
		uint256 _amount
	) internal {
		if (_recipient.transferType == TransferType.FuseBridge) {
			nativeToken().transferAndCall(
				fuseBridge,
				_amount,
				abi.encodePacked(_recipient.addr)
			);
		} else if (_recipient.transferType == TransferType.LayerZeroBridge) {
			nativeToken().approve(address(mpbBridge), _amount);
			(uint256 lzFee, ) = ILayerZeroFeeEstimator(address(mpbBridge))
				.estimateSendFee(
					mpbBridge.toLzChainId(_recipient.chainId),
					address(this),
					_recipient.addr,
					_amount,
					false,
					""
				);
			if (lzFee > feeSettings.maxFee) revert FEE_LIMIT(lzFee);

			mpbBridge.bridgeToWithLz{ value: lzFee }(
				_recipient.addr,
				_recipient.chainId,
				_amount,
				""
			);
		} else if (_recipient.transferType == TransferType.AxelarBridge) {
			nativeToken().approve(address(mpbBridge), _amount);
			uint256 axlFee = getAxelarFee(_recipient.chainId);

			if (axlFee > feeSettings.maxFee) revert FEE_LIMIT(axlFee);

			mpbBridge.bridgeToWithAxelar{ value: axlFee }(
				_recipient.addr,
				_recipient.chainId,
				_amount,
				getTargetChainRefundAddress(_recipient.chainId)
			);
		} else if (_recipient.transferType == TransferType.Contract) {
			nativeToken().transferAndCall(_recipient.addr, _amount, "");
		}
	}

	function buyNativeWithGD(uint256 amountToSell) internal {
		address[] memory path = new address[](2);
		path[0] = nameService.getAddress("DAI");
		path[1] = address(0);
		address exchg = nameService.getAddress("EXCHANGE_HELPER");
		nativeToken().approve(exchg, amountToSell);
		ExchangeHelper(exchg).sell(path, amountToSell, 0, 0, address(this));
	}
}