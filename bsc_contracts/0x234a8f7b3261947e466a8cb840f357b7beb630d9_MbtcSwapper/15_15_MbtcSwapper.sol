// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IRequest.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract MbtcSwapper is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
	
	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	bytes32 public constant AUTH_ROLE = keccak256("AUTH_ROLE");
    using SafeERC20Upgradeable for IERC20Upgradeable;
	
	IRequest public requestContract;
	IERC20Upgradeable public mbtc; 
	
	address public beneficiary;
	
	modifier onlyIfGranted( uint8 v, bytes32 r, bytes32 s, bytes32 hashMsg ) {
		address recoveredSigner = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX, hashMsg)), v, r, s);
		require(hasRole(AUTH_ROLE, recoveredSigner), "unauthorized");
		_;
	}
	
	modifier onlyIfValidRequest( uint256 requestId, uint256 timestamp) {
		require(timestamp >= block.timestamp, "expired");
		require(!requestContract.get(requestId), "request duplicated");
		_;
	}
	
    function initialize(IERC20Upgradeable _mbtc, IRequest _request, address authorizer, address _beneficiary) public initializer {
	
        __Ownable_init();
		__ReentrancyGuard_init();
		__AccessControl_init();
		
		requestContract = _request;
		mbtc = _mbtc;
		beneficiary = _beneficiary;
		
		_setupRole(AUTH_ROLE, authorizer);
    }
	
	function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
	
	function deposit(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		
		require(amount > 0, "invalid amount");
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		mbtc.safeTransferFrom(msg.sender, beneficiary, amount);
	}
	
	function withdraw(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		require(mbtc.balanceOf(address(this)) >= amount, "insufficient mbtc");
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		mbtc.safeTransfer(msg.sender, amount);
		
	}
	
	function emergencyCollectToken(address token, uint amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(owner(), amount);
    }
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}