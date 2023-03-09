// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";
import "./iChecks.sol";

/** 

                           ^77777777777777777777!!~^::.                                             
                           ^7777!~~~~~~~!!!!77777777777!~^.                                         
                           :777~  .............:^~~!7777777!~:.                                     
                           ~7777!777777777!!!~~^^:...::~!77??77!:.                                  
                          :77777777777777777??????77!!~^:::~!7???7^                                 
                          !?7777???7?77??77?777777???????7!~^:^!7??~                                
                         :???????????????????????????????????7!!???7.                               
                        .7?????????????????????????????????????????7                                
                        ~??????????????????????????????????????????7                                
                    ..^!???????????????????????????????????????????7                                
               .:~!7??JJ??????????????????????????????????????????J7                                
             :!?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?^.                              
            !JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ??7!~^:.                       
            !?JJJ??77!!!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?:                     
              ....     .JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?77!!~^.                     
                      .?YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ!.                             
                     ^?!7YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY7^^^^:.                        
                    !7.:?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?.                       
                   ~7.~YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7                        
                   . !5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?                         
                     .:!YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7:                       
                        JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJY55YYYYYYYYY5Y7.                     
                        ?5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5?::~?Y55YYYYYYYY57                     
                        :5555555555555555555555555555555555555Y?..5YJ555555555?                     
                         !55555555555555555555555555555555555555J.~: !55555555Y^                    
                          755555555555555555555555555555555555555Y~ :75555555555~                   
                          .?555555555555555555555555555555555555555?~7JY555555555^                  
                            :^^:::..::!55555555555555555555555555555Y^ .7555555YY:                  
                                      ?5555555555555555555555555555555?^!?JJ7~...                   
                                    :JP5555555555555555555555555555555P5Y7^.                        
                            ..::^~!J5P5555555555555555555555555555555555PPP5J7~:.                   
                     .^~7?JYY555PPPPP5555555PPPPPPPPPPPPPPPPPPP555555555555PPPP5Y?!^:               
                  .!J5PPPPPPPPPPPPPPPPPPPPPP?^^~!7JJJJYYJJ?77JPPPPPPPPPPPPPPPPPPPPPP5Y?!^:          
                .75PPPPPPPPPPPPPPPPPPPPPPPPP7         J~      7PPPPPPPPPPPPPPPPPPPPPPPPPP5Y?~.      
               ^5PPPPPPPPPPPPPPPPPPPPPPPPPPP5.       .J:      ^PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57.    
              ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP?     ^Y5P!      7PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY:   
             ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP~  .7PPPPP?.   ^PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY.  
            :5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5!?5PPPPPPP57::5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP7  
           .YPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5. 
           ?PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP! 
          ~PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY 
         ^5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP7
         JPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57
 
*/
//TODO: remove comments on mainnet
//0xB93d3b8e78849EDad1410479b8FE3C78a9A4bf71
//TODO: contract Checksons is 
contract Test is 
ERC1155, 
ERC1155Supply, 
ERC2981, 
Ownable,
ReentrancyGuard,
DefaultOperatorFilterer
{

    struct ChecksonClaim{
        uint256 checkTokenId;
        uint256 checksonTokenId;
    }

    string public name = "Checksons";
    string public symbol = "CKS";
    string internal _contractURI;
    uint public constant MAX_SUPPLY = 300;

    /// @notice The VV Checks Originals contract.
    Checks public checksOriginals;
   // uint internal _editionPrice = 0.01 ether;
    uint internal _editionPrice = 1000;
    bool internal _isOpenEditionActive = false;

    mapping(uint256 => string) internal _metadataHashes;
    mapping(uint256 => bool) internal _claimedCheckTokens;
    mapping(uint256 => bool) internal _claimedChecksonTokens;

    constructor(
        address royaltyReceiver,
        uint96 royaltyFeesInBips,
        string memory contractUri
    ) ERC1155("") {
        super._setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
         _contractURI = contractUri;
         //TODO: goerli 0x0D8937b275ef3E3e29596C0350BfD79DD0969175
         //TODO: change to mainnet address 0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1
         checksOriginals = Checks(0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1);//mainnet
    }

    //Contract logic

    function chaingeIsOpenEditionActive(bool setIsOpenEditionActive) 
    external 
    onlyOwner{
        _isOpenEditionActive = setIsOpenEditionActive;
    }

    function isOpenEditionActive() public view returns(bool){
        return _isOpenEditionActive;
    }

    function mintOpenEdition() external{
        require(_isOpenEditionActive, "Open edition is not active");
        _mint(msg.sender, 1, 1, "");
    }

    function setTokenUri(uint256 tokenId, string calldata metadataHash) 
    external 
    onlyOwner{
        require(tokenId < MAX_SUPPLY, "Token ID exceeds max supply");
        require(bytes(_metadataHashes[tokenId]).length == 0, "Token URI already set");
        _metadataHashes[tokenId] = metadataHash;
    }

     function setTokenUriSequence(uint256 firstTokenIdInSequence, string[] calldata metadataHashs) 
     external 
     onlyOwner{
        require((firstTokenIdInSequence + (metadataHashs.length -1)) < MAX_SUPPLY, "Token IDs exceed max supply");
        uint256 tokenIdToSet = firstTokenIdInSequence;
         for (uint i = 0; i < metadataHashs.length; i++) {
                require(bytes(_metadataHashes[tokenIdToSet]).length == 0, "Token URI already set");
                _metadataHashes[tokenIdToSet] = metadataHashs[i];
                tokenIdToSet++;
         }
    }

    function withdrawFunds() 
    external  
    onlyOwner{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function claimChecksons(ChecksonClaim[] calldata checksonClaims) 
    external 
    payable 
    nonReentrant{

        //prepare variabels
        uint totalEditionsToMint = 0;
        uint256[] memory tokenIdsToMint = new uint256[](checksonClaims.length);
        uint256[] memory amountsToMint = new uint256[](checksonClaims.length);

         for (uint i = 0; i < checksonClaims.length; i++) {

            //ChecksonClaim params
            uint256 checkTokenId = checksonClaims[i].checkTokenId;
            uint256 checksonTokenId = checksonClaims[i].checksonTokenId;

            //Checks contract calls
            address checkOwner = checksOriginals.ownerOf(checkTokenId);
            uint8 checksCount = checksOriginals.getCheck(checkTokenId).checksCount;
            
            require(bytes(_metadataHashes[checksonTokenId]).length != 0, "No token metadata");
            require(!_claimedChecksonTokens[checksonTokenId], "Checkson already claimed");
            require(!_claimedCheckTokens[checkTokenId], "Check already claimed");
            require(checkOwner == msg.sender, "Check not owned by sender");

            //update claimed tokens
            _claimedCheckTokens[checkTokenId] = true;
            _claimedChecksonTokens[checksonTokenId] = true;

            totalEditionsToMint += checksCount;
            tokenIdsToMint[i] = checksonTokenId;
            amountsToMint[i] = checksCount;
         }
            //Each edition cost _editionPrice
            require(msg.value >= (totalEditionsToMint * _editionPrice), "payment is not sufficient"); 

            //mint Checksons editions
            checksonClaims.length > 1 ? 
            _mintBatch(msg.sender, tokenIdsToMint, amountsToMint, ""):
            _mint(msg.sender, tokenIdsToMint[0], amountsToMint[0], "");
    }

    function claimedChecksons() 
    public 
    view 
    returns(bool[] memory){
    bool[] memory claimedChecksonsIds = new bool[](MAX_SUPPLY);
        for (uint i = 0; i < MAX_SUPPLY; i++) {
            claimedChecksonsIds[i] = _claimedChecksonTokens[i];
        }
        return claimedChecksonsIds;
    }

    function getChecksonsCallerBalances() 
    public 
    view 
    returns(uint256[] memory){
    uint256[] memory checksonsCallerBalances = new uint256[](MAX_SUPPLY);
        for (uint i = 0; i < MAX_SUPPLY; i++) {
            checksonsCallerBalances[i] = balanceOf(msg.sender, i);
        }
        return checksonsCallerBalances;
    }

    function getChecksonsSuplies() 
    public 
    view 
    returns(uint256[] memory){
    uint256[] memory checksonsSupplies = new uint256[](MAX_SUPPLY);
        for (uint i = 0; i < MAX_SUPPLY; i++) {
            checksonsSupplies[i] = totalSupply(i);
        }
        return checksonsSupplies;
    }

    function isCheckClaimed(uint256 checkTokenId) 
    public 
    view 
    returns(bool){
        return _claimedCheckTokens[checkTokenId];
    }

    function isChecksonClaimed(uint256 checksonTokenId) 
    public 
    view 
    returns(bool){
        return _claimedChecksonTokens[checksonTokenId];
    }

     //Setters and getters

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory) {
            string memory metadataHash = _metadataHashes[tokenId];
            return string(
                abi.encodePacked("ipfs://", metadataHash));
        }

    function setEditionPriceInWei(uint editionPriceInWeiToSet) 
    external 
    onlyOwner{
        _editionPrice = editionPriceInWeiToSet;
    }

   function editionPriceInWei()
    public
    view
    returns (uint priceInWei) {
        return _editionPrice ;
    }

    function setContractURI(string calldata uriToSet)
    external
    onlyOwner {
        _contractURI = uriToSet;
    }

    function contractURI()
    public
    view
    returns (string memory) {
        return _contractURI;
    }

    // hooks and overrides

    function setDefaultRoyalty(address receiver, uint96 royaltyFeesInBips)
    external
    onlyOwner {
        super._setDefaultRoyalty(receiver, royaltyFeesInBips);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

     /* Opensea creator fee enforcement */

    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    virtual
    override
    onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}