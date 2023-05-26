// PABI.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PABI is ERC721Enumerable, Ownable {

	using SafeMath for uint256;

	using Counters for Counters.Counter;
	Counters.Counter private tokenIds;
	
	uint256 public maxSupply = 11001;
	uint256 public maxPresaleSupply = 700;
	uint256 public mintedPresaleSupply = 0;
	string private baseUri = "https://polyverseart.mypinata.cloud/ipfs/Qme7ALw4X1ygyDgDTMF1uvVwr8RPgkbgyPZJMkvfBCHDAc/";
	string private contractUri = "https://polyverseart.mypinata.cloud/ipfs/QmUWVASv8uBzh1ANA9Kh7yoTMr2koAxtKvdCCx59nuVY7M";
	string private beforeRevealUri = "https://polyverseart.mypinata.cloud/ipfs/QmSUu7yyFEeb6ezxYtrtHHnMdhbmRRFCNzqZPpBAdA7TrK";
	bool private isRevealed = false;

	enum SaleStatus { NotSale, PreSale, PublicSale }
	SaleStatus private saleStatus = SaleStatus.NotSale;

	uint256 public currentPrice = 0.2 ether;

	mapping (address => bool) private whiteList;
	
	uint256 private maxTokensWhitelistWallet = 2;
	uint256 private maxTokensPublicSaleWallet = 50;
	uint256 private mintLimit = 10;

	//bool public isSetStoreWallet; //init to false by default
	//address public storeWallet;//init to address(0) by default

	
	mapping (address => uint256) public walletMintedTokensPresale;
	mapping (address => uint256) public walletMintedTokensSale;
	mapping(uint256 => address) public whitelistTokensOwners;
	mapping(uint256 => uint256) public whitelistTokens;
    uint256 public whitelistTokensLength; //0 by default

	mapping (uint256 => address) private reservedTokensOwners;
	mapping (uint256 => bool) private tokenReserveStatus;
	mapping(uint256 => uint256) public reservedTokens;
    uint256 public reservedTokensLength; //0 by default

	event TokensMinted(address to, uint256 numOfToken);
    event TokensMintedPresale(address to, uint256 numOfToken);
   

	modifier onlyWhitelisted {
		require(whiteList[msg.sender], "not whitelisted");
		_;
	}

	constructor() ERC721("Polyverse Art by Idriss B.", "PABI") {}

	function _baseURI() internal view override returns (string memory) {
		return baseUri;
	}

	function reserveToken(address ownerAddr, uint256 tokenId) external onlyOwner {
		require(ownerAddr != address(0), "Reserve: Owner address invalid");
		require(tokenId > 0, "Reserve: Token Id is invalid");
		require(tokenId <= maxSupply, "Reserve: Overdue to max token Id");
		require(!_exists(tokenId), "Reserve: Token already minted");
		reservedTokensOwners[tokenId] = ownerAddr;
        reservedTokens[reservedTokensLength] = tokenId;
		reservedTokensLength++;
		tokenReserveStatus[tokenId] = true;
	}

    //all or nothing approach could fail (just can't be digested for node), and you need fall back
    //if reservedTokensLength is 100 (0..99), you can do it in 0..100, if fails do it in 
    //parts
    //0-10 (0..9)
    //10-20 (10..19)
    //and so on
    //90-100
	function airdropReservedTokens(uint256 startRange, uint256 endRange) external onlyOwner {
        require(startRange >= 0 && endRange <= reservedTokensLength,"out of range");
		for (uint256 i=startRange; i < endRange; i++) {
			uint256 tokenId = reservedTokens[i];
			address holderAddress = reservedTokensOwners[tokenId];
			if (holderAddress != address(0)) {
                _safeMint(holderAddress, tokenId);
				reservedTokensOwners[tokenId] = address(0);
			}
		}
	}


   function airdropReservedTokensByUser() external  {      
		for (uint256 i=0; i < reservedTokensLength; i++) {
			uint256 tokenId = reservedTokens[i];
			address holderAddress = reservedTokensOwners[tokenId];
			if (holderAddress == msg.sender) { //msg.sender cannot be address(0)
                _safeMint(holderAddress, tokenId);
				reservedTokensOwners[tokenId] = address(0);
			}
		}
	}

	
    function airdropReservedIsDone() external view returns(bool){
        bool status = true;
        for (uint256 i = 0; i < reservedTokensLength; i++) {
            status = status && _exists(reservedTokens[i]);
            if (!status) break;
        }
        return status;
    }

	function _availableTokenId() internal returns (uint256) {
		uint256 tokenId;
		while (tokenIds.current() < maxSupply) {
			tokenIds.increment();
			tokenId = tokenIds.current();
			if (!tokenReserveStatus[tokenId]) {
				break;
			}  
		}
		return tokenId;
	}

	function _mintToken(address to, uint256 numOfToken) internal {
		require(numOfToken > 0, "MINT: need to mint at least 1 token");
		require(numOfToken <= mintLimit, "MINT: exceed transaction limit");
		require((totalSupply() + numOfToken) <= maxSupply, "MINT: reach max supply");
		require(to != address(0), "MINT: zero address");
		for (uint256 i=0;i<numOfToken;i++) {
			uint256 tokenId = _availableTokenId();
			require(tokenId != 0, "no available token id");
			_safeMint(to, tokenId);
		}

        // we call this function from mintOwner also (not only from mintToken), 
        // mintOnwer could work at PreSale, not only at PublicSale, so we need to track this
        if (saleStatus == SaleStatus.PreSale ){
            walletMintedTokensPresale[to] += numOfToken;
        } else if (saleStatus == SaleStatus.PublicSale ) {
            walletMintedTokensSale[to] += numOfToken;
        }
		
		
		emit TokensMinted(to, numOfToken);

	}

	function mintOwner(address to, uint256 numOfToken) external onlyOwner {
		require(saleStatus != SaleStatus.NotSale, "MINT: not in Sale");
		_mintToken(to, numOfToken);
	}

	function mintPreSale(uint256 numOfToken) external payable onlyWhitelisted {
		require(saleStatus == SaleStatus.PreSale, "PreSale: not in PreSale");
		require(currentPrice.mul(numOfToken) == msg.value, "PreSale: incorrect ether amount");
		require(numOfToken > 0, "PreSale: need to mint at least 1 token");
		require(numOfToken <= mintLimit, "PreSale: exceed transaction limit");
		require(mintedPresaleSupply + numOfToken <= maxPresaleSupply, "PreSale: exceed max presale limit");
		require(walletMintedTokensPresale[msg.sender] + numOfToken <= maxTokensWhitelistWallet, "PreSale: exceed presale wallet limit");
		require((totalSupply() + numOfToken) <= maxSupply, "PreSale: reach max supply");

		for (uint256 i=0;i<numOfToken;i++) {
			uint256 tokenId = _availableTokenId();
			require(tokenId != 0, "no available token id");
			whitelistTokensOwners[tokenId] = msg.sender;
			whitelistTokens[whitelistTokensLength] = tokenId;
            whitelistTokensLength++;
		}
		walletMintedTokensPresale[msg.sender] += numOfToken;
		mintedPresaleSupply += numOfToken;
		emit TokensMintedPresale(msg.sender, numOfToken);
	}

	function mintToken(uint256 numOfToken) external payable {
		require(saleStatus == SaleStatus.PublicSale, "MINT: not in Sale");
		require(currentPrice.mul(numOfToken) == msg.value, "MINT: incorrect ether amount");
		require(walletMintedTokensSale[msg.sender] + numOfToken <= maxTokensPublicSaleWallet, "MINT: exceed wallet limit");
		_mintToken(msg.sender, numOfToken);
	}

   

    //all or nothing approach could fail (just can't be digested for node), and you need fall back
    //if whitelistTokensLength is 100 (0..99), you can do it in 0..100, if fails do it in 
    //parts
    //0-10 (0..9)
    //10-20 (10..19)
    //and so on
    //90-100
    function airdropWhitelistTokens(uint256 startRange, uint256 endRange) external onlyOwner {
		require(saleStatus == SaleStatus.PublicSale, "Public Sale is not started yet.");
        require(startRange >= 0 && endRange <= whitelistTokensLength,"out of range");
		
		for (uint256 i = startRange; i < endRange; i++) {
            _safeMint(whitelistTokensOwners[whitelistTokens[i]], whitelistTokens[i]);
		}
	}

    
    function airdropWhitelistTokensByUser() external  {
		require(saleStatus == SaleStatus.PublicSale, "Public Sale is not started yet.");
		
		for (uint256 i = 0; i < whitelistTokensLength; i++) {
			uint256 tkn = whitelistTokens[i];
			if (msg.sender == whitelistTokensOwners[tkn] && !_exists(tkn))
                _safeMint(msg.sender, tkn);
		}
	}

    function airdropWhitelistedIsDone() external view returns(bool){
        bool status = true;
        for (uint256 i = 0; i < whitelistTokensLength; i++) {
            status = status && _exists(whitelistTokens[i]);
            if (!status) break;
        }
        return status;
    }

	function getSaleStatus() public view returns (SaleStatus) {
		return saleStatus;
	}

	function getCurrentPrice() public view returns (uint256) {
		return currentPrice;
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		baseUri = newBaseURI;
	}

	function setSaleStatus(SaleStatus newStatus) external onlyOwner {
		saleStatus = newStatus;
	}
	
	function addToWhitelist(address addr) external onlyOwner {
		whiteList[addr] = true;
	}

	function addToWhitelistBulk(address[] calldata addr) external onlyOwner {
		for (uint256 i=0; i < addr.length; i++){
			whiteList[addr[i]] = true;
		}
		
	}

	function removeFromWhitelist(address addr) external onlyOwner {
		whiteList[addr] = false;
	}

	function isWhitelisted(address addr) external view returns(bool){
		return whiteList[addr];
	}

	function setCurrentPrice(uint256 newPrice) external onlyOwner {
		currentPrice = newPrice;
	}

	function setMintLimit(uint256 newLimit) external onlyOwner {
		mintLimit = newLimit;
	}

	function setMaxTokensWhitelistWallet(uint256 newLimit) external onlyOwner {
		maxTokensWhitelistWallet = newLimit;
	}

	function setMaxTokensPublicSaleWallet(uint256 newLimit) external onlyOwner {
		maxTokensPublicSaleWallet = newLimit;
	}

	function setMaxSupply(uint256 supply) external onlyOwner {
		maxSupply = supply;
	}

	function setMaxPresaleSupply(uint256 supply) external onlyOwner {
		require(supply < maxSupply, "maxPresaleSupply should be less than maxSupply");
		maxPresaleSupply = supply;
	}
    

	function withdraw() external onlyOwner {
		require(address(this).balance > 0, "no balance");
		bool success = false;
		(success, ) = (payable(msg.sender)).call{value: address(this).balance}("");
		require(success, "withdraw failed");
	}

	receive() external payable {
		require(msg.value == 0, "do not accept direct ether send"); //do not accept ether
	}

	function setContractURI(string memory newContractUri) external onlyOwner {
		contractUri = newContractUri;
	}

	function contractURI() external view returns (string memory) {
		return contractUri;
	}

	function setBeforeRevealUri(string memory newUri) external onlyOwner {
		beforeRevealUri = newUri;
	}
	function getBeforeRevealUri() external view returns (string memory) {
		return beforeRevealUri;
	}

	function setRevealStatus(bool status) external onlyOwner {
		isRevealed = status;
	}
	function getRevealStatus() external view returns (bool) {
		return isRevealed;
	}

	function tokenURI(uint256 tokenId) public  view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		if (!isRevealed){
			return beforeRevealUri;
		} else {
        	return super.tokenURI(tokenId);
		}
    }

}