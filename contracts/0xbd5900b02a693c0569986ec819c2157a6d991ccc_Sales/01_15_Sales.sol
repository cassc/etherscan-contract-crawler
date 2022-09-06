// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./IERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IOkOctopus is IERC721Upgradeable{
	function mint(address to, uint256 qty) external;
	function totalSupply() external view returns (uint256);
}

contract Sales is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    
	
	using StringsUpgradeable for uint256;
	
	bytes public constant PREFIX = "\x19Ethereum Signed Message:\n32";
	bytes32 public constant WL_SIGNER_ROLE = keccak256("WL_SIGNER_ROLE");
	uint256 public constant daySeconds = 86400;
	
	IOkOctopus public nft;
	
	uint256 public wlPeriod;
	uint256 public saleStart;
	uint256 public saleEnd;
	address public beneficiary;//warning: only EOA acount allow
    uint256 public supplyLimit; 
	uint256 public maxWlFreeMint;
	uint256 public maxPbFreeMint;
	uint256 public maxFreeMint; //total free mint

    uint256 public salePrice; 
	
	struct purchaseInfo{
		uint256 wlFreeMint;
		uint256 pbFreeMint;
		uint256 paidMint;
	}
	mapping(address => purchaseInfo) public purchaseHistory;
	
	function initialize(address _beneficiary, uint256 _supplyLimit, IOkOctopus _nft, address signer, uint256 _saleStart, uint256 _saleEnd, uint256 _wlPeriod) public virtual initializer {
		
		require(_saleStart + _wlPeriod < _saleEnd, "invalid sale date");
		
		__Ownable_init();
		__ReentrancyGuard_init();
		__Pausable_init();
		__AccessControl_init();

		salePrice = 0.008 ether;
		maxFreeMint = 3;
		maxWlFreeMint = 3;
		maxPbFreeMint = 2;
		
		supplyLimit = _supplyLimit;
		beneficiary = _beneficiary;
		nft = _nft;
		saleStart = _saleStart;
		saleEnd = _saleEnd;
		wlPeriod = _wlPeriod;
		
		_setupRole(WL_SIGNER_ROLE, signer);
    }
   
	//=======
	//sales
	//=======
    function purchase(uint256 qty) public payable nonReentrant whenNotPaused {
		
		require(qty > 0, "Invalid qty");
        require(block.timestamp > saleStart+wlPeriod && block.timestamp <= saleEnd, "Not public sales");
        require(nft.totalSupply() + qty <= supplyLimit, "Exceed supply limit");
		
		purchaseInfo storage myPurchaseNft = purchaseHistory[msg.sender];
		uint256 totalMint = myPurchaseNft.wlFreeMint + myPurchaseNft.pbFreeMint;
		uint256 freeQuota;

		if (myPurchaseNft.pbFreeMint >= maxPbFreeMint) {
			freeQuota = 0;
		} else {
			if (myPurchaseNft.wlFreeMint == 0) {
				freeQuota = maxPbFreeMint - totalMint;
			} else {
				freeQuota = maxFreeMint - totalMint;
				if (freeQuota > maxPbFreeMint) {
					freeQuota = maxPbFreeMint;
				}
			}
		}
		
		uint256 orderPrice;
		uint256 freeMint;
		uint256 paidMint;
		
		if (qty > freeQuota) {
			freeMint = freeQuota;
			paidMint = (qty - freeQuota);
			orderPrice = salePrice * paidMint;
		} else {
			freeMint = qty;
			paidMint = 0;
			orderPrice = 0;
		}
		
		require(orderPrice == msg.value, "Incorrect eth value");
		
		nft.mint(msg.sender, qty);
	   
        myPurchaseNft.pbFreeMint += freeMint;
		myPurchaseNft.paidMint += paidMint;
		
		if (orderPrice > 0) {
			payable(beneficiary).transfer(address(this).balance);
		}
    }
	
	function wlPurchase(uint256 qty, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant whenNotPaused {
		
		require(qty > 0, "Invalid qty");
        require(block.timestamp >= saleStart && block.timestamp <= saleStart+wlPeriod, "Not wl sales");
        require(nft.totalSupply() + qty <= supplyLimit, "Exceed supply limit");
		
		bytes32 hashedMsg = keccak256(abi.encodePacked(address(this), address(msg.sender)));
		bytes32 digest = keccak256(abi.encodePacked(PREFIX, hashedMsg));
		address recovered = ecrecover(digest, v, r, s);
			
		require(hasRole(WL_SIGNER_ROLE, recovered), "Permission denied");
		
		purchaseInfo storage myPurchaseNft = purchaseHistory[msg.sender];
		
		uint256 freeQuota = maxWlFreeMint - myPurchaseNft.wlFreeMint;
		
		uint256 orderPrice;
		uint256 freeMint;
		uint256 paidMint;
		
		if (qty > freeQuota) {
			freeMint = freeQuota;
			paidMint = (qty - freeQuota);
			orderPrice = salePrice * paidMint;
		} else {
			freeMint = qty;
			paidMint = 0;
			orderPrice = 0;
		}
		
		require(orderPrice == msg.value, "Incorrect eth value");
		
		nft.mint(msg.sender, qty);
	   
        myPurchaseNft.wlFreeMint += freeMint;
		myPurchaseNft.paidMint += qty - freeMint;
		
		if (orderPrice > 0) {
			payable(beneficiary).transfer(address(this).balance);
		}
    }
	
	//======
	//admin 
	//======
	function setSaleDate(uint256 _saleStart,uint256 _saleEnd, uint256 _wlPeriod) public onlyOwner{
		require(_saleStart + _wlPeriod < _saleEnd, "invalid sale date");
	
		saleStart = _saleStart;
		saleEnd = _saleEnd;
		wlPeriod = _wlPeriod;
	}
	
	function setSalePrice(uint256 _salePrice) public onlyOwner{
		salePrice = _salePrice;
	}
	
	function setSupplyLimit(uint256 _supplyLimit) public onlyOwner{
		supplyLimit = _supplyLimit;
	}
	
	function setBeneficiary(address _beneficiary) public onlyOwner{
		beneficiary = _beneficiary;
	}
	
	//========
	//getters
	//========
	function getConfig() public view returns(uint256, uint256, uint256, uint256, address, uint256, uint256, uint256, uint256) {
		return (supplyLimit, saleStart, saleEnd, salePrice, beneficiary,wlPeriod,maxFreeMint, maxWlFreeMint, maxPbFreeMint);
	}
	
	//============
	//solidity/oz
	//============
	function version() public pure returns (string memory) {
		return "1.1";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}