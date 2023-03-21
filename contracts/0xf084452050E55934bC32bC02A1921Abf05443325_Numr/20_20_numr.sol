// SPDX-License-Identifier: MIT
/*
          _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \         
        /::\____\                /::\____\                /::\____\                /::\    \        
       /::::|   |               /:::/    /               /::::|   |               /::::\    \       
      /:::::|   |              /:::/    /               /:::::|   |              /::::::\    \      
     /::::::|   |             /:::/    /               /::::::|   |             /:::/\:::\    \     
    /:::/|::|   |            /:::/    /               /:::/|::|   |            /:::/__\:::\    \    
   /:::/ |::|   |           /:::/    /               /:::/ |::|   |           /::::\   \:::\    \   
  /:::/  |::|   | _____    /:::/    /      _____    /:::/  |::|___|______    /::::::\   \:::\    \  
 /:::/   |::|   |/\    \  /:::/____/      /\    \  /:::/   |::::::::\    \  /:::/\:::\   \:::\____\ 
/:: /    |::|   /::\____\|:::|    /      /::\____\/:::/    |:::::::::\____\/:::/  \:::\   \:::|    |
\::/    /|::|  /:::/    /|:::|____\     /:::/    /\::/    / ~~~~~/:::/    /\::/   |::::\  /:::|____|
 \/____/ |::| /:::/    /  \:::\    \   /:::/    /  \/____/      /:::/    /  \/____|:::::\/:::/    / 
         |::|/:::/    /    \:::\    \ /:::/    /               /:::/    /         |:::::::::/    /  
         |::::::/    /      \:::\    /:::/    /               /:::/    /          |::|\::::/    /   
         |:::::/    /        \:::\__/:::/    /               /:::/    /           |::| \::/____/    
         |::::/    /          \::::::::/    /               /:::/    /            |::|  ~|          
         /:::/    /            \::::::/    /               /:::/    /             |::|   |          
        /:::/    /              \::::/    /               /:::/    /              \::|   |          
        \::/    /                \::/____/                \::/    /                \:|   |          
         \/____/                  ~~                       \/____/                  \|___|          
                                                                                                    
*/
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/utils.sol";
import "../IERC4906.sol";
contract Numr is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard, IERC4906 {
    using SafeMath for uint;
    uint public thresholdFreeMint = 100000;
    uint public maxFeeMint = 999999;
    uint public thresholdPaidMint = 10000;
    uint public totalCommunityMint = 1000;
    uint public price = 9000000000000000; //.009 eth
    uint public priceBurn = 900000000000000; // .0009 eth
    uint public auctionPeriod = 86400;
    uint public swapPoint = 200;
    uint public stepPrice = 50000000000000000; //0.05 eth
    uint public totalSupplyPaidMint = 0;
    uint public totalBidding = 0;
    uint public basePriceFourDigit = 300000000000000000; // .3 eth
    uint public basePriceThreeDigit = 3000000000000000000; // 3 eth
    uint public totalAvailablesBidThreeNumber = 841;
    uint public totalAvailablesBidFourNumber = 8791;
    uint public totalAvailablesFreeBidThreeNumber = 50;
    uint public totalAvailablesFreeBidFourNumber = 200;
    uint public addNonBidThreeNumber = 0;
    uint public addNonBidFourNumber = 0;
    uint public addCommunityMint = 0;
    uint[] public tokenBidding;
    bool public isAscend = false;
    bool public isSwap = true;
    bool public isStartTimePaidMint = false;
    bool public isStartTimeBidThreeNumber = false;
    bool public isStartTimeBidFourNumber = false;
    address public reserveWallet;
    /*//////////////////////////////////////////////////////////////
                                STRUCT
    //////////////////////////////////////////////////////////////*/
    struct List {
        address to;
        uint bid;
        uint blockTime;
    }

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint)) public bidUser;
    mapping(address => bool) public freeMintAddress;
    mapping(uint => uint) public minBid;
    mapping(uint => uint) public maxBid;
    mapping(uint => address) public userBid;
    mapping(uint => uint) public latestBid;
    mapping(uint => List[]) public list;
    mapping(uint => uint) power;
    mapping(address => address[]) private listRef;
    mapping(address => uint) public referralPoint;
    mapping(address => address) public sponsor;
    mapping(address => mapping(uint => uint)) public nonBids;
    mapping(address => uint) public nonPaidMint;
    mapping(uint => bool) public isReserveToken;
    mapping(uint => bool) public isMinted;
    mapping(address => uint) public communitySlot;
    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAdmin {
        require(admin[msg.sender]);
        _;
    }
    modifier verifyListTokenId(uint[] memory tokenId) {
        for(uint i = 0; i < tokenId.length; i++){
            require(!isMinted[tokenId[i]]);
        }
        _;
        for(uint i = 0; i < tokenId.length; i++){
            isMinted[tokenId[i]] = true;
        }
    }
    modifier verifyTokenId(uint tokenId){
        require(!isMinted[tokenId]);
        _;
        isMinted[tokenId] = true;
    }
    modifier isFeeMinted(address user){
        require(!freeMintAddress[user]);
        _;
        freeMintAddress[user] = true;
    }
    modifier verifyPaidMint(uint[] memory tokenId){
        require( (totalSupplyPaidMint + tokenId.length) <= (89991 - totalCommunityMint));
        _;
        totalSupplyPaidMint += tokenId.length;
    }
    modifier verifyCommunityMint(uint[] memory tokenId) {
        require(communitySlot[msg.sender] >= tokenId.length);
        _;
        communitySlot[msg.sender] -= tokenId.length;
    }
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Mint(
        address to,
        uint tokenId,
        uint price,
        uint blockTime
    );
    event Bid(
        address to,
        uint tokenId,
        uint bid,
        uint blockTime
    );
    event Withdraw(
        address to,
        uint amount,
        uint blockTime
    );
    event UpdateMinBid(
        uint tokenId,
        uint bid,
        uint blockTime
    );
    event AddAdmin(
        address admin,
        uint blockTime
    );

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _reserveWallet) ERC721("Numr", "NUMR") { 
        reserveWallet = _reserveWallet;
        // mintReserve(_tokenId);
    }
    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function addTokenReserve(uint[] memory _tokenId) external onlyOwner {
        for(uint i =0; i < _tokenId.length; i++){
            isReserveToken[_tokenId[i]] = true;
        }
    }
    function mintReserve(uint[] memory _tokenId) external  verifyListTokenId(_tokenId) onlyOwner {
        for(uint i =0; i < _tokenId.length; i++){
            require((_tokenId[i] > 0 && _tokenId[i]< 100 ) ||  isReserveToken[_tokenId[i]])  ;
            _mint(msg.sender, _tokenId[i]);
        }
    }
    function updateStepPrice(uint _price) external onlyOwner {
        require(_price > 0);
        stepPrice = _price;
    }
    function updateIsTime(uint _time) external onlyOwner {
        require(_time == 1 || _time == 2 || _time ==3);
        if(_time == 1){
            isStartTimePaidMint = true;
        }
        if(_time == 2){
            isStartTimeBidThreeNumber = true;
        }
        if(_time == 3){
            isStartTimeBidFourNumber = true;
        }
    }
    function addAddmin(address[] memory _admin) external onlyOwner {
        for(uint i; i < _admin.length; i++){
            admin[_admin[i]] = true;
            emit AddAdmin(_admin[i], block.timestamp);
        }
    }
    function updateMinBid(uint tokenId, uint _bid) external onlyAdmin {
        minBid[tokenId] = _bid;
        emit UpdateMinBid(tokenId, _bid, block.timestamp);
    }

    function toggleAscend() public onlyOwner {
        isAscend = !isAscend;
    }

    function swapBidding() public onlyOwner {
        isSwap = !isSwap;
    }

    function addNonBids(address[] calldata addresses, uint[] calldata quantity, uint option) external onlyOwner {
        // option == 1 Bidding 3 number
        // option == 2 Bidding 4 number
        uint totalQuantity = 0;
        require(option == 1 || option == 2);
        require(addresses.length == quantity.length);
        for (uint i = 0; i < addresses.length; i++) {
            nonBids[addresses[i]][option] += quantity[i];
            totalQuantity += quantity[i];
        }
        if(option == 1 ){
            addNonBidThreeNumber += totalQuantity;
            require(addNonBidThreeNumber <= totalAvailablesFreeBidThreeNumber);
        }else {
            addNonBidFourNumber += totalQuantity;
            require(addNonBidFourNumber <= totalAvailablesFreeBidFourNumber);
        }
    }

    function addCommunity(address[] calldata addresses, uint[] calldata quantity) external onlyOwner {
        uint totalQuantity = 0;
        require(addresses.length == quantity.length);
        for(uint i = 0; i < addresses.length; i++){
            communitySlot[addresses[i]] += quantity[i];
            totalQuantity += quantity[i];
        }
        require((addCommunityMint + totalQuantity) <= totalCommunityMint);
        addCommunityMint += totalQuantity;
    } 

    /*//////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function freeMint(address to, uint tokenId, address ref) external verifyTokenId(tokenId) isFeeMinted(to){
        require(thresholdFreeMint <= tokenId && tokenId <= maxFeeMint);
        require(!isReserveToken[tokenId]);
        addSponsor(msg.sender, ref);
        addPower(initValue(tokenId), msg.sender);
        _mint(to, tokenId);
        emit Mint(to, tokenId, 0, block.timestamp);
    }

    function paidMint(address to, uint[] memory tokenId, address ref) external verifyListTokenId(tokenId) verifyPaidMint(tokenId) nonReentrant payable {
        require(isStartTimePaidMint);
        addSponsor(msg.sender, ref);
        uint pricePaid = getPricePaidMint();
        require(msg.value >= tokenId.length * pricePaid, "not enough eth");
        require(payable(reserveWallet).send(msg.value));    
        uint powerUser = 0;
        for(uint i = 0 ; i < tokenId.length; i++){
            require(tokenId[i] >= thresholdPaidMint && tokenId[i] < thresholdFreeMint);
            require(!isReserveToken[tokenId[i]]);
            powerUser = powerUser + initValue(tokenId[i]);
            _mint(to, tokenId[i]);
            emit Mint(to, tokenId[i], price, block.timestamp);
        }
        addPower(powerUser, msg.sender);
    }

    function pointMint(address to, uint[] memory tokenId) external verifyListTokenId(tokenId) verifyPaidMint(tokenId) nonReentrant {
        require(isStartTimePaidMint);
        require(isSwap);
        require(referralPoint[msg.sender] >= tokenId.length * swapPoint );
        for(uint i = 0 ; i < tokenId.length; i++){
            require(tokenId[i] >= thresholdPaidMint && tokenId[i] < thresholdFreeMint);
            require(!isReserveToken[tokenId[i]]);
            _mint(to, tokenId[i]);
            emit Mint(to, tokenId[i], price, block.timestamp);
        }
        referralPoint[msg.sender]  -= tokenId.length * swapPoint;
    }

    function communityMint(address to, uint[] memory tokenId) external verifyListTokenId(tokenId) verifyCommunityMint(tokenId) nonReentrant {
         for(uint i = 0 ; i < tokenId.length; i++){
            require(tokenId[i] >= thresholdPaidMint && tokenId[i] < thresholdFreeMint);
            require(!isReserveToken[tokenId[i]]);
            _mint(to, tokenId[i]);
            emit Mint(to, tokenId[i], price, block.timestamp);
        }
    }
    function bid(uint tokenId, uint _bid, address ref) external nonReentrant payable {
        uint totalBid = (tokenId < 1000) ? totalAvailablesBidThreeNumber : totalAvailablesBidFourNumber;
        bool isTimeBid = (tokenId < 1000) ?  isStartTimeBidThreeNumber : isStartTimeBidFourNumber;
        require(totalBid > 0);
        require(!isMinted[tokenId]);
        require(msg.value == _bid && _bid >= basePrice(tokenId));
        require(isTimeBid);
        require(!_exists(tokenId));
        require(tokenId < thresholdPaidMint && tokenId > 99);
        require(!isReserveToken[tokenId]);
        addSponsor(msg.sender, ref);
        bidUser[msg.sender][tokenId] = _bid;
        if(userBid[tokenId] != address(0)){
            require(payable(userBid[tokenId]).send(maxBid[tokenId]));
            require(_bid >= maxBid[tokenId] + stepPrice);
        }
        if(list[tokenId].length == 0){
            tokenBidding.push(tokenId);
            totalBidding +=1;
        }
        list[tokenId].push(List(msg.sender, _bid, block.timestamp));
        maxBid[tokenId] = _bid;
        userBid[tokenId] = msg.sender;
        latestBid[tokenId] = block.timestamp;        
        emit Bid(msg.sender, tokenId, _bid, block.timestamp);
    }

    function claimWinAuction(address to, uint tokenId) external nonReentrant verifyTokenId(tokenId){
        require(bidUser[msg.sender][tokenId] == maxBid[tokenId] && (latestBid[tokenId] + auctionPeriod) <= block.timestamp);
        require(maxBid[tokenId] > 0, "not enough eth");
        require(payable(reserveWallet).send(maxBid[tokenId]));
        addPower(initValue(tokenId), msg.sender);
        _mint(to, tokenId);
        if(tokenId < 1000){ totalAvailablesBidThreeNumber -= 1; } else { totalAvailablesBidFourNumber -= 1; }
        emit Mint(to, tokenId, maxBid[tokenId], block.timestamp);
    } 

    function nonBid(address to , uint tokenId, address ref) external nonReentrant verifyTokenId(tokenId) payable {
        uint freeBidType = (tokenId < 1000) ? 1 : 2;
        uint priceBid = (tokenId < 1000) ? basePriceThreeDigit : basePriceFourDigit;
        require(nonBids[msg.sender][freeBidType] >= 1);
        require(msg.value >= priceBid, "not enough eth");
        require(!isReserveToken[tokenId]);
        addSponsor(msg.sender, ref);
        addPower(initValue(tokenId), msg.sender);
        if(userBid[tokenId] != address(0)){
            require(payable(userBid[tokenId]).send(maxBid[tokenId]));
        }
        _mint(to, tokenId);
        nonBids[msg.sender][freeBidType] -= 1;
        emit Mint(to, tokenId, maxBid[tokenId], block.timestamp);
    }
    function ascend(uint[] memory tokens) external payable {
        require(isAscend, "ascending not active");
        uint sum;
        uint totalFreeBurn;
        for (uint i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "must own all tokens");
            sum = sum + getPower(tokens[i]);
        }
        for (uint i = 1; i < tokens.length; i++) {
            _burn(tokens[i]);     
            if(tokens[i] >= 100000 && tokens[i]< 1000000){
                totalFreeBurn = totalFreeBurn + 1;
            }
            power[tokens[i]] = 0;
            emit MetadataUpdate(tokens[i]);
        }
        if(totalFreeBurn > 0){
            require(msg.value >= totalFreeBurn * priceBurn, "not enough eth");
        }
        // Why was 6 afraid of 7? Because 7 8 9!
        power[tokens[0]] = sum;
        emit MetadataUpdate(tokens[0]);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/
    function isExists(uint tokenId) external view returns(bool){
       return _exists(tokenId);
    }

    function basePrice(uint tokenId) public view returns(uint){
        uint _price =  (tokenId < 1000) ? basePriceThreeDigit : basePriceFourDigit;
        uint result = _price > minBid[tokenId] ? _price : minBid[tokenId];
        return result;
    }

    function getPricePaidMint() public view returns(uint) {
        uint result;
        if(totalSupplyPaidMint < 400000){
            result = price/3;
        }else if(totalSupplyPaidMint < 700000){ 
            result = 2 * price / 3;
        }else if(totalSupplyPaidMint < thresholdFreeMint){
            result = price;
        }
        return result;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return getMetadata(tokenId);
    }

    function getPower(uint256 tokenId) public view returns (uint) {
        if (!_exists(tokenId)) {
            return 0;
        } else if (power[tokenId] > 0) {
            return power[tokenId];
        } else {
            return initValue(tokenId);
        }
    }

    function biddingList(uint256 tokenId) public view returns (List[] memory){
        return list[tokenId];
    }

    function getReferralPoint(address user) external view returns (uint){
        return referralPoint[user];
    }
    function getReferral(address user) external view returns (address[] memory){
        return listRef[user];
    }
    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function addSponsor(address user, address _sponsor) internal {
        require(user != _sponsor && sponsor[_sponsor] != user);
        if(sponsor[user] == address(0) && _sponsor != address(0)){
            sponsor[user] = _sponsor;
            listRef[_sponsor].push(user);
        }
    }
    function addPower(uint _power, address user) internal {
        if(sponsor[user] != address(0)){
            referralPoint[sponsor[user]] = referralPoint[sponsor[user]] + _power;
        }
    }
    
    function initValue(uint tokenId) internal pure returns (uint value) {
        if (tokenId < 10) {
            value = 400;
        } else if (tokenId < 100) {
            value = 350;
        }  else if (tokenId < 1000) {
            value = 300;
        }  else if (tokenId < 10000) {
            value = 100;
        }  else if (tokenId < 100000) {
            value = 10;
        }  else if (tokenId < 1000000) {
            value = 1;
        } else {
            value = 0;
        }
        return value;
    }

    function getType(uint tokenId) internal view returns(string memory){
        string memory result;
        if(tokenId < 99 || isReserveToken[tokenId]){
            result = 'Special Event';
        }
        else if(tokenId < thresholdPaidMint){
            result = 'Auction';
        }
        else if(tokenId >= thresholdPaidMint && tokenId < thresholdFreeMint){
            result = 'Paid';
        }
        else if(tokenId >= thresholdFreeMint && tokenId < maxFeeMint){
            result = 'Airdrop';
        }else {
            result = '0x0';
        }
        return result;
    }

    function getTier(uint tokenId) internal pure returns (string memory) {
        string memory value;
        if (tokenId < 10) {
            value = 'Ultimate';
        } else if (tokenId < 100) {
            value = 'Immortal';
        }  else if (tokenId < 1000) {
            value = 'Legendary';
        }  else if (tokenId < 10000) {
            value = 'Epic';
        }  else if (tokenId < 100000) {
            value = 'Rare';
        }  else if (tokenId < 1000000) {
            value = 'Common';
        } else {
            value = 'Non';
        }
        return value;
    }

    function getMetadata(uint tokenId) internal view returns (string memory) {
        string memory json;

        if (!_exists(tokenId)) {
            json = string(abi.encodePacked(
            '{"name": "NUMR ',
            utils.uint2str(tokenId),
            '", "description": "The Unique Number NFTs Collection."}'
        ));
        }else {
             json = string(abi.encodePacked(
            '{"name": "NUMR ',
            utils.uint2str(tokenId),
            '", "description": "The Unique Number NFTs Collection.", "attributes":[{"trait_type": "Number", "value": "',  utils.uint2str(tokenId),'"}',
            ',{"trait_type": "Power", "value": "', utils.uint2str(getPower(tokenId)),
            '"},{"trait_type": "Tier", "value": "', getTier(tokenId),'"}], "image": "https://img.numr.io/',
            utils.uint2str(tokenId),
            '"}'
            ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function getTokenBidding() external view returns (uint[] memory) {
        return tokenBidding;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}