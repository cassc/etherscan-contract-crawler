// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;
// @cryptoconner simple but effective. 

/*  This contract gives holders an eth reward deposited by the owner of the contract
    it does not reward holders on a set token level or APR instead rewards are added which
    updates the amount of claimable rewards based on how many where added / total holders. 
  this contract accepts ETH deposits through the AddRewards function
  to add rewards do not deposit by transferring Eth into the contract, it will just be locked or seen as a team donation
    if you do send it there is a OnlyOwner function you can use to pull out the extra Eth
    A User must buy before new rewards are added to qualify to claim its managed through a Period Id not time of purcahse
    

    Notes for the owner: PUB_PRICE is denominated in gwei, set reveal, and toggle pub mint must be called after deployment

    Shoutout to VB if you like the nfts, made with love in the dark forest that is our home. 

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


contract OfficialGinuNFCT is ERC721, Ownable {
    //libraries
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

  Counters.Counter private _supply;

    // Structs
    struct TokenCycle {
        uint256 rewardsamount;
        uint256 time;
        uint256 currentsupply;
        }


    //Mappings
    mapping(IERC20 => uint256) public TokenID;
    mapping(uint256 => TokenCycle) public rewardCycle;
    mapping(uint256 => uint256) public NFTSPeriodId;

    //Variables public
    uint256 public RewardsForHolders;
    uint256 public currentRewardPeriodId;
    uint256 public CompanyFunds;
    uint256  public NewRewards;
    uint256 public UnclaimedRewards;
    bool public pubMintActive = false;
    uint256 public PUB_MINT_PRICE;
    address public managerAddress;

    //Variables Private
    string private baseURI;
    string private baseExt = ".json";
    bool public revealed = false;
    string private notRevealedUri;
    bool private _locked = false; // for re-entrancy guard

  //Constants
    uint256 private constant PUB_MAX_PER_WALLET = 10; // 3/wallet (uses < to save gas)
  // Total supply
    uint256 public constant MAX_SUPPLY = 2000;

    //events
    event ClaimedRewards(uint256 tokenid, address to);
    event minted(address to, uint256 quantity);
    event Rewardsadded(uint256 amount);


  constructor(string memory _initBaseURI, string memory _initNotRevealedUri, uint256 PUB_PRICE, address manageraddress) ERC721("OfficialGinuNFT", "GINU") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
        setPrice(PUB_PRICE);
        UpdateManagerAddress(manageraddress);
    _supply.increment();
  }

        /// @dev Throws if not called by pool manager address provided in constructor.
    modifier onlyManager() {
        require(msg.sender == managerAddress, "Message sender must be the contract's Manager.");
        _;
    }
    ///Functions For RewardCycle information
    function UpdateManagerAddress(address newmanager) public onlyOwner {
        managerAddress = newmanager;
    }

    ///Functions For RewardCycle information
    function FetchAmountById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].rewardsamount;
    }
    function FetchTimeById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].time;
    }
    function FetchSupplyById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].currentsupply;
    }

// Function used to add new Eth Rewards to the contract
    function AddRewards() public payable onlyManager {
        if(currentRewardPeriodId > 0) {
            UnclaimedRewards = address(this).balance.sub(msg.value).sub(CompanyFunds);
            require(msg.value > 0, "Failed to deposit Ether."); //address(this).balance
            NewRewards = address(this).balance.sub(CompanyFunds).sub(UnclaimedRewards);
            updateRewardCycle(currentRewardPeriodId.add(1), NewRewards);
            currentRewardPeriodId = currentRewardPeriodId.add(1);
        } else {
            require(msg.value > 0, "Failed to deposit Ether.");
            NewRewards = address(this).balance.sub(CompanyFunds);
            updateRewardCycle(currentRewardPeriodId.add(1), NewRewards );
            currentRewardPeriodId = currentRewardPeriodId.add(1);
            
        }
        emit Rewardsadded((address(this).balance));

    }

    //Reward cycle update functions
    function updateNftsRewardCycle(uint256 tokenid) private {
        NFTSPeriodId[tokenid] = currentRewardPeriodId.add(1);
    }
    
    //update a users id for emergencies only
    function Updatenftid(uint256 tokenid, uint256 periodid) external onlyOwner {
    NFTSPeriodId[tokenid] = periodid;
  }  
    // updates a new reward round once rewards are depositted
    function updateRewardCycle(uint index, uint256 amount) private {
        rewardCycle[index].time = block.timestamp;
        rewardCycle[index].rewardsamount = amount;
        rewardCycle[index].currentsupply = _supply.current().sub(1);
    }


    //Can User Claim - for frontend dapp
    function CanClaim(uint256 tokenid) public view returns (bool) {
        if(NFTSPeriodId[tokenid] <= currentRewardPeriodId) {
            return true;
        } else {
            return false;
        }
    }

//Function to Claim tokens for one specific tokenid it claims all 
    function ClaimTokens(uint256 tokenid) public nonReentrant {
    require(ownerOf(tokenid) == msg.sender  , "You are not the current owner of this tokenid");
    require(balanceOf(msg.sender) > 0, "Go buy an nft sir or madam");
    require(NFTSPeriodId[tokenid] > 0 && NFTSPeriodId[tokenid] <= currentRewardPeriodId, "not the correct period id to claim");
        for(uint i= NFTSPeriodId[tokenid]; i < currentRewardPeriodId.add(1); i++) {
        updateNftsRewardCycle(tokenid);
        (bool sent, ) = payable(msg.sender).call{ value: rewardCycle[i].rewardsamount.div(rewardCycle[i].currentsupply) }("");
    require(sent, "Failed to withdraw Ether.");
        }
        emit ClaimedRewards(tokenid, msg.sender);
    }   
//Function to claim for multiple tokenids for multiple rounds
    function ClaimForMultiple(uint256[] memory tokenIds) public nonReentrant {
    for (uint256 j = 0; j < tokenIds.length; j++) {
    uint256 tokenId = tokenIds[j];
        require(ownerOf(tokenId) == msg.sender, "You are not the current owner of this token ID");
        require(balanceOf(msg.sender) > 0, "Go buy an NFT sir or madam");
        require(NFTSPeriodId[tokenId] > 0 && NFTSPeriodId[tokenId] <= currentRewardPeriodId, "not the correct period id to claim");
        for(uint i = NFTSPeriodId[tokenId]; i < currentRewardPeriodId.add(1); i++) {
            updateNftsRewardCycle(tokenId);
            (bool sent, ) = payable(msg.sender).call{ value: rewardCycle[i].rewardsamount.div(rewardCycle[i].currentsupply) }("");
            require(sent, "Failed to withdraw Ether.");
        }
        emit ClaimedRewards(tokenId, msg.sender);
    }
}

// Public mint - only publicly available mint function
  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(pubMintActive, "Public sale is closed at the moment.");
    address _to = msg.sender;
    require(_quantity > 0, "Invalid mint quantity.");
        require( balanceOf(msg.sender).add(_quantity) <= PUB_MAX_PER_WALLET, "invalid mint quantity, cant mint that many");
    require(msg.value == (PUB_MINT_PRICE .mul(_quantity)), "Must send exact amount to mint, either increase or decrease eth amount");
        CompanyFunds = CompanyFunds + (PUB_MINT_PRICE.mul(_quantity));
        mint(_to, _quantity);
        emit minted(msg.sender, _quantity);

  }

   //Airdrop for promotions & collaborations
   //You can remove this block if you don't need it
    //to not mess up rewards just set the period id to the next one up from the current period
  function airDropMint(address _to, uint256 periodid, uint256 tokenid) external onlyOwner {
      NFTSPeriodId[tokenid] = periodid;
    Promomint(_to, 1);
  }

  // Mint an NFT internal function
  function mint(address _to, uint256 _quantity) private {
    
     // To save gas, since we know _quantity won't underflow / overflow
     //Checks are performed in caller functions / methods
     //
    unchecked {
      require((_quantity + _supply.current()) <= MAX_SUPPLY, "Max supply exceeded.");

      for (uint256 i = 0; i < _quantity; i++) {
        _safeMint(_to, _supply.current());
                updateNftsRewardCycle(_supply.current());
        _supply.increment();
      }
    }
        emit minted(_to, _quantity);
  }

       // Mint an nft for airdrop - internal function 
      function Promomint(address _to, uint256 _quantity) private {
    /**
     * To save gas, since we know _quantity won't underflow / overflow
     * Checks are performed in caller functions / methods
     */
    unchecked {
      require((_quantity + _supply.current()) <= MAX_SUPPLY, "Max supply exceeded.");

      for (uint256 i = 0; i < _quantity; i++) {
        _safeMint(_to, _supply.current());
        _supply.increment();
      }
    }
        emit minted(_to, _quantity);
  }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        if(NFTSPeriodId[tokenId] > 0 && NFTSPeriodId[tokenId] <= currentRewardPeriodId)  {
        ClaimTokens(tokenId);
        NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _transfer(from, to, tokenId);

        }else {
        NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _transfer(from, to, tokenId);
        }
    }
  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        if(NFTSPeriodId[tokenId] > 0 && NFTSPeriodId[tokenId] <= currentRewardPeriodId)  {
        ClaimTokens(tokenId);
        NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _transfer(from, to, tokenId);

        }else {
        NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _transfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
                if(NFTSPeriodId[tokenId]> 0 && NFTSPeriodId[tokenId] <= currentRewardPeriodId)  {
        ClaimTokens(tokenId);
        NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _safeTransfer(from, to, tokenId, data);

}else {
          NFTSPeriodId[tokenId] = currentRewardPeriodId.add(1);
        _safeTransfer(from, to, tokenId, data);
        }
    }


  // Get total supply
  function totalSupply() public view returns (uint256) {
    return _supply.current().sub(1);
  }

    // Set Mint price
    function setPrice(uint256 PUB_PRICE) public onlyOwner {
        PUB_MINT_PRICE = PUB_PRICE * 1e9;
    
    }
    // Toggle public sales activity
  function togglePubMintActive() public onlyOwner {
    pubMintActive = !pubMintActive;
  }

  // Base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // Set base URI
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  // Get metadata URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExt))
        : "";
  }

  // Activate reveal
  function setReveal() public onlyOwner {
    revealed = true;
  }

  // Set not revealed URI
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  // Withdraw balance
  function withdraw() external onlyOwner {
    // Transfer the  balance  minus user rewards to the owner
    // Do not remove this line, else you won't be able to withdraw the funds
    (bool sent, ) = payable(owner()).call{ value: CompanyFunds }("");
    require(sent, "Failed to withdraw Ether.");
        CompanyFunds = 0;
  }
   function Emergencywithdraw() external onlyOwner {
    // Transfer the full balance to the owner
    // Do not remove this line, else you won't be able to withdraw the funds
    (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
    require(sent, "Failed to withdraw Ether.");
  }
   function EmergencywithdrawExactAmount(uint256 value) external onlyOwner {
    // Transfer a exact amount of balance to the owner
    // Do not remove this line, else you won't be able to withdraw the funds
    (bool sent, ) = payable(owner()).call{ value: value }("");
    require(sent, "Failed to withdraw Ether.");
  }

    function approveERC20(address spender, uint256 amount, IERC20 token) private returns (bool) {
        token.approve(spender, amount);
        return true;
    } 

    function Rescuetokens(IERC20 token, uint256 amount) external onlyOwner {
        approveERC20(msg.sender, amount, token);
    token.transfer(msg.sender, amount);
  }    

  // Receive any funds sent to the contract
  receive() external payable {}

  // Reentrancy guard modifier
  modifier nonReentrant() {
    require(!_locked, "No re-entrant call.");
    _locked = true;
    _;
    _locked = false;
  }
}