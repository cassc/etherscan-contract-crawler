// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ProofOfVitalik is  Ownable,ERC721A,ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    bool public MintStatus = false;
    uint public MintPrice = 0.003 ether; //0.003 ETH
    string public baseURI;  
    uint public freeMint = 3;
    uint public maxMintPerTx = 20;  
    uint public maxSupply = 6969;

    constructor() ERC721A("Proof Of Vitalik", "POV",69,6969){}

    function mint(uint256 qty) external payable
    {
        require(MintStatus , "Notification:  Minting Public Pause");
        require(qty <= maxMintPerTx, "Notification:  Limit Per Transaction");
        require(totalSupply() + qty <= maxSupply,"Notification:  Soldout");
        _safemint(qty);
    }

    function _safemint(uint256 qty) internal
    {
        if(WalletMint[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Notification:  Fund not enough");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Notification:  Fund not enough");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setPublicMinting() external onlyOwner {
        MintStatus  = !MintStatus ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
    }

    function setMaxFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setmaxSupply(uint256 qty_) external onlyOwner {
        maxSupply = qty_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}