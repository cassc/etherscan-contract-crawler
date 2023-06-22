// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HypeRockets is ERC721, Ownable {

    uint constant public TICKET_ID = 0;
    uint constant public MAX_SUPPLY = 10000;
    uint constant public PRICE = 0.0069 ether;

    string private baseURI;
    IERC1155 public ticketsContract;
    uint public maxNFTPerMint;
    uint public maxFreeNFTPerWallet;
    uint public maxMintsPerWallet;

    bool public isClaimingAvailable;
    bool public isMintingAvailable;
    uint public rocketsMinted;

    mapping(address => uint) public claimedWithTickets;
    mapping(address => uint) public mintedNFTs;

    constructor() ERC721("One Day Moon Way", "ODB") {

    }

    // Setters region
    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function setIsClaimingAvailable(bool _isClaimingAvailable) external onlyOwner {
        isClaimingAvailable = _isClaimingAvailable;
    }

    function setIsMintingAvailable(bool _isMintingAvailable) external onlyOwner {
        isMintingAvailable = _isMintingAvailable;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxFreeNFTPerWallet(uint _maxFreeNFTPerWallet) external onlyOwner {
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
    }

    function configure(
        IERC1155 _ticketsContract,
        bool _isClaimingAvailable,
        bool _isMintingAvailable,
        uint _maxMintsPerWallet,
        uint _maxFreeNFTPerWallet
    ) external onlyOwner {
        ticketsContract = _ticketsContract;
        isClaimingAvailable = _isClaimingAvailable;
        isMintingAvailable = _isMintingAvailable;
        maxMintsPerWallet = _maxMintsPerWallet;
        maxFreeNFTPerWallet = _maxFreeNFTPerWallet;
    }
    // endregion

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier maxSupplyCheck(uint amount)  {
        require(rocketsMinted + amount <= MAX_SUPPLY, "Tokens supply reached limit");
        _;
    }

    // Mint and Claim functions
    function mintPrice(uint amount) public view returns (uint) {
        uint minted = mintedNFTs[msg.sender];
        uint remainingFreeMints = maxFreeNFTPerWallet > minted ? maxFreeNFTPerWallet - minted : 0;
        if (remainingFreeMints >= amount) {
            return 0;
        } else {
            return (amount - remainingFreeMints) * PRICE;
        }
    }

    function mint(uint amount) external payable {
        require(isMintingAvailable, "Minting is not available");
        require(mintPrice(amount) == msg.value, "Wrong ethers value");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "maxMintsPerWallet constraint violation");
        mintedNFTs[msg.sender] += amount;
        mintNFTs(amount);
    }

    function claim(uint amount) external {
        require(isClaimingAvailable, "Claiming is not available");
        uint tickets = ticketsContract.balanceOf(msg.sender, TICKET_ID);
        require(claimedWithTickets[msg.sender] + amount <= tickets, "Insufficient ticket balance");
        claimedWithTickets[msg.sender] += amount;
        mintNFTs(amount);
    }

    function mintNFTs(uint amount) internal maxSupplyCheck(amount) {
        uint fromToken = rocketsMinted + 1;
        rocketsMinted += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, fromToken + i);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance / 18 * 3;
        payable(0x50131231dE9E36B3838c5F4B9D80D07e45FDD7Ae).transfer(share1);
        payable(0x55dFc6B1A586542e0aB569434F5f38766D3bD0a1).transfer(balance - share1);
    }

}