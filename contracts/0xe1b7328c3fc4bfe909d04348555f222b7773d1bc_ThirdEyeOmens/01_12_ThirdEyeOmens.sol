//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.8;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract ThirdEyeOmens is ERC721,Ownable {
    uint256 public mintPrice = 0.03 ether;
    uint256 public tokenCounter;
    uint256 public maxToken = 3333;
    uint256 public maxMintWhiteList = 15;

    // ### Elder mint ###
    uint public numElderlyTokens = 150;
    bool public isElderMintStarted;
    bool public isElderMintEnded;
    bool public isElderlyMintReveiled;
    bytes32 public elderMintWhitelistRoot;
    mapping(address=>uint) public hasMintedElderPass; 

    // ### Community Mint ###
    uint public numCommunityTokens;
    bool public isCommunityMintStarted;
    bool public isCommunityMintEnded;
    bool public isCommunityMintReveiled;
    bytes32 public communityMintWhitelistRoot;
    mapping(address=>uint) public hasMintedCommunityPass; 

    // ### Public Mint ###
    bool public isPublicMintStarted;
    bool public isPublicMintReveiled;

    // ### Metadatas ###
    string public dummyMetaData = "https://gateway.pinata.cloud/ipfs/QmNiV3EjJJJ17PnrvDAVeWj7w54a8rf3r1zRQ3F3kfE7r3";
    string public elderlyMetaData = "";
    string public communityMetaData = "";
    string public publicMetaData = "";

    constructor() ERC721("TEO", "ThirdEyeOmens") {
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        // require(_exists(_tokenId),"Invalid tokenId");
        string memory _metaData = "";

        if(_tokenId < numElderlyTokens){
            if(isElderlyMintReveiled){
                _metaData = elderlyMetaData;
            }else{
                return dummyMetaData;
            }
        }else if(_tokenId < numElderlyTokens + numCommunityTokens){
           if(isCommunityMintReveiled){
                _metaData = communityMetaData;
            }else{
                return dummyMetaData;
            } 
        }else{
            if(isPublicMintReveiled){
                _metaData = publicMetaData;
            }else{
                return dummyMetaData;
            }
        }

        return
            string(
                abi.encodePacked(
                    _metaData,
                    Strings.toString(_tokenId),
                    "/metadata.json"
                )
            );
    }

    // ### reveil metadata ###
    function setElderlyURI(string memory _uri) external onlyOwner {
        elderlyMetaData = _uri;
        isElderlyMintReveiled = true;
    }

    function setCommunityURI(string memory _uri) external onlyOwner {
        communityMetaData = _uri;
        isCommunityMintReveiled = true;
    }

    function setPublicURI(string memory _uri) external onlyOwner {
        publicMetaData = _uri;
        isPublicMintReveiled = true;
    }

    // ### Admistration ###
    function requestWithdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // ### Public Sale ###
    function startElderlyMint(bytes32 _root) external onlyOwner{
       elderMintWhitelistRoot = _root;
       isElderMintStarted = true;
    }

    function startCommunityMint(bytes32 _root, uint _numCommunityTokens) external onlyOwner{
       communityMintWhitelistRoot = _root;
       numCommunityTokens = _numCommunityTokens;
       isCommunityMintStarted = true;
    }

    function startPublicMint() external onlyOwner{
        isPublicMintStarted = true;
    }

    function elderlyMint(uint numTokens,bytes32[] calldata proof)
    external payable
    {
        require(isElderMintStarted,"Elderly mint not started yet");
        require(!isElderMintEnded,"Elderly mint ended");
        require(_verify(_leaf(msg.sender),elderMintWhitelistRoot,proof), "Invalid merkle proof");
        require(msg.value >= mintPrice * numTokens,"Ether sent was less then the total token price");
        require(hasMintedElderPass[msg.sender] + numTokens <= maxMintWhiteList,"Maximum mints exceeded");
        require(tokenCounter + numTokens < numElderlyTokens, "Max Elderly Reserved Token Minted");

        hasMintedElderPass[msg.sender] += numTokens;
        uint _tempCounter = tokenCounter;
        for (uint256 i = 0; i < numTokens; i++) {    
            _safeMint(msg.sender, _tempCounter);
            _tempCounter += 1;
        }
        
        tokenCounter += numTokens;
    }

    function communityMint(uint numTokens,bytes32[] calldata proof)
    external payable
    {
        require(isCommunityMintStarted,"Community mint not started yet");
        require(!isCommunityMintEnded,"Community mint ended");
        require(_verify(_leaf(msg.sender),communityMintWhitelistRoot,proof), "Invalid merkle proof");
        require(msg.value >= mintPrice * numTokens,"Ether sent was less then the total token price");
        require(hasMintedCommunityPass[msg.sender] + numTokens <= maxMintWhiteList,"Maximum mints exceeded");
        require(tokenCounter + numTokens < numElderlyTokens + numCommunityTokens, "Max Community Reserved Token Minted");

        hasMintedCommunityPass[msg.sender] += numTokens;
        uint _tempCounter = tokenCounter;
        for (uint256 i = 0; i < numTokens; i++) {    
            _safeMint(msg.sender, _tempCounter);
            _tempCounter += 1;
        }
        
        tokenCounter += numTokens;
    }

    function publicMint(uint numTokens)
    external payable
    {
        require(isPublicMintStarted,"Public mint not started yet");
        require(msg.value >= mintPrice * numTokens,"Ether sent was less then the total token price");
        require(tokenCounter + numTokens < maxToken, "Max Token Minted");
        require(numTokens <= maxMintWhiteList,"Maximum mints exceeded");

        uint _tempCounter = tokenCounter;
        for (uint256 i = 0; i < numTokens; i++) {    
            _safeMint(msg.sender, _tempCounter);
            _tempCounter += 1;
        }
        
        tokenCounter += numTokens;
    }

    function claimRemainingElderlyMints(uint _num) external onlyOwner{
        require(isElderMintStarted,"Elderly mint not started yet");

        uint _tempCounter = tokenCounter;
        
        if(_tempCounter < numElderlyTokens){
            for (uint256 i = 0; i < _num; i++) {
                _safeMint(msg.sender, _tempCounter);
                _tempCounter += 1;
            } 
        }

        tokenCounter = _tempCounter;
        isElderMintEnded = true;        
    }

    function claimRemainingCommunityMints(uint _num) external onlyOwner{
        require(isCommunityMintStarted,"Community mint not started yet");

        uint _tempCounter = tokenCounter;
        
        if(_tempCounter < numElderlyTokens + numCommunityTokens){
            for (uint256 i = 0; i < _num; i++) {
                _safeMint(msg.sender, _tempCounter);
                _tempCounter += 1;
            } 
        }

        tokenCounter = _tempCounter;
        isCommunityMintEnded = true;        
    }

    // ### Merkle Verification ####
    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf,bytes32 _root,bytes32[] memory proof)
    internal pure returns (bool)
    {
        return MerkleProof.verify(proof, _root, leaf);
    }

}