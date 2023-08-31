// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../cat/ERC20/CATERC20Proxy.sol";
import "../libraries/LibDiamond.sol";
contract CATProxyTokenFacet is Context {
	
	using SafeERC20 for IERC20;
	// --- all contract events listed here
	
	// when token deployed by hot wallet/admin this event will be emitted
	event ProxyTokenDeployed(
		address indexed owner,
		address indexed token,
		bytes32 salt
	);
	
	
	// when user initiate bridge out request this event will be emitted
	event InitiatedProxyBridgeOut(
		address indexed caller,
		address indexed token,
		address proxyToken,
		uint256 amount,
		uint16 destinationChain,
		bytes32 recipient,
		uint256 nonce,
		uint256 gasValue,
		string trackId
	);
	// --- end of events
	
	/**
	 * @notice CATRelayer deploy token contract and this function will only be called by admin or hot wallet.
	 * @param existingToken existing token address which will be used as deploy proxy token.
	 * @param salt token salt which is unique and store in relayer backend system.
	 * @param owner token owner
	 */
	function handleDeployProxyToken(
		address existingToken,
		bytes32 salt,
		address owner
	) external returns (address tokenAddress) {
		require(existingToken != address(0), "existing token address can't be zero");
		LibDiamond.enforceIsContractOwner();
		LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
		address projectedTokenAddress = computeAddress(salt);
		require(!isContract(projectedTokenAddress) , "already address deployed");
		tokenAddress = address(new CATERC20Proxy{ salt: salt }());
		CATERC20Proxy(tokenAddress).initialize(diamondStorage.chainId, existingToken, diamondStorage.wormhole, diamondStorage.finality);
		Ownable(tokenAddress).transferOwnership(_msgSender()); // as first we need to register other chains. so we will transfer ownership from proxy to our hot wallet address.
		emit ProxyTokenDeployed(owner, tokenAddress, salt);
	}
	
	/**
	 * @notice compute token address by salt before deployment.
	 * @param salt token salt which is unique and store in relayer backend system.
	 */
	function computeAddress(bytes32 salt) internal view returns (address addr) {
		bytes memory byteCodeForContract = type(CATERC20Proxy).creationCode;
		
		//create contract code hash
		bytes32 bytecodeHash = keccak256(byteCodeForContract);
		
		address deployer = address(this);
		assembly {
			let ptr := mload(0x40) // Get free memory pointer
		
		// |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
		// |-------------------|---------------------------------------------------------------------------|
		// | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
		// | salt              |                                      BBBBBBBBBBBBB...BB                   |
		// | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
		// | 0xFF              |            FF                                                             |
		// |-------------------|---------------------------------------------------------------------------|
		// | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
		// | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |
			
			mstore(add(ptr, 0x40), bytecodeHash)
			mstore(add(ptr, 0x20), salt)
			mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
			let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
			mstore8(start, 0xff)
			addr := keccak256(start, 85)
		}
	}
	
	/**
	 * @notice check if address is contract address or not.
	 * @param addr address
	 */
	function isContract(address addr) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}
	
	
	/**
* @dev this function is allowed to be called by user to start relaying tokens on all selected chain.
 	*/
	function initiateProxyBridgeOut(
		address tokenAddress,
		address proxyTokenAddress,
		uint256 amount,
		uint16 recipientChain,
		bytes32 recipient,
		uint32 nonce,
		string calldata trackId
	) external payable {
		require(proxyTokenAddress != address(0), "invalid proxy token address");
		LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
		
		require(msg.value > 0, "invalid value for gas");
		diamondStorage.gasCollector.transfer(msg.value);
		IERC20 erc20 = IERC20(tokenAddress);
		erc20.safeTransferFrom(_msgSender(), address(this), amount);
		if (erc20.allowance(address(this), proxyTokenAddress) < amount) {
			erc20.approve(proxyTokenAddress, amount);
		}
		
		// here we will call bridge out function of token contract.
		CATERC20Proxy(proxyTokenAddress).bridgeOut(amount, recipientChain, recipient, nonce);
		
		emit InitiatedProxyBridgeOut(
			_msgSender(),
			tokenAddress,
			proxyTokenAddress,
			amount,
			recipientChain,
			recipient,
			nonce,
			msg.value,
			trackId
		);
	}
} // end of contract