// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../utils/DAOUpgradeableContract.sol";

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
	enum TransferType {
		FuseBridge,
		MultichainBridge,
		TransferAndCall,
		Transfer
	}

	struct DistributionRecipient {
		uint32 bps; //share out of each distribution
		uint32 chainId; //for multichain bridge
		address addr; //recipient address
		TransferType transferType;
	}

	DistributionRecipient[] public distributionRecipients;

	address public fuseBridge;
	IMultichainRouter public multiChainBridge;
	address public anyGoodDollar; //G$ multichain wrapper on ethereum

	event Distribution(
		uint256 distributed,
		uint256 startingBalance,
		uint256 incomingAmount,
		DistributionRecipient[] distributionRecipients
	);
	event RecipientUpdated(DistributionRecipient recipient, uint256 index);
	event RecipientAdded(DistributionRecipient recipient, uint256 index);

	function initialize(INameService _ns) external initializer {
		__AccessControlEnumerable_init();
		setDAO(_ns);
		_setupRole(DEFAULT_ADMIN_ROLE, avatar); //this needs to happen after setDAO for avatar to be non empty
		updateAddresses();
	}

	function updateAddresses() public {
		fuseBridge = nameService.getAddress("BRIDGE_CONTRACT");
		multiChainBridge = IMultichainRouter(
			nameService.getAddress("MULTICHAIN_ROUTER")
		);
		anyGoodDollar = nameService.getAddress("MULTICHAIN_ANYGOODDOLLAR");
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
		// console.log("addOrUpdate addr: %s", _recipient.addr);
		for (uint256 i = 0; i < distributionRecipients.length; i++) {
			// console.log(
			// 	"addOrUpdate addr: %s idx: %s, recipient: %s",
			// 	_recipient.addr,
			// 	i,
			// 	distributionRecipients[i].addr
			// );
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
		} else if (_recipient.transferType == TransferType.MultichainBridge) {
			nativeToken().approve(address(multiChainBridge), _amount);
			multiChainBridge.anySwapOutUnderlying(
				anyGoodDollar,
				_recipient.addr,
				_amount,
				_recipient.chainId
			);
		} else if (_recipient.transferType == TransferType.TransferAndCall) {
			nativeToken().transferAndCall(_recipient.addr, _amount, "");
		} else if (_recipient.transferType == TransferType.Transfer) {
			nativeToken().transfer(_recipient.addr, _amount);
		}
	}
}