// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SkaterHomies is ERC721A,ERC721AQueryable, Ownable {
    
    uint256 public MINT_RATE = 0.05 ether;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public MAX_MINTS = 2;
    uint256 public LIMIT_PER_TIME_MINT = 4;
    uint256 public DELAY_MINT = 1 minutes;
    uint256 public MAX_OG = 2;
    uint256 public MAX_WL = 2;

    enum STEP{Private,Public,Reveal}
    STEP public choice;
    bool public paused = false;
    string public baseURI;
    mapping(address => uint256) public addressLastMint;
    mapping(address => uint256) public addressWLMint;
    bytes32 private merkleRoot_OG;
    bytes32 private merkleRoot_WL;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        choice = STEP.Private;
    }

    // publicMint
    function publicMint(uint256 _mintAmount) external payable {
        require(STEP.Private!=choice,"Is not Public Sale");
        uint256 MAX_MINTS_NEW = (addressWLMint[msg.sender] > 0)?MAX_MINTS+addressWLMint[msg.sender]:MAX_MINTS;
        require(_mintAmount + balanceOf(msg.sender) <= MAX_MINTS_NEW,"User has minted max amount of NFT");
        require(screening(_mintAmount,msg.value));
        require(_mintAmount <= LIMIT_PER_TIME_MINT,"limit per transaction");
        uint256 ownerMintedCount = balanceOf(msg.sender);
            if (ownerMintedCount >= 1 && DELAY_MINT > 0) {
                uint256 mins = (DELAY_MINT / 60);
                uint256 checkTimeLimit = (block.timestamp - addressLastMint[msg.sender]);
                require(checkTimeLimit > DELAY_MINT,string(abi.encodePacked("Limit Mint ",  _toString(mins), " minutes")));
            }
        addressLastMint[msg.sender] = block.timestamp;
        _safeMint(msg.sender, _mintAmount);
    }

    // privateMint
    function privateMint(uint256 _mintAmount,bytes32[] calldata _merkleProof_og,bytes32[] calldata _merkleProof_wl) external payable {
        require(STEP.Private==choice,"Is not Private Sale");
        require(screening(_mintAmount,msg.value));
        bool OG = isOG(_merkleProof_og);
        bool WL = isWL(_merkleProof_wl);
        require(OG || WL, "User is not whitelisted");
        uint256 max_mint = MAX_WL;
          if(OG && WL){
              max_mint = MAX_OG+MAX_WL;
          }else if(OG){
              max_mint = MAX_OG;
          }else{
              max_mint = MAX_WL;
          }
        require(_mintAmount + balanceOf(msg.sender) <= max_mint,"Max mint per whitelisted"); 
        addressWLMint[msg.sender] = _mintAmount + balanceOf(msg.sender);
        _safeMint(msg.sender, _mintAmount);
    }
    
    function isOG(bytes32[] calldata _merkleProof_og) public view returns (bool) {
        bytes32 leaf_OG = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof_og, merkleRoot_OG, leaf_OG);
    }
    
    function isWL(bytes32[] calldata _merkleProof_wl) public view returns (bool) {
        bytes32 leaf_WL = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof_wl, merkleRoot_WL, leaf_WL);
    }

    function screening(uint256 _mintAmount,uint256 _value) private view returns (bool){
        require(!paused, "The contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(supply + _mintAmount <= MAX_SUPPLY, "Not enough tokens");
        require(_value >= (MINT_RATE * _mintAmount),"Insufficient funds");
        
        return true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        require(_exists(tokenId), "ERC721A: URI query for nonexistent token");
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }
    
    function getWaitTime(address _to) public view returns (uint256) {
        return (block.timestamp - addressLastMint[_to]);
    }

    function ContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOG() public view returns (bytes32) {
        return merkleRoot_OG;
    }

    function getWL() public view returns (bytes32) {
        return merkleRoot_WL;
    }
    
    function isSTEP() external view returns (string memory) {
        STEP temp = choice;
        if (temp == STEP.Private) return "Private Sale";
        if (temp == STEP.Public) return "Public Sale";
        if (temp == STEP.Reveal) return "Reveal";
        return "";
    }

    //only owner
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setSTEP(uint256 _choice) external onlyOwner {
        require(_choice >= 0);
         choice = STEP(_choice);
    }

    function setOG(bytes32 _root) external onlyOwner {
        merkleRoot_OG = _root;
    }

    function setWL(bytes32 _root) external onlyOwner {
        merkleRoot_WL = _root;
    }

    function burnToken(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }

    function giveaway(address _to, uint256 _mintAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(supply + _mintAmount <= MAX_SUPPLY, "Not enough tokens");
        _safeMint(_to, _mintAmount);
    }

    function setDELAY_MINT(uint256 _newLimit) public onlyOwner {
        DELAY_MINT = _newLimit;
    }

    function setLimitPerTimeMint(uint256 _limit) public onlyOwner {
        LIMIT_PER_TIME_MINT = _limit;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }
    function setMINT_RATE(uint256 _newMINT_RATE) public onlyOwner {
        MINT_RATE = _newMINT_RATE;
    }
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        MAX_MINTS = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}