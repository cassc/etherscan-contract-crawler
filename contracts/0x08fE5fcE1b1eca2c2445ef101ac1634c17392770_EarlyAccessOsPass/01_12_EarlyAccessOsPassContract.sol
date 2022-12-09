// SPDX-License-Identifier: MIT
//     ______    _______    _______  _____  ___    ________  ___________  _______    _______       __       ___      ___ 
//    /    " \  |   __ "\  /"     "|(\"   \|"  \  /"       )("     _   ")/"      \  /"     "|     /""\     |"  \    /"  |
//   // ____  \ (. |__) :)(: ______)|.\\   \    |(:   \___/  )__/  \\__/|:        |(: ______)    /    \     \   \  //   |
//  /  /    ) :)|:  ____/  \/    |  |: \.   \\  | \___  \       \\_ /   |_____/   ) \/    |     /' /\  \    /\\  \/.    |
// (: (____/ // (|  /      // ___)_ |.  \    \. |  __/  \\      |.  |    //      /  // ___)_   //  __'  \  |: \.        |
//  \        / /|__/ \    (:      "||    \    \ | /" \   :)     \:  |   |:  __   \ (:      "| /   /  \\  \ |.  \    /:  |
//   \"_____/ (_______)    \_______) \___|\____\)(_______/       \__|   |__|  \___) \_______)(___/    \___)|___|\__/|___|
//      --- OPENSTREAM NFT PASS CONTRACT ----
// @creator: openstreamnft
// @security: [email protected]
// @website: https://www.openstreamnft.com

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract EarlyAccessOsPass is ERC721A, Ownable, DefaultOperatorFilterer {

    using Counters for Counters.Counter;
    Counters.Counter private totalOsSupply;    
    uint256 public constant MAX_SUPPLY = 1596; 
    uint256 public constant MINT_PER_WALLET = 2;
    uint256 public constant WHITELIST_MINT_PRICE = 0.049 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.069 ether;
    uint256 public constant FREE_MINT_PRICE = 0 ether;

    bool public paused = false;
    
    bytes32 public mpWhitelistRoot;

    bytes32 public mpFreeMintlistRoot;

    string internal _tokenBaseURI = "https://srv01.api.openstreamnft.com/api/v1/pass/metadata/";                    
                    
    enum mintState { CREATED /*0*/, LOCKED /*1*/, INACTIVE /*2*/, WLMINT /*3*/, PMINT /*4*/ }
    mintState public state = mintState.INACTIVE;

    event FallbackCalled(address);
    constructor() ERC721A("OpenStreamPass", "OSPASS") {}
    //(_type FREEMINT => 0 , WHITELIST => 1)
    function whiteListMint(uint256 tokenQuantity,bytes32[] memory proof, uint128 _type) 
    external
    payable 
    OnlyIfHumanAndAuthorised
    mintCompliance(tokenQuantity)
    {
        require(state == mintState.WLMINT, "Whitelist minting is not started");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(isInWLMint(proof,leaf,_type),"Invalid proof");
        require(isWhiteListPriceCorrect(tokenQuantity,_type) == true, "Incorrect value" );
        for(uint256 i= 0; i< tokenQuantity; i++)
        {
            totalOsSupply.increment();
        }
        _safeMint(msg.sender,tokenQuantity);
    }

    function mint(uint256 tokenQuantity) 
    external 
    payable
    mintCompliance(tokenQuantity) 
    OnlyIfHumanAndAuthorised
    {
        require(state == mintState.PMINT, "Public minting is not started");
        require(isWhiteListPriceCorrect(tokenQuantity,2), "incorrect value" );
        for(uint256 i= 0; i< tokenQuantity; i++)
        {
            totalOsSupply.increment();
        }
        _safeMint(msg.sender, tokenQuantity);
        
    }

    function totalSupply() public override view returns (uint256) 
    {
        return totalOsSupply.current(); 
    }

    function isInWLMint(bytes32[] memory proof, bytes32 leaf, uint128 _type) public view returns(bool)
    {       
        bytes32 merkleTreeRoot = (_type == 0 ? mpFreeMintlistRoot : mpWhitelistRoot);
        return MerkleProof.verify(proof, merkleTreeRoot, leaf);
    }

    function isAuthorised() public view returns(bool) 
    {
        require(msg.sender == tx.origin, "UnAuthorized EOA");
        return true; 
    }

    function isWhiteListPriceCorrect(uint256 _tokenQuantity, uint128 _wlType) internal view returns(bool)
    {
        if(state == mintState.WLMINT)
        {
            require(_wlType <= 1,"Param _wlType out of bound");
            uint256 mintPrice = (_wlType == 0 ? FREE_MINT_PRICE : WHITELIST_MINT_PRICE);
            require(
            msg.value >= (mintPrice * _tokenQuantity),
            "Incorrect value price provided");
            return true;
        }
        if(state == mintState.PMINT)
        {
            require(
                msg.value >= (PUBLIC_MINT_PRICE * _tokenQuantity),
                "Incorrect value price provided");
            return true;
        }
        return false;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
    {
        require(_exists(tokenId), "Error: URI query for nonexistent token");
        return super.tokenURI(tokenId);

    }

    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        _tokenBaseURI = _tokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    //MODIFIERS ******
    modifier OnlyIfHumanAndAuthorised
    {
        require(paused == false, "contract is in pause");
        require(isAuthorised());       
        _;
    }

    modifier mintCompliance(uint256 _mintAmount)
    {   
        require((balanceOf(msg.sender)+_mintAmount) <= MINT_PER_WALLET, "Max Mint per wallet reached"); 
        require(_mintAmount > 0 ,"you must mint at least one token");
        require(_mintAmount > 0 && _mintAmount <=  MINT_PER_WALLET, "invalid mint amount");
        require((totalOsSupply.current() + _mintAmount) <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }
    //ADMIN FUNCTION ******
    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId, true);
    }
    
    function setContractState(uint256 _mintState) external onlyOwner
    {
        require(_mintState < 5, "unspecified contract state");
        state = mintState(_mintState);
    }
    
    function setPaused(bool _paused) external onlyOwner 
    {
        paused = _paused;
        if(paused == true) state = (mintState.LOCKED);
        else state = (mintState.PMINT);
    } 
    
    function withdrawAll() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "withdraw failed for owner account");
    }

    function setMerkleProofRootWl(bytes32 _merkleProofRoot) external onlyOwner
    {
        mpWhitelistRoot = _merkleProofRoot;
    } 

    function setMerkleProofRootFreeWl(bytes32 _merkleProofRoot) external onlyOwner
    {
        mpFreeMintlistRoot = _merkleProofRoot;
    } 
    function airDropOsPass(address[] calldata airDropAddress) public onlyOwner
    {
         for (uint i = 0; i < airDropAddress.length; i++) {
            totalOsSupply.increment();
            _safeMint(airDropAddress[i], 1);
        }
    }

    receive() external payable {}
    fallback() external payable {
        emit FallbackCalled(msg.sender);
    }
    //OPERATORS
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator)  {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable{
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable{
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}