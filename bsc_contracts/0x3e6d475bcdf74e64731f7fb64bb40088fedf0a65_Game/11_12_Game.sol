// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./IRequest.sol";

contract Game is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

	using AddressUpgradeable for address;
	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	IRequest public requestContract;
	IERC20Upgradeable public hnt; 
	
	address[] public signers;
	
	modifier onlyIfGranteds( uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, bytes32 hashMsg ) {
		
		address lastAddr = address(0);
		
        uint8 verifiedSigners = 0;
        for (uint64 i = 0; i < vs.length; i++) {
            address recovered = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX,hashMsg)), vs[i], rs[i], ss[i]);
            if (recovered > lastAddr && signers[i]==recovered)
                verifiedSigners++;
            lastAddr = recovered;
        }
        require(verifiedSigners == signers.length, "Invalid signers");
		
		_;
	}
	
	modifier onlyIfValidRequest( uint256 requestId, uint256 timestamp) {
		require(timestamp >= block.timestamp, "expired");
		require(!requestContract.get(requestId), "request duplicated");
		_;
	}

	function initialize(IERC20Upgradeable _hnt, IRequest _request, address[] memory _signers) public virtual initializer {
		__Ownable_init();
		__ReentrancyGuard_init();
		
		requestContract = _request;
		hnt = _hnt;
		signers = _signers;
    }

	/*+=======+
	  | admin |
	  +=======+*/
	function setSigners(address[] memory _signers) public onlyOwner {
        signers = _signers;
    }  
	
	function emergencyCollectToken(address token, uint amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(owner(), amount);
    }
	
	/*+======+
	  | core |
	  +======+*/
	function depositHnt(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranteds(vs, rs, ss, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		
		require(amount > 0, "invalid amount");
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hnt.safeTransferFrom(msg.sender, address(this), amount);
	}
	
	function withdrawHnt(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranteds(vs, rs, ss, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		require(hnt.balanceOf(address(this)) >= amount, "insufficient hnt");
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hnt.safeTransfer(msg.sender, amount);
	}  
	
	/*+=======+
	  | other |
	  +=======+*/
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