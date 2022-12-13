// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract AiBlocks is ERC721A, Ownable, PaymentSplitter {

    // Settings
    string public baseURI;
    uint256 private _teamLength;
    uint256 constant public MAX_SUPPLY = 300;

    // Public settings
    uint256 constant public MAX_MINT_PUBLIC = 6;
    uint256 public mintPricePublic = 0.1 ether;   
    mapping(address => uint256) private _mintedAmountPublic;

    // Team settings
    uint256 private _teamSupply;
    uint256 private _mintedForTeam = 0;

    // Sale config
    enum MintStatus {
        CLOSED,
        PUBLIC
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    constructor(
        string memory _initialBaseURI,
        uint256 teamSupply_,
        address[] memory payments,
        uint256[] memory shares
    ) 
        ERC721A("Ai Blocks", "ABLCKS")
        PaymentSplitter(payments, shares)
    {
        baseURI = _initialBaseURI;
        _teamSupply = teamSupply_;
        _teamLength = payments.length;
    }

    modifier mintCompliance(uint256 amount) {
        require(tx.origin == msg.sender, "Only humans are allowed to mint!");
        require(amount > 0, "Can't mint zero!");
        require(totalSupply() + amount <= MAX_SUPPLY, "There are no more Ai Blocks available!");
        _;
    }

    // Metadata
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Public metadata
    function setMintPricePublic(uint256 _newMintPricePublic) external onlyOwner {
        mintPricePublic = _newMintPricePublic;
    }

    function setTeamSupply(uint256 teamSupply_) external onlyOwner {
        _teamSupply = teamSupply_;
    }

    // Sale metadata
    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    // Withdraw funds
    function releaseAll() external onlyOwner {
        for(uint i = 0; i < _teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    // Mint
    function mintPublic(uint256 amount) external payable mintCompliance(amount) {
        require(mintStatus == MintStatus.PUBLIC, "Public sale is inactive!");
        require(_mintedAmountPublic[msg.sender] + amount <= MAX_MINT_PUBLIC, "Can't mint that many over public!");
        require(msg.value >= mintPricePublic * amount, "The ether value sent is not correct!");
  
        _mintedAmountPublic[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintTeam(uint256 amount, address _recipient) external mintCompliance(amount) onlyOwner {  
        require(_mintedForTeam + amount <= _teamSupply, "You can't mint so many for the team!");

        _mintedForTeam += amount;         
        _safeMint(_recipient, amount);
    }
}