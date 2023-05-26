//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*****************************************************************************************
  _   _     U  ___ u _____    ____    U  ___ u _____   ____       _      U  ___ u 
 |'| |'|     \/"_ \/|_ " _| U|  _"\ u  \/"_ \/|_ " _| |  _"\  U  /"\  u   \/"_ \/ 
/| |_| |\    | | | |  | |   \| |_) |/  | | | |  | |  /| | | |  \/ _ \/    | | | | 
U|  _  |u.-,_| |_| | /| |\   |  __/.-,_| |_| | /| |\ U| |_| |\ / ___ \.-,_| |_| | 
 |_| |_|  \_)-\___/ u |_|U   |_|    \_)-\___/ u |_|U  |____/ u/_/   \_\\_)-\___/  
 //   \\       \\   _// \\_  ||>>_       \\   _// \\_  |||_    \\    >>     \\    
(_") ("_)     (__) (__) (__)(__)__)     (__) (__) (__)(__)_)  (__)  (__)   (__)   
 ****************************************************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./BatchReveal.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract HotPotDAO is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBase, BatchReveal {

    //Contract URI
    string public CONTRACT_URI = "ipfs://QmYTwE1CQKECdqAQwNNfzg5XcJDaDbYpyYg3trnsQvAR6S";

    mapping(address => uint256) public userToHasMinted;

    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://Qmaq16n6jNCGEVKKfcG63drGf1nKeb2qvgnobANehTPUmt";
    string public BASE_URI;
    uint256 public mintWave = 0;
    uint256 public MINT_PRICE = 0.1 ether;
    uint256 public MAX_BATCH_SIZE = 1;
    uint256 public MAX_MINTED_PER_WALLET = 2;

    bytes32 immutable private s_keyHash;
    address immutable private linkToken;
    address immutable private linkCoordinator;

    constructor(bytes32 _s_keyHash, address _linkToken, address _linkCoordinator) 
        ERC721A("HotPotDAO", "HOTPOTDAO") 
        VRFConsumerBase(_linkCoordinator, _linkToken) {
            linkToken = _linkToken;
            linkCoordinator = _linkCoordinator;
            s_keyHash = _s_keyHash;
        }

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Max collection size reached!"
        );
        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = (MINT_PRICE) * quantity;
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Mint would surpass Collection Size!");
        require(totalSupply() + quantity <= mintWave * REVEAL_BATCH_SIZE, "Next mint wave has not begun");
        require(userToHasMinted[msg.sender] + quantity <= MAX_MINTED_PER_WALLET, "Already minted max to wallet!");   
        require(quantity <= MAX_BATCH_SIZE, "Tried to mint quanity over limit, retry with reduced quantity");
        require(msg.value >= price, "Must send enough eth for public mint");
        userToHasMinted[msg.sender]++;
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }   
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setMintWave(uint _mintWave) public onlyOwner {
        mintWave = _mintWave;
    }

    function setBaseURI(bool _revealed, string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
        REVEALED = _revealed;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Batch Reveal Randomization
    // Get randomeness from Chainlink VRF
    function revealNextBatch(uint s_fee) public onlyOwner returns (bytes32 requestId) {
        require(totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE), "totalSupply too low");

        // checking LINK balance
        require(IERC20(linkToken).balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");

        // requesting randomness
        requestId = requestRandomness(s_keyHash, s_fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE), "totalSupply too low");
        uint batchNumber = lastTokenRevealed/REVEAL_BATCH_SIZE;
        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[batchNumber] = randomness % (COLLECTION_SIZE - (batchNumber*REVEAL_BATCH_SIZE));
        unchecked {
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if(id >= lastTokenRevealed){
            return UNREVEALED_URI;
        } else {
            return string(abi.encodePacked(BASE_URI, Strings.toString(getShuffledTokenId(id))));
        }
    }
}