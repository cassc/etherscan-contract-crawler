// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721OBI.sol";

//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
//  ONCHAIN BLOCK INVADERS - Mint contract



interface IMotherShip  {
    function isMotherShip() external pure returns (bool);
    function launchPad(uint256 tokenId,uint8 idx1,uint8 idx2,uint8 cnt1,uint8 cnt2 ) external view returns (string memory);
}

contract BlockInvaders is ERC721OBI, Ownable, ReentrancyGuard {
    
    struct globalConfigStruct {
        uint8  skinIndex;
        uint8  colorIndex;
    }

    globalConfigStruct globalConfig;
    
    //Mint Related
    uint256 public constant MAX_PER_TX                   = 1;
    uint256 public FOUNDERS_RESERVE_AMOUNT               = 250;
    uint256 public constant MAX_SUPPLY                   = 9750;
    uint256 private isMintPaused = 0;


    //Accountability 
    //Future Skin and color Morph Mint
    uint256 public MORPH_MINT_PRICE;
    address obiAccount;
    address artistAccount;
    uint256 artistPercentage;
    uint256 private morphMintPhase = 0;
   
    //white List
    bytes32 public whiteListRoot;
    mapping(address => uint256) private _addressToMinted; 
        
    
    //Mapping from token index to Address
    //this will give the Token Owner the ability to switch betwen upgradable Contracts
    mapping(uint256 =>address) private _tokenIndexToAddress;
    
    //Events 
    event ConnectedToMotherShip(address motherShipAddress);
    event ContractPaused();
    event ContractUnpaused();
    event MintNewSkinPaused();
    event MintNewSkinUnpaused();
    event whiteListRootSet();
    event mintPriceSet();


//Implementation
    constructor() ERC721OBI("Onchain Block Invaders", "OBI") {
        //initialize the collection
        _mint(_msgSender(),0);
    } 

// deployment related 
//===============================   
    //Acknowledge contract is `BlockInvaders` :always true
    function isBlockInvaders() external pure returns (bool) {return true;}
    
    
    function setTeleporterAddress(address _motherShipAddress,uint8 _skinIndex,uint8 _indexColor) public onlyOwner {
        
        IMotherShip  motherShip = IMotherShip (_motherShipAddress);
        // Verify that we have the appropriate address
        require( motherShip.isMotherShip() );

        //prepare the new skin and/or color pallete for morph mint
        globalConfig.skinIndex    =  _skinIndex;
        globalConfig.colorIndex   =  _indexColor;

        //store the address of the mothership contract per skin
        _tokenIndexToAddress[globalConfig.skinIndex] =  _motherShipAddress;

        emit ConnectedToMotherShip(_tokenIndexToAddress[globalConfig.skinIndex]);
    } 

    function getRenderingContract(uint256 skinIdx) public view returns (address) {
        if (_tokenIndexToAddress[skinIdx] == address(0)) {
            return address(0);
        }
        return _tokenIndexToAddress[skinIdx];
    }

    function getGlobalConfig() public view returns (address,uint8,uint8) {
        return (_tokenIndexToAddress[globalConfig.skinIndex],globalConfig.skinIndex,globalConfig.colorIndex);
    }

// ERC721 related
//===============================   

    function tokenOfOwnerByIndex(address owner, uint256 index) public view  returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721: owner index out of bounds");
        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i].account){
                if(count == index) return i;
                else count++;
            }
        }
        revert("ERC721: owner index out of bounds");
    }
    
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]].account != account)
                return false;
        }

        return true;
    }
    
    function getOwnerTokens(address owner) public view  returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) return new uint256[](0);
  
        uint256[] memory tokensId = new uint256[](tokenCount);
     
        uint k;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i].account){
                tokensId[k]=i;
                k++;
            }
        }
        return tokensId;
    }

    function totalSupply() public view  returns (uint256) {
        return _owners.length;
    }

// Contract Actions
//===============================   
   
    function unpauseMint(uint256 _mintType) public onlyOwner {
        isMintPaused = _mintType;
        emit ContractUnpaused();
    }

    function getMintPhase() public view returns (uint256) {
        return isMintPaused;
    }
    
    function unpauseMorph(uint256 _morphType) public onlyOwner {
        morphMintPhase = _morphType;
    }

    function getMorphPhase() public view returns (uint256) {
        return morphMintPhase;
    }

// merkleTree 
//===============================       
    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }
    
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whiteListRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof) public view returns (string memory) {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(allowance, payload), proof), "OBI: Merkle Tree proof supplied.");
        return allowance;
    }

    function setWhiteListRoot(bytes32 _whiteListRoot) external onlyOwner {
        whiteListRoot = _whiteListRoot;
        emit whiteListRootSet();
    }

// skins and chromas related
//===============================   
      
    //1.returns the total number of skins or color for a given skin or color index [flag = 0 - skin, 1 - color]
    function getMorphTotalSupply(uint8 id,uint256 flag) public view returns (uint256) {
        require((id >=0) && (id<32), "OBI: invalid ID.Should be [0-31].");
        uint256 k=0;
        for(uint256 tknID = 0; tknID < _owners.length; tknID++){
            uint32 bitmap = _owners[tknID].bitmap1;
            if (flag == 1){
                bitmap = _owners[tknID].bitmap2;
            }
            if( isBitSet(bitmap,id)==true ){
                k++;
            }
        }
        return k;
    }
    
    //2.returns the active index for skins or color for a token, [flag = 0 - skin, 1 - color]
    function getActiveMorphIdxByToken(uint256 tokenId,uint256 flag) public view returns (uint8){
        require(tokenId < _owners.length, "OBI: invalid token ID.");
        uint8 idx = _owners[tokenId].idx1;
        if (flag == 1){
                idx = _owners[tokenId].idx2;
        }
        return idx;
    }
    
    //3.returns a list of active index for skins or color for a token list, [flag = 0 - skin, 1 - color]
    function getActiveMorphIdxByTokenLst(uint256[] calldata tokensIdList,uint256 flag) public view returns (uint8[] memory){
        uint8[] memory activeIdxList = new uint8[](tokensIdList.length);
        for(uint256 id = 0; id < tokensIdList.length; id++){
            uint256 tokenId = tokensIdList[id];
            require(tokenId < _owners.length, "OBI: invalid token ID.");
            activeIdxList[id] =  _owners[tokenId].idx1;
            if (flag == 1){
                activeIdxList[id] =  _owners[tokenId].idx2;
            }
        }
        return activeIdxList;
    }
    
    //4.returns the map of skins or color for a token, [flag = 0 - skin, 1 - color]
    function getMorphMapByToken(uint256 tokenId,uint256 flag) public view returns (uint32){
        require(tokenId < _owners.length, "OBI: invalid token ID.");
        if (flag == 0){
        return _owners[tokenId].bitmap1;
        }
        else{
            return _owners[tokenId].bitmap2;
        }
    }
    
    //5.returns a list of tokens that have the selected skin or color for a token list, [flag = 0 - skin, 1 - color]
    function getOBIforIdx(uint256[] calldata tokensIdList,uint8 idx,uint256 flag) public view returns (uint256[] memory) {
        require((idx >=0) && (idx<32), "OBI: invalid IDX.Should be [0-31].");
        uint256 count=0;
        for(uint256 id = 0; id < tokensIdList.length; id++)
        {
            uint256 tokenID = tokensIdList[id];
            uint32 bitmap = _owners[tokenID].bitmap1;
            if (flag == 1){
                bitmap = _owners[tokenID].bitmap2;
            }
            if ( isBitSet(bitmap,idx) == true )
            {
                count ++;
            }
        }
        uint256 k=0;
        uint256[] memory tokenList = new uint256[](count);
        for(uint256 id = 0; id < tokensIdList.length; id++){
           uint256 tokenID = tokensIdList[id];
           uint32 bitmap = _owners[tokenID].bitmap1;
           if (flag == 1){
                bitmap = _owners[tokenID].bitmap2;
            }
           if(isBitSet(bitmap,idx) ){
                tokenList[k] = tokenID;
                k++;
           }
        }
        return tokenList;
    }

    //6.returns the list skins owned by token 
    function getOBISkinListByToken(uint256 tokenId) public view returns (uint8[] memory) {
        require(tokenId < _owners.length, "OBI: invalid token id.");
        uint32 count=countSetBits(_owners[tokenId].bitmap1);
        uint8[] memory skinList = new uint8[](count);
        uint8 k = 0;
        for(uint8 i=0; i <32; i++) {
            if(isBitSet(_owners[tokenId].bitmap1,i)){
                skinList[k] = i;
                k++;
            }
        }
        return skinList;
    }

    //7.returns the list of colors owned by token 
    function getOBIColorListByToken(uint256 tokenId) public view returns (uint8[] memory) {
        require(tokenId < _owners.length, "OBI: invalid token id.");
        uint32 count=countSetBits(_owners[tokenId].bitmap2);
        uint8[] memory colorList = new uint8[](count);
        uint8 k = 0;
        for(uint8 i=0; i <32; i++) {
            if(isBitSet(_owners[tokenId].bitmap2,i)){
                colorList[k] = i;
                k++;
            }
        }
        return colorList;
    }

    //Strict Validation for payed Mint
    function _validateMorphList(uint256[] calldata tokensIdList) internal view  {
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");
            require(msg.sender == _owners[tokenID].account, "OBI: You are not the owner of one of the OBI.");
            
            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            require( ( hasSkin == false) || (hasColor == false), "OBI: One of the OBI is already Morph Minted.");
        }
    }
    //Light Validation for free Mint,morph transform
    function _validateLightMorphList(uint256[] calldata tokensIdList) internal view  {
        uint256 count = 0;
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");
            require(msg.sender == _owners[tokenID].account, "OBI: You are not the owner of one of the OBI.");

            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            if ( ( hasSkin == true) && (hasColor == true))
            {
                count++;
            }
        }
        require(  count < tokensIdList.length , "OBI: All the OBIs are up to date");
    }

    function _updateMorphList(uint256[] calldata tokensIdList) internal   {
        for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex) == false ){
                _owners[tokenID].cnt1 ++;
                _owners[tokenID].bitmap1 = setBit(_owners[tokenID].bitmap1, globalConfig.skinIndex);
            }
                _owners[tokenID].idx1 =  globalConfig.skinIndex;
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex) == false ){
                _owners[tokenID].cnt2 ++;
                _owners[tokenID].bitmap2 = setBit(_owners[tokenID].bitmap2, globalConfig.colorIndex);
            }
               _owners[tokenID].idx2 = globalConfig.colorIndex;
        }
    }
   
    //change the owned Skins or owned Colors for OBI
    function morphOBI(uint256[] calldata tokensIdList,uint8 skinNr,uint8 colorNr) public {
       //validation
       require((skinNr >=0) && (skinNr<32), "OBI: invalid skinNr.Value must be between [0-31]");
       require((colorNr >=0) && (colorNr<32), "OBI: invalid colorNr.Value must be between [0-31]");
       
       //Validate Morph
       for(uint256 id; id < tokensIdList.length; id++){
        uint256 tokenID = tokensIdList[id];
        require(tokenID < _owners.length, "OBI: invalid token id");
        require(msg.sender == _owners[tokenID].account, "OBI: You ar e not the owner of one of the OBI");
       } 
       //Morph the OBIS
       for(uint256 id; id < tokensIdList.length; id++){
            uint256 tokenID = tokensIdList[id];
            //update skin if you own it
            if ( isBitSet(_owners[tokenID].bitmap1,skinNr) == true ){
                if ( _owners[tokenID].idx1 != skinNr){ //check if not already set,maybe save some gas
                  _owners[tokenID].idx1 =skinNr;
                }
            }
            //update color if you own it
            if ( isBitSet(_owners[tokenID].bitmap2,colorNr) == true ){
                if ( _owners[tokenID].idx2 != colorNr){ //check if not already set,maybe save some gas
                _owners[tokenID].idx2 = colorNr;
                }
            }
       }
    }
//OBI Mint
//=============================== 
    
    function mintWhitelist(uint256 _count, uint256 allowance, bytes32[] calldata proof) external nonReentrant {
        require(isMintPaused == 1, "OBI List Mint is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + _count <= MAX_SUPPLY, "OBI: All OBIs have been minted.");
        require(_verify(_leaf(Strings.toString(allowance), payload), proof), "OBI:Your are not on the OBI List.");
        require(_count > 0 && _addressToMinted[_msgSender()] + _count <= allowance, "OBI:Exceeds OBIList supply"); 
        require(msg.sender == tx.origin);
        
        _addressToMinted[_msgSender()] += _count;

        for(uint i=0; i < _count; i++) { 
            _mint(_msgSender(), _totalSupply + i);
        }
    }
    
    //mint only 1 OBI per Wallet on Public Mint
    function mintPublic() external nonReentrant   {
        
        require(isMintPaused == 2, "OBI: Public Mint is not active");
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + 1 <= MAX_SUPPLY, "OBI: All OBIs have been minted.");
        require(msg.sender == tx.origin);
        
        uint256 _ownedCount = balanceOf(_msgSender());
        require(_ownedCount < ( _addressToMinted[_msgSender()]+ 1 ), "OBI: Exceeds max OBIs per wallet.");
             
        _mint(_msgSender(), _totalSupply);
        
    }

    //only allowed for OBI Founders to mint according to the FOUNDERS_RESERVE_AMOUNT
    //this supply will be allocated equaly to each OBI Founder
    //or some part of the supply will be used for giveaways
    function mintDev(uint256 tknQuantity)  external onlyOwner nonReentrant {
            require(tknQuantity <= FOUNDERS_RESERVE_AMOUNT, "OBI:more tokens requested than founders reserve");
            uint256 _totalSupply = totalSupply();
            FOUNDERS_RESERVE_AMOUNT -= tknQuantity;
            for(uint256 i=0; i < tknQuantity; i++)
                _mint(_msgSender(),_totalSupply + i);
    }

    
    //------------------------------------
    //The Mint and Morph can be called only by the owner of the token
    //------------------------------------
    
    //OBI 0 will be minted only by OBI Team.
    //And it is used to show case future skins and color palettes.
    function mintOBIZeroMorph() public onlyOwner {
            
            //update skin
            if ( isBitSet(_owners[0].bitmap1,globalConfig.skinIndex) == false ){
                _owners[0].cnt1 ++;
                _owners[0].bitmap1 = setBit(_owners[0].bitmap1, globalConfig.skinIndex);
            }
            _owners[0].idx1 = globalConfig.skinIndex;
            //update color 
            if ( isBitSet(_owners[0].bitmap1,globalConfig.colorIndex) == false ){
                _owners[0].cnt2 ++;
                _owners[0].bitmap2 = setBit(_owners[0].bitmap2, globalConfig.colorIndex);
            }
            _owners[0].idx2 = globalConfig.colorIndex;
    }
  
    //free Mint
    function mintFreeOBIMorph(uint256[] calldata tokenIdList) public  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 1, "OBI: Free OBI Morph is not active");

        _validateLightMorphList(tokenIdList);
        _updateMorphList(tokenIdList);
    }

    function mintFreeOBIListMorph(uint256[] calldata tokenIdList,bytes32[] calldata proof) public  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 2, "OBI: Free OBIList Morph is not active");
        bytes memory payload = abi.encodePacked(_msgSender());
        require(_verify(keccak256(payload), proof), "OBI: Your are not on the OBIList.");

        _validateLightMorphList(tokenIdList);
        _updateMorphList(tokenIdList);
    }

    function mintOBIMorph(uint256[] calldata tokenIdList) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 3, "OBI: OBI Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
         
         //avoid to pay in case Obi already minted 
        _validateMorphList(tokenIdList);    
        _updateMorphList(tokenIdList);
    }
    
    function mintOBIListMorph(uint256[] calldata tokenIdList,bytes32[] calldata proof) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 4, "OBI: OBILIST Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
        bytes memory payload = abi.encodePacked(_msgSender());
        require(_verify(keccak256(payload), proof), "OBI: Your are not on the OBIList.");
        
        //avoid to pay in case Obi already minted 
        _validateMorphList(tokenIdList);    
        _updateMorphList(tokenIdList);
    }
    
    //give a skin or pallete to a friend
    function mintGiveawayMorph(uint256[] calldata tokenIdList) public payable  {
        require(msg.sender == tx.origin);
        require(morphMintPhase == 5 , "OBI: OBI Giveaway Morph is not active");
        require(tokenIdList.length * MORPH_MINT_PRICE == msg.value, "OBI: Invalid funds provided.");
         
         //avoid to pay in case Obi already minted 
        for(uint256 id; id < tokenIdList.length; id++){
            uint256 tokenID = tokenIdList[id];
            require(tokenID < _owners.length, "OBI: invalid token id");

            bool hasSkin = isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex);
            bool hasColor= isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex);
            require( ( hasSkin == false) || (hasColor == false), "OBI: One of the OBI is already Morph Minted");
        }    
        
        for(uint256 id; id < tokenIdList.length; id++){
            uint256 tokenID = tokenIdList[id];
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap1,globalConfig.skinIndex) == false ){
                _owners[tokenID].cnt1 ++;
                _owners[tokenID].bitmap1 = setBit(_owners[tokenID].bitmap1, globalConfig.skinIndex);
            }
            //update skin if owner does not have it already
            if ( isBitSet(_owners[tokenID].bitmap2,globalConfig.colorIndex) == false ){
                _owners[tokenID].cnt2 ++;
                _owners[tokenID].bitmap2 = setBit(_owners[tokenID].bitmap2, globalConfig.colorIndex);
            }
        }
    }

  //=============================== 
    receive() external payable {}
    
    function setupMorphMint(uint256 _price,address account1,address account2,uint256 percentage) public onlyOwner {
        obiAccount = account1;
        artistAccount = account2;
        artistPercentage = percentage;
        MORPH_MINT_PRICE = _price;
    }
    
    function getMorphMintConfig() public view onlyOwner returns (uint256,address,address,uint256){
        return (MORPH_MINT_PRICE,obiAccount,artistAccount,artistPercentage);
    }
    
    //function to return the price
    function getMintPrice() public view returns (uint256) {
        return MORPH_MINT_PRICE;
    }
   
    
    function withdrawAllAdmin() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 totalBalance  = address(this).balance;
        uint256 _artistBalance = totalBalance * artistPercentage/100;
        uint256 _obiBalance = totalBalance - _artistBalance;
        require(payable(artistAccount).send(_artistBalance));
        require(payable(obiAccount).send(_obiBalance));
    }

//===============================   
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "OBI:URI query for nonexistent OBI.");
        if (_tokenIndexToAddress[_owners[_tokenId].idx1] == address(0)) {
            return '';
        }
        IMotherShip  motherShip = IMotherShip (_tokenIndexToAddress[_owners[_tokenId].idx1]);
        return motherShip.launchPad(_tokenId,_owners[_tokenId].idx1,_owners[_tokenId].idx2,_owners[_tokenId].cnt1,_owners[_tokenId].cnt2);     
    }
}