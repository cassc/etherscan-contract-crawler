/*

   ______                 __  _ __        __  _                        
  / ____/___  ____  _____/ /_(_) /___  __/ /_(_)___  ____              
 / /   / __ \/ __ \/ ___/ __/ / __/ / / / __/ / __ \/ __ \             
/ /___/ /_/ / / / (__  ) /_/ / /_/ /_/ / /_/ / /_/ / / / /             
\____/\____/_/ /_/____/\__/_/\__/\__,_/\__/_/\____/_/ /_/            __
   / ____/________ ______/ /_(_)___  ____  ____ _/ (_)___  ___  ____/ /
  / /_  / ___/ __ `/ ___/ __/ / __ \/ __ \/ __ `/ / /_  / / _ \/ __  / 
 / __/ / /  / /_/ / /__/ /_/ / /_/ / / / / /_/ / / / / /_/  __/ /_/ /  
/_/   /_/   \__,_/\___/\__/_/\____/_/ /_/\__,_/_/_/ /___/\___/\__,_/   
    ____           __  ____ __  ____  ____  ____                       
   / __ )__  __    \ \/ / // / / __ \/ __ \/ __ \                      
  / __  / / / /     \  / // /_/ / / / / / / / / /                      
 / /_/ / /_/ /      / /__  __/ /_/ / /_/ / /_/ /                       
/_____/\__, /      /_/  /_/  \____/\____/\____/                        
      /____/                                                           

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract CFRAC is ERC721, Pausable, Ownable, PaymentSplitter {

    uint256 public tkPrice = 50000000000000000;
    uint256 public peopleRequired = 1000000000000000000000; 
    string public baseURI;
    bool public isSaleActive;
    bool public giveawaysProcessed;

    bytes32 public constant MERKLE_ROOT = 0xaedd1b9b342f996a6c749cab3e4b93591320ab7e53b1a7df4e33f09a551f5b67;
    uint256 public constant MAX_TKS = 1776;
    uint256 public constant MAX_FREE = 1;
    uint256 public constant MAX_PER_WALLET = 8;
    address public constant PEOPLE_TK = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71; 

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // update name and symbol
    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory uri
    ) 
        ERC721("Constitution Fractionalized", "CFRAC") 
        PaymentSplitter(_payees, _shares)
    { 
        // set baseURI
        baseURI = uri;
        // Tokens for principals
        for(uint i = 0; i < _payees.length; i++) {
            for(uint j=1; j <= 8; j++){  
                _safeMint(_payees[i], _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }

    // distributes tokens to leaderboard winners
    function processGiveaways(address[] calldata _winners_2x, address[] calldata _winners_1x, string memory uri) public onlyOwner {
        require(!giveawaysProcessed, 'GIVEAWAYS_ALREADY_SENT'); // can only be run once
        baseURI = uri;
        for (uint i=0; i<_winners_2x.length; i++) {
            _safeMint(_winners_2x[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _safeMint(_winners_2x[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }        
        for (uint i=0; i<_winners_1x.length; i++) {
            _safeMint(_winners_1x[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        giveawaysProcessed = true;
    }

    // activates mint 
    function activateSale() public onlyOwner {
        require(!isSaleActive, 'SALE_ALREADY_ACTIVE'); // can only be run once
        isSaleActive = true;
    }

    function mintNFT(uint256 numTokens) public payable whenNotPaused{
        require(isSaleActive, 'SALE_NOT_ACTIVE');
        require(_tokenIdCounter.current() + numTokens <= MAX_TKS, 'MAX_REACHED');
        require(balanceOf(_msgSender()) + numTokens <= MAX_PER_WALLET, 'MAX_OBTAINED');
        require(numTokens > 0, 'INVALID_NUM_TOKENS');
        require(tkPrice * numTokens <= msg.value, 'LOW_ETHER');

        for(uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function daoMint(bytes32[] calldata _merkleProof) public whenNotPaused {
        require(isSaleActive, 'SALE_NOT_ACTIVE');
        require(_tokenIdCounter.current() + 1 <= MAX_TKS, 'MAX_REACHED');
        require(balanceOf(_msgSender()) + 1 <= MAX_FREE, 'MAX_FREE_REACHED');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf), 'NOT_DAO_MEMBER');

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function peopleMint() public whenNotPaused {
        require(isSaleActive, 'SALE_NOT_ACTIVE');
        require(_tokenIdCounter.current() + 1 <= MAX_TKS, 'MAX_REACHED');
        require(balanceOf(_msgSender()) + 1 <= MAX_FREE, 'MAX_FREE_REACHED');
        IERC20 pToken = IERC20(PEOPLE_TK);
        require(pToken.balanceOf(msg.sender) >= peopleRequired, 'NOT_ENOUGH_PEOPLE_TOKENS');

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        // assuming two payees
        release(payable(payee(0)));
        release(payable(payee(1)));
    }

    function withdrawSingle(address payable account) public onlyOwner {
        release(account);
    }    

    // Update price if needed
    function setPrice(uint256 newPrice) public onlyOwner {
        tkPrice = newPrice;
    }

    // Update baseURI
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}