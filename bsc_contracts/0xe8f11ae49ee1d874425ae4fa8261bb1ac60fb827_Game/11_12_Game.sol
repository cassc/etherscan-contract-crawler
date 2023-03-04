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
	
	IERC20Upgradeable public hwt; 
	
	address public beneficiary;
	
	uint256 public withdrawHntLimit;
	uint256 public withdrawHwtLimit;
	
	struct Player{
		uint256 accHntDeposit;
		uint256 accHntWithdrawal;
		uint256 accHwtDeposit;
		uint256 accHwtWithdrawal;
	}
	mapping(address => Player) public players;
	
	uint256 public totalHntDeposit;
	uint256 public totalHntWithdrawal;
	uint256 public totalHwtDeposit;
	uint256 public totalHwtWithdrawal;
	
	event CheckHntWithdrawal(address indexed player, uint256 indexed accHntDeposit, uint256 indexed accHntWithdrawal);
	event CheckHwtWithdrawal(address indexed player, uint256 indexed accHwtDeposit, uint256 indexed accHwtWithdrawal);
	
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
	function adjustPlayer(address _player, uint256 _accHntDeposit, uint256 _accHntWithdrawal, uint256 _accHwtDeposit, uint256 _accHwtWithdrawal) public onlyOwner {
		Player storage player = players[_player];
		player.accHntDeposit = _accHntDeposit;
		player.accHntWithdrawal = _accHntWithdrawal;
		player.accHwtDeposit = _accHwtDeposit;
		player.accHwtWithdrawal = _accHwtWithdrawal;
	}
	  
	function setTotalHntDeposit(uint256 _totalHntDeposit) public onlyOwner {
		totalHntDeposit = _totalHntDeposit;
	}
	
	function setTotalHntWithdrawal(uint256 _totalHntWithdrawal) public onlyOwner {
		totalHntWithdrawal = _totalHntWithdrawal;
	}
	
	function setTotalHwtDeposit(uint256 _totalHwtDeposit) public onlyOwner {
		totalHwtDeposit = _totalHwtDeposit;
	}
	
	function setTotalHwtWithdrawal(uint256 _totalHwtWithdrawal) public onlyOwner {
		totalHwtWithdrawal = _totalHwtWithdrawal;
	}
	 
	function setWithdrawHntLimit(uint256 _withdrawHntLimit) public onlyOwner {
		withdrawHntLimit = _withdrawHntLimit;
	}
	
	function setWithdrawHwtLimit(uint256 _withdrawHwtLimit) public onlyOwner {
		withdrawHwtLimit = _withdrawHwtLimit;
	}
	  
	function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }   
	 
	function setHwt(IERC20Upgradeable _hwt) public onlyOwner {
        hwt = _hwt;
    }  
	
	function setSigners(address[] memory _signers) public onlyOwner {
        signers = _signers;
    }  
	
	function emergencyCollectToken(IERC20Upgradeable token, uint amount) public onlyOwner {
        token.transfer(owner(), amount);
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
		
		Player storage player = players[msg.sender];
		player.accHntDeposit += amount;
		
		totalHntDeposit += amount;
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hnt.safeTransferFrom(msg.sender, beneficiary, amount);
	}
	
	function withdrawHnt(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranteds(vs, rs, ss, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		
		require(amount > 0, "invalid amount");
		require(amount <= withdrawHntLimit, "exceed limit");
		require(hnt.balanceOf(address(this)) >= amount, "insufficient hnt");
		
		Player storage player = players[msg.sender];
		player.accHntWithdrawal += amount;
		
		totalHntWithdrawal += amount;
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hnt.safeTransfer(msg.sender, amount);
		
		emit CheckHntWithdrawal(msg.sender, player.accHntDeposit, player.accHntWithdrawal);
	}  
	
	function depositHwt(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranteds(vs, rs, ss, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
		
		require(amount > 0, "invalid amount");
		
		Player storage player = players[msg.sender];
		player.accHwtDeposit += amount;
		
		totalHwtDeposit += amount;
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hwt.safeTransferFrom(msg.sender, beneficiary, amount);
	}
	
	function withdrawHwt(
		uint256 requestId,
        uint256 amount,
		uint256 timestamp,
        uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss
	) nonReentrant onlyIfValidRequest(requestId, timestamp) onlyIfGranteds(vs, rs, ss, keccak256(abi.encodePacked(this, msg.sender, requestId, amount, timestamp))) public  {
	
		require(amount > 0, "invalid amount");
		require(amount <= withdrawHwtLimit, "exceed limit");
		require(hwt.balanceOf(address(this)) >= amount, "insufficient hwt");
		
		Player storage player = players[msg.sender];
		player.accHwtWithdrawal += amount;
		
		totalHwtWithdrawal += amount;
		
		requestContract.add(
			requestId, 
			abi.encode(amount),
			abi.encode(true)
		);
		
		hwt.safeTransfer(msg.sender, amount);
		
		emit CheckHwtWithdrawal(msg.sender, player.accHwtDeposit, player.accHwtWithdrawal);
	}  
	
	/*+=======+
	  | other |
	  +=======+*/
	function version() public pure returns (string memory) {
		return "1.3";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}