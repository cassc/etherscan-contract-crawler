//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IEmber.sol";
import "./interfaces/IProxy.sol";
import "./factory.sol";
import "./proxy.sol";

contract Ember is factory, IEmber{

    // A unique Id for each NFT to be lended
    uint256 private lendingId;

    // represent seconds in one day
    uint256 public ONE_DAY = 86400;

    // A uint to struct mapping to store lending & renting data against Id
    mapping(uint256 => IEmber.LendingRenting) private lendingRenting;

    //A address BorrowerProxy struct to store newBorrower address & proxyAddress
    mapping(address => IEmber.BorrowerProxy) private BorrowerProxyAddress;
    
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
    ) external override {

        createLendData(_tokenId, lendingId, _maxRentDuration, _perDayRentCharges, msg.sender, _adapter);

        ensureLendable(_nft, _maxRentDuration, _perDayRentCharges);

        IERC721(_nft).transferFrom(msg.sender,address(this),_tokenId);

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
    ) external override payable returns(address){
        uint256 amount = msg.value;
        address proxy = getProxy(_lendingId, msg.sender);

        if(IERC721(_nft).ownerOf(_tokenId) != address(this)){
            
            IProxy(proxy).getNFT(_nft, _tokenId, _lendingId);    

        }

        createRentData(_lendingId, _rentDuration, _tokenId, _nft, msg.sender);
        
        ensureRentable(_nft, _tokenId, _lendingId, _rentDuration);
        
        payable(lendingRenting[_lendingId].lending.lenderAddress).transfer(address(this).balance);
        
        IERC721(_nft).transferFrom(address(this),proxy,_tokenId);
        
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
        
        return proxy;   
    }


    /**
    * @notice unLend the the NFT.
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
    ) external override {

        ensureStopable(_nft,_tokenId,_lendingId);

        if(IERC721(_nft).ownerOf(_tokenId)!= address(this)){
    
            IProxy(checkProxy(lendingRenting[_lendingId].renting.renterAddress)).getNFT(_nft, _tokenId, _lendingId);
           
        }

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
    


    function getProxy(uint256 _lendingId, address _borrower) internal returns(address){
        
        if(!BorrowerProxyAddress[_borrower].newBorrower) // new borrower
        {   
            
            bytes memory bytecode = getbytecode(address(this), _borrower);
            getAddress(bytecode, _lendingId);
            address _proxyAddress = deploy(bytecode, _lendingId);
            BorrowerProxyAddress[_borrower].newBorrower = true;
            BorrowerProxyAddress[_borrower].proxyAddress = _proxyAddress;
            
        }

        return BorrowerProxyAddress[_borrower].proxyAddress;

    }

    // view functions 

    /**
     * @dev ensure the NFT is lendable by passing through require checks
     * @param _nft - nft address
     * @param _maxRentDuration - lended till
     * @param _dailyRentPrice  - per day rent charges 
    */

    function ensureLendable(address _nft, uint256 _maxRentDuration, uint256 _dailyRentPrice) internal view{

        require(is721(_nft),"Ember:: Not ERC721 token");
        require(_maxRentDuration!=0 && _dailyRentPrice!=0,"Ember :: Invalid Parameters");
    
    }


    /**
     * @dev ensure the NFT is rentable by passing through require checks
     * @param _nft - nft address
     * @param _tokenId - tokenid
     * @param _lendingId - lendingId
     * @param _rentDuration - rent duration for NFT 
    */

    function ensureRentable(address _nft, uint256 _tokenId, uint256 _lendingId, uint256 _rentDuration) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress!=msg.sender, "Lender can't be borrower for it's own NFT");
        require(_rentDuration!=0,"Ember :: Invalid RentDuaration");
        require(is721(_nft),"Ember:: Not ERC721 token");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember::invalid tokenId || _lendingId");
        require(lendingRenting[_lendingId].renting.rentedTill <= lendingRenting[_lendingId].lending.stakedTill,"Ember::Rent duration>staked duration");
        require(lendingRenting[_lendingId].lending.dailyRentPrice * (lendingRenting[_lendingId].renting.rentDuration)/ONE_DAY == msg.value, "Invalid Amount");
    
    }

    /**
     * @dev ensure the NFT is can unlendable by passing through require checks
     * @param _nft - nft address
     * @param _tokenId - tokenId
     * @param _lendingId - lendingId
    */

    function ensureStopable(address _nft, uint256 _tokenId, uint256 _lendingId) internal view{

        require(lendingRenting[_lendingId].lending.lenderAddress == msg.sender, "Ember::not lender");
        require(is721(_nft),"Ember:: Not ERC721 token");
        require(lendingRenting[_lendingId].lending.tokenId == _tokenId,"Ember:: invalid tokenId || _lendingId");
    
    }

    // Getter Functions


    /**
     * @dev checks whether NFT is type of ERC721 & returns true if success 
     * @param _nft nft address
    */

    function is721(address _nft) private view returns (bool) {

        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    /**
     * @dev Returns the adapter address against lendingId
     * @notice this function can be called from proxy contract  
     * @param _lendingId - lendingId
    */

    function getNFTAdapter(uint256 _lendingId) external override view returns(address){

        return lendingRenting[_lendingId].lending.adapter;
        
    }

    /**
     * @dev Returns the proxy address against borrower  
     * @param _borrower - borrower address
    */

    function checkProxy(address _borrower) public override view returns(address){

        return BorrowerProxyAddress[_borrower].proxyAddress;
        
    }


    /**
     * @dev Returns the NFT staked Till  
     * @param _lendingId - lendingId
    */
    function getStakedTill(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].lending.stakedTill; 
    
    }

    /**
     * @dev Returns the NFT rented Till  
     * @param _lendingId - lendingId
    */
    function getRentedTill(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].renting.rentedTill; 
    
    }


    /**
     * @dev Returns the NFT per day rent charges  
     * @param _lendingId - lendingId
    */
    function getDailyRentCharges(uint256 _lendingId) external override view returns(uint256){

        return lendingRenting[_lendingId].lending.dailyRentPrice; 
    
    }

    /**
     * @dev Returns the NFT address & tokenId associated to the lendingId  
     * @param _lendingId - lendingId
    */

    function getNFTtokenID(uint256 _lendingId) external override view returns(address,uint256){

        return (lendingRenting[_lendingId].renting.nft,lendingRenting[_lendingId].renting.tokenId);
    }
}