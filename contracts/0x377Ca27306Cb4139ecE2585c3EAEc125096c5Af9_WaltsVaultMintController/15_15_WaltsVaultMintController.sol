// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

////....................................................................................
////....................................................................................
////.............................▒██▓.....................................[K0K0'23].....
////........▓█████▒.............▓██▓....................................................
////.......▓██▓▒▓██▓...▒██▓....▓██▓.....................................................
////.......███▒..███▒..▒███....███...▓███.....▓███....▓███████████.▓██..▓██████▓........
////........▓▓▒...███..▓███...▓██▒...████▓.....███....▒▓...███...▓.▓▓..███▒..▓█▓........
////..............▓██▒.████▒.▒███...▒█████.....███.........███.........███▒.............
////..............▒███▒█████.███▒...███▒██▓....███.........███..........▓███▓▒..........
////...............█████████▓███....██▓.███....███.........███.........▓▒.▒▓███▓........
////...............▒████▓▒█████▒...▓███████▒...███.........███........▓██▓...▒███.......
////................████▒.█████....███▓▓▓███...███.........███........███▒....███.......
////................▓███..▓███▒...▓██▒...▓██▒..████████▓...███.........████▓████▒.......
////................▒███..▒███...▒▓▓▓▒...▓▓▓▓.▒▓▓▓▓▓▓▓▓▓..▒▓▓▓▒.........▒▓▓▓▓▓▒.........
////................▓███..▓███..........................................................
////....................................................................................
////...........▒▒▒▒..........▒███▒......................................................
////.........▒██████▓.......▒██▓........................................................
////.........███..▒██▓......███.........................................................
////.........▓██▒..▓██▒....▓██▒...████....▓██▒....███..▓██▒.....█▓▓▓███▓▓█▓.............
////................███...▒██▓...▒████▒...▓██▒....▓██..▓██▒.........██▓.................
////................▓██▒..▓██▒...▓█████...▓██▒....▓██..▓██▒.........██▓.................
////.................███.▒██▓...▒██▒▒██▒..▓██▒....▓██..▓██▒.........██▓.................
////.................▓██▒███....▓██▒.██▓..▓██▒....▓██..▓██▒.........██▓.................
////.................▒█████▓....████████▒.▒██▓....███..▓██▒.........██▓.................
////..................█████....▓██▒..▒██▓..███▒..▓██▒..▓██▒.........██▓.................
////..................▓███▓...▒███....███▒..▓██████▒...▓████████▒...███.................
////..................▒███▒...▒▒▒▒....▒▒▒▒....▒▒▒......▒▒▒▒▒▒▒▒▒....▒▒▒.................
////..................▓▓▓▓▒.............................................................
////....................................................................................
////....................................................................................
////..........▓▒▒ Once you open the Vault ~ imagination is the only limit ▒▒▓...........
////....................................................................................
////....................................dream.a.little..................................
////....................................................................................

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IWaltsVaultNFT} from "./Interfaces/IWaltsVaultNFT.sol";
import {Signer} from "./utils/Signer.sol";

contract WaltsVaultMintController is OwnableUpgradeable, Signer, PausableUpgradeable {
	
	IWaltsVaultNFT public ravendale;
	IWaltsVaultNFT public waltsVault;
	
	address public TREASURY;
	address public AUTHORISED_SIGNER;
	
	uint8 public MAX_MINTS_PER_TOKEN_RD;
	uint8 public MAX_MINTS_PER_SPOT_VL;
	
	uint16 public MAX_MINTS_PER_ADDR_PUBLIC;
	uint16 public MAX_AMOUNT_FOR_SALE;
	uint16 public AVAILABLE_AMOUNT_FOR_VL;
	uint16 public SIGNATURE_VALIDITY;
	
	uint32 public START_TIME_RD;
	uint32 public END_TIME_RD;
	uint32 public START_TIME_VL;
	uint32 public END_TIME_VL;
	uint32 public START_TIME_PUBLIC;
	uint32 public END_TIME_PUBLIC;
 
	uint256 public PRICE;
	
	uint16 public amountSold;
	mapping(address => uint256) public rdMintsBy;
	mapping(address => uint256) public vlMintsBy;
	mapping(address => uint256) public publicMintsBy;
    mapping(address => uint256[]) private tokensLockedBy;
	mapping(uint256 => address) public lockerOf;
    mapping(bytes => bool) private isSignatureUsed;
	
	event RavendaleClaim(address indexed _claimer, uint256 indexed _tokenId);
	event RavendaleMint(address _minter, uint256 indexed _amount);
	event VaultListMint(address _minter, uint256 indexed _amount);
	event PublicMint(address _minter, uint256 indexed _amount);
	event ReleaseRavendale(address indexed _receiver, uint256 indexed _tokenId);
	
	
	function initialize() external initializer {
		__Ownable_init();
		__Signer_init();
		__Pausable_init();
		
		ravendale = IWaltsVaultNFT(0xf83A99E084C1D575AF8e12FF492F5E6C7b768b48);
		waltsVault = IWaltsVaultNFT(0x9980b3aA61114B07A7604FfDC7C7D04bb6D8d735);
                
		TREASURY = 0x2F86b325E8FfeE20703C93A8F28Ab7a5Dd711b7E;
        AUTHORISED_SIGNER = 0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6;
		SIGNATURE_VALIDITY = uint16(5 minutes);
		
        PRICE = 0.0628 ether;
		MAX_MINTS_PER_TOKEN_RD = uint8(1);
		MAX_MINTS_PER_SPOT_VL = uint8(1);
		MAX_MINTS_PER_ADDR_PUBLIC = uint16(2);
		MAX_AMOUNT_FOR_SALE = uint16(5960);
		AVAILABLE_AMOUNT_FOR_VL = MAX_AMOUNT_FOR_SALE - uint16(928);
		
		START_TIME_RD = uint32(1683118800);
        END_TIME_RD = START_TIME_RD + uint32(8 hours);
        START_TIME_VL = START_TIME_RD;
        END_TIME_VL = END_TIME_RD;
        START_TIME_PUBLIC = END_TIME_VL;
        END_TIME_PUBLIC = START_TIME_PUBLIC + uint32(100 days);
	}
	
	function mint(
        uint16 amountRD,
		uint16 amountVL,
		uint16 amountPUBLIC,
		uint256[] calldata tokensToLockRD,
		signedData memory spotsDataVL
	) external payable whenNotPaused {
        uint256 amountTOTAL = amountRD + amountVL + amountPUBLIC;

        require(PRICE * amountTOTAL == msg.value, "mint: unacceptable payment");

        require(MAX_AMOUNT_FOR_SALE  >= amountSold + amountTOTAL, "mint: unacceptable amount");

        if(tokensToLockRD.length > 0){
            _ravendaleMint(amountRD, tokensToLockRD);
		}
		
		if(amountVL > 0){
            _vaultListMint(amountVL, spotsDataVL);
		}
		
		if(amountPUBLIC > 0){
            _publicMint(amountPUBLIC);
		}

		amountSold += uint16(amountTOTAL);
	}


    // ======== INTERNAL FUNCTIONS ======== //

	function _ravendaleMint(
		uint16 amountRD,
		uint256[] calldata tokensToLockRD
	) internal {
		require(START_TIME_VL <= block.timestamp, "ravendale: sale not started");
		for(uint256 i=0; i<tokensToLockRD.length; i++){
			tokensLockedBy[msg.sender].push(tokensToLockRD[i]);
			lockerOf[tokensToLockRD[i]] = msg.sender;
			
			ravendale.safeTransferFrom(msg.sender, address(this), tokensToLockRD[i]);
			waltsVault.safeTransferFrom(address(this), msg.sender, tokensToLockRD[i]);
			
			emit RavendaleClaim(msg.sender, tokensToLockRD[i]);
		}
		
		if(amountRD > 0){
			require(END_TIME_VL >= block.timestamp, "ravendale: sale over");
			require(MAX_MINTS_PER_TOKEN_RD * tokensToLockRD.length >= amountRD, "ravendale: unacceptable amount");
			rdMintsBy[msg.sender] += amountRD;
			
			(address[] memory receiver, uint256[] memory AmountRD) = _getArray(msg.sender, amountRD);
			waltsVault.airdrop(receiver, AmountRD);
			
			emit RavendaleMint(msg.sender, amountRD);
		}
		
		AVAILABLE_AMOUNT_FOR_VL += uint16(tokensToLockRD.length) - amountRD;
	}

	function _vaultListMint(
		uint16 amountVL,
		signedData memory spotsDataVL
	) internal {
		require(START_TIME_VL <= block.timestamp, "vault list: sale not started");
		require(block.timestamp <= END_TIME_VL, "vault list: sale over");
		require(amountVL <= AVAILABLE_AMOUNT_FOR_VL, "vault list: unavailable amount");
		
		require(block.timestamp < spotsDataVL.nonce + SIGNATURE_VALIDITY, "vault list: expired nonce");
		require(getSigner(spotsDataVL) == AUTHORISED_SIGNER, "vault list: unauthorised signer");
		require(!isSignatureUsed[spotsDataVL.signature], "vault list: used signature");
		require(spotsDataVL.userAddress == msg.sender, "vault list: unauthorised address");
	
		require(MAX_MINTS_PER_SPOT_VL * spotsDataVL.allocatedSpots >= vlMintsBy[msg.sender] + amountVL, "vault list: unacceptable amount");
	
		isSignatureUsed[spotsDataVL.signature] = true;
		vlMintsBy[msg.sender] += amountVL;
		AVAILABLE_AMOUNT_FOR_VL -= amountVL;
		
		(address[] memory receiver, uint256[] memory AmountVL) = _getArray(spotsDataVL.userAddress, amountVL);
		waltsVault.airdrop(receiver, AmountVL);
	
		emit VaultListMint(msg.sender, amountVL);
	}
	
	function _publicMint(
		uint16 amountPUBLIC
	) internal {
		require(START_TIME_PUBLIC <= block.timestamp, "public: sale not started");
		require(END_TIME_PUBLIC >= block.timestamp, "public: sale over");
		require(MAX_MINTS_PER_ADDR_PUBLIC >= publicMintsBy[msg.sender] + amountPUBLIC, "public: unacceptable amount");
		publicMintsBy[msg.sender] += amountPUBLIC;
		
		(address[] memory receiver, uint256[] memory amount) = _getArray(msg.sender, amountPUBLIC);
		waltsVault.airdrop(receiver, amount);
		
		emit PublicMint(msg.sender, amountPUBLIC);
	}
	
	
	function _getArray(address userAddress, uint256 totalTokens) internal pure returns (address[] memory addressArray, uint256[] memory tokenArray) {
		addressArray = new address[](1);
		tokenArray = new uint256[](1);
		addressArray[0] = userAddress;
		tokenArray[0] = totalTokens;
	}
	

	// ======== OWNER FUNCTIONS ======== //
	
	/**
       * @notice The function is used to pause/ unpause mint functions
    */
	function togglePause() external onlyOwner {
		if (paused()) {
			_unpause();
		} else {
			_pause();
		}
	}
        
	function releaseRavendale(
		address[] calldata lockers
	) external onlyOwner {
		for(uint256 j=0; j<lockers.length; j++){
			uint256[] memory tokensToRelease = tokensLockedBy[lockers[j]];
			delete tokensLockedBy[lockers[j]];
				for(uint256 i=0; i<tokensToRelease.length; i++){
					lockerOf[tokensToRelease[i]] = address(0);
					ravendale.safeTransferFrom(address(this), lockers[j], tokensToRelease[i]);
					emit ReleaseRavendale(lockers[j], tokensToRelease[i]);
			}
		}
	}
	
	function withdraw() external onlyOwner {
		payable(TREASURY).transfer(address(this).balance);
	}
	
    function setRavendaleAddr(address _ravendale) external onlyOwner {
	    ravendale = IWaltsVaultNFT(_ravendale);
	}

    function setWaltsVaultAddr(address _waltsVault) external onlyOwner {
        waltsVault = IWaltsVaultNFT(_waltsVault);
    }
	
	function setTreasury(address _treasury) external onlyOwner {
		TREASURY = _treasury;
	}
	
	function setAuthorisedSigner(address _signer) external onlyOwner {
		AUTHORISED_SIGNER = _signer;
	}
	
	function setSignatureValidityTime(uint16 validityTime) external onlyOwner {
		SIGNATURE_VALIDITY = validityTime;
	}
	
	function setPrice(uint256 _price) external onlyOwner {
		PRICE = _price;
	}
	
	function setMaxAmtForSale(uint16 _amount) external onlyOwner {
		MAX_AMOUNT_FOR_SALE = _amount;
	}
	
	function setMaxMintsPerTokenRD(uint8 _amount) external onlyOwner {
		MAX_MINTS_PER_TOKEN_RD = _amount;
	}
	
	function setMaxMintsPerSpotVL(uint8 _amount) external onlyOwner {
		MAX_MINTS_PER_SPOT_VL = _amount;
	}
	
	function setMaxMintsPerAddrPublic(uint16 _amount) external onlyOwner {
		MAX_MINTS_PER_ADDR_PUBLIC = _amount;
	}
	
	function setStartEndTime(
		uint32 _startVL,
		uint32 _endVL,
		uint32 _startPB,
		uint32 _endPB,
		uint32 _startRD,
		uint32 _endRD
	) external onlyOwner {
		START_TIME_VL = _startVL;
		END_TIME_VL = _endVL;
		START_TIME_PUBLIC = _startPB;
		END_TIME_PUBLIC = _endPB;
		START_TIME_RD = _startRD;
		END_TIME_RD = _endRD;
	}
	
	// ======== READ FUNCTIONS ======== //

	function getTokensLockedByAddr(address addr) external view returns(uint256[] memory){
		return tokensLockedBy[addr];
	}
	
	function getTotalTokensLocked(address addr) external view returns(uint256){
		return tokensLockedBy[addr].length;
	}
	
	function getTokenLockedByIndex(address addr, uint256 index) external view returns(uint256){
		return tokensLockedBy[addr][index];
	}
	

	// ======== AUXILIARY FUNCTIONS ======== //

	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public pure virtual returns (bytes4) {
		return this.onERC721Received.selector;
	}

	// ======== UPGRADE #01 ======== //
	
	function releaseRavendale() external {
		uint256[] memory tokensToRelease = tokensLockedBy[msg.sender];
		require(tokensToRelease.length > 0, "no tokens to release");
		delete tokensLockedBy[msg.sender];
		unchecked {
			for (uint256 i = 0; i < tokensToRelease.length; i++) {
				lockerOf[tokensToRelease[i]] = address(0);
				ravendale.safeTransferFrom(address(this), msg.sender, tokensToRelease[i]);
				emit ReleaseRavendale(msg.sender, tokensToRelease[i]);
			}
		}
	}
}