// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IHorseNFT.sol";
import "./IHasHorse.sol";
import "./IRequest.sol";
import "./IMbtcSales.sol";
import "./IErc20.sol";
import "./IGrade24.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

contract HorseSales is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {

	uint256 public constant MAX_DECIMALS = 18;
	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	
    using SafeERC20Upgradeable for IErc20;
    using Counters for Counters.Counter;
	
    Counters.Counter private _tokenIds;
    IHasHorse public hasHorseContract;
    IHorseNFT public horseNFTContract;
	IRequest public requestContract;
	IMbtcSales public mbtcSalesContract;
	IGrade24 public grade24Contract;
	
    address public beneficiary;
    uint256 public whitelistStartTime;
    uint256 public whitelistEndTime;
    uint256 public publicStartTime;
    uint256 public publicEndTime;
    uint256 public redeemStartTime;
    uint256 public redeemEndTime;
    uint256 public totalTicketPurchased;
    uint256 public ticketPrice;

    //store minted unique names
    mapping(string => bool) public horseNames;
    //check for address whitelist
    mapping(address => bool) public whitelistedAddresses;
    //address => ticketCount
    mapping(address => uint256) public ticketQty;
    //address => per address ticket limit 2
    mapping(address => uint256) public myTicketCount;
	
	struct buyWithStruct {
		IErc20 buyToken;
		uint256 decimals;
	}
	
	buyWithStruct[] public buyWiths;

    function initialize(
        IHorseNFT _horseNFT,
        IHasHorse _hasHorse,
		IRequest _request,
		IMbtcSales _mbtcSales, 
		address minter,
		IErc20[] calldata _buyWiths,
		uint256[] calldata decimals
    ) public initializer {
        __Ownable_init();
		__ReentrancyGuard_init();
		__AccessControl_init();

		require(_buyWiths.length == decimals.length, "invalid accept buy tokens");

        horseNFTContract = _horseNFT;
        hasHorseContract = _hasHorse;
		requestContract = _request;
		mbtcSalesContract = _mbtcSales;

        ticketPrice = 1000 ether;
		
		_setupRole(MINTER_ROLE, minter);
		
		for(uint256 i=0; i < _buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			require(decimals[i] == 18, "wrong decimal");
			buyWiths.push( buyWithStruct(_buyWiths[i], decimals[i]) );
		}
    }
	
	function acceptBuyTokens(IErc20[] calldata _buyWiths, uint256[] calldata decimals) public onlyOwner {
		require(_buyWiths.length == decimals.length, "invalid accept buy tokens");
		
		delete buyWiths;
		
		for(uint256 i=0; i < _buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			require(decimals[i] == 18, "wrong decimal");
			buyWiths.push( buyWithStruct(_buyWiths[i], decimals[i]) );
		}
	}

	function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

	function setGrade24Contract(IGrade24 _grade24) public onlyOwner {
        grade24Contract = _grade24;
    }
	
    function setHorseNFTContract(IHorseNFT _horseNFT) public onlyOwner {
        horseNFTContract = _horseNFT;
    }

    function setHasHorseContract(IHasHorse _hasHorseContract) public onlyOwner {
        hasHorseContract = _hasHorseContract;
    }

    function setWhitelistPeriod(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
	
        require(_endTime > _startTime, "invalid time");
		
        whitelistStartTime = _startTime;
        whitelistEndTime = _endTime;
    }

    function setSalesPeriod(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
    {
        require(_endTime > _startTime, "invalid time");
		require(_startTime > whitelistEndTime, "invalid time");
		
        publicStartTime = _startTime;
        publicEndTime = _endTime;
    }

    function setRedeemPeriod(uint256 _startTime, uint256 _endTime)
        public
        onlyOwner
    {
        require(_endTime > _startTime, "invalid time");
		require(_startTime > publicStartTime, "invalid time");
		
        redeemStartTime = _startTime;
        redeemEndTime = _endTime;
    }

    function addUsersToWhitelist(address[] memory _addressToWhitelist)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addressToWhitelist.length; i++) {
            whitelistedAddresses[_addressToWhitelist[i]] = true;
        }
    }

    function removeUserFromWhitelist(address[] memory _addressToWhitelist)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addressToWhitelist.length; i++) {
            whitelistedAddresses[_addressToWhitelist[i]] = false;
        }
    }

    function buyTicket(IErc20 buyWith, uint256 quantity, address referrer) public nonReentrant  {
	
		IErc20 selectedToken;
		uint256 selectedDecimals;
		
		require(buyWith != IErc20(address(0)), "invalid buy token");
        
		if (block.timestamp >= whitelistStartTime && block.timestamp <= whitelistEndTime) {
			require(whitelistedAddresses[msg.sender], "not whitelister");
            require(totalTicketPurchased + quantity <= 1000, "whitelist limit reached");
        } else if (block.timestamp >= publicStartTime && block.timestamp <= publicEndTime) {
            require(totalTicketPurchased + quantity <= 2500, "total supply reached");
        } else {
			revert("sales not available");
		}
       
        require(myTicketCount[msg.sender] + quantity <= 2, "2 nfts per address");
		
		for(uint256 i=0; i < buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			if (buyWiths[i].buyToken == buyWith) {
				selectedToken = buyWiths[i].buyToken;
				selectedDecimals = buyWiths[i].decimals;
				break;
			}
		}
		
		require(selectedToken != IErc20(address(0)), "buy token not found");
		
		uint256 reqTokenAmount;
		if (keccak256(bytes(selectedToken.name())) == keccak256(bytes("MTBTC"))) {
			uint256 mbtcPrice = mbtcSalesContract.getSellPrice();
			/*
			1 mtbtc = 0.008 usd
			1 ticket = 1000 usd or 125000 mtbtc(1000/0.008)
			*/
			reqTokenAmount = (quantity * ticketPrice / mbtcPrice);
		} else {
			reqTokenAmount = (quantity * ticketPrice);
		}
		
		require(reqTokenAmount > 0, "precision error");
		
        ticketQty[msg.sender] += quantity;
        myTicketCount[msg.sender] += quantity;
        totalTicketPurchased += quantity;
		
        selectedToken.safeTransferFrom(msg.sender, beneficiary, reqTokenAmount);
		
		if (!grade24Contract.isRegistered(msg.sender)) {
			grade24Contract.registerExt(msg.sender, referrer);
		}
		
		grade24Contract.updateTicketP(msg.sender, int256(quantity));
    }
	
	modifier onlyIfValidName(string memory horseName) {
		require(!horseNames[horseName], "name duplicated");
		_;
	}
	
	modifier onlyIfGranted( uint8 v, bytes32 r, bytes32 s, bytes32 hashMsg ) {
		address recoveredSigner = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX, hashMsg)), v, r, s);
		require(hasRole(MINTER_ROLE, recoveredSigner), "unauthorized");
		_;
	}
	
	modifier onlyIfValidRequest( uint256 requestId, uint256 timestamp) {
		require(timestamp >= block.timestamp, "expired");
		require(!requestContract.get(requestId), "request duplicated");
		_;
	}
	
	function becomeSuperHorse(
		uint256 requestId,
        uint256 tokenId,
		uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyIfValidRequest(requestId, timestamp) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, requestId, timestamp))) {
		
		(address owner, , IHasHorse.Horse memory thisHorse, ) = getInfo(tokenId);
		
		require(!thisHorse.isSuperHorse, "it is superhorse");
		require(owner == msg.sender, "wrong owner");
		
		requestContract.add(
			requestId, 
			abi.encode(tokenId),
			abi.encode(true)
		);
		hasHorseContract.becomeSuperHorse(tokenId);

    }
	
	//breed method#1
    function redeemTicket(
        IHasHorse.Horse memory horse,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant onlyIfValidName(horse.name) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, horse.name, timestamp))) returns (uint256) {
		
        require(block.timestamp >= redeemStartTime && block.timestamp <= redeemEndTime, "redeem period ended");
        require(ticketQty[msg.sender] > 0, "insufficient ticket");
		
        _tokenIds.increment();
        ticketQty[msg.sender] -= 1;
		_breedHorse(_tokenIds.current(), horse);
		
        return _tokenIds.current();
    }
	
	//breed method#2
    function standardBreed(
		uint256 requestId,
        IHasHorse.Horse memory horse,
        uint256 parentTokenId,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant onlyIfValidName(horse.name) onlyIfValidRequest(requestId, timestamp) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, requestId, horse.name, timestamp))) returns (uint256) {
		
		require(ownerOf(parentTokenId) == msg.sender, "wrong owner");
		
		_tokenIds.increment();
		
		requestContract.add(
			requestId, 
			abi.encode(horse, parentTokenId),
			abi.encode(_tokenIds.current())
		);
		
        _burnHorse(parentTokenId);
        _breedHorse(_tokenIds.current(), horse);
		
		grade24Contract.updateBreedP(msg.sender, 1);
		
        return _tokenIds.current();
    }

	//breed method#3
    function superBreed(
		uint256 requestId,
        IHasHorse.Horse memory horse,
		uint256 parentTokenId,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant onlyIfValidName(horse.name) onlyIfValidRequest(requestId, timestamp) onlyIfGranted(v, r, s, keccak256(abi.encodePacked(this, msg.sender, requestId, horse.name, timestamp))) returns (uint256) {
		
		(address owner, , IHasHorse.Horse memory thisHorse, IHasHorse.SuperHorse memory superHorse) = getInfo(parentTokenId);
		
		require(thisHorse.isSuperHorse, "not superhorse");
		bool ownBreed;
		if (owner == msg.sender) { //own breed
			require(superHorse.ownBreed==0, "own breed over");
			ownBreed = true;
		} else { //rent out
			ownBreed = false;
		}
		
		hasHorseContract.maintainSuperBreed(parentTokenId, ownBreed);
        
		_tokenIds.increment();
		
		requestContract.add(
			requestId, 
			abi.encode(horse, parentTokenId),
			abi.encode(_tokenIds.current())
		);
		
        _breedHorse(_tokenIds.current(), horse);
		
		grade24Contract.updateBreedP(msg.sender, 1);
		
        return _tokenIds.current();
    }

    function _breedHorse(
        uint256 newItemId,
        IHasHorse.Horse memory horse
    ) internal {
        horseNFTContract.mint(newItemId, msg.sender);
        horseNames[horse.name] = true;
		hasHorseContract.setHorse(newItemId, horse);
    }

    function withdrawToken(IErc20 _token) public onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(tokenBalance > 0, "insufficient token");
        _token.safeTransfer(msg.sender, tokenBalance);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getCurrentTokenId() public view onlyOwner returns (uint256) {
        return _tokenIds.current();
    }

    function getInfo(uint256 _tokenId)
        public
        view
        returns (
            address,
            string memory,
            IHasHorse.Horse memory,
			IHasHorse.SuperHorse memory
        )
    {
        address _addressOwner = ownerOf(_tokenId);
        string memory _tokenURI = tokenURI(_tokenId);
        (IHasHorse.Horse memory _horse, IHasHorse.SuperHorse memory _superHorse) = hasHorseContract.getHorse(_tokenId);
        return (_addressOwner, _tokenURI, _horse, _superHorse);
    }

    //horseNFTContract function callers
	 function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return horseNFTContract.tokenURI(tokenId);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return horseNFTContract.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = horseNFTContract.ownerOf(tokenId);
        return owner;
    }

    function _burnHorse(uint256 tokenId) internal {
        hasHorseContract.burnHorse(tokenId);
        horseNFTContract.burn(tokenId);
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