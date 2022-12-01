// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// @cryptoconner simple but effective. 

// this NFT Contract can take deposits of ERC20 Tokens and allows holders of the nft to claim a portion of thse tokens
// When you claim, you claim all past reward rounds at once.
// each reward round is initiated when the owner of the contract calls setreward ater depositing tokens
// when this it called it logs the amount deposited, the time, the current holder count, and the asset address in itself. 
// there is only 1 nft per user. 
//1 billion = 1eth mintPrice for gwei denomented price 
//https://ipfs.io/ipfs/QmYapEVYpoAUDJmDrjiod7GPaFcjxZdM3mrfLAFGmWiG3q/ base uri
//encoded constructors: 0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004468747470733a2f2f697066732e696f2f697066732f516d596170455659706f4155444a6d44726a696f643747506146636a785a644d336d72664c4146476d57694733712f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004468747470733a2f2f697066732e696f2f697066732f516d596170455659706f4155444a6d44726a696f643747506146636a785a644d336d72664c4146476d57694733712f00000000000000000000000000000000000000000000000000000000
/// 
// steps for redeployment 
// if you want to redeploy this and use it just deploy as usual feeding in your baseuri, and pub mint price ( in Gwei)
// then after deployment call setreveal, and togglepubmint
// once users have minted, send tokens to contract and call setreward(your deposited token address)
// holders may now claim that token. 
// the withdraw function only pulls eth from minting fees, if you do not setreward then those ERC20 reward tokens are effectively locked in the contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OfficialRuneStoneNFT is ERC721, Ownable {
	using Strings for uint256;
	using Counters for Counters.Counter;

	Counters.Counter private _supply;

    using SafeERC20 for IERC20;


    struct TokenCycle {
        IERC20 tokenaddress;
        uint256 rewardsamount;
        uint256 time;
        uint256 currentholdercount;
        }

    uint256 public currentRewardPeriodId;

    mapping(address=>uint256[]) public UserClaimableTokenAmount;
    mapping(address => uint256) public amountofRewardRoundsuserholds;
    mapping(IERC20=>uint256) public TokenID;
    mapping(address => uint256) public lastUpdateTime; // userdeposittime
    mapping(address =>IERC20[]) public UserClaimableTokens; 
    mapping(address => uint256) public usersPeriodId; // this use this to keep track of what rewards they are due
    mapping(uint256 => TokenCycle) public rewardCycle;

    //events
    event ClaimedRewards(address to);
    event minted(address to, uint256 quantity);
	event Rewardsadded(IERC20 tokenaddress, uint256 amount);

	string private baseURI;
	string private baseExt = ".json";

	bool public revealed = false;
	string private notRevealedUri;

	// Total supply
	uint256 public constant MAX_SUPPLY = 2000;

	// Public mint constants
	bool public pubMintActive = false;
	uint256 private constant PUB_MAX_PER_WALLET = 2; // 3/wallet (uses < to save gas)
	//uint256 private constant PUB_MINT_PRICE = 0.065 ether;

	bool private _locked = false; // for re-entrancy guard
    uint256 public PUB_MINT_PRICE;

	// Initializes the contract by setting a `name` and a `symbol`
	constructor(string memory _initBaseURI, string memory _initNotRevealedUri, uint256 PUB_PRICE) ERC721("OfficialRuneStoneNFT", "RUNE") {
		setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedUri);
        setPrice(PUB_PRICE);
		_supply.increment();
	}

  //if user is reward cycle 3 and we are on 6 his ids are 4 in length- 3-4-5-6
function FetchIdByDetails(IERC20 token) public view returns (uint256) {
    return TokenID[token];
}

function FetchTokenById(uint256 id) public view  returns (IERC20) {
        return rewardCycle[id].tokenaddress;
    }
function FetchAmountById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].rewardsamount;
    }
function FetchTimeById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].time;
    }
function FetchholdersById(uint256 id) public view  returns (uint256) {
        return rewardCycle[id].currentholdercount;
    }

function approveERC20(address spender, uint256 amount, IERC20 token) private returns (bool) {
        token.approve(spender, amount);
        return true;
    }


function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        if(usersPeriodId[msg.sender] > 0 && usersPeriodId[msg.sender] <= currentRewardPeriodId)  {
        ClaimAllTokens();
		usersPeriodId[to] = currentRewardPeriodId + 1;
		usersPeriodId[from] = 0;
        _transfer(from, to, tokenId);

        }else {
		 usersPeriodId[to] = currentRewardPeriodId + 1;
		 usersPeriodId[from] = 0;
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
        if(usersPeriodId[msg.sender] > 0 && usersPeriodId[msg.sender] <= currentRewardPeriodId)  {
        ClaimAllTokens();
		usersPeriodId[to] = currentRewardPeriodId + 1;
		usersPeriodId[from] = 0;
        _transfer(from, to, tokenId);

        }else {
		 usersPeriodId[to] = currentRewardPeriodId +1;
		 usersPeriodId[from] = 0;
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
                if(usersPeriodId[msg.sender] > 0 && usersPeriodId[msg.sender] <= currentRewardPeriodId)  {
        ClaimAllTokens();
		usersPeriodId[to] = currentRewardPeriodId + 1;
		usersPeriodId[from] = 0;
        _safeTransfer(from, to, tokenId, data);

        }else {
		 usersPeriodId[to] = currentRewardPeriodId +1;
		 usersPeriodId[from] = 0;
        _safeTransfer(from, to, tokenId, data);
        }
    }
   

function setReward(IERC20 tokenaddress) external onlyOwner {
        updateRewardCycle(currentRewardPeriodId + 1, tokenaddress.balanceOf(address(this)), tokenaddress );
        currentRewardPeriodId = currentRewardPeriodId + 1;
        emit Rewardsadded(tokenaddress, tokenaddress.balanceOf(address(this)));

    }
function updateUsersRewardCycle(address account) private {
    lastUpdateTime[msg.sender] = block.timestamp;
    usersPeriodId[account] = currentRewardPeriodId + 1;
   }

function updateRewardCycle(uint index, uint256 amount, IERC20 tokenaddress) private {
        TokenID[IERC20(tokenaddress)] = currentRewardPeriodId + 1;
        rewardCycle[index].time = block.timestamp;
        rewardCycle[index].rewardsamount = amount;
        rewardCycle[index].tokenaddress= tokenaddress;
        rewardCycle[index].currentholdercount = _supply.current() - 1;
    }


IERC20 public claimabletokens;

function ClaimAllTokens() public {
    require(balanceOf(msg.sender) > 0, "Go buy an nft sir or madam");
    require(usersPeriodId[msg.sender] > 0 && usersPeriodId[msg.sender] <= currentRewardPeriodId, "not the correct period id to claim");
    for(uint i=usersPeriodId[msg.sender]; i < currentRewardPeriodId + 1; i++) {
    claimabletokens = rewardCycle[i].tokenaddress;
    approveERC20(msg.sender,rewardCycle[i].rewardsamount / rewardCycle[i].currentholdercount, claimabletokens);
    updateUsersRewardCycle(msg.sender);
    claimabletokens.transfer(msg.sender, rewardCycle[i].rewardsamount / rewardCycle[i].currentholdercount);
     }

    emit ClaimedRewards(msg.sender);
}


	// Public mint
	function publicMint(uint256 _quantity) external payable nonReentrant {
		require(pubMintActive, "Public sale is closed at the moment.");
		address _to = msg.sender;
		require(_quantity > 0 && (balanceOf(_to) + _quantity) < PUB_MAX_PER_WALLET, "Invalid mint quantity.");
		require(msg.value >= (PUB_MINT_PRICE * _quantity), "Not enough ETH.");
        if(usersPeriodId[msg.sender] > 0 && usersPeriodId[msg.sender] <= currentRewardPeriodId) {
            updateUsersRewardCycle(msg.sender);
            ClaimAllTokens();
		    mint(_to, _quantity);
        }else {
            mint(_to, _quantity);
			updateUsersRewardCycle(msg.sender);
        }

	}

	/**
	 * Airdrop for promotions & collaborations
	 * You can remove this block if you don't need it
	 */ //to not mess up rewards just set the period id to the next one up from the current period
	function airDropMint(address _to, uint256 periodid) external onlyOwner {
		lastUpdateTime[_to] = block.timestamp;
    	usersPeriodId[_to] = periodid;
        //updateUsersRewardCycle(_to);
		mint(_to, 1);
	}

	// Mint an NFT
	function mint(address _to, uint256 _quantity) private {
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


	// Toggle public sales activity
	function togglePubMintActive() public onlyOwner {
		pubMintActive = !pubMintActive;
	}


	// Get total supply
	function totalSupply() public view returns (uint256) {
		return _supply.current();
	}


    function setPrice(uint256 PUB_PRICE) public onlyOwner {
        PUB_MINT_PRICE = PUB_PRICE * 1e9;
    
    }

    


	// Base URI
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// Set base URI
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

		function Rescuetokens(IERC20 token, uint256 amount) external onlyOwner {
		token.transfer(msg.sender, amount);
	}

			function Updateusersid(address _user, uint256 periodid) external onlyOwner {
		usersPeriodId[_user] = periodid;
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
		// Transfer the remaining balance to the owner
		// Do not remove this line, else you won't be able to withdraw the funds
		(bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
		require(sent, "Failed to withdraw Ether.");
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