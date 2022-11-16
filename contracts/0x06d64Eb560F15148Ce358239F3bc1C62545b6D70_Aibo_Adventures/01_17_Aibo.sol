//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
error MaxDarkMints();
error MaxLightMints();
//@0xSimon
contract Aibo_Adventures is ERC721AQueryable, ERC2981,Ownable,DefaultOperatorFilterer {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint constant public MAX_SUPPLY = 7799;
    uint constant public MAX_WHITELIST_SUPPLY = 4750;
    uint constant public MAX_PUBLIC_RAFFLE_SUPPLY = MAX_WHITELIST_SUPPLY + 2750;
    uint constant private MAX_PER_ALLEIGANCE = 4500;
    uint constant private INITIAL_LIGHT_MINTS = 125;
    uint private lightMintCounter = INITIAL_LIGHT_MINTS;
    //Dark Mint Counter Is Simply Total Supply - Light Mint Counter
    // uint public darkMintCounter;

    uint public presalePrice = .0077 ether;
    uint public publicRafflePrice = .0099 ether;
    uint public publicPrice = .0099 ether;
    string public baseURI;
    string public darkNotRevealedUri = "ipfs://QmPcXTQ1ycPJg1qDvFHK7oXnn37Mtj1zv2ecMRt3BwtQD7";
    string public lightNotRevealedUri = "ipfs://Qmcn85fgmFsXR5dwMrpf9ReduM7nLq6KwErdywQDwga9Pe";
    string public uriSuffix = ".json";
    uint constant private NUM_RESERVED_FOR_TEAM = 249;
    uint public maxTotalMints = 3;

    address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
    bool public revealed;
    enum SaleStatus  {INACTIVE,WHITELIST,PUBLIC_RAFFLE,PUBLIC}
    enum Alleigance {DARK,LIGHT}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;
    //0 If Dark
    //1 If Light
    mapping(uint => Alleigance) private tokenIdToAlleigance;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("Aibo Adventures", "AIBO")
    {
        //Fee Denominator is 10000 -> 9.90% = 990/10000
        _setDefaultRoyalty(_msgSender(),990);
        _mint(_msgSender(),NUM_RESERVED_FOR_TEAM);
    }

    function teamMint(address[] calldata accounts,Alleigance[] calldata alleigances) external onlyOwner {
        if(accounts.length != alleigances.length) revert ArraysDontMatch();

        //Cache Storage To Avoid Redundant SLOADs
        uint nextTokenId = _nextTokenId();
        uint numLightMints = getNumLightMints();
        uint numDarkMints = getNumDarkMints();
        
        for(uint i; i<accounts.length;){
            if(nextTokenId + 1 > MAX_SUPPLY) revert MaxMints();
            Alleigance alleigance = alleigances[i];
            if(alleigance == Alleigance.LIGHT) {
                //Safety Check To Make Sure No Side Can Have More Than 4500
                if(numLightMints + 1 > MAX_PER_ALLEIGANCE) revert MaxLightMints();
                //Set the alleigance of the token in the mapping
                // tokenIdToAlleigance[nextTokenId] = Alleigance.LIGHT;
                assembly{
                    mstore(0x00,nextTokenId)
                    mstore(0x20,tokenIdToAlleigance.slot)
                    let mappingHash := keccak256(0x00,0x40)
                    sstore(mappingHash,1)
                    //++numLightMints
                    numLightMints := add(numLightMints,1)
                }
            
            }
            else{
            //No need to set the token alleigance mapping since 0 = dark
            if(numDarkMints + 1 > MAX_PER_ALLEIGANCE) revert MaxDarkMints();
            unchecked{++numDarkMints;}

            }
         

            _mint(accounts[i],1);
            unchecked{
                ++nextTokenId;
                ++i;
            }
        }
        //Update Light Mint Counter At The End To Avoid Redundant SSTORES
        assembly{
            // lightMintCounter = numLightMints
            sstore(lightMintCounter.slot,numLightMints)
        }     
    }

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function whitelistMint(uint amount,bytes memory signature,Alleigance alleigance) external payable {
        /*
        1. Check If Whitelist
        2. Check if Next Token ID + Amount > Max Whitelist Supply
        3. Check Signer
        4. Check if number minted from user + amount > maxTotalMints
        5. If Light
            a. Check If Number of Light Mints + Amount > Max Per Alleigance
            b. For Loop to SSTORE each _nextTokenId + i in the token Alleigance Mapping
            c. Increment lightMintCounter
        5b) If Dark
            a. Check if Num Dark Mints + Amount  > Alleigance

        */
        if(saleStatus != SaleStatus.WHITELIST) revert SaleNotStarted();
        uint nextTokenId = _nextTokenId();
        if(nextTokenId + amount > MAX_WHITELIST_SUPPLY + NUM_RESERVED_FOR_TEAM) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("ABUW",_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(_numberMinted(_msgSender()) + amount > maxTotalMints) revert MaxMints();
        if(msg.value < presalePrice * amount ) revert Underpriced();

        if(alleigance == Alleigance.LIGHT) {
            uint numLightMints = getNumLightMints();
            //Safety Check To Make Sure No Side Can Have More Than 4500
            if(numLightMints + amount > MAX_PER_ALLEIGANCE) revert MaxLightMints();
            //Set the alleigance of the token in the mapping
            //tokenIdToAlleigance[nextTokenId] = Alleigance.LIGHT;
            //Set Light Counter
            assembly{
                    /*  
                    for(uint i = nextTokenId; i<amount+nextTokenId;++i){
                        tokenIdToAlleigance[i] = Alleignace.LIGHT
                    }
                    */
                  for {let i:= nextTokenId} lt(i,add(amount,nextTokenId)) {i:=add(i,1)}{
                    mstore(0x00,i)
                    mstore(0x20,tokenIdToAlleigance.slot)
                    let mappingHash := keccak256(0x00,0x40)
                    sstore(mappingHash,1)
                }
                //lightMintCounter += amount
                sstore(lightMintCounter.slot,add(numLightMints,amount))
            }
        }
        else{
            uint numDarkMints = getNumDarkMints();
            //No need to set the token alleigance mapping since 0 = dark
            //No need to ++darkMintCounter --check out getNumDarkMints() function
            if(numDarkMints + amount > MAX_PER_ALLEIGANCE) revert MaxDarkMints();

        }

        _mint(_msgSender(),amount);
    }
    function publicRaffle(uint amount,bytes memory signature,Alleigance alleigance) external payable {
        if(saleStatus != SaleStatus.PUBLIC_RAFFLE) revert SaleNotStarted();
        uint nextTokenId = _nextTokenId();

        if(nextTokenId + amount > MAX_PUBLIC_RAFFLE_SUPPLY + NUM_RESERVED_FOR_TEAM) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("ABUP",_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(_numberMinted(_msgSender()) + amount > maxTotalMints) revert MaxMints();
        if(msg.value < publicRafflePrice * amount) revert Underpriced();
          if(alleigance == Alleigance.LIGHT) {
            uint numLightMints = getNumLightMints();
            //Safety Check To Make Sure No Side Can Have More Than 4500
            if(numLightMints + amount > MAX_PER_ALLEIGANCE) revert MaxLightMints();
            //Set the alleigance of the token in the mapping
           assembly{
                    /*  
                    for(uint i = nextTokenId; i<amount+nextTokenId;++i){
                        tokenIdToAlleigance[i] = Alleigance.LIGHT
                    }
                    */
                  for {let i:= nextTokenId} lt(i,add(amount,nextTokenId)) {i:=add(i,1)}{
                    mstore(0x00,i)
                    mstore(0x20,tokenIdToAlleigance.slot)
                    let mappingHash := keccak256(0x00,0x40)
                    sstore(mappingHash,1)
                }
                //lightMintCounter += amount
                sstore(lightMintCounter.slot,add(numLightMints,amount))
            }
        }
        else{
            uint numDarkMints = getNumDarkMints();
            //No need to set the token alleigance mapping since 0 = dark
            //No need to ++darkMintCounter --check out getNumDarkMints() function
            if(numDarkMints + amount > MAX_PER_ALLEIGANCE) revert MaxDarkMints();

        }
        _mint(_msgSender(),amount);
    }
  
    function publicMint(uint amount,Alleigance alleigance) external payable {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        uint nextTokenId = _nextTokenId();
        if(nextTokenId + amount > MAX_SUPPLY) revert SoldOut();
        
        uint numMinted = _numberMinted(_msgSender());
        if(numMinted + amount > maxTotalMints) revert MaxMints();
        //Impossible To Overflow Since Supply < type(uint64).max
        if(msg.value < publicPrice*amount) revert Underpriced();
          if(alleigance == Alleigance.LIGHT) {
            uint numLightMints = getNumLightMints();
            //Safety Check To Make Sure No Side Can Have More Than 4500
            if(numLightMints + amount > MAX_PER_ALLEIGANCE) revert MaxLightMints();
            //Set the alleigance of the token in the mapping
            //Increment Light Counter
            assembly{
                  for {let i:= nextTokenId} lt(i,add(amount,nextTokenId)) {i:=add(i,1)}{
                    mstore(0x00,i)
                    mstore(0x20,tokenIdToAlleigance.slot)
                    let mappingHash := keccak256(0x00,0x40)
                    sstore(mappingHash,1)
                }
                //lightMintCounter += amount
                sstore(lightMintCounter.slot,add(numLightMints,amount))
            }
        }
        else{
            uint numDarkMints = getNumDarkMints();
            //No need to set the token alleigance mapping since 0 = dark
            //No need to ++darkMintCounter --check out getNumDarkMints() function
            if(numDarkMints + amount > MAX_PER_ALLEIGANCE) revert MaxDarkMints();

        }
        _mint(_msgSender(),amount);
    }
    function getNumMinted(address account) external view returns(uint) {
        return _numberMinted(account);
    }
    
    function getNumDarkMints() public view returns(uint){
        return _totalMinted() - lightMintCounter;
    }
    function getNumLightMints() public view returns(uint) {
        return lightMintCounter;
    }

    /// @return 0 = dark , 1 = light
    function getAlleigance(uint tokenId) public view returns(Alleigance) {
        /*
        First 125 Token IDS Are Light From Airdrop
        [0...124]
        */
        if(tokenId < 125) {
            return Alleigance.LIGHT;
        }
        //No Need To Check For Dark Tokens Since They Will Implicity Be Alleigance.DARK 
        return tokenIdToAlleigance[tokenId];
    }

    ///@dev returns an array of alleigances for lesser off-chain calls
    ///@return an array of 0s and 1s. 0 = dark , 1 = light. This array is 1-1 with the input array of tokenIds
    function getBatchAlleigances(uint[] calldata tokenIds) external view returns(Alleigance[] memory) {
        Alleigance[] memory alleigances = new Alleigance[](tokenIds.length);
        for(uint i; i<tokenIds.length;++i){
            uint tokenId = tokenIds[i];
            alleigances[i] = getAlleigance(tokenId);
        }
        return alleigances;
    }
    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setDarkNotRevealedUri(string memory _notRevealedURI) public onlyOwner {
        darkNotRevealedUri = _notRevealedURI;
    }
    
    function setLightNotRevealedUri(string memory _notRevealedURI) public onlyOwner {
        lightNotRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistOn() external onlyOwner {
        saleStatus = SaleStatus.WHITELIST;
    }
    function setPublicRaffleOn() external onlyOwner{
        saleStatus = SaleStatus.PUBLIC_RAFFLE;
    }
    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
    function setPublicPrice(uint newPrice) external onlyOwner{
        publicPrice = newPrice;
    }
    function setPresalePrice(uint newPrice) external onlyOwner {
        presalePrice = newPrice;
    }
    function setPublicRafflePrice(uint newPrice) external onlyOwner{
        publicRafflePrice = newPrice;
    }
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function setMaxTotalMints(uint newMax) external onlyOwner{
        maxTotalMints = newMax;
    }
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A,ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            //if not revealed and alleigance is dark, return darkNotRevealedURI
            if(getAlleigance(tokenId) == Alleigance.DARK){
                return darkNotRevealedUri;
            }
            //If not revealed and light , reveal lightNotRevealedURI
            else{
                return lightNotRevealedUri;
            }
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }
    

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

      function withdraw() public  onlyOwner {
        uint balance = address(this).balance;
        payable(0x9d7525BB37D50a659bA16A1Deb36a95081114F4D).transfer(balance);

    }

    function emergencySetLight(uint[] calldata tokenIds) external onlyOwner{
       for(uint i; i<tokenIds.length;++i){
        if(tokenIdToAlleigance[tokenIds[i]] == Alleigance.LIGHT) revert("Token Is Already Light");
        tokenIdToAlleigance[tokenIds[i]] = Alleigance.LIGHT;
       }
       lightMintCounter += tokenIds.length;
    }
    function emergencySetDark(uint[] calldata tokenIds) external onlyOwner {
        for(uint i; i<tokenIds.length;++i){
        if(tokenIdToAlleigance[tokenIds[i]] == Alleigance.DARK) revert("Token Is Already Dark");
        tokenIdToAlleigance[tokenIds[i]] = Alleigance.DARK;
       }
       lightMintCounter -= tokenIds.length;
    }

    function emergencySetLightMintCounter(uint newCounter) external onlyOwner{
        lightMintCounter = newCounter;
    }

    /*
    --Overrides and Opensea Filterer--
    */

    //Start Token ID at 1 To Align With JSONs and PNGs


    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A,ERC721A, ERC2981) returns (bool) {

        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
    function transferFrom(address from, address to, uint256 tokenId) public  payable override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable  override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public  payable 
        override (IERC721A,ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


   

}