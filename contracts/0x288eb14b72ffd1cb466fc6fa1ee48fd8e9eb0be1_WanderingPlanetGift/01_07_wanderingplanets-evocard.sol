// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol"; 

pragma solidity ^0.8.7;

struct Stake_Info{
    bool staked;
    address previous_owner;
    uint256 stake_time;
}

interface WPSInterFace {
    function getStakeInfo(uint256 tokenID) external view returns (Stake_Info memory);
}

contract WanderingPlanetGift is ERC721A, Ownable, Pausable, ReentrancyGuard {
    event BaseURIChanged(string newBaseURI);
    event Minted(address indexed minter, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event GiftConsumed(uint256 tokenID);
    event GenesisArrived();

    // Rewarded gifts to mint
    mapping(address => uint256) public rewardNum;
    // Reward history
    mapping(uint256 => uint256 []) public rewardList;

    uint256 public rewardTimes = 0;
    uint256 public constant MAX_TOKEN = 999;
    string public baseURI;

    WPSInterFace Stake_Contract;

    constructor(string memory baseURI_, address Stake_contract_address_) ERC721A("GensisGift", "GenG") {
        require(Stake_contract_address_ != address(0), "invalid contract address");
        Stake_Contract = WPSInterFace(Stake_contract_address_);
        baseURI = baseURI_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    function mintRewards(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(rewardNum[msg.sender] >= numberOfTokens_, "invalid gift number");
        mint(numberOfTokens_);
        rewardNum[msg.sender] -= numberOfTokens_;
    }

    function mint(uint64 numberOfTokens_) internal {
        require(totalMinted() + numberOfTokens_ <= MAX_TOKEN, "max supply exceeded");
        _safeMint(_msgSender(), numberOfTokens_);
        mint_refund();
        emit Minted(msg.sender, numberOfTokens_);
    }


    function mint_refund() private {
        if (msg.value > 0) {
            payable(_msgSender()).transfer(msg.value);
        }
    }

    function burn(uint256 tokenID) external nonReentrant{
        _burn(tokenID, true);
        emit GiftConsumed(tokenID);
    }
 
    /***********************************|
    |               State               |
    |__________________________________*/

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getRewardList(uint256 times) public view returns (uint256 [] memory){
        return rewardList[times];
    }

    function getRewardNum(address address_) public view returns (uint256) {
        return rewardNum[address_];
    }

    function getStakeInfo(uint256 tokenID) public view returns (Stake_Info memory){
        return Stake_Contract.getStakeInfo(tokenID);
    }

    /***********************************|
    |               Owner               |
    |__________________________________*/
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function genesisGlance(uint256[] memory tokenIDs) external onlyOwner {
        require(tokenIDs.length + totalMinted() <= MAX_TOKEN, "no more mercy");
        rewardList[rewardTimes] = tokenIDs;
          for(uint256 i = 0; i < tokenIDs.length; i++){
              require(tokenIDs[i] >= 0 && tokenIDs[i] < 2999, "invalid token ID");
              Stake_Info memory status = Stake_Contract.getStakeInfo(tokenIDs[i]); 
              if(status.staked){
                rewardNum[status.previous_owner]++;
              }
        }
        rewardTimes++;
        emit GenesisArrived();
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }
    
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "token transfer paused");
    }


    function emergencyPause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    
    /***********************************|
    |              Modifier             |
    |__________________________________*/

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }
}