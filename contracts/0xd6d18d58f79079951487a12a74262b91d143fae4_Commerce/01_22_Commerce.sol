// SPDX-License-Identifier: MIT
// @bitcoinski & @calvinhoenes
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './Abstract1155Factory.sol';
import "hardhat/console.sol";

contract Commerce is Abstract1155Factory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter; 

    mapping(uint256 => Token) public tokens;
    event Purchased(uint[] index, address indexed account, uint[] amount);
    struct Token {
        string ipfsMetadataHash;
        string extraDataUri;
        mapping(address => uint256) claimedTokens;
        mapping(uint => address) redeemableContracts;
        uint256 numRedeemableContracts;
        mapping(uint => Whitelist) whitelistData;
        uint256 numTokenWhitelists;
        MintingConfig mintingConfig;
        WhiteListConfig whiteListConfig;
        bool isTokenPack;
        TokenPackConfig tokenPackConfig;
    }
    struct MintingConfig {
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        uint256 numMinted;
    }
    struct WhiteListConfig {
        bool maxQuantityMappedByWhitelistHoldings;
        bool requireAllWhiteLists;
        bool hasMerkleRoot;
        bytes32 merkleRoot;
    }
    struct TokenPackConfig {
        uint256[] packTokens;
        bool isRandomPack;
        uint numRandom;
        uint numWhiteListBonus;
        bool allotOwnedTokenQuantity;
        bool isWhiteListBonusAggregatedAcrossAllWhiteLists;
    }
    struct Whitelist {
        string tokenType;
        address tokenAddress;
        uint mustOwnQuantity;
        uint256 tokenId;
        bool active;
    }

    string public _contractURI;
   
    constructor(
        string memory _name, 
        string memory _symbol,
        address[] memory _admins,
        string memory _contract_URI
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint i=0; i< _admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
        _contractURI = _contract_URI;
    }

     function getOpenSaleTokens() public view returns (string memory){
        string memory open = "";
        uint256 numTokens = 0;
        while(!compareStrings(tokens[numTokens].ipfsMetadataHash, "")) {
           if(isSaleOpen(numTokens)){
                open = string(abi.encodePacked(open, Strings.toString(numTokens), ","));
            }
            numTokens++;
        }
        return open;
    }

    function addToken(
        string memory _ipfsMetadataHash,
        string memory _extraDataUri,
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _maxPerWallet,
        bool _maxQuantityMappedByWhitelistHoldings,
        bool _requireAllWhiteLists,
        address[] memory _redeemableContracts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        editToken(tokenCounter.current(), _ipfsMetadataHash, _extraDataUri, _windowOpens, _windowCloses, _mintPrice, _maxSupply, _maxMintPerTxn, _maxPerWallet, _maxQuantityMappedByWhitelistHoldings, _requireAllWhiteLists, _redeemableContracts);
        tokenCounter.increment();
    }

     function editToken(
        uint256 _tokenIndex,
        string memory _ipfsMetadataHash,
        string memory _extraDataUri,
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _maxPerWallet,
        bool _maxQuantityMappedByWhitelistHoldings,
        bool _requireAllWhiteLists,
        address[] memory _redeemableContracts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        token.mintingConfig.windowOpens = _windowOpens;
        token.mintingConfig.windowCloses = _windowCloses;
        token.mintingConfig.mintPrice = _mintPrice;
        token.mintingConfig.maxSupply = _maxSupply;
        token.mintingConfig.maxMintPerTxn = _maxMintPerTxn;
        token.mintingConfig.maxPerWallet = _maxPerWallet;
        token.ipfsMetadataHash = _ipfsMetadataHash;
        token.extraDataUri = _extraDataUri;
        for (uint i=0; i<_redeemableContracts.length; i++) {
            token.redeemableContracts[i] = _redeemableContracts[i];
        }
        token.numRedeemableContracts = _redeemableContracts.length;
        token.whiteListConfig.maxQuantityMappedByWhitelistHoldings = _maxQuantityMappedByWhitelistHoldings;
        token.whiteListConfig.requireAllWhiteLists = _requireAllWhiteLists;
    }   


    function configTokenPack(
        uint256 _tokenIndex,
        bool _isTokenPack,
        uint256[] memory _packTokens,
        bool _isRandomPack,
        uint _numRandom,
        uint _numWhiteListBonus,
        bool _allotOwnedTokenQuantity,
        bool _isWhiteListBonusAggregatedAcrossAllWhiteLists
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenPackConfig storage tokenPackConfig = tokens[_tokenIndex].tokenPackConfig;
        tokens[_tokenIndex].isTokenPack = _isTokenPack;
        tokenPackConfig.packTokens = _packTokens;
        tokenPackConfig.isRandomPack = _isRandomPack;
        tokenPackConfig.numRandom = _numRandom;
        tokenPackConfig.numWhiteListBonus = _numWhiteListBonus;
        tokenPackConfig.allotOwnedTokenQuantity = _allotOwnedTokenQuantity;
        tokenPackConfig.isWhiteListBonusAggregatedAcrossAllWhiteLists = _isWhiteListBonusAggregatedAcrossAllWhiteLists;
        
    }

    function addWhiteList(
         uint256 _tokenIndex,
         string memory _tokenType,
         address _tokenAddress,
         uint _tokenId,
         uint _mustOwnQuantity
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        Whitelist storage whitelist = tokens[_tokenIndex].whitelistData[tokens[_tokenIndex].numTokenWhitelists];
        whitelist.tokenType = _tokenType;
        whitelist.tokenId = _tokenId;
        whitelist.active = true;
        whitelist.tokenAddress = _tokenAddress;
        whitelist.mustOwnQuantity = _mustOwnQuantity;
        tokens[_tokenIndex].numTokenWhitelists = tokens[_tokenIndex].numTokenWhitelists + 1;
    }

     function disableWhiteList(
       uint256 _tokenIndex,
       uint _whiteListIndexToRemove
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex].whitelistData[_whiteListIndexToRemove].active = false;
    }

   function editTokenWhiteListMerkleRoot(
       uint256 _tokenIndex,
        bytes32 _merkleRoot,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex].whiteListConfig.merkleRoot = _merkleRoot;
        tokens[_tokenIndex].whiteListConfig.hasMerkleRoot = enabled;
    } 

   
     function burnFromRedeem(
        address account, 
        uint256 tokenIndex, 
        uint256 amount
    ) external {
        Token storage token = tokens[tokenIndex];
        bool hasValidRedemptionContract = false;
         if(token.numRedeemableContracts > 0){
            for (uint i=0; i < token.numRedeemableContracts; i++) {
                if(token.redeemableContracts[i] == msg.sender){
                    hasValidRedemptionContract = true;
                }
            }
        }
        require(hasValidRedemptionContract, "b1");
        _burn(account, tokenIndex, amount);
    }  

    function purchase(
        uint256[] calldata _quantities,
        uint256[] calldata _tokenIndexes,
        uint256[] calldata _merkleAmounts,
        bytes32[][] calldata _merkleProofs
    ) external payable {

        require(!paused(), "p0");
        uint256 totalPrice = 0;
        for (uint i=0; i< _tokenIndexes.length; i++) {
            totalPrice = totalPrice.add(_quantities[i].mul(tokens[_tokenIndexes[i]].mintingConfig.mintPrice));
        }
        require(msg.value >= totalPrice, "p1");
        for (uint i=0; i< _tokenIndexes.length; i++) {
            
            uint256 quantityToMint = getQualifiedAllocation(msg.sender,_tokenIndexes[i], _quantities[i],_merkleAmounts[i],_merkleProofs[i], true); 
            require(quantityToMint > 0 && quantityToMint >= _quantities[i], "p2");
            tokens[_tokenIndexes[i]].claimedTokens[msg.sender] = tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(_quantities[i]);
            
            uint256[] memory idsToMint;
            uint256[] memory quantitiesToMint;
            if(tokens[_tokenIndexes[i]].isTokenPack){
                quantityToMint = getQualifiedAllocation(msg.sender,_tokenIndexes[i], _quantities[i],_merkleAmounts[i],_merkleProofs[i], false); 
                for (uint j=0; j < _quantities[i]; j++) {
                    uint256[] memory inStockTokens = filterInStockTokensFromPack(tokens[_tokenIndexes[i]].tokenPackConfig, j);
                    if(tokens[_tokenIndexes[i]].tokenPackConfig.isRandomPack){
                        idsToMint = new uint256[](quantityToMint);
                        quantitiesToMint = new uint256[](quantityToMint);
                        uint startingIndex = 0;
                        uint q = 0;
                        while(q < quantityToMint) {
                            idsToMint[q] = inStockTokens[startingIndex];
                            quantitiesToMint[q] = 1;
                            
                            if(startingIndex < inStockTokens.length - 1){
                                startingIndex = startingIndex + 1;
                            }
                            else{
                                startingIndex = 0;
                            }
                            q = q + 1;
                        }     

                    
                    }
                    else{
                        idsToMint = new uint256[](inStockTokens.length);
                        for (uint q=0; q < inStockTokens.length; q++) {
                            idsToMint[q] = inStockTokens[q];
                            quantitiesToMint[q] = 1;
                        }  
                    }
                    _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
                    emit Purchased(idsToMint, msg.sender, quantitiesToMint);
                    tokens[_tokenIndexes[i]].mintingConfig.numMinted = tokens[_tokenIndexes[i]].mintingConfig.numMinted + 1;

                    
                }
            }
            else{
                idsToMint = new uint256[](1);
                idsToMint[0] =  _tokenIndexes[i];
                quantitiesToMint = new uint256[](1);
                quantitiesToMint[0] = _quantities[i];
                _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
                emit Purchased(idsToMint, msg.sender, quantitiesToMint);
            }
          
        }

        
    }

     function filterInStockTokensFromPack(TokenPackConfig memory tokenPackConfig, uint seed) internal view returns(uint256[] memory){
        tokenPackConfig.packTokens = shuffle(tokenPackConfig.packTokens, false, seed);
        uint256[] memory inStockTokens;
        uint totalInStock = 0;
        for (uint i=0; i < tokenPackConfig.packTokens.length; i++) {
              if(getTokenSupply(tokenPackConfig.packTokens[i]) < tokens[tokenPackConfig.packTokens[i]].mintingConfig.maxSupply){
                 totalInStock++;
             }
         }

        inStockTokens = new uint256[](totalInStock);

        uint startingIndex = 0;
        for (uint i=0; i < tokenPackConfig.packTokens.length; i++) {
            if(getTokenSupply(tokenPackConfig.packTokens[i]) < tokens[tokenPackConfig.packTokens[i]].mintingConfig.maxSupply){
                inStockTokens[startingIndex] = tokenPackConfig.packTokens[i];
                startingIndex++;
            }
         }
        return inStockTokens;
    }

    function shuffle(uint256[] memory numberArr, bool returnRandomIndex, uint seed) internal view returns(uint256[] memory){
        if(!returnRandomIndex){
             for (uint256 i = 0; i < numberArr.length; i++) {
                uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % (numberArr.length - i);
                uint256 temp = numberArr[n];
                numberArr[n] = numberArr[i];
                numberArr[i] = temp;
            }
        }
        else{
            uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % numberArr.length;
            uint256[] memory retNumberArr = new uint256[](1);
            retNumberArr[0] = numberArr[randomHash];
            numberArr = retNumberArr;
        }
       
        return numberArr;
    }

    function mintBatch(
        address to,
        uint256[] calldata qty,
        uint256[] calldata _tokens) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mintBatch(to, _tokens, qty, "");
    }

     function getQualifiedAllocation(address sender, 
        uint256 tokenIndex,
        uint256 quantity,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool returnAllocationOnly) public view returns (uint256) {
        
        Token storage token = tokens[tokenIndex];

        if(!returnAllocationOnly){
            require(token.mintingConfig.saleIsOpen, "v1");
            require(!paused(), "v2");
            require(token.mintingConfig.windowOpens > 0, "v3");
            require (block.timestamp > token.mintingConfig.windowOpens && block.timestamp < token.mintingConfig.windowCloses, "v4");
            require(token.claimedTokens[sender].add(quantity) <= amount, "v5");
            require(token.claimedTokens[sender].add(quantity) <= token.mintingConfig.maxPerWallet, "v6");
            require(quantity <= token.mintingConfig.maxMintPerTxn, "v7");
            require(getTokenSupply(tokenIndex) + quantity <= token.mintingConfig.maxSupply, "v8");
        }
        uint256 totalAllowed = token.mintingConfig.maxPerWallet;
        if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            totalAllowed = 0;
        }

        uint256 whiteListsValidAmounts = 0;
        if(token.numTokenWhitelists > 0){
            uint256 balance = 0;
            uint256 _wl_amount = 0;
            for (uint i=0; i < token.numTokenWhitelists; i++) {
                if(token.whitelistData[i].active){
                
                    _wl_amount = verifyWhitelist(sender, tokenIndex, i, returnAllocationOnly);
                    
                    if(token.whiteListConfig.requireAllWhiteLists){
                        require( verifyWhitelist(sender, tokenIndex, i, returnAllocationOnly) > 0, "v9");
                    }
                    
                    if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
                        Whitelist memory balanceRequest;
                        balanceRequest.tokenType = token.whitelistData[i].tokenType;
                        balanceRequest.tokenAddress = token.whitelistData[i].tokenAddress;
                        balanceRequest.tokenId = token.whitelistData[i].tokenId;
                        balance = getExternalTokenBalance(sender, balanceRequest);
                        totalAllowed = balance;
                        whiteListsValidAmounts = balance;
                        
                    }
                    else{
                        whiteListsValidAmounts = _wl_amount;
                    }
                }
               
            }
        }
        else{
            whiteListsValidAmounts = token.mintingConfig.maxMintPerTxn;
        }

        if(!returnAllocationOnly){
            require(whiteListsValidAmounts > 0, "v10");

            if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            require(token.claimedTokens[sender].add(quantity) <= totalAllowed, "v11");
            }
        }
       

        if(token.whiteListConfig.hasMerkleRoot){
             require(
                verifyMerkleProof(merkleProof, tokenIndex, amount),
                "v12" 
            ); 
        }
        
        if(returnAllocationOnly){
            return whiteListsValidAmounts < quantity ? whiteListsValidAmounts : quantity;
        }
        else{
            return whiteListsValidAmounts;
        }
       
         

    }

    function verifyWhitelist(address sender, uint256 tokenIndex, uint whitelistIndex, bool returnAllocationOnly) internal view returns (uint256) {
       
       uint256 isValid = 0;
       uint256 balanceOf = 0;
       Token storage token = tokens[tokenIndex];
       Whitelist memory balanceRequest;
       balanceRequest.tokenType = token.whitelistData[whitelistIndex].tokenType;
       balanceRequest.tokenAddress = token.whitelistData[whitelistIndex].tokenAddress;
       balanceRequest.tokenId = token.whitelistData[whitelistIndex].tokenId;
       balanceOf = getExternalTokenBalance(sender, balanceRequest);
       bool meetsWhiteListReqs = (balanceOf >= token.whitelistData[whitelistIndex].mustOwnQuantity);
        if(token.isTokenPack && !returnAllocationOnly){
            if(token.tokenPackConfig.isRandomPack){
                isValid = isValid + token.tokenPackConfig.numRandom;
            }
            else{
                isValid = isValid + token.tokenPackConfig.packTokens.length;
            }

            if(token.tokenPackConfig.numWhiteListBonus > 0 && meetsWhiteListReqs){
                isValid = isValid + token.tokenPackConfig.numWhiteListBonus;
            }
            
        }
        else if(token.isTokenPack && token.tokenPackConfig.allotOwnedTokenQuantity && meetsWhiteListReqs){
            isValid = balanceOf;
            
        }
        else if(!token.isTokenPack && token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            isValid = balanceOf;
        
        }
        else if( meetsWhiteListReqs){
            isValid = token.mintingConfig.maxMintPerTxn;
        }

        if(isValid == 0 && !token.whiteListConfig.requireAllWhiteLists){
            isValid = token.mintingConfig.maxMintPerTxn;
        }
        return isValid;
    }


    function getExternalTokenBalance (address sender, Whitelist memory balanceRequest) public view returns (uint256) {
        if(compareStrings(balanceRequest.tokenType, "ERC721")){
            WhitelistContract721 _contract = WhitelistContract721(balanceRequest.tokenAddress);
            return _contract.balanceOf(sender);
        }
        else if(compareStrings(balanceRequest.tokenType, "ERC1155")){
            WhitelistContract1155 _contract = WhitelistContract1155(balanceRequest.tokenAddress);
            return _contract.balanceOf(sender, balanceRequest.tokenId);
        }
    }

    function isSaleOpen(uint256 tokenIndex) public view returns (bool) {
        Token storage token = tokens[tokenIndex];
        if(paused()){
            return false;
        }
        if(block.timestamp > token.mintingConfig.windowOpens && block.timestamp < token.mintingConfig.windowCloses){
            return token.mintingConfig.saleIsOpen;
        }
        return false;
        
    }

    function toggleSale(uint256 mpIndex, bool on) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[mpIndex].mintingConfig.saleIsOpen = on;
    }

    function makeLeaf(address _addr, uint amount) internal view returns (string memory) {
         bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked(string(s), "_", Strings.toString(amount)));
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex, uint amount) internal view returns (bool) {
        if(!tokens[mpIndex].whiteListConfig.hasMerkleRoot){
            return true;
        }
        string memory leaf = makeLeaf(msg.sender, amount);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, tokens[mpIndex].whiteListConfig.merkleRoot, node);
    }

    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(getTokenSupply(_id) > 0, "URI: na");
        if(compareStrings(tokens[_id].ipfsMetadataHash, "")){
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
        }
        else{
            return string(abi.encodePacked(tokens[_id].ipfsMetadataHash));
        }   
    } 

    function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

     function getTokenSupply(uint256 tokenIndex) public view returns (uint256) {
         Token storage token = tokens[tokenIndex];
        return token.isTokenPack ? token.mintingConfig.numMinted : totalSupply(tokenIndex);
    }
}


contract WhitelistContract1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256) {}
}

contract WhitelistContract721 {
    function balanceOf(address account) external view returns (uint256) {}
 }