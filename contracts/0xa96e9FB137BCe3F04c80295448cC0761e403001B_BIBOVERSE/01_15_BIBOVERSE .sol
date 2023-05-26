// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//  ___  ___  ___   ___  __   __ ___  ___  ___  ___
// | _ )|_ _|| _ ) / _ \ \ \ / /| __|| _ \/ __|| __|
// | _ \ | | | _ \| (_) | \ V / | _| |   /\__ \| _|
// |___/|___||___/ \___/   \_/  |___||_|_\|___/|___|


contract BIBOVERSE is Ownable, EIP712, ERC721A, ERC721AQueryable {

	using SafeMath for uint256;
	using Strings for uint256;

	// Sales variables
	// ------------------------------------------------------------------------
	uint256 public MAX_BIBO = 1990;
	uint256 public STAGE_LIMIT = 1990;
	uint256 public PRICE = 0.07 ether;
	uint256 public MAX_ADDRESS_TOKEN = 3;
	uint256 public numAirdrop = 0;
	uint256 public numGiveaway = 0;
	uint256 public numSale = 0;
	uint256 public saleTimestamp = 1672416000;

	bool public hasSaleStarted = false; 
	bool public hasAuctionStarted = false; 
	bool public haswhitelistStarted = false;
	bool public hasBurnStarted = false;

	string private _baseTokenURI = "ipfs://QmWvTvbpSPTpQKyPiqTTB245WobnXzY9QhS89xvu4KxsKD/";
	address public treasury = 0x4Fa955eDa10a162c714756485ba0f38eE2AF01ce;
	address public signer = 0x4Fa955eDa10a162c714756485ba0f38eE2AF01ce;

    // Dutch auction config
    uint256 public auctionStartTimestamp; 
    uint256 public auctionTimeStep;
    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;
    uint256 public auctionPriceStep;
    uint256 public auctionStepNumber;

	mapping (address => uint256) public hasMinted;

	// Events
	// ------------------------------------------------------------------------
	event mintEvent(address owner, uint256 quantity, uint256 totalSupply);
	
	// Constructor
	// ------------------------------------------------------------------------
	constructor()
	EIP712("BIBOVERSE", "1.0.0")
	ERC721A("BIBOVERSE", "BIBO"){}  

    // Modifiers
    // ------------------------------------------------------------------------
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }

	// Airdrop functions
	// ------------------------------------------------------------------------
	function airdrop(address[] calldata _to, uint256[] calldata quantity) public onlyOwner{
		uint256 count = _to.length;

		for (uint256 i = 0; i < count; i++){
			_safeMint(_to[i], quantity[i]);
			emit mintEvent(_to[i], quantity[i], totalSupply());
		}

		numAirdrop = totalSupply();
	}

	// Giveaway functions
	// ------------------------------------------------------------------------
	function giveaway(address _to, uint256 quantity) external onlyOwner{
		require(totalSupply().add(quantity) <= MAX_BIBO, "Exceeds MAX_BIBO.");

		_safeMint(_to, quantity);

		numGiveaway = numGiveaway.add(quantity);
		emit mintEvent(_to, quantity, totalSupply());
	}

	// Verify functions
	// ------------------------------------------------------------------------
	function verify(uint256 maxQuantity, bytes memory SIGNATURE) public view returns (bool){
		address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);

		return signer == recoveredAddr;
	}

	// Whitelist functions
	// ------------------------------------------------------------------------
	function mintWhitelist(uint256 quantity, uint256 maxQuantity, bytes memory SIGNATURE) public payable{
		require(haswhitelistStarted == true, "WHITELIST_NOT_ACTIVE");
        require(block.timestamp >= saleTimestamp, "NOT_IN_WHITELIST_TIME");
		require(totalSupply().add(quantity) <= STAGE_LIMIT, "This stage is sold out!");
		require(verify(maxQuantity, SIGNATURE), "Not eligible for whitelist.");
		require(quantity > 0 && hasMinted[msg.sender].add(quantity) <= maxQuantity, "Exceeds max whitelist number.");
		require(totalSupply().add(quantity) <= MAX_BIBO, "Exceeds MAX_BIBO.");
		require(msg.value >= PRICE.mul(quantity), "Ether value sent is not equal the price.");

		numSale = numSale.add(quantity);
		hasMinted[msg.sender] = hasMinted[msg.sender].add(quantity);

		_safeMint(msg.sender, quantity);

		emit mintEvent(msg.sender, quantity, totalSupply());
	}

	// Auction functions
	// ------------------------------------------------------------------------
    function getDutchAuctionPrice() public view returns (uint256) {
        require(hasAuctionStarted == true, "AUCTION_NOT_ACTIVE");

        if (block.timestamp < auctionStartTimestamp) {
            return auctionStartPrice;
        } else {
            // calculate step
            uint256 step = (block.timestamp - auctionStartTimestamp) / auctionTimeStep;
            if (step > auctionStepNumber) {
                step = auctionStepNumber;
            }

            // claculate final price
            if (auctionStartPrice > step * auctionPriceStep){
                return auctionStartPrice - step * auctionPriceStep;
            } else {
                return auctionEndPrice;
            }
        }
    }
	// Public and Auction functions
	// ------------------------------------------------------------------------
	function mintBIBO(uint256 quantity) external payable callerIsUser{
		if (hasAuctionStarted == true) {
			require(msg.value >= getDutchAuctionPrice().mul(quantity), "Ether value sent is not enough.");
		} else {
			require(hasSaleStarted == true, "SALE_NOT_ACTIVE");
			require(msg.value >= PRICE.mul(quantity), "Ether value sent is not enough.");
		}
		require(block.timestamp >= saleTimestamp, "NOT_IN_SALE_TIME");
		require(totalSupply().add(quantity) <= STAGE_LIMIT, "This stage is sold out!");
		require(totalSupply().add(quantity) <= MAX_BIBO, "Exceeds MAX_BIBO.");
		require(quantity > 0 && hasMinted[msg.sender].add(quantity) <= MAX_ADDRESS_TOKEN, "Exceeds MAX_ADDRESS_TOKEN.");
		
		numSale = numSale.add(quantity);
		hasMinted[msg.sender] = hasMinted[msg.sender].add(quantity);

		_safeMint(msg.sender, quantity);

		emit mintEvent(msg.sender, quantity, totalSupply());
	}

	// Base URI Functions
	// ------------------------------------------------------------------------
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

    // Burn Functions
    // ------------------------------------------------------------------------
    function burn(address account, uint256 id) public virtual {
        require(hasBurnStarted == true, "Burn hasn't started.");
        require(account == tx.origin || isApprovedForAll(account, _msgSender()), "Caller is not owner nor approved.");
		require(ownerOf(id) == account, "Caller not tokenId owner.");

        _burn(id);
    }

	// setting functions
	// ------------------------------------------------------------------------
	function setURI(string calldata _tokenURI) external onlyOwner {
		_baseTokenURI = _tokenURI;
	}

	function setTokenLimit(uint256 _STAGE_LIMIT, uint256 _MAX_ADDRESS_TOKEN) external onlyOwner {
		STAGE_LIMIT = _STAGE_LIMIT;
		MAX_ADDRESS_TOKEN = _MAX_ADDRESS_TOKEN;
	}

	function setMAX_BIBO(uint256 _MAX_num) external onlyOwner {
		MAX_BIBO = _MAX_num;
	}

	function set_PRICE(uint256 _price) external onlyOwner {
		PRICE = _price;
	}

    function setSaleSwitch(
		bool _hasSaleStarted, 
		bool _hasAuctionStarted, 
		bool _haswhitelistStarted, 
		bool _hasBurnStarted, 
		uint256 _saleTimestamp
	) external onlyOwner {
        hasSaleStarted = _hasSaleStarted;
		hasAuctionStarted = _hasAuctionStarted;
		haswhitelistStarted = _haswhitelistStarted;
		hasBurnStarted = _hasBurnStarted;
        saleTimestamp = _saleTimestamp;
    }

    function setDutchAuction(
        uint256 _auctionStartTimestamp, 
        uint256 _auctionTimeStep, 
        uint256 _auctionStartPrice, 
        uint256 _auctionEndPrice, 
        uint256 _auctionPriceStep, 
        uint256 _auctionStepNumber
    ) external onlyOwner {
        auctionStartTimestamp = _auctionStartTimestamp;
        auctionTimeStep = _auctionTimeStep;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceStep = _auctionPriceStep;
        auctionStepNumber = _auctionStepNumber;
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "SETTING_ZERO_ADDRESS");
        signer = _signer;
    }

	// Withdrawal functions
	// ------------------------------------------------------------------------
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "SETTING_ZERO_ADDRESS");
        treasury = _treasury;
    }

	function withdrawAll() public payable onlyOwner {
		require(payable(treasury).send(address(this).balance));
	}
}