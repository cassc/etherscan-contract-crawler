//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract WeakDogs is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 3333;
    uint256 public price = 0.005 ether;
    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 5; //单笔
    uint256 constant public PUBLIC_MINT_LIMIT = 5; //单钱包
    string public baseURI;
    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI;
    bool public paused = true;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Weak Dogs", "WKDG") { }

    /* private function */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* public function */

    function ownerMint(uint256 quantity, address reciever) public payable onlyOwner  {
        _mint(reciever, quantity);
    }
    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");
        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        require(msg.value >= (price * quantity), "price not enough, 0.005ETH each");

        numUserMints[msg.sender] = (currMints + quantity);

        _mint(msg.sender, quantity);
    }

    /* view function */

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /* owner function */


    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }


    function withdraw() external payable onlyOwner {
        address DEV_ADDRESS = 0x1ED3b0ebEd4b5e32E5c0fc47779794eF1eA7A615;
        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: address(this).balance / 5
        }("");
        require(succ, "Dev transfer failed");

        // Withdraw remaining balance to the owner wallet
        (succ, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(succ, "Owner transfer failed");
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}