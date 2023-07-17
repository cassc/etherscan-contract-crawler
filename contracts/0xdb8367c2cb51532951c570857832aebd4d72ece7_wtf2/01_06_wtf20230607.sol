// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

//on goerli at:0x4692F6c59dfb3C0487B507Ff01253376b4C80D6B
// and 0x4f08dC326A0E9BCB12ffE5c0F37dEeB9B8503556
// on mainet: 0xDB8367c2cB51532951C570857832AebD4D72Ece7

//deployed on MainNet at: 
//Fixes problems w/202220929: election problem resolution
//adds feature: change SPend Limit

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface InftContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);    
}

//contract BasicNFT is ERC721URIStorage, Ownable {
contract wtf2  {
    //using Counters for Counters.Counter;
    //Counters.Counter private _tokenIds;
    
    //vars for Mangers voting
    bool public blnElecActive; //0=false=election NOT active
    uint256 public intElecEndTime; //example: block.timestamp;
    uint256 public intElecProposal; //enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
    uint256 public intWtfMngr0Vote; //NFT that wtfManager(="wtfManager0") votes for in 'proposed' election above
    uint256 public intWtfMngr1Vote; //NFT that wtfManager1 votes for in 'proposed' election above
    uint256 public intWtfMngr2Vote; //NFT that wtfManager2 votes for in 'proposed' election above

    //vars for spending limit
    uint256 public intSpendInterval; //interval time period. aka: 1 day, 1 week ...
    uint256 public intSpendLimitUSD; //USD limit value of interval
    uint256 public intSpendCurrInterval;  //time stamp of curr' intervals start
    uint256 public intCurrSpendingUSD; //the amount that has been spent int the current interval

    //var's needed to track for a (ERC20 token only)"request for mngr approve":'requ mangr', 'tokenAddress', 'to address', 'amount'
    address public requSpendERC20Mngr;  //address of manager requesting to spend
    address public requSpendERC20Token;  //address of token
    address public requSpendERC20ToAddr; //address of where token(s) are TO be sent
    uint256 public requSpendERC20Amount; //amount of the token to send

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    //address public constant gTST_ADDRESS = 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D;  //use for Goerli tests

    /*
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    AggregatorV3Interface internal priceFeed;

    struct NftStat {
        uint256 movePos;  // request to move asset
        uint256 moveLoc;  // location requested to move
        uint256 moveQty;  // qty requested to move
        uint256 currPos;  // current move posion
        uint256 currLoc;  //current Locaion
        uint256 currQty;  //current QTY
    }

    mapping(uint256 => NftStat) public nftStat;
    //uint256 public totNft; //running total of all NFTs for this contract
    
    //nft number of WTF MANAGER that approves dispensation to and from WTF account
    uint256 public wtfManager; //primary manager. AKA wtfManager)
    uint256 public wtfManager1; //aux mngr1
    uint256 public wtfManager2; //aux mngr2

    //nftnumber of Helix account
    uint256 public helixNft;

    ////define: nftContrAddress, tokenId in constructor
    address nftContrAddress;
    //uint256 tokenId;

    string public wtfUrl = "helixnft.io";

    event evMoveRequest(
        uint256 indexed _token,
        address sender
    );
    event evMoved(
        uint256 indexed _token,
        address sender
    );
    event TransferSent(address _from, address _destAddr, uint _amount);

    
       

  


    //constructor() ERC721("wtf20230527", "WTF7") { 
    constructor(address _nftContrAddress){  //}, uint256 _tokenId){  
    //constructor(){ 
        wtfManager=1;//set manager(s) nft 1
        helixNft=15;//set helix nft 15
        wtfManager1=3;
        wtfManager2=13;

        //set ini' spend limit vars
        intSpendInterval = 60*60*24; //60*60*24=1 dayinterval time period. aka: 1 day, 1 week ...
        intSpendLimitUSD = 28000;//$28000 is starting limit for 1 mngr to trans in 1 day. USD limit value of interval
        //NOTE: block.timestamp = SECONDS from epoch
        intSpendCurrInterval = block.timestamp;  //time stamp of curr' intervals START (ends at + intSpendInterval)
        intCurrSpendingUSD =0;  //set initial current spending to zero

        //vars for Mangers voting
        blnElecActive =false; //0=false=election NOT active
        intElecEndTime= 0; //example: block.timestamp;
        intElecProposal=0; //enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
        intWtfMngr0Vote=0; //NFT that wtfManager(="wtfManager0") votes for in 'proposed' election above
        intWtfMngr1Vote=0; //NFT that wtfManager1 votes for in 'proposed' election above
        intWtfMngr2Vote=0; //NFT that wtfManager2 votes for in 'proposed' election above

        //priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); //!!!!!!!goerli only
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); //main net USD/ETH

        nftContrAddress=_nftContrAddress;
        //tokenId=_tokenId;
    }
   
    /*
    //mint func for setting up beginer nft's
    function ownerMint(string memory tokenURI) external onlyOwner {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totNft = newItemId; //update total number of NFTs for this contract

        //set nftStat[newItemId]. struct items

    }
    */

    function getNftOwner(uint256 _tokenId) public view returns (address){
        InftContract nftContr=InftContract(nftContrAddress);
        address _nftOwner=nftContr.ownerOf(_tokenId);
        return _nftOwner;
    }

    //change Spend Limit
    function changeSpendLimitUSD(uint256 newLimit) internal{
        intSpendLimitUSD=newLimit;
    }

    //initiate an new election
    function createElection(uint256 proposal) internal{
        blnElecActive=true;
        //intElecEndTime= block.timestamp + 600; //600 sec =10min. !!!!!!!!!!!!!change 1 week on Main Net Deploy Deploy!!!!!!!!!!!
        intElecEndTime= block.timestamp + 604800;  //604800
        intElecProposal= proposal;
        intWtfMngr0Vote=0;
        intWtfMngr1Vote=0;
        intWtfMngr2Vote=0;
    }

    //call at end of election
    function destroyElection() internal{
        blnElecActive=false;
        intElecEndTime= 0; 
        intElecProposal= 0;
        intWtfMngr0Vote=0;
        intWtfMngr1Vote=0;
        intWtfMngr2Vote=0;
    }

    //resolve election function
    function resolveElec() public view returns(uint256){
        uint256 winner= 0; //default 'winner' (if zero "no winner")
        if(intWtfMngr0Vote == intWtfMngr1Vote){
            winner=intWtfMngr0Vote;
        }
        if(intWtfMngr0Vote == intWtfMngr1Vote){
            winner=intWtfMngr0Vote;
        }
        if(intWtfMngr1Vote == intWtfMngr2Vote){
            winner=intWtfMngr1Vote;
        }
        if(winner==0){
            if(intWtfMngr0Vote>0){ winner=intWtfMngr0Vote; }
            if(intWtfMngr1Vote>0){ winner=intWtfMngr1Vote; }
            if(intWtfMngr2Vote>0){ winner=intWtfMngr2Vote; }
        }
        return winner;
    }


    //election function
    function mngrElection(uint256 callingNft, uint256 request, uint256 directObject) public returns(uint256){
        //callingNft = number of nft who is calling this function
        //request = what election action being requested: 1 = "TO vote", 2 = "FOR a vote/election"
        //directObject = item or qty that 'action' is being requested on. 
            //intElecProposal=0; enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
            //intElecProposal = 200,000,000 to 209,999,999 = change Mngr Spending Limit to: (intElecProposal - 200,000,000) = a number between 0 and 9,999,999 
        uint256 elecError =0; //default error = 0 = no errors
        if(blnElecActive){
            if(intWtfMngr0Vote>0 && intWtfMngr0Vote>0 && intWtfMngr0Vote>0){
                //resolveElec();	//call resolve election
                //check for elec' type: new manager OR spend limit change OR .........
                if (intElecProposal>9 && intElecProposal<13){
                    //new mangaer election
                    setWtfMngr(intElecProposal, resolveElec());
                }
                if (intElecProposal>200000000 && intElecProposal<210000000){
                    //spending limit change
                    if (resolveElec()!=0){ changeSpendLimitUSD((resolveElec()-200000000));}
                }
                
                destroyElection();
            }else{
                if(block.timestamp>intElecEndTime){
                    if(resolveElec()!=0){
                        //check for elec' type: new manager OR spend limit change OR .........
                        //setWtfMngr(intElecProposal, resolveElec());
                        if (intElecProposal>9 && intElecProposal<13){
                            //new mangaer election
                            setWtfMngr(intElecProposal, resolveElec());
                        }
                        if (intElecProposal>200000000 && intElecProposal<210000000){
                            //spending limit change
                            if (resolveElec()!=0){ changeSpendLimitUSD((resolveElec()-200000000));}
                        }
                    }
                    //reset election timer OR stop election
                    destroyElection();
                }else{
                    if(request==2){
                        elecError=1;  //error "1" = request for new vote with vote already in progress
                    }else{
                        if(request==1){
                            //check for 'callingNft' == manager 1, 2 or 3
                            address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
                            address wtfManAddr1=getNftOwner(wtfManager1);
                            address wtfManAddr2=getNftOwner(wtfManager2);
                            
                            //check mnager# = 'callingNft'
                            if (callingNft==wtfManager){
                                //setintwetMngr0Vote
                                require((wtfManAddr==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr0Vote==directObject;
                            }
                            if (callingNft==wtfManager1){
                                //setintwetMngr0Vote
                                require((wtfManAddr1==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr1Vote=directObject;
                            }
                            if (callingNft==wtfManager2){
                                //setintwetMngr0Vote
                                require((wtfManAddr2==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr2Vote=directObject;
                            }
                        }else{
                            elecError=2; 
                        }
                    }
                }
            }
        }else{
            if(request==1){
                elecError= 4; //error "4" = voting with out active election in progress
            }else{
                if(request==2){
                    //check for 'callingNft' == manager 1, 2 or 3
                    address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
                    address wtfManAddr1=getNftOwner(wtfManager1);
                    address wtfManAddr2=getNftOwner(wtfManager2);
                    require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                    createElection(directObject); //call create Election function
                }else{
                    elecError = 2; //error "2" = unknow request. maybe researved for future use?
                }
            }
        }
        return elecError;
    }

    //change wtfUrl "pointer". primary manager (wtfMan) only.
    function setWtfUrl(string memory _value) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        wtfUrl = _value;
    }

    //change usd/eth oricale "pointer". primary manager (wtfMan) only.
    function setPriceFeed(address _addr) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        priceFeed = AggregatorV3Interface(_addr); //main net USD/ETH
    }

    //change NFT "pointer". primary manager (wtfMan) only.
    function setNftContrAddr(address _addr) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        //priceFeed = AggregatorV3Interface(_addr); //main net USD/ETH
        nftContrAddress=_addr;
    }

    /*
    //this is the mint function for managers only
    function mint(string memory tokenURI) public {
        address wtfManAddr=ownerOf(wtfManager);             //set var for managers address
        address wtfManAddr1=ownerOf(wtfManager1);
        address wtfManAddr2=ownerOf(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totNft = newItemId; //update total number of NFTs for this contract

        //set nftStat[newItemId]. struct items

    }
    */

    //owner of nft request asset to "move"
    function setMoveRequ(uint256 tokenId_, uint256 movePos_, uint256 moveLoc_, uint256 moveQty_) external payable {
        address nftOwner=getNftOwner(tokenId_);
        require(nftOwner==msg.sender, "not owner of NFT");
        
        //move qty not set by user. assume value to be amount payed to contract
        //"4" to be used as enumerated value for "deposit"
        if (moveQty_== 0 && movePos_==4){
            moveQty_=msg.value;
        }

        //"5" enum "movePos" value for "withdrawl". qty to withhdr' = moveQty_ in wei.
        
        nftStat[tokenId_].movePos=movePos_;
        nftStat[tokenId_].moveLoc=moveLoc_;
        nftStat[tokenId_].moveQty=moveQty_;
        emit evMoveRequest(
            tokenId_,
            msg.sender
        );

    }

    //function to withdrawl from WTF
    function wtfWithdrawl(uint256 tokenId_, uint256 currPos_, uint256 currLoc_, uint256 currQty_) external payable {
        //reqire func user to be wtfManager
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        
        address nftOwner=getNftOwner(tokenId_);                 //get address of nft owner to be payed

        uint256 withDrawlPaym = msg.value;                  //set amount to be payed

        payable(nftOwner).transfer(withDrawlPaym);          //pay nft owner 

        //set CURRent status for nftStat var's
        nftStat[tokenId_].currPos=currPos_;  //currPos- CURRent POSition
        nftStat[tokenId_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[tokenId_].currQty=currQty_;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[tokenId_].movePos=0;
        nftStat[tokenId_].moveLoc=0;
        nftStat[tokenId_].moveQty=0;
        //emit event to "listening" affected devices
        emit evMoved(
            tokenId_,
            msg.sender
        );

    }


    //WTF Manager to set vars per recent request
    //this is to ACTUALY set the 'move' request to the 'curr' (current) "status"
    function setMoveStatus(uint256 tokenId_, uint256 currPos_, uint256 currLoc_, uint256 currQty_) public {
        //reqire func user to be wtfManager
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        /*
        Reserved 'xPos' (movePos or currPos):
        4 ="deposit"
        5 = "withdrawal"
        xxx= "call for new manager election- existing managers only"
        xxx= "cast vote in manager election for a new manager - existing managers only"
        xxx="request for  approval of 'over limit transaction'- existing managers only"
        xxx="approve of 'over limit transaction'- existing managers only"

        */
        //add "switch" here= series of "IF"s



        //!!!!!!!Execute "move" !!!!!!!!!!!!!
        //set CURRent status for nftStat var's
        nftStat[tokenId_].currPos=currPos_;  //currPos- CURRent POSition
        nftStat[tokenId_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[tokenId_].currQty=currQty_;  //currQty- CURRent QuanTitY
        //!!!!!!!END Execute "move" !!!!!!!!!!!!


        //set "move"(aka "request to MOVE") status to "null"
        nftStat[tokenId_].movePos=0;
        nftStat[tokenId_].moveLoc=0;
        nftStat[tokenId_].moveQty=0;
        //emit event to "listening" affected devices
        emit evMoved(
            tokenId_,
            msg.sender
        );
    }

    function setWtfMngr(uint256 newWtfMngr) public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        require((wtfManAddr==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager=newWtfMngr;
    }
    function setWtfMngr1(uint256 newWtfMngr) public {
        address wtfManAddr1=getNftOwner(wtfManager1);
        require((wtfManAddr1==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager1=newWtfMngr;
    }
    function setWtfMngr2(uint256 newWtfMngr) public {
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager2=newWtfMngr;
    }

    function setHelixNft(uint256 newHelixNft) public{
        address addrHelNft=getNftOwner(helixNft);
        require((addrHelNft==msg.sender), "Not authorized");
        helixNft=newHelixNft;

    }

    function setWtfMngr(uint256 mngrToSet, uint256 newWtfMngr) internal {
        if(mngrToSet==10){
        //reset mngr0
        wtfManager=newWtfMngr;
        }
        if(mngrToSet==11){
        //reset mngr1
        wtfManager1=newWtfMngr;
        }
        if(mngrToSet==12){
        //reset mngr2
        wtfManager2=newWtfMngr;
        }
        
    }

    //func for other manager to approve a spending request by a manager
    function approveSpendRequest(bool blnApprvTx) public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");
        require((msg.sender!=requSpendERC20Mngr), "another manager must authorize");
        if(blnApprvTx){
            //if requSpendERC20Token == address(this) then this is an ETH tx NOT ERC20!!!!
            if (requSpendERC20Token == address(this)){
                //use ETH tx process
                (bool sent,) =requSpendERC20ToAddr.call{value:requSpendERC20Amount}(""); //(amount);
                //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
                require(sent, "Failed to send Ether");
            }else{
                //spending is approved. Execute Tx.
                //set erc20 token address
                IERC20 token =IERC20(requSpendERC20Token);
                token.transfer(requSpendERC20ToAddr, requSpendERC20Amount);
                //accumulate "current sum"="proposed sum"
                //intCurrSpendingUSD=propTotSpending;
                emit TransferSent(msg.sender, requSpendERC20ToAddr, requSpendERC20Amount);
            }
            
        }

        //reset requSpend var's
        requSpendERC20Mngr = address(0);//0;
        requSpendERC20Token = address(0);  //address of token
        requSpendERC20ToAddr = address(0); //address of where token(s) are TO be sent
        requSpendERC20Amount = 0; //amount of the token to send
    }
    //func' "request for mngr aprv spending"('requ mangr', 'tokenAddress', 'to address', 'amount')
    function requSpendApprove(address requMngr, address tokAddr, address to,uint256 amount) internal{
        //Manager 'requMngr' requests to send 'amount' of token at address 'tokAddr' TO 'to' .
        /*
        address public requSpendERC20Mngr;
        address public requSpendERC20Token;  //address of token
        address public requSpendERC20ToAddr; //address of where token(s) are TO be sent
        uint256 public requSpendERC20Amount; //amount of the token to send
        */
        //set public var's:
        requSpendERC20Mngr = requMngr;
        requSpendERC20Token = tokAddr;  //address of token
        requSpendERC20ToAddr = to; //address of where token(s) are TO be sent
        requSpendERC20Amount = amount; //amount of the token to send

        //insert EVENT if needed to notifiy listeners

    }

    //move an ERC 20 token from the SC to another address
    function transferERC20(address tokAddr, address to, uint256 amount) public {
        IERC20 token =IERC20(tokAddr); //convert tokAddr to IERC20 type
        //NOTE 'amoun' is in "Base Units" of the 'token'. Use erc20 contract (of token) 'decimals()' func' if needed
        //bool transApproved = false; //must be true for transfer to execute
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        //get token type
        //!!!!!!!! for test on Goerli, use "TST" at 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D !!!!!!!!!!!!!!!!!!!
        //verify to be "USDT"- only USDT or ETH currently supported for valuations in SC
            //IF token type is "NOT ETH" OR is "NOT USDT" token trans' requires aproval of a second manager!!
        if(tokAddr!=USDT_ADDRESS){      //!!!!!!!!!!!!!changed to USDT addresss for Main Net Deploy Deploy!!!!!!!!!!!
            //needs other mngr approval
            requSpendApprove(msg.sender, tokAddr, to, amount);
        }else{
            //get value "USD". note 'USDT' always val's at '1 to 1' //!!!!!!!!!!add on Main Net Deploy !!!!!!!
            uint256 valUSD=amount / (10**18); //!!!!!!!change on Main Net Deploy !!!!!!!!!!!!!!!!!!
            //get current interval 
            //if "current interval" is expired: reset interval
            if ((intSpendCurrInterval+intSpendInterval)>block.timestamp){
                intSpendCurrInterval=block.timestamp; //reset interval START
                intCurrSpendingUSD=0;   //reset current spending SUM
            }
            //get "current sum of spending"=intCurrSpendingUSD
            //"proposed Sum"= add  value to "current sum"
            uint256 propTotSpending=intCurrSpendingUSD + valUSD;
            //if "proposed sum"> "interval spend limit": move transaction to "pending mngr aproval" 
            if (propTotSpending>intSpendLimitUSD){
                //send info to func' "request for mngr aprv spending"('requ mangr', 'tokenAddress', 'to address', 'amount')
                requSpendApprove(msg.sender, tokAddr, to, amount);
            }else{
                token.transfer(to, amount);
                //accumulate "current sum"="proposed sum"
                intCurrSpendingUSD=propTotSpending;
                emit TransferSent(msg.sender, to, amount);        
            }  
        }
    }    

    //move an ETH the SC to another address
    function transferETH(address payable _to, uint256 amount) public payable {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        //get value "USD".
        //if "current interval" is expired: reset interval
        if ((intSpendCurrInterval+intSpendInterval)>block.timestamp){
            intSpendCurrInterval=block.timestamp; //reset interval START
            intCurrSpendingUSD=0;   //reset current spending SUM
        }

        (
            /*uint80 roundID*/,
            int intCurrEthPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        //int intCurrEthPrice = getLatestPrice();
        uint256 currEthPrice = 0;
        if(intCurrEthPrice < 0) {
            currEthPrice=0;
        }else{
            currEthPrice=uint(intCurrEthPrice);
        }
        //uint8 decimals = priceFeed.decimals();
        uint8 decs =  priceFeed.decimals();//getLatestDecimals();
        currEthPrice = currEthPrice/(10**decs);
        uint256 propTotSpending=intCurrSpendingUSD + currEthPrice * (amount/(10**18));
        if (propTotSpending>intSpendLimitUSD){
           //needs appr' by 2nd manager requSpendApprove(msg.sender, tokAddr, to, amount);
           requSpendApprove(msg.sender, address(this), _to, amount); //use "this" conatrcant address to distinguish a ETH trans'
        }else{
            (bool sent,) =_to.call{value:amount}(""); //(amount);
            //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
    }  

    function depositApprove(uint256 depositorAtoms, uint256 depositorNft, uint256 wtfAtoms, uint256 helixAtoms, uint256 refrNftAtoms, uint256 refrNft)public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        //update SC depositors atoms
        //set CURRent status for nftStat var's
        //nftStat[depositorNft_].currPos=currPos_;  //currPos- CURRent POSition
        //nftStat[depositorNft_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[depositorNft].currQty=depositorAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[depositorNft].movePos=0;
        nftStat[depositorNft].moveLoc=0;
        nftStat[depositorNft].moveQty=0;
        
        //update SC Wtf atoms
        nftStat[wtfManager].currQty=wtfAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[wtfManager].movePos=0;
        nftStat[wtfManager].moveLoc=0;
        nftStat[wtfManager].moveQty=0;

	    //update SC Helix atoms
        nftStat[helixNft].currQty=helixAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[helixNft].movePos=0;
        nftStat[helixNft].moveLoc=0;
        nftStat[helixNft].moveQty=0;

        if (refrNft!=0){
            //update SC Referecne NFT atoms
             nftStat[refrNft].currQty=refrNftAtoms;  //currQty- CURRent QuanTitY
            //set "move"(aka "request to MOVE") status to "null"
            nftStat[refrNft].movePos=0;
            nftStat[refrNft].moveLoc=0;
            nftStat[refrNft].moveQty=0;

        }
	    
    }    


}