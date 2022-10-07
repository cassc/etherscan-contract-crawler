// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Identity20XY is Initializable, VRFConsumerBaseV2Upgradable, UUPSUpgradeable, OwnableUpgradeable, ERC721AUpgradeable{
    
    address                         link;                      
    address                         vrfCoordinator;            

    VRFCoordinatorV2Interface       COORDINATOR;
    LinkTokenInterface              LINKTOKEN;

    bytes32                  public s_keyHash; 

    uint64                   public s_subscriptionId;        
    uint32                   public callbackGasLimit;        
    uint32                   public numWords;                
    uint16                   public requestConfirmations;   
    uint16                   public currentRevealCount;   

    bytes32                  public whitelistMerkleRoot;     

    string                   public tokenPreRevealURI;       
    string                   public tokenRevealURI;          

    bool                     public transferLocked;          

    address                  public paymentAddress;          

    SaleData                 public saleData;                
    
    mapping(uint16 => revealStruct) public reveals;          


    struct SaleData {
        uint256 whitelistPrice;
        uint256 publicPrice;
        uint32 whitelistStartTime;
        uint32 whitelistRangeTime;
        uint32 publicStartTime;
        uint16 whitelistMintMaxSupply;
        uint16 publicMintMaxSupply;
    }

    struct revealStruct {
        uint256 REQUEST_ID;
        uint256 RANDOM_NUM;
        uint256 SHIFT;
        uint256 RANGE_START;
        uint256 RANGE_END;
    }

    event RandomProcessed(uint256 stage, uint256 randNumber, uint256 _shiftsBy, uint256 _start, uint256 _end);

    event Locked(bool);

    event Allowed(address, bool);

    function initialize(uint64 subscriptionId, SaleData memory _saleData, bytes32 _whitelistMerkleRoot) public initializerERC721A initializer {
        __Ownable_init();
        __ERC721A_init("Identity20XY", "IXY");
        link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
        s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
        callbackGasLimit = 100000;
        numWords =  1;
        requestConfirmations = 3;
        currentRevealCount = 0;
        setVrfCoordinator(vrfCoordinator);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        transferLocked = false;

        s_subscriptionId = subscriptionId;
        saleData = _saleData;
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 _tokenId,
        uint256 quantity
    ) internal override {
        require(!transferLocked, "Transfers are not enabled");
        super._beforeTokenTransfers(from, to, _tokenId, quantity);
    }
    
    function reveal() public onlyOwner {
        require(reveals[currentRevealCount].RANGE_END < totalSupply(), "Reveal request already happened");

        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = totalSupply();
        currentReveal.REQUEST_ID = requestRandomWords();
    }

    function requestRandomWords() public onlyOwner returns (uint256 _requestId) {
        _requestId = COORDINATOR.requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
       );
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {

        require(msg.sender == vrfCoordinator, "Unauthorized contract caller");

        revealStruct storage currentReveal = reveals[currentRevealCount];
        if(currentReveal.REQUEST_ID == _requestId){
            currentReveal.RANDOM_NUM = randomWords[0] / 2;
            currentReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;
            currentReveal.SHIFT = currentReveal.RANDOM_NUM % ( currentReveal.RANGE_END - currentReveal.RANGE_START );
            
            if(currentReveal.SHIFT == 0) {
                currentReveal.RANDOM_NUM = currentReveal.RANDOM_NUM / 3;
                currentReveal.SHIFT = currentReveal.RANDOM_NUM % ( currentReveal.RANGE_END - currentReveal.RANGE_START );
            }

            emit RandomProcessed(
                currentRevealCount,
                currentReveal.RANDOM_NUM,
                currentReveal.SHIFT,
                currentReveal.RANGE_START,
                currentReveal.RANGE_END
            );
            
        }else{
            revert("Incorrect requestId received");
        }
    }

    function SafeMint(uint256 _quantity) external payable {
        SaleData memory _saleData = saleData;
        require(_quantity > 0, "You can't mint less than 1 NFT.");
        require(!transferLocked, "Transfers are currently paused.");
        require(_quantity + totalSupply() <= _saleData.whitelistMintMaxSupply + _saleData.publicMintMaxSupply, "There are no NFTs left.");
        require(uint256(_saleData.publicStartTime) != 0 && block.timestamp >= uint256(_saleData.publicStartTime), "NFT sale has not started.");
        require(_quantity * _saleData.publicPrice == msg.value, "Sent ether is not correct.");
        _safeMint(msg.sender, _quantity);
    }

    function WhitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable isWhitelisted(_merkleProof) {
        SaleData memory _saleData = saleData;
        require(_quantity > 0, "You can't mint less than 1 NFT.");
        require(!transferLocked, "Transfers are currently paused.");
        require(_quantity + totalSupply() <= _saleData.whitelistMintMaxSupply, "There are no NFTs left.");
        require(uint256(_saleData.whitelistStartTime) != 0 && block.timestamp >= uint256(_saleData.whitelistStartTime), "Whitelist sale has not started.");
        require(block.timestamp < uint256(_saleData.whitelistStartTime) + uint256(_saleData.whitelistRangeTime), "Whitelist sale has ended.");
        require(_quantity * _saleData.whitelistPrice == msg.value, "Sent ether is not correct.");
        _safeMint(msg.sender, _quantity);
    }

    modifier isWhitelisted(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof");
        _;
    }

    function SetPreRevealURI(string calldata tokenPreRevealURI_) public onlyOwner {
        tokenPreRevealURI = tokenPreRevealURI_;
    }

    function SetRevealURI(string calldata tokenRevealURI_) external onlyOwner {
        tokenRevealURI = tokenRevealURI_;
    }

    function findRevealRangeForN(uint256 n) public view returns (uint16) {
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            if(n <= reveals[i].RANGE_END) {
                return i;
            }
        }
        return 0;
    }

    function uri(uint256 _token, uint16 _randgeId) private view returns (uint256) {
        if(_randgeId == 0) {
            return _token;
        }

        revealStruct memory currentReveal = reveals[_randgeId];
        uint256 shiftedN = _token + currentReveal.SHIFT;
        if (shiftedN <= currentReveal.RANGE_END) {
            return shiftedN;
        }
        return currentReveal.RANGE_START + shiftedN - currentReveal.RANGE_END;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721AUpgradeable) returns(string memory) {
        require(_exists(_tokenId), "Token ID does not exist");

        uint16 rangeId = findRevealRangeForN(_tokenId);
        if(rangeId == 0) {
            return tokenPreRevealURI;
        }

        revealStruct memory currentReveal = reveals[rangeId];

        if(currentReveal.RANDOM_NUM == 0) {
            return tokenPreRevealURI;
        }

        uint256 shiftedTokenId = uri(_tokenId, rangeId);

        string memory baseURI = tokenRevealURI;

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(shiftedTokenId))) : "";
    }

    function SetWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function Withdraw() public payable onlyOwner {
        (bool success, ) = payable(paymentAddress).call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @dev Admin: Lock / Unlock transfers
     */
    function SetTransferLock(bool _locked) external onlyOwner {
        transferLocked = _locked;
        emit Locked(_locked);
    }

    /**
     * @dev Admin: Set new Payment Splitter Contract address
     */
    function SetPaymentAddress(address _paymentAddressArg) public onlyOwner {
        require(_paymentAddressArg != address(0), "Payment Contract address can't be zero.");
        paymentAddress = _paymentAddressArg;
    }

    function SetVRFCoordinator(address _vrfCoordinator) public onlyOwner{
        vrfCoordinator = _vrfCoordinator;
    }

    function SetKeyHash(bytes32 _keyhash) public onlyOwner {
        s_keyHash = _keyhash;
    }

    function SetCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function SetSaleData(SaleData memory _saleData) public onlyOwner{
        saleData = _saleData;
    }

    function SetSubscriptionId(uint64 _s_subscriptionId) public onlyOwner{
        s_subscriptionId = _s_subscriptionId;
    }

    function SetRequestConfirmations(uint16 _requestConfirmations) public onlyOwner{
        requestConfirmations = _requestConfirmations;
    }

    function MaxSupply() public view returns(uint16){
        SaleData memory _saleData = saleData;
        return _saleData.whitelistMintMaxSupply + _saleData.publicMintMaxSupply;
    }

}