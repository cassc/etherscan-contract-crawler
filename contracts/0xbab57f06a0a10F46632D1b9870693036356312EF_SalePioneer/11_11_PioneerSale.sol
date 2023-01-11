// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPioneerNFT.sol";


contract SalePioneer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public usdt;
    IERC20 public usdc;
    IPioneerNFT public Pioneer;

    AggregatorV3Interface internal priceFeed;

    uint256 public phaseOneTime;
    uint256 public phaseTwoTime;
    uint256 public epochInitalEnd;

    uint256 public airdropTimeLimit;

    bytes32 public merkleRoot;
    uint public nftPrice ; 

    uint256 public maxPurchaseInitial;
    bool public saleIsActive;

    IERC20 public tomi;

    address public marketingWallet;
    address public teamWallet;

    address payable public fundsWallet;
 
    mapping(address => uint) public publicsaleMintedNFT;    

    
    mapping(address => bool) public addressWhitelisted;

     constructor(
        uint _phaseOneTime,
        uint _phaseTwoTime,
        address _fundsWallet,
        address _marketingWallet,
        bytes32 _merkleRoot,
        IERC20 _tomiToken,
        IERC20 _usdt,
        IERC20 _usdc,
        IPioneerNFT pioneer_,
        AggregatorV3Interface priceFeed_
    )  {
        nftPrice= 3000*10**6;
        maxPurchaseInitial = 1500;
        saleIsActive = false;
        marketingWallet = _marketingWallet;
        merkleRoot = _merkleRoot;
        saleIsActive = true;
        phaseOneTime = block.timestamp.add(_phaseOneTime);
        phaseTwoTime = phaseOneTime.add(_phaseTwoTime);
        tomi = _tomiToken;
        fundsWallet = payable(_fundsWallet);
        epochInitalEnd = block.timestamp.add(2 weeks);
        usdt= _usdt;
        usdc= _usdc;
        priceFeed = priceFeed_;
        Pioneer = pioneer_;
        airdropTimeLimit = block.timestamp.add(2 days);
    }

    receive() external payable {
        revert();
    }

    function initialMint(uint paySelect, uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        
        require(saleIsActive, "Sale must be active to mint nft");
        
        if ( block.timestamp <= phaseOneTime ) {
            whiteListClaimedPaid( quantity, _merkleProof );
           

        } else if (  block.timestamp > phaseOneTime && block.timestamp <= phaseTwoTime ) {
           publicSale( quantity,  paySelect);
            
        } else{
            revert("Phase Ended");
        }
    }

    // internal functions || Whitelist

    function whiteListClaimedPaid( uint quantity, bytes32[] calldata _merkleProof ) internal { // uint mintAllowed, // uint quantity
        
        require ( addressWhitelisted[msg.sender] == false, "Already minted/Not whiteListed" );
        uint phase = 1;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, phase, quantity) );
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Proof" );
       
        _mintUnpaid( quantity);
        addressWhitelisted[msg.sender] = true;
    }


    function publicSale (uint quantity, uint paySelect) internal {
        require(Pioneer.totalSupply().add(quantity) <= maxPurchaseInitial, "Limit reached");
        require ( publicsaleMintedNFT[msg.sender].add(quantity) <= 10,"Enter Correct value to Mint" );
        if(paySelect==1){
            require(msg.value >= priceOfNftinETH().mul(quantity), "Send Correct Eth Value");
            fundsWallet.transfer(msg.value);
            _mintUnpaid(quantity);
            publicsaleMintedNFT[msg.sender] = publicsaleMintedNFT[ msg.sender].add(quantity);
        }else if(paySelect==2){
            require(usdt.balanceOf(msg.sender)>= nftPrice.mul(quantity),"No Enough USDT balance");
            require(usdt.allowance(msg.sender,address(this))>=nftPrice.mul(quantity),"No Enough USDT Allowance");
            usdt.safeTransferFrom(msg.sender,fundsWallet, nftPrice.mul(quantity));
           _mintUnpaid(quantity);
           publicsaleMintedNFT[msg.sender] = publicsaleMintedNFT[ msg.sender].add(quantity);

        }else{
            require(usdc.balanceOf(msg.sender)>= nftPrice.mul(quantity),"Not Enough USDC balance");
            require(usdc.allowance(msg.sender,address(this))>=nftPrice.mul(quantity),"No Enough USDC Allowance");
            usdc.safeTransferFrom(msg.sender,fundsWallet, nftPrice.mul(quantity));
           _mintUnpaid(quantity);
           publicsaleMintedNFT[msg.sender] = publicsaleMintedNFT[ msg.sender].add(quantity);
        }

    }

    function _mintUnpaid(uint quantity) internal{
        Pioneer.saleMint(_msgSender(), quantity);
    }


    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // latest Eth Price
    function getLatestPrice() public view returns (uint) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = /*uint timeStamp*/ priceFeed.latestRoundData();

        return uint(price);
    }

    function priceOfNftinETH() public view returns (uint) {
        return (nftPrice.mul(10**20)).div(getLatestPrice());
    }
    // _increasedTime should be in seconds
    function setTimeIncrease(
        uint8 phase,
        uint256 _increasedTime
    ) public onlyOwner {
        if (phase == 1) {
            phaseOneTime = phaseOneTime.add(_increasedTime);
            phaseTwoTime = phaseTwoTime.add(_increasedTime);
           
        } else if (phase == 2) {
            phaseTwoTime = phaseTwoTime.add(_increasedTime);
           
        } else {
            revert();
        }
    }

    function setNFTPrice(uint _newPrice) public onlyOwner {
       
        nftPrice = _newPrice;
    }

    function setUsdtUsdc(IERC20 _usdt, IERC20 _usdc) public onlyOwner {
        usdt= _usdt;
        usdc= _usdc;
    }

    function airDrop(address[] calldata _addresses , uint[] calldata _quantity) public onlyOwner {
        require(block.timestamp <= airdropTimeLimit, "Airdop Time Limit reached");
        for(uint i=0; i< _addresses.length; i++){
            Pioneer.saleMint(_addresses[i], _quantity[i]);
        }
    }

    function setPriceFeed(AggregatorV3Interface _priceFeed) public onlyOwner{
        priceFeed= _priceFeed;
    }
}