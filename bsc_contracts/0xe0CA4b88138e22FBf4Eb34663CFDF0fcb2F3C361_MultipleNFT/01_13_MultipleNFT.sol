// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MultipleNFT is ERC1155 {
    address owner;
    uint256 public mintPrice = 5000000000000000; // 0.005 ether
    // Variables
    uint256 public maxMintAmount = 100;

    struct NFTInfo {
        uint id;
        uint price;
        uint reserves;
        uint256 copies;
        string mintName;
        uint256 timeofmint;
        string description;
        string nftowner;
        string uri;
       }
    
    struct collectioninfo
    {
        address collectionowner;
        bytes Cname;
        bytes Dname;
        bytes websiteURL;
        bytes description;
        bytes imghash;
        uint256 marketfees;
    }

    mapping(uint256 => NFTInfo) public nftInfo;
    uint[] ids;
    uint[] prices;
    uint[] maxAmounts;
    string baseExtension = ".json";
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    string baseURI = "https://ipfs.io/ipfs/QmcDRWwXCE1LjvdESNZsmc75syTJP2zA8WW9SHEaCwEmkc/";
    mapping(uint256 => uint256) nftType;
    address[] approvers;
    modifier onlyOwner() {
        require(msg.sender == devwallet, "not owner");
        _;
    }
     struct MintVariables {
        uint idx;
        uint id;
        uint price;
        uint reserves;
        uint amount;
        uint totalPrice;
        uint beneficiaryAmount;
        uint devAmount;
        uint category;
    }
    
    MintVariables  mintVariables;
    mapping(string => bool) stopduplicate;
    address _stackingContract;
    mapping(uint256 =>collectioninfo) collection;
    mapping(uint256 => mapping(address=>bool)) public stakerAddress;
    mapping(address => uint256 []) public userinfo;
    mapping(address => uint256) public totalcollection;
    mapping(uint256 => uint256 []) public collectionstored;
    mapping(uint256=>uint256) public totalnft;
    mapping(uint256=>mapping(uint256=>uint256)) idnumber;
    mapping(uint256 => uint256) public nftcollectionid;
    mapping(uint256 => address) public originalowner;
    mapping(uint256 => mapping (address => bool)) public isMinted;
    mapping(uint256=>uint256) csdogenumber;
    mapping(uint256 => bool) public csdogechoice;
    address payable private devwallet;
    uint32 private MINUTES_IN_DAY;
    address[] public stakersArray;
    uint256 [] csdogearray;
    uint256 public tokenidmint;
    uint256 public collectionform;
    uint256 public csdogefees = 2;
    mapping(uint256 => fixedsale) nftprice;
    mapping(uint256=>uint256) public salenftlist;
    mapping(uint256 =>auction) timeforauction;
    uint256 public auctionfees = 20;
    uint256 []  salenft;
    uint256 [] auctionnft;
    uint256 private devFeeVal;
    mapping(uint256 => address) finalowner;
    mapping(uint256 =>mapping(address => uint256)) amountforauction;
    mapping(uint256=>bool) public nftstakestate;
    mapping(uint256=>uint256) public auctionnftlist;
    uint public numberOfApprovers;
    address token;

     struct fixedsale
    {
         uint256 price;
         bool inlist;
    }
     struct auction
    {
        uint256 time;
        uint256 minprice;
        bool inlist;
        uint256 biddingamount;
        
    }
    event MintNFT(
        address to,
        uint256 _id,
        uint256 _catories,
        uint256 amount,
        bytes data
    );
    event MintBatchNFT(
        address to,
        uint256[] ids,
        uint256[] amounts,
        uint256[] _catories,
        bytes data
    );
    constructor() ERC1155(baseURI) {
        devwallet = payable(msg.sender);
        numberOfApprovers = 0;
        devFeeVal = 10;
    }

    function setToken (address _token) public onlyOwner{
        token = _token;
    }

    function BulkaddNFT(
        uint256[] memory ids_,
        string[] memory mintnames_,
        uint[] memory maxAmounts_,
        string[] memory descriptions,
        string[] memory nftowners,
        uint256[] memory copies,
        string[] memory _uris
    ) public {
        ids = ids_;
        maxAmounts  = maxAmounts_;
        string[] memory mintnames =  mintnames_;
        require(ids.length == prices.length && ids.length == maxAmounts.length,"TokenIDs, TokenPrices and TokenAmounts should be of the same length");
         for(uint i =0; i< ids.length; i++) {
            addNFT(ids[i], mintnames[i], maxAmounts[i], descriptions[i],nftowners[i],copies[i],_uris[i]);
         }
    }
    function addNFT (
        uint256  id_,
        string memory mintName_,
        uint256  maxAmount_,
        string memory _description,
        string memory _nftowner,
        uint256 copies,
        string memory _uri
    ) public {
        nftInfo[id_]=NFTInfo(
            id_,
            mintPrice,
            copies,
            maxAmount_,
            mintName_,
            block.timestamp,
            _description,
            _nftowner,
            _uri
        );

    }

    function getApprovers() public view returns(address[] memory){
        return approvers;
    }

    function setApprover(address _approver) public onlyOwner {
        isApprover[_approver] = true;
        numberOfApprovers = numberOfApprovers + 1;
        approvers.push(_approver);
    }
    
    function setIntializeApprovers() public onlyOwner {
        uint length = approvers.length;
        for (uint i = 0; i< length;i++)
        {
            address approver = approvers[i];
            isApprover[approver] =  false;
        }
        delete approvers;
        numberOfApprovers = 0;
    }

     function createcsdoge(
        uint256 collectionid,
        address to,
        string memory _uri, 
        string memory _mintname,
        string memory _nftowner,
        string memory description,
        uint256 copies
     ) external 
    {        
        require(!stopduplicate[_uri],"value not allowed");
        tokenidmint+=1;
        addNFT(tokenidmint, _mintname, copies, description, _nftowner,copies, _uri);
        collectionstored[collectionid].push(tokenidmint);
        totalnft[collectionid]+=1;
        idnumber[collectionid][tokenidmint]=totalnft[collectionid]-1;
        nftcollectionid[tokenidmint]=collectionid;
        originalowner[tokenidmint]=msg.sender;
        // mint(to,tokenidmint,collectionid,_copies,description);
        stopduplicate[_uri]=true;
        csdogenumber[tokenidmint]=csdogearray.length;
        csdogearray.push(tokenidmint);
    }
     function createcollection(string memory _Cname,string memory _Dname,string memory _wensiteURL,string memory _description,string memory _imghash,uint256 _marketfee) external 
    {
        require(!stopduplicate[_imghash],"value not allowed");
        collectionform+=1;
        collection[collectionform].collectionowner = msg.sender;
        collection[collectionform].Cname = bytes(_Cname);
        collection[collectionform].Dname = bytes(_Dname);
        collection[collectionform].websiteURL = bytes(_wensiteURL);
        collection[collectionform].description = bytes(_description);
        collection[collectionform].imghash = bytes(_imghash);
        collection[collectionform].marketfees = _marketfee;
        userinfo[msg.sender].push(collectionform);
        totalcollection[msg.sender]=collectionform;
        stopduplicate[_imghash]=true;
    }
    function mintNFT(
        address to,
        uint256 _id,
        uint256 _category,
        uint256 amount,
        bytes memory data
    )  public payable {
        require(to != address(0x0), "invalid address");
        require(_id <= tokenidmint, "NFT doesn't exist");
        uint256 price;
        uint256 nftReserves;
        price = nftInfo[_id].price;    
        nftReserves = nftInfo[_id].reserves;

        require( nftReserves >= amount,"ERC1155: Sorry, this NFT's sold out!");
       
          if(csdogechoice[_id])
        {
            uint256 totalPrice = amount*nftprice[_id].price;
            require(token!=address(0),'not valid address');
            require(IERC20(token).balanceOf(msg.sender) > totalPrice);
            uint256 fee = devFee(totalPrice);
            IERC20(token).transferFrom(msg.sender,address(this),totalPrice-fee);
            IERC20(token).transferFrom(msg.sender, devwallet,fee);
            
        }
        else{
            require(price*amount <= msg.value,"ERC1155: You don't have enough funds.");
            uint256 fee = devFee(msg.value);
            devwallet.transfer(fee);
        }

        _updateReserves(_id,amount);
        _mint(to, _id, amount, "");
        isMinted[_id][to] = true;
        nftprice[_id].inlist=false;
        emit MintNFT(to, _id, _category, amount, data);
    }
    function devFee(uint256 amount) public view returns(uint256){
        return amount*devFeeVal/100;
    }
    function _updateReserves(uint256 _idx,uint256 amount) internal {
        nftInfo[_idx].reserves -= amount;
    }

    function setURI(string memory newuri) private {
        _setURI(newuri);
    }

      function totalcollectiondetails() external view returns(uint [] memory)
    {
        return userinfo[msg.sender];
    }

    function timing(uint256 tokenid) external view returns(uint256)
    {
        if(timeforauction[tokenid].time>=block.timestamp)
        {
            return (timeforauction[tokenid].time-block.timestamp);
        }
        else
        {
            return uint256(0);
        }
    }
    
     function  csdogeinfo(uint256 tokenid) external view returns(bool,uint256,uint256)
    {
        uint256 _idx =  tokenid;
        return (csdogechoice[tokenid],nftInfo[_idx].reserves,nftInfo[_idx].copies);
    }

      function nftInformation(uint256 id) external view returns(uint256,string memory,uint256,string memory,uint256,string memory,string memory,uint256,bool, uint)
    {
        require(id <= tokenidmint, "unvalid NFT" );
        uint256 _idx =  id;
        return (id,nftInfo[_idx].mintName,nftInfo[_idx].timeofmint,nftInfo[_idx].nftowner,nftInfo[_idx].copies,nftInfo[_idx].description,nftInfo[_idx].uri,nftcollectionid[_idx], isMinted[_idx][msg.sender],nftInfo[_idx].price);
    }

     function auctiondetail(uint256 tokenid) external view returns(uint256,address) 
    {
        return (timeforauction[tokenid].biddingamount,finalowner[tokenid]);
    }
    
     function collectionnft(uint256 collectionid) external view returns(uint [] memory)
    {
        return (collectionstored[collectionid]);
    }
    
     function setstackingContract(address _address) external
    {
        require(msg.sender == devwallet,"not devwallet");
        _stackingContract = _address;
    }

     function collectiondetails(uint256 id) external view returns(uint256,address,string memory,string memory,string memory,string memory,string memory,uint256)
    {
        string memory Cname  = string(collection[id].Cname);  
        string memory Dname  = string(collection[id].Dname);  
        string memory URL  = string(collection[id].websiteURL);  
        string memory description  = string(collection[id].description);  
        string memory imghash  = string(collection[id].imghash);  
        uint256 value = id;
        uint256 fees = collection[value].marketfees;
        address collectionowners =  collection[value].collectionowner;
        return (value,collectionowners,Cname,Dname,URL,description,imghash,fees);
    }
    
    function setDevFeeVal(uint256 fee) public onlyOwner{
        devFeeVal = fee;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

     function burncopies(uint256 copiesnumber,uint256 tokenid) external 
    {
        require( nftInfo[tokenid].copies > copiesnumber);
        require( nftInfo[tokenid].reserves > copiesnumber);        
        nftInfo[tokenid].copies -= copiesnumber;
        nftInfo[tokenid].reserves -= copiesnumber;
        
    }

    function burnorinalnft(uint256 _collectionid,uint256 tokenid) external
    {
        delete collectionstored[_collectionid][(idnumber[_collectionid][tokenid])];
        delete csdogearray[(csdogenumber[tokenid])];
        originalowner[tokenid]=address(0);
        stopduplicate[nftInfo[tokenid].uri]=false;
        uint256 amount = nftInfo[tokenid].reserves;
        _burn(msg.sender, tokenid, amount);    
    }
    
     function changecsdogefees(uint256 fees) external
    {
        require(msg.sender == devwallet,"not devwallet");
        csdogefees = fees;
    }
    
    function changeauctionreturnamountfees(uint256 fees) external
    {
        require(msg.sender == devwallet,"not devwallet");
        auctionfees = fees;
    }
    
     function listofsalenft(uint256 tokenid) external view returns(uint256 [] memory,uint256 [] memory,uint256,uint256)
    {
        return (salenft,auctionnft,timeforauction[tokenid].minprice,nftprice[tokenid].price);
    }
    
     function csdogenft() external view returns(uint256 [] memory)
    {
        return (csdogearray);
    }

     function buyauction(uint256 tokenid) external payable
    {
        require(timeforauction[tokenid].inlist,"nft not in sale");
        require(msg.value >= timeforauction[tokenid].minprice,"amount should be greater");
        require(msg.value > timeforauction[tokenid].biddingamount,"previous bidding amount");
        require(timeforauction[tokenid].time >= block.timestamp,"auction end");
        timeforauction[tokenid].biddingamount=msg.value;
        amountforauction[tokenid][msg.sender] = msg.value;
        finalowner[tokenid]=msg.sender;
        uint256 values = msg.value;
        (bool success,)  = address(this).call{ value:values}("");
        require(success, "refund failed");
    }

     function startauction(uint256 tokenid,uint256 price,uint256 endday,uint256 endhours) external
    {
        require(!nftstakestate[tokenid],"nft is stake");
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftprice[tokenid].inlist,"already in sale");
        require(isMinted[tokenid][msg.sender] == true,"You are not owner");
        timeforauction[tokenid].time = block.timestamp +(endday * uint256(86400)) + (endhours*uint256(3600));
        timeforauction[tokenid].minprice =price;
        timeforauction[tokenid].inlist=true;
        auctionnftlist[tokenid]=auctionnft.length;
        auctionnft.push(tokenid);
        safeTransferFrom(msg.sender,address(this), tokenid,1,"");
    }

      function removesfromauction(uint256 tokenid) external
    {
        require(isMinted[tokenid][msg.sender] == true,"You are not owner");
        timeforauction[tokenid].minprice= 0;
        timeforauction[tokenid].biddingamount=0;
        timeforauction[tokenid].inlist=false;
        timeforauction[tokenid].time=0;
        safeTransferFrom(address(this),msg.sender,tokenid,1,"");
        delete auctionnft[(auctionnftlist[tokenid])];
    }

    function upgradeauction(uint256 tokenid,bool choice) external payable
    {
        require(timeforauction[tokenid].time >= block.timestamp,"auction end");
        uint256 val = uint256(100)-auctionfees;
        if(choice)
        {
            amountforauction[tokenid][msg.sender] += msg.value;
            if(amountforauction[tokenid][msg.sender] > timeforauction[tokenid].biddingamount)
            {
                timeforauction[tokenid].biddingamount=msg.value;
                finalowner[tokenid]=msg.sender;
                uint256 values = msg.value;
                (bool success,)  = address(this).call{ value:values}("");
                require(success, "refund failed");
            }
        }
        else
        {
           if(finalowner[tokenid]!=msg.sender)
           {
              require(amountforauction[tokenid][msg.sender]>0,"You dont allow");
              uint256 totalamount = amountforauction[tokenid][msg.sender];
              uint256 amount = (totalamount*uint256(val)/uint256(100));
              uint256 ownerinterest = (totalamount*uint256(auctionfees)/uint256(100)); 
              (bool success,) = msg.sender.call{value:amount}("");
              require(success,"refund failed"); 
              (bool csdoges,)  = devwallet.call{ value: ownerinterest}("");
              require(csdoges, "refund failed");
              amountforauction[tokenid][msg.sender]=0;
           }
        }
    }
     function buycopies(address tokenAddress,uint256 tokenid,address _to) external payable
    {
        require(nftInfo[tokenid].reserves!=0,"copies finish");
        if(csdogechoice[tokenid])
        {
            uint256 amount = nftprice[tokenid].price;
            IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount);
            address firstowner    = originalowner[tokenid];
            IERC20(tokenAddress).transfer(firstowner,amount);
        }
        else
        {
           uint256 values = msg.value;
           require(values >= nftprice[tokenid].price,"price should be greater");
           address firstowner    = originalowner[tokenid];
           (bool success,)  = firstowner.call{ value: values}("");
           require(success, "refund failed");
        }
        uint256 collectionid = totalcollection[_to];
        copycsdoge(collectionid,_to,nftInfo[tokenid].uri, nftInfo[tokenid].mintName,nftInfo[tokenid].nftowner,1,nftInfo[tokenid].description);
    }

     function withdrawbnb(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        (bool success,) = devwallet.call{value:amount}("");
        require(success,"refund failed"); 
    }

     function copycsdoge(uint256 collectionid,address to,string memory _tokenURI,string memory _mintname,string memory _nftowner,uint256 _copies,string memory description) internal 
    {
        tokenidmint+=1;
        collectionstored[collectionid].push(tokenidmint);
        totalnft[collectionid]+=1;
        idnumber[collectionid][tokenidmint]=totalnft[collectionid]-1;
        nftcollectionid[tokenidmint]=collectionid;
        originalowner[tokenidmint]=msg.sender;

        nftInfo[collectionid].reserves += _copies;
        stopduplicate[_tokenURI]=true;
    }

    function nftstake(uint256 tokenid) external
    {
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftprice[tokenid].inlist,"already in sale");
        require(isMinted[tokenid][msg.sender] == true,"You are not owner");
        nftstakestate[tokenid] = true;
    }

    function nftunstack(uint256 tokenid) external
    {
        require(msg.sender == _stackingContract,"You are not owner");
        nftstakestate[tokenid] = false;
    }

    function nftauctionend(uint256 tokenid) external view returns(bool auctionnftbool)
    {
        require(timeforauction[tokenid].time <= block.timestamp,"auction end");
        if(finalowner[tokenid]!=address(0))
        {
            return true;
        }
        
    }

     function changecollection(uint256 _collectionid,uint256 tokenid) internal
    {
       delete collectionstored[_collectionid][(idnumber[_collectionid][tokenid])];
       collectionstored[(totalcollection[msg.sender])].push(tokenid);
       totalnft[(totalcollection[msg.sender])]+=1;
       idnumber[(totalcollection[msg.sender])][tokenid]=totalnft[(totalcollection[msg.sender])]-1;
       nftprice[tokenid].price= 0;
       nftprice[tokenid].inlist=false;
       nftcollectionid[tokenid]=totalcollection[msg.sender];
       originalowner[tokenid] = msg.sender;
       delete salenft[(salenftlist[tokenid])];
       if(_collectionid==1)
       {
          delete csdogearray[(csdogenumber[tokenid])];
       }
    }

    function fixedsales(uint256 tokenid,uint256 price,bool csdogeb) external
    {
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftprice[tokenid].inlist,"already in sale");
        nftprice[tokenid].price  = price;
        nftprice[tokenid].inlist = true;
        nftInfo[tokenid].price = price;
        salenftlist[tokenid] = salenft.length;
        salenft.push(tokenid);
        csdogechoice[tokenid] = csdogeb;
    }

    function mintBatchNFT(
        address[] memory to,
        uint256 _ids
    ) external payable {
       require(msg.sender != address(0x0), "invalid address");
       mintVariables.totalPrice = 0;
       mintVariables.price = nftInfo[_ids].price;
       mintVariables.amount = 1;
       for(uint i =0; i< to.length; i++) {
        mintVariables.totalPrice= mintVariables.totalPrice+ (mintVariables.price*mintVariables.amount);
       }
        for(uint i =0; i< to.length; i++) {
        mintVariables.id = _ids;
        uint256 _idx =  _ids;
        
        mintVariables.reserves = nftInfo[_idx].reserves;
       
        require(mintVariables.reserves >= mintVariables.amount,
        "ERC1155: Not enough NFTs of this tokenId in stock!");
        mintNFT(to[i], mintVariables.id, 1, 1, "");
        }
        

    }
}