/** 

                                                                                              
                                                                                      
    //   / /                                        //   ) )                          
   //__ / /    ___      __    __  ___  ___         //         ___      __      ___    
  //__  /    //   ) ) //  ) )  / /   //   ) )     //        //   ) ) //  ) ) ((   ) ) 
 //   \ \   //   / / //       / /   //   / /     //        //   / / //        \ \     
//     \ \ ((___( ( //       / /   ((___/ /     ((____/ / ((___( ( //      //   ) )   
                                                                                      

                                Developed by carl.
                                                                                      
**/                                                                                 
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract KartoCarsNFT is ERC721A, Ownable, VRFConsumerBaseV2 {

    event RequestSent(uint256 requestID, uint32 numWords); 
    event RequestFulfilled(uint256 requestID, uint256[] randomWords); 

    struct RequestStatus { 
      bool fulfilled; 
      bool exists;
      uint256[] randomWords; 
    }

    enum SaleStatus {
      PAUSED, // 0
      WHITELIST, // 1
      PUBLIC // 2
    }

    using Strings for uint256;

    // ~~~~~~~~~~~~~~~~~~ Set Sale as PAUSED on DEPLOY ~~~~~~~~~~~~~~~~~~
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    string private preRevealURI;
    string private postRevealBaseURI;

    // ~~~~~~~~~~~~~~~~~~ Sale Settings ~~~~~~~~~~~~~~~~~~
    uint256 public PRICE_KC = 0.07 ether; //Price set to first sale of OG.
    uint256 private constant MAX_KC = 10000;
    uint256 public publicPerWallet = 3;
    uint256 public wlPerWallet = 3; 

    //~~~~~~~~~~~~~~~~~~ Chainlink Settings ~~~~~~~~~~~~~~~~~~
    uint256[] public requestIds; 
    uint256 public lastRequestId; 
    uint32 callbackGasLimit = 100000; 
    uint16 requestConfirmations = 3; 
    uint32 numWords = 1; 
    VRFCoordinatorV2Interface COORDINATOR;

    address[] private teamAddress;
    uint[] private teamSplit;

    // ~~~~~~~~~~~~~~~~~~ Chainlink Sub ID ~~~~~~~~~~~~~~~~~~
    uint64 s_subscriptionId;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public wlMintedAmt;
    mapping (address => uint256) public publicMintAmt; 
    mapping(uint256 => RequestStatus) public s_requests; 

    // ~~~~~~~~~~~~~~~~~~ Reveal ~~~~~~~~~~~~~~~~~~
    bool public revealed;
    uint256 public tokenOffset;

    // ~~~~~~~~~~~~~~~~~~ Chainlink VRF ~~~~~~~~~~~~~~~~~~
    bytes32 public chainlinkKeyHash;


    constructor(
      address[] memory _team,
      uint[] memory _split,
      string memory _preRevealURI,
      address _vrfCoordinator,
      bytes32 _chainlinkKeyHash,
      uint64 _subscriptionId
    ) 
      ERC721A("Karto Cars NFT", "KARTOCARS") 
      VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) { 
        addTeam(_team, _split);
        preRevealURI = _preRevealURI;
        chainlinkKeyHash = _chainlinkKeyHash;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
    }

    // ~~~~~~~~~~~~~~~~~~ Prevent Bots ~~~~~~~~~~~~~~~~~~
    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    // ~~~~~~~~~~~~~~~~~~ Metadata Functions ~~~~~~~~~~~~~~~~~~
    function setPreRevealURI(string memory _URI) external onlyOwner {
      preRevealURI = _URI;
    }

    function setPostRevealBaseURI(string memory _URI) external onlyOwner {
      postRevealBaseURI = _URI;
    }

    // ~~~~~~~~~~~~~~~~~~ Token URI ~~~~~~~~~~~~~~~~~~
    // Before reveal, return same pre-reveal URI
    // After reveal, return post-reveal URI with random token offset from Chainlink
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      if (!revealed) return preRevealURI;
      uint256 shiftedTokenId = (_tokenId + tokenOffset) % totalSupply();
      return string(abi.encodePacked(postRevealBaseURI, shiftedTokenId.toString()));
    }

    // ~~~~~~~~~~~~~~~~~~ Sale State Function ~~~~~~~~~~~~~~~~~~

    function setSaleStatus(SaleStatus _status) external onlyOwner {
      saleStatus = _status;
    }

    // ~~~~~~~~~~~~~~~~~~ Setting Merkle Root Function ~~~~~~~~~~~~~~~~~~
    function setMerkleRoots(bytes32 _whitelistMerkleRoot) external onlyOwner {
      whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function processMint(uint256 _quantity) internal {
      require(msg.value == PRICE_KC * _quantity, "INCORRECT ETH SENT");
      require(totalSupply() + _quantity <= MAX_KC, "MAX CAP OF KC EXCEEDED");
      _mint(msg.sender, _quantity);
    }

    // ~~~~~~~~~~~~~~~~~~ Whitelist Sale Function ~~~~~~~~~~~~~~~~~~
    function whitelistSale(uint256 _quantity, bytes32[] memory _proof) external payable callerIsUser {
      require(saleStatus == SaleStatus.WHITELIST, "WL SALE NOT ACTIVE");
      require(
        MerkleProof.verify(_proof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
        "MINTER IS NOT ON WHITELIST"
      );
      require(_quantity <= wlPerWallet, "SURPASSED WL TX LIMIT"); 
      require(_quantity + wlMintedAmt[msg.sender] <= wlPerWallet , "MAX WL MINTED");
      wlMintedAmt[msg.sender]+= _quantity; 

      processMint(_quantity);
    }

    // ~~~~~~~~~~~~~~~~~~ Public Sale Function ~~~~~~~~~~~~~~~~~~
    function publicSale(
      uint256 _quantity
    ) external payable callerIsUser {
      require(saleStatus == SaleStatus.PUBLIC, "PUBLIC SALE NOT LIVE");
      require(_quantity <= publicPerWallet, "QUANTITY SURPASSES PER-TXN LIMIT"); 
      require(_quantity + publicMintAmt[msg.sender] <= publicPerWallet, "MAX PUBLIC MINTED"); 
      publicMintAmt[msg.sender]+= _quantity; 
      processMint(_quantity);
    }

  // ~~~~~~~~~~~~~~~~~~ Airdrop Function ~~~~~~~~~~~~~~~~~~
  function airDrop(
    uint256 _quantity, address _receiver 
  ) public onlyOwner {
    _mint(_receiver, _quantity); 
  }

    // ~~~~~~~~~~~~~~~~~~ Edit Chainlink Configuration ~~~~~~~~~~~~~~~~~~
    function setChainlinkConfig(bytes32 _keyhash) external onlyOwner {
      chainlinkKeyHash = _keyhash;
    }

    // ~~~~~~~~~~~~~~~~~~ Request Token Offset ~~~~~~~~~~~~~~~~~~
    // NOTE: contract must be approved for and own LINK before calling this function
    function startReveal(string memory _newURI) external onlyOwner returns (uint256 requestId) {
      require(!revealed, "ALREADY REVEALED");
      postRevealBaseURI = _newURI;
      requestId = COORDINATOR.requestRandomWords(
              chainlinkKeyHash,
              s_subscriptionId,
              requestConfirmations,
              callbackGasLimit,
              numWords
          );
          s_requests[requestId] = RequestStatus({
              randomWords: new uint256[](0),
              exists: true,
              fulfilled: false
          });
          requestIds.push(requestId); 
          lastRequestId = requestId; 
          emit RequestSent(requestId, numWords); 
      return requestId;
    }

    // ~~~~~~~~~~~~~~~~~~ CHAINLINK CALLBACK FOR TOKEN OFFSET ~~~~~~~~~~~~~~~~~~
    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {
      require(!revealed, "ALREADY REVEALED");
      require(s_requests[_requestId].exists, "Request not found.");
      s_requests[_requestId].fulfilled = true;
      s_requests[_requestId].randomWords = randomWords;
      emit RequestFulfilled(_requestId, randomWords); 
      revealed = true;
      tokenOffset = randomWords[0] % totalSupply();
      
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "Request not found."); 
        RequestStatus memory request = s_requests[_requestId]; 
        return (request.fulfilled, request.randomWords); 
    }

    // ~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~
    function changePrice(uint256 _price) public onlyOwner {
        PRICE_KC = _price; 
    }

    function changePublicAmt(uint256 _amt) public onlyOwner {
        publicPerWallet = _amt; 
    }

    function changeWhitelistAmt(uint256 _wlAmt) public onlyOwner {
        wlPerWallet = _wlAmt; 
    }

    function numberMinted(address _owner) public view returns (uint256) {
      return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 _tokenId) external view returns (TokenOwnership memory) {
      return _ownershipOf(_tokenId);
    }

    function addTeam(address[] memory _team, uint[] memory _split) public onlyOwner {
        require(_team.length == _split.length, "Address and Shares must equal"); 
        teamAddress = _team; 
        teamSplit = _split; 
    }

    //~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~
    function internalWithdrawal(uint _amount) internal onlyOwner {
        for(uint i = 0; i < teamAddress.length; i++) {
            uint split = teamSplit[i]; 
            (bool os, ) = payable(teamAddress[i]).call{value: _amount * split / 100}(''); 
            require(os);
        }
    }

    function teamWithdraw() public onlyOwner {
        internalWithdrawal(address(this).balance); 
    }

    function emergencyWithdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}(''); 
        require(os);
    }
}