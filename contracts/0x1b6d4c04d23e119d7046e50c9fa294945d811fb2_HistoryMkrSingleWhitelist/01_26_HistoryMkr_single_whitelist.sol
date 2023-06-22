// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "hardhat/console.sol";
import "./HistoryMkr.sol";

interface FeelGood {
    // mind the `view` modifier
    function balanceOf(address _owner) external view returns (uint256);
}

contract HistoryMkrSingleWhitelist is HistoryMkr, ERC721Pausable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    mapping(address => uint8) preMintBalanceLedger; //map to track preMintBalances (otherwise they can move away and buy again)

    bool private preMintEnabled = false;
    bool public running = true;

    FeelGood public feelGoodContract;
    constructor(string memory name, string memory symbol, string memory _provenanceHash, address _whitelistContract, address payable _treasurer, uint16 _initialId, uint16 _treasurersTokens, uint16 _maxAvailableTokens) 
        HistoryMkr(name, symbol, _provenanceHash, _treasurer, _initialId, _treasurersTokens, _maxAvailableTokens) {
        royaltyPercentageBasePoints = 500; //5%
        feelGoodContract = FeelGood(_whitelistContract);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(HistoryMkr, ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(HistoryMkr, ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(HistoryMkr, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    } 

    function contractURI() public view override returns (string memory) {
        return "ipfs://QmRTBo4Zz38qAqu53GBXuzRWWgVvUnuFsbtp1rGYqRQabS/"; 
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, HistoryMkr) returns (string memory) {
        return super.tokenURI(tokenId); 
    }

    function preMint() public payable whenMintPaused() {
        require(preMintEnabled, "this can only be done before any minting is open to public");
        require(preMintBalanceLedger[msg.sender] == 0, "you have bought your limit"); //checking in our map
        uint256 senderBalance = feelGoodContract.balanceOf(msg.sender);
        require(senderBalance > 0, "you are not on the whitelist for preMint purchasing");
        require(_tokenIdTracker.current() + 1 <= maxAvailableTokens, "all tokens have been minted");
        require(!Address.isContract(msg.sender), "address cannot be a contract");
        require(msg.value == _salePrice, "Ether sent is not equal to PRICE" );
        payable(treasurer).transfer(msg.value);
        transferNFTs(1, msg.sender);
        preMintBalanceLedger[msg.sender] = preMintBalanceLedger[msg.sender] + 1;
    }

    function currentState() public view returns (string memory)  {
        console.log("checking current state");
        string memory state = "idle";
        if (paused()) {
            state = "paused";
        } else if (preMintEnabled) {
            state = "premint";
        } else if (!mintPaused) {
            state = "mint";
        }
        console.log("returning state:", state);
        return state;
    }
    function startMintingProcess(uint256 tokenPrice) public override whenRunning() whenPreMintDisabled() onlyOwner {
        super.startMintingProcess(tokenPrice);
    }
    function startPreMintingProcess(uint256 tokenPrice) public whenRunning() whenMintPaused() onlyOwner {
        require(balanceOf(treasurer) >= treasurersTokens, "cannot pre mint until all tokens have been claimed");
        _salePrice = tokenPrice;
        preMintEnabled = true;
    }
    function stopPreMintingProcess() public whenMintPaused() onlyOwner {
        preMintEnabled = false;
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public whenRunning() onlyOwner {
        _unpause();
    }
    //very dangerosus. Stops the entire contract
    function endContract() public onlyOwner() {
        pause();
        preMintEnabled = false;
        running = false;
    }
    function _baseURI() internal view virtual override (HistoryMkr, ERC721) returns (string memory) {
        return baseURI;
    }

    function setNewTreasurer(address payable _treasurer) public whenPaused onlyOwner {
        treasurer = _treasurer;
    }   

    modifier whenRunning() {
        require(running, "contract is no longer running");
        _;
    }
    modifier whenPreMintDisabled() {
        require(!preMintEnabled, "pre mint is running");
        _;
    }
    
}