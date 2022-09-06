//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
//import "./interface/IEmber.sol";
// import "./interfaces/IProxy.sol";

// import "./factory.sol";
// import "./proxy.sol";

contract Demo{
    address owner;
    constructor(){
        whitelistedAddresses[0xDbfA076EDBFD4b37a86D1d7Ec552e3926021fB97] = true;
        whitelistedAddresses[0xEc0B81a2689dA3C89d91057adDd3a50ea07CDE0e] = true;
        owner = 0xDbfA076EDBFD4b37a86D1d7Ec552e3926021fB97;
    }

    struct Lending {
        address lenderAddress;
        address adapter;
        uint256 dailyRentPrice;
        uint256 stakedTill;
        uint256 tokenId;
    }


    struct Renting {
        address payable renterAddress;
        address nft;
        uint256 tokenId;
        uint256 rentedTill;
        uint256 rentedAt;
        uint256 rentDuration;
    }

    struct LendingRenting {
       Lending lending;
       Renting renting;
    }


    event Lent(
        address indexed nftAddress,
        address indexed lenderAddress,
        uint256 tokenId,
        uint256 lendingId, 
        uint256 dailyRentPrice,
        uint256 stakedTill,
        uint256 lentAt
    );

    event Rented(
        address indexed renterAddress,
        address indexed lenderAddress,
        address indexed nft,
        uint256 tokenId,
        uint256 lendingId,
        uint256 rentDuration,
        uint256 amountPaid,
        uint256 rentedAt
    );

    event LendingStopped(address msgSender, uint256 stoppedAt, address nft);

    modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
    }
    // A unique Id for each NFT to be lended
    uint256 private lendingId;

    // represent seconds in one_day
    uint256 private ONE_DAY = 86400;
    
    //mapping(address => mapping(uint256=>bool)) public isborrowed;

    // A uint to struct mapping to store lending & renting data against Id
    mapping(uint256 => LendingRenting) public lendingRenting;

    //A address BorrowerProxy struct to store newBorrower address & proxyAddress
    //mapping(address => IEmber.BorrowerProxy) public BorrowerProxyAddress;
    mapping(address => bool) whitelistedAddresses;
    
    function addUser(address _addressToWhitelist) public onlyOwner {
    whitelistedAddresses[_addressToWhitelist] = true;
    }
    
    /**
    * @notice lend NFT for renting.
    * @dev A unique lending Id will be associated with each NFT staked.
    * @param _nft - nft address
    * @param _adapter - adapter address: adapters include functions allowed by lender
    * to be executed using it's nft by borrower
    * @param _tokenId - nft's tokenId
    * @param _maxRentDuration - rent duration for NFT
    * @param _perDayRentCharges - per day rent charges  
    * Emits a {lend} event.
    */
     
    function lend(
        address _nft,
        address _adapter, 
        uint256 _tokenId,
        uint256 _maxRentDuration,
        uint256 _perDayRentCharges
    ) external {

        createLendData(_tokenId, lendingId, _maxRentDuration, _perDayRentCharges, msg.sender, _adapter);
        ensureLendable(_maxRentDuration, _perDayRentCharges);
        IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);
        //safeTransfer(_nft, msg.sender, address(this), _tokenId, _lentAmounts);
        emit Lent(
        _nft,
        msg.sender,
        _tokenId,
        lendingId,
        _perDayRentCharges,
        lendingRenting[lendingId].lending.stakedTill,
        block.timestamp
        );

        lendingId++;
        
    }


    /**
    * @notice Rent NFT.
    * @dev for each unique borrower a proxy contract will be deployed and that
    * borrowed nft will be transffered to that proxy contract
    * payable - Amount in ETH for renting the NFT will be transffered to NFT lender 
    * @param _nft - nft address
    * @param _tokenId - nft's tokenId
    * @param _lendingId - lendingID for that NFT  
    * Emits a {rent} event.
    */

    function rent(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId,
        uint256 _rentDuration
    ) external payable{
        require(whitelistedAddresses[msg.sender],"NWU");
        uint256 amount = msg.value;
        createRentData(_lendingId, _rentDuration, _tokenId, _nft, msg.sender);
        ensureRentable(_tokenId, _lendingId, _rentDuration);
        console.log((lendingRenting[_lendingId].lending.lenderAddress).balance);
        payable(lendingRenting[_lendingId].lending.lenderAddress).transfer(address(this).balance);
        console.log((lendingRenting[_lendingId].lending.lenderAddress).balance);
        IERC721(_nft).transferFrom(address(this),msg.sender,_tokenId);
        emit Rented(
        msg.sender,
        lendingRenting[_lendingId].lending.lenderAddress,
        _nft,
        _tokenId,
        _lendingId,
        _rentDuration,
        amount,
        block.timestamp
        );
    }


    /**
    * @notice unLend the NFT.
    * @dev  get NFT from proxy if it's not in this contract and then transfer to the lender 
    * @param _nft - nft address
    * @param _tokenId - nft's tokenId
    * @param _lendingId - lendingID for that NFT 
    * Emits a {LendingStopped} event.
    */

    function stopLending(
        address _nft,
        uint256 _tokenId,
        uint256 _lendingId
    ) external {

        ensureStopable(_tokenId,_lendingId);
        IERC721(_nft).transferFrom(address(this),msg.sender,_tokenId);
        emit LendingStopped(msg.sender, block.timestamp, _nft);
            delete lendingRenting[_lendingId];
    }

      /**
    * @notice  update the renting struct agianst lendingId.
    * @param _lendingId - lendingID 
    * @param _rentDuration -  rent duration for NFT
    * @param msgSender - Renter address
    */

    function createRentData(uint256 _lendingId,  uint256 _rentDuration, uint256 _tokenId, address _nft,address msgSender) internal {

        lendingRenting[_lendingId].renting.renterAddress = payable(msgSender);
        lendingRenting[_lendingId].renting.rentedTill = block.timestamp + _rentDuration;
        lendingRenting[_lendingId].renting.rentDuration = _rentDuration;
        lendingRenting[_lendingId].renting.tokenId = _tokenId;
        lendingRenting[_lendingId].renting.nft = _nft;
        
    
    }


    /**
    * @notice  update the lending struct agianst lendingId.
    * @param _tokenId - lendingID 
    * @param _lendingId - lendingID 
    * @param _maxRentDuration - NFT lend duration i.e for 30 days
    * @param _perDayRentPrice - _perDayrentPrice
    * @param msgSender - lender address
    * @param _adapter - adapter address
    */

    function createLendData(uint256 _tokenId,uint256 _lendingId, uint256 _maxRentDuration, uint256 _perDayRentPrice, address msgSender, address _adapter) internal{

        lendingRenting[_lendingId].lending.lenderAddress = msgSender;
        lendingRenting[_lendingId].lending.adapter = _adapter;
        lendingRenting[_lendingId].lending.dailyRentPrice = _perDayRentPrice;
        lendingRenting[_lendingId].lending.stakedTill = block.timestamp + _maxRentDuration;
        lendingRenting[_lendingId].lending.tokenId = _tokenId; 
    
    }

    /**
    * @notice  returns the proxy address for after delopying new proxy contract cond: unique borrrower
    * @dev check that isnewBorrower then deploy new Proxy; update Borrowerproxy struct & return proxy Address
    * @param _lendingId - lendingID 
    * @param _borrower - borrower address
    */
    
    // view functions 

    /**
     * @dev ensure the NFT is lendable by passing through require checks
     * @param _maxRentDuration - lended till
     * @param _dailyRentPrice  - per day rent charges 
    */

    function ensureLendable(uint256 _maxRentDuration, uint256 _dailyRentPrice) internal pure{

        require(_maxRentDuration!=0 && _dailyRentPrice!=0,"Ember :: Invalid Parameters");
    
    }


    /**
     * @dev ensure the NFT is rentable by passing through require checks
     * @param _tokenId - tokenid
     * @param _lendingId - lendingId
     * @param _rentDuration - rent duration for NFT 
    */

    function ensureRentable(uint256 _tokenId, uint256 _lendingId, uint256 _rentDuration) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress!=msg.sender, "Lender can't be borrower for it's own NFT");
        require(_rentDuration!=0,"Ember :: Invalid RentDuaration");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember::invalid tokenId || _lendingId");
        require(lendingRenting[_lendingId].renting.rentedTill <= lendingRenting[_lendingId].lending.stakedTill,"Ember::Rent duration>staked duration");
        require(lendingRenting[_lendingId].lending.dailyRentPrice * (lendingRenting[_lendingId].renting.rentDuration)/ONE_DAY == msg.value, "Invalid Amount");
    
    }

    /**
     * @dev ensure the NFT is can unlendable by passing through require checks
     * @param _tokenId - tokenId
     * @param _lendingId - lendingId
    */

    function ensureStopable(uint256 _tokenId, uint256 _lendingId) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress == msg.sender, "Ember::not lender");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember:: invalid tokenId || _lendingId");
    
    }

    // Getter Functions


    /**
     * @dev checks whether NFT is type of ERC721 & returns true if success 
     * @param _nft nft address
    */

    
    /**
     * @dev Returns the adapter address against lendingId
     * @notice this function can be called from proxy contract  
     * @param _lendingId - lendingId
    */

    function getNFTAdapter(uint256 _lendingId) external view returns(address){

        return lendingRenting[_lendingId].lending.adapter;
        
    }

    /**
     * @dev Returns the proxy address against borrower  
     * @param _borrower - borrower address
    */

    


    /**
     * @dev Returns the NFT staked Till  
     * @param _lendingId - lendingId
    */
    function getStakedTill(uint256 _lendingId) external view returns(uint256){

        return lendingRenting[_lendingId].lending.stakedTill; 
    
    }

    /**
     * @dev Returns the NFT rented Till  
     * @param _lendingId - lendingId
    */
    function getRentedTill(uint256 _lendingId) external view returns(uint256){

        return lendingRenting[_lendingId].renting.rentedTill; 
    
    }


    /**
     * @dev Returns the NFT per day rent charges  
     * @param _lendingId - lendingId
    */
    function getDailyRentCharges(uint256 _lendingId) external view returns(uint256){

        return lendingRenting[_lendingId].lending.dailyRentPrice; 
    
    }

    /**
     * @dev Returns the NFT address & tokenId associated to the lendingId  
     * @param _lendingId - lendingId
    */

    function getNFTtokenID(uint256 _lendingId) external view returns(address,uint256){
        return (lendingRenting[_lendingId].renting.nft,lendingRenting[_lendingId].renting.tokenId);
    }
}