// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract chibigenzOfficial is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;
    address public constant TeamWallet = 0x8003510B6874BbDAeDb9aa892713cef545C232b2;
    uint256 public constant maxSupply         = 7777;
    uint256 public Mintprice                  = 0.01 ether;
    uint256 public maxPerTx                   = 3;
    uint256 public maxPerWallet               = 3;
    bool    public mintEnabled                = false;
    bool    public revealed                   = false;
    string  public baseURI;
    mapping(address => uint256) public _walletMints;
    

    constructor() ERC721A("CHIBI BY KENJII", "GENZ"){
        _setDefaultRoyalty(msg.sender, 600);
        _registerForOperatorFiltering();
    }

    function Mint(uint256 amount) external payable {
        require(mintEnabled, "Fail: Mint is not live");
        require(totalSupply() + amount <= maxSupply, "Sold out");
        require(amount <= maxPerTx, "Fail: Too many per tx");
        require(_walletMints[msg.sender] + amount <= maxPerWallet, "Fail: Too many per wallet");
        require(msg.value == Mintprice * amount, "Incorrect Ether value.");
        require(msg.sender == tx.origin, "No contracts");
        _walletMints[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (!revealed) {
            return "https://gateway.pinata.cloud/ipfs/QmSdxkQjXEd3qXP3mCZxLooEfPDYZQmTCXdPWhdY17SkLw/chibigenz.json";
        }
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function SetBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function SetPrice(uint256 price_) external onlyOwner {
        Mintprice = price_;
    }

    function TeamSetWLMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function Reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function Reserve(uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= maxSupply, "Minting max supply");
        require(tokens > 0, "Must mint at least one");
        require(_walletMints[_msgSender()] + tokens <= 7777, "fail");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }
    function TeamAirdrop(address _address, uint256 _amount) external onlyOwner {
        require(
            totalSupply() + _amount <= 7777,
            "Can't Airdrop more than max supply"
        );
        _mint(_address, _amount);
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }


    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(TeamWallet, ((balance * 100) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}