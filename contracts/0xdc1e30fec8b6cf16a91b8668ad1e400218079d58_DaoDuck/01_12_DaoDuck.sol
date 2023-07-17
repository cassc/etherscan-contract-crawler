// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract DaoDuck is ERC721, Ownable {

    bool public ON_SALE;    
    bool public ON_PRESALE;
    bool public ON_HATCH;
    bool public ON_MUTATION;

    uint256 public TOKEN_PRICE = 0.05 ether;
    uint256 public totalPublicMinted = 0;
    uint256 public totalMutantMinted = 0;
    uint256 public totalTokens = 0;
    uint256 public MAX_TOKENS_PER_WALLET = 2;
    uint256 public MAX_TOKENS_PER_WALLET_PRESALE = 1;
    uint256 public MAX_PUBLIC = 299;
    uint256 public firstMintedToken = 1001;
    uint256 public firstMutantToken = 10001;

    address proxyRegistryAddress;
    string private BASE_URI = "https://enefte.info/duckdao/?token_id=";
        
    mapping(address => uint256) public mintsForWallet;  
    mapping(address => uint256) public presaleMintsForWallet;  

    //live
    IERC1155 public OPENSEA_STORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);

    mapping(uint256 => bool) public mutatedDucks;
    mapping(uint256 => bool) public hatchedGenesis;
    mapping(uint256 => uint256) public mintedEggs;
    mapping(address => bool) public presaleWhitelist;
    
    constructor(address _proxyRegistryAddress) ERC721("DaoDuck", "DUCK") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    
    //starting at firstMintedToken
    function mint(uint256 numberOfTokens) external payable  {
        require(ON_SALE, "not on sale");
        require(totalPublicMinted + numberOfTokens <= MAX_PUBLIC, "Not enough");
        require(mintsForWallet[msg.sender] + numberOfTokens <= MAX_TOKENS_PER_WALLET, "Not enough left");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');

        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(msg.sender, firstMintedToken+totalPublicMinted+i);
        }
        totalPublicMinted += numberOfTokens;
        totalTokens += numberOfTokens;
        mintsForWallet[msg.sender] += numberOfTokens;
    }

    //starting at firstMintedToken
    function mintPresale(uint256 numberOfTokens) external payable  {
        require(ON_PRESALE, "not on presale");
        require(totalPublicMinted + numberOfTokens <= MAX_PUBLIC, "Not enough");
        require(presaleWhitelist[msg.sender], "not on whitelist");
        require(presaleMintsForWallet[msg.sender] + numberOfTokens <= MAX_TOKENS_PER_WALLET_PRESALE, "Not enough left");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');

        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(msg.sender, firstMintedToken+totalPublicMinted+i);
        }
        totalPublicMinted += numberOfTokens;
        totalTokens += numberOfTokens;
        presaleMintsForWallet[msg.sender] += numberOfTokens;
    }

    // starting at 0
	function hatch(uint256 _tokenId) external {
        require(ON_HATCH, "not on hatching");        
        if(_tokenId > 100000){
            require(isValidDuck(_tokenId),"not valid duck");
            require(OPENSEA_STORE.balanceOf(msg.sender, _tokenId) > 0,"not own duck");
            uint256 id = returnCorrectId(_tokenId);
            require(!hatchedGenesis[100000+id],"duck already hatched");
            _safeMint(msg.sender, id);
            hatchedGenesis[100000+id] = true;
            totalTokens += 1;
        }else{
            require(!hatchedGenesis[_tokenId],"duck already hatched");
            require(mintedEggs[_tokenId] > 0,"duck not hatchable");
            _safeMint(msg.sender, mintedEggs[_tokenId]);
            hatchedGenesis[_tokenId] = true;
            totalTokens += 1;
        }
	} 

	function mutate(uint256 _tokenId) external {
        require(ON_MUTATION, "not on mutation");
        if(_tokenId > 100000){
            require(isValidDuck(_tokenId),"not valid duck");
            require(OPENSEA_STORE.balanceOf(msg.sender, _tokenId) > 0,"not own duck");
            uint256 id = returnCorrectId(_tokenId);
            require(!mutatedDucks[100000+id],"duck already mutated");
            _safeMint(msg.sender, firstMutantToken+totalMutantMinted+1);
            mutatedDucks[100000+id] = true;
            totalTokens += 1;
            totalMutantMinted += 1;
        }else{
            require(!mutatedDucks[_tokenId],"duck already mutated");
            //require(mintedEggs[_tokenId] > 0,"duck not mutatable");
            _safeMint(msg.sender, firstMutantToken+totalMutantMinted+1);
            mutatedDucks[_tokenId] = true;
            totalTokens += 1;
            totalMutantMinted += 1;
        }
	} 
    
    function airdrop(uint256 numberOfTokens, address userAddress) external onlyOwner {
        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(userAddress, firstMintedToken+totalPublicMinted+i);
        }
        totalPublicMinted += numberOfTokens;
        totalTokens += numberOfTokens;
    }
    
    function addToWhitelist(address[] calldata whitelist) external onlyOwner {
        for(uint256 i = 0; i < whitelist.length; i+=1) {
            presaleWhitelist[whitelist[i]] = true;
        }
    }
    
    function addToMintedEggs(uint256 duckId, uint256 hatchId) public onlyOwner {
        mintedEggs[duckId] = hatchId;
    }

    function startPreSale() external onlyOwner {
        ON_PRESALE = true;
    }
    function stopPreSale() external onlyOwner {
        ON_PRESALE = false;
    }
    function startSale() external onlyOwner {
        ON_SALE = true;
    }
    function stopSale() external onlyOwner {
        ON_SALE = false;
    }
    function startHatch() external onlyOwner {
        ON_HATCH = true;
    }
    function stopHatch() external onlyOwner {
        ON_HATCH = false;
    }
    function startMutate() external onlyOwner {
        ON_MUTATION = true;
    }
    function stopMutate() external onlyOwner {
        ON_MUTATION = false;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxPublic(uint256 maxTokens) external onlyOwner {
        MAX_PUBLIC = maxTokens;
    }
    function setMaxPerWallet(uint256 maxTokens) external onlyOwner {
        MAX_TOKENS_PER_WALLET = maxTokens;
    }
    function setMaxPerWalletPresale(uint256 maxTokens) external onlyOwner {
        MAX_TOKENS_PER_WALLET_PRESALE = maxTokens;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
    }


    function isValidDuck(uint256 _id) internal pure returns(bool) {
		if (_id >> 96 != 0x000000000000000000000000ed40624deb1202e63d0729b6411ffa0efb333ad9)
			return false;

		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;

		uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
	    if (id > 120)
			return false;
		return true;
	}
    

	function returnCorrectId(uint256 _id) internal pure returns(uint256) {
        // should return the ID we want to MINT
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
        if(_id <= 35){
		    return _id-5;
        }else if(_id <= 56){
		    return _id-6;
        }else if(_id == 57){
		    return 53;
        }else if(_id == 58){
		    return 51;
        }else if(_id == 59){
		    return 52;
        }else if(_id == 60){
		    return 55;
        }else if(_id == 61){
		    return 56;
        }else if(_id <= 65){
		    return _id-5;
        }else if(_id == 66){
		    return 54;
        }else if(_id == 67){
		    return 70;
        }else if(_id == 68){
		    return 69;
        }else if(_id == 69){
		    return 66;
        }else if(_id == 71){
		    return 62;
        }else if(_id == 72){
		    return 63;
        }else if(_id == 73){
		    return 67;
        }else if(_id == 74){
		    return 68;
        }else if(_id == 75){
		    return 64;
        }else if(_id == 78){
		    return 61;
        }else if(_id == 79){
		    return 65;
        }else if(_id == 80){
		    return 71;
        }else if(_id == 82){
		    return 75;
        }else if(_id == 83){
		    return 79;
        }else if(_id == 84){
		    return 80;
        }else if(_id == 86){
		    return 73;
        }else if(_id == 92){
		    return 72;
        }else if(_id == 91){
		    return 74;
        }else if(_id == 90){
		    return 78;
        }else if(_id == 88){
		    return 77;
        }else if(_id == 87){
		    return 76;
        }else if(_id == 93){
		    return 81;
        }else if(_id == 94){
		    return 82;
        }else if(_id == 95){
		    return 83;
        }else if(_id == 102){
		    return 84;
        }else if(_id == 103){
		    return 85;
        }else if(_id == 97){
		    return 86;
        }else if(_id == 98){
		    return 87;
        }else if(_id == 99){
		    return 88;
        }else if(_id == 100){
		    return 89;
        }else if(_id == 101){
		    return 90;
        }else if(_id == 104){
		    return 91;
        }else if(_id == 105){
		    return 92;
        }else if(_id == 106){
		    return 93;
        }else if(_id == 107){
		    return 94;
        }else if(_id == 108){
		    return 95;
        }else if(_id == 109){
		    return 96;
        }else if(_id == 110){
		    return 97;
        }else if(_id == 111){
		    return 98;
        }else if(_id == 112){
		    return 99;
        }else if(_id == 113){
		    return 100;
        }else if(_id == 114){
		    return 101;
        }else{
            return _id;
        }
	}    

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 tokenid;
            uint256 index;
            for (tokenid = 0; tokenid < totalTokens; tokenid++) {
                if(_exists(tokenid)){
                    if(_owner == ownerOf(tokenid)){
                        result[index]=tokenid;
                        index+=1;
                    }
                }
            }
            delete index;
            return result;
        }
    }

    function totalSupply() public view virtual returns(uint256){
        return totalTokens;
    }
    
    

}