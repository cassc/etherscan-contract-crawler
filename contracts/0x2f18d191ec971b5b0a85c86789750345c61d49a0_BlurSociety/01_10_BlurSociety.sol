// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

contract BlurSociety is ERC721A, ERC721AQueryable,OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true), Ownable {
    
    bool public Minting  = false;
    uint256 public MintPrice = 0.0025 ether;
    string public baseURI;  
    uint256 public maxPerTx = 20;  
    uint256 public maxSupply = 5555;
    uint256[] public FreeClaim = [3,2,1];
    uint256[] public FreeSupply = [3000,4000,5555];
    mapping (address => uint256) public minted;
    bool public operatorFilteringEnabled = true;

    constructor() ERC721A("Blur Society", "Blur Society"){}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 qty) external payable
    {
        require(Minting , "Blur Society Minting Close !");
        require(qty <= maxPerTx, "Blur Society  Max Per Tx !");
        require(totalSupply() + qty <= maxSupply,"Blur Society  Soldout !");
        _mint(qty);
    }

    function _mint(uint256 qty) internal  {
        uint freeMint = CalculateClaim();
        if(minted[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Blur Society  Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Blur Society  Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function CalculateClaim() public view returns (uint256) {
        if(totalSupply() < FreeSupply[0])
        {
            return FreeClaim[0];
        }
        else if (totalSupply() < FreeSupply[1])
        {
            return FreeClaim[1];
        }
        else if (totalSupply() < FreeSupply[2])
        {
            return FreeClaim[2];
        }
        else
        {
            return 0;
        }
    }
    
    function setOperatorFilteringEnabled(bool _enabled) external onlyOwner {
        operatorFilteringEnabled = _enabled;
    }

    function setOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe) external onlyOwner{
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] calldata listedAirdrop ,uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty);
        }
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setMintingIsLive() external onlyOwner {
        Minting  = !Minting ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setFreeSupply(uint256[] calldata FreeSupply_) external onlyOwner {
        FreeSupply = FreeSupply_;
    }
    
    function setFreeClaim(uint256[] calldata FreeClaim_) external onlyOwner {
        FreeClaim = FreeClaim_;
    }

    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(to, operatorFilteringEnabled) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator, operatorFilteringEnabled) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}