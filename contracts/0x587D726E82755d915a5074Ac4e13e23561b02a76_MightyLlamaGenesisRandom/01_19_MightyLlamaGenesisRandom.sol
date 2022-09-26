// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MightyLlamaGenesisRandom is ERC721PsiAddressData , VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINK;

    address private _owner;
    bytes32 private s_keyHash;
    uint256 private chainLinkVrfFee;
    uint256 private randomWinnerCount = 0;
    uint64 private s_subscriptionId;
    address private vrfCoordinator;
    address private linkAddress;
    uint32 private callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;      
    uint32 numWords =  1;
    string[] private unrevealedURIs;
    bool revealed = false;
    uint256 cost;
    string baseURI;
    bool publicMint = false;
    uint256 nftPrice = 0;
    uint256 defaultMaxMintAmount = 2;
    uint256 MAX_TOTAL_SUPPLY = 30;
    address contractAddress;
	uint32 whiteListMaxMintAmount = 2;
	uint32 ogMaxMintAmount = 3;
    string public baseExtension = '.json';
    bool public isPaused = true;
    uint private lastTimeRaffleCalled;
    uint private interval = 840; //14 minutes
    
   
    struct Token {
        string url;
        uint256 tokenId;
    }

    mapping(uint256 => uint256) private randomWinnerMap;
    mapping(uint256 => uint256) private reqeustIdsMap;
    mapping(uint256 => uint256) private randomTokenWinner;
     // all whitelists and OGs 
    mapping(address => uint32) private whitelisted;


    constructor(address _linkAddress, address _vrfCoordinator, bytes32 _vrfKeyHash, uint64 _vrfSubscriptionId )
        VRFConsumerBaseV2 (_vrfCoordinator)
        ERC721Psi("MIGT", "MTghY")
        {
            _owner = _msgSender();
            COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
            LINK = LinkTokenInterface(_linkAddress); 
            linkAddress = _linkAddress;
            s_subscriptionId = _vrfSubscriptionId;
            s_keyHash = _vrfKeyHash;
            lastTimeRaffleCalled = block.timestamp;
        }

    event NFTCreated(
        uint256 indexed tokenIdBatchHead,
        uint256 _quantity,
        address indexed nftContractAddress,
        address indexed creator
    );

    //event fires on Randomness request is fullfilled by chainlink VRF and tandom token id saved in the contract
    event RandomWinnerAnnounced(
        uint256 indexed tokenId,
        uint256 indexed requestId
    );

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Only Owner function. Access denied!");
        _;
    }

    modifier canRequestRandomWords() {
         require((block.timestamp - lastTimeRaffleCalled) > interval, "It can't be done now, you need to wait");
        _;
    }

	modifier totalSupplyExceed(uint256 _quantity) {
        require((_quantity + totalSupply()) <= MAX_TOTAL_SUPPLY, "No more Mighty Llama left to Mint");
        _;
    }

	modifier onlyPaid(uint256 _quantity) {
        require(
            msg.value >= nftPrice * _quantity,
            'you need to send correct amout of eth to Mint Mighty Llama'
        );
        _;
    }

	modifier maxMintAmountExceed(uint256 _quantity) {
        uint256 maxMint = getAddressMaxMint(_msgSender());
        uint256 amountToOwn = _quantity + balanceOf(_msgSender());
        require(maxMint > 0 || _msgSender() == _owner, "you are not allowed to mint yet, please try later");
        require(_quantity > 0, "number of mint needs to be greater than zero");
        require(amountToOwn <= maxMint || _msgSender() == _owner, "you are not allowed to mint this many in this wallet");
        _;
    }

    function _isOwner() internal view returns (bool) {
         return  _msgSender() == _owner;
    }

    function contractState(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function _createNft(address _to, uint256 _quantity) internal {
        require(      
            totalSupply() + _quantity <= MAX_TOTAL_SUPPLY,
            'there is not enough token left to mint in this collection'
        );

        uint256 tokenIdBatchHead = totalSupply();

        _safeMint(_to, _quantity);

        emit NFTCreated(tokenIdBatchHead, _quantity, contractAddress, _to);
    }

    function mint(uint256 _quantity) external payable onlyPaid( _quantity)  totalSupplyExceed(_quantity) maxMintAmountExceed(_quantity) {
            require(
                !isPaused || _isOwner(),
                'Minting not started yet, please try later'
            );
            
            _createNft(msg.sender, _quantity);
    }

    function airDrop(address _to, uint256 _quantity) public onlyOwner totalSupplyExceed(_quantity) {
        // owner can mint and send NFT to any address they want
        _createNft(_to, _quantity);
    }

	function bulkAirDrop(address[] memory _addresses) public onlyOwner totalSupplyExceed(_addresses.length) {
        // owner can mint and send NFT to any address they want
		 for (uint256 i = 0; i < _addresses.length; i++) {
            _createNft(_addresses[i], 1);
		 }
    }

    function addWhitelist(address[] memory _addresses) public onlyOwner {
        require(_addresses.length > 0, "addresss are in wrong format");
        for (uint i=0; i < _addresses.length; i++) {
           whitelisted[_addresses[i]] = whiteListMaxMintAmount;
        }
    }

    function addOGWhitelist(address[] memory _addresses) public onlyOwner{
		require(_addresses.length > 0, "addresss are in wrong format");
        for (uint i=0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = ogMaxMintAmount;
        }
    } 

    function getAddressMaxMint(address _address) public view returns (uint32) {

      if(whitelisted[_address] > 0)  {
          return whitelisted[_address];
      }

      if(publicMint) {
          return whiteListMaxMintAmount;
      }

      return 0;
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        if (revealed == false) {
            if(tokenId % 4 == 0) {
               return unrevealedURIs[2];
            }
            if(tokenId % 7 == 0) {
               return unrevealedURIs[1];
            }
            return unrevealedURIs[0];    
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : '';
    }

    function reveal(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function isPublicMint(bool _isPublic) public onlyOwner {
        publicMint = _isPublic;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        defaultMaxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // Random TokenID Winner selector with ChainLink Rnadomness VRF
    function requestRandomWords() external canRequestRandomWords {
        uint256 s_requestId = COORDINATOR.requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        randomWinnerCount ++;
        reqeustIdsMap[randomWinnerCount] = s_requestId;
        lastTimeRaffleCalled = block.timestamp;
    }

    // on Randomness fullfilment select a random tokenId and save it in randomTokenWinner
    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        uint256 value = (randomWords[0] % totalSupply()) + 1;
        randomTokenWinner[randomWinnerCount] = value;
        emit RandomWinnerAnnounced(value, reqeustIdsMap[randomWinnerCount]);
    }

    function getLinkBalance() view public returns (uint256)  {
        return LINK.balanceOf(address(this));
    }

    function getLatestRandomWinner() view public returns (uint256) {
        return  randomTokenWinner[randomWinnerCount];
    }

    function getRandomWinner(uint _randomWinnerCount) view public onlyOwner returns (uint256) {
        return  randomTokenWinner[_randomWinnerCount];
    }

    function getRandomWinnerCount() view public onlyOwner returns (uint256) {
        return  randomWinnerCount;
    }

    function setSubscriptionId(uint64 id) public onlyOwner {
        s_subscriptionId = id;
    }
    function getSubscriptionId() public view returns (uint64){
       return s_subscriptionId;
    }

    function setInterval(uint64 _interval) public onlyOwner {
        interval = _interval;
    }

    function getInterval() public view returns (uint){
       return interval;
    }

    function setUnrevealedURIsl(string[] memory _unrevealedURIs) public onlyOwner {
        unrevealedURIs = _unrevealedURIs;
    }

    function getUnrevealedURIs() public view returns (string[] memory){
       return unrevealedURIs;
    }

    function withdrawLINK(address to, uint256 value) public onlyOwner {
        require(LINK.transfer(to, value), 'Not enough LINK');
    }
}