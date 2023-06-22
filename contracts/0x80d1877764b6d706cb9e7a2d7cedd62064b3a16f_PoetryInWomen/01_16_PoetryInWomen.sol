// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFTInterface is IERC721Enumerable {}

contract PoetryInWomen is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    
    uint public constant MAX_TOKENS = 2222;
    uint public PRICE;
    uint public constant PRESALE_PRICE = 0.12 ether;
    uint public constant PUBLICSALE_PRICE = 0.125 ether;
    string public METADATA_PROVENANCE_HASH = "";

    string public baseURI = "https://poetryinwomen.pages.dev/json/";
    
    uint private _curIndex = 1;
    
    bool public saleActive = false;
    bool public isPrioritysaleLive = false;
    bool public isPresaleLive = false; 
    bool public isPublicsaleLive = false;

    mapping(address => uint256) private diamondList;

    
    constructor(address royaltyRecipient, uint96 royaltyPoints) ERC721A("Poetry in Women","PIW")  {
        _setDefaultRoyalty(royaltyRecipient, royaltyPoints);
    }
    
    
    /** NFT */
    
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mint(uint256 numTokens) external payable nonReentrant() {
        require(saleActive, "Sale is not active.");
        require(isPrioritysaleLive == true || isPresaleLive == true || isPublicsaleLive == true, "Sale is not active.");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Not enough pieces remain.");
        require(balanceOf(msg.sender) + numTokens <= 35, "Max 35 pieces per wallet.");
        /** If in Priority Sale, check Diamond List **/
        if (isPrioritysaleLive) {
            /** if wallet not on diamond list, will throw exception **/
            require(numTokens <= diamondList[msg.sender], "Not on Diamond List or exceeds max.");
        }
        /** Check sale state for PRICE then do require**/
        if (isPrioritysaleLive || isPresaleLive) {
            PRICE = PRESALE_PRICE;
        }
        else if (isPublicsaleLive) {
            PRICE = PUBLICSALE_PRICE;
        }
        require((msg.value >= numTokens * PRICE), "More ETH required to mint.");

        /** Mint **/
        _safeMint(msg.sender, numTokens);

        /** If in Priority Sale decrement diamondList for wallet **/
        if (isPrioritysaleLive) {
            diamondList[msg.sender] -= numTokens;
        }

        /** Turn off sale states when minted out **/
        if (totalSupply() + numTokens >= MAX_TOKENS) {
            saleActive = false;
            isPresaleLive = false;
            isPublicsaleLive = false;
            isPrioritysaleLive = false;
        }
    }

    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseURI();
    }
    
    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setDiamondList(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            diamondList[addresses[i]] = 35; /** Max 35 mints per wallet **/
        }
    }

    function flipSaleState() external onlyOwner {
        saleActive = !saleActive;
        if (!saleActive) {
            isPrioritysaleLive = false;
            isPresaleLive = false;
            isPublicsaleLive = false;
        }
    }

    function flipPrioritySale() external onlyOwner {
        isPrioritysaleLive = !isPrioritysaleLive;
    }

    function flipPresale() external onlyOwner {
        isPresaleLive = !isPresaleLive;
        if (isPrioritysaleLive) {
            isPrioritysaleLive = false;
        }
    }

    function flipPublicsale() external onlyOwner {
        isPublicsaleLive = !isPublicsaleLive;
        if (isPresaleLive) {
            isPresaleLive = false;
        }
    }

    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // Claim = mint to owner wallet

    function claimMany(uint256 numTokens) external onlyOwner {
        require(totalSupply() < MAX_TOKENS, "Sale has already ended");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Not enough available");
        _safeMint(owner(), numTokens);
    }

    function claimAllRemaining() external onlyOwner {
        // send remaining pieces to owner wallet
        _safeMint(owner(), MAX_TOKENS - totalSupply());
        saleActive = false;
    }

    // Give away = mint to another wallet

    function giveAway(address recipient) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_TOKENS, "No more pieces");
        _safeMint(recipient, 1);
    }

    function giveAwayManyToOne(address recipient, uint256 numTokens) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_TOKENS, "No more pieces");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Not enough available");
        _safeMint(recipient, numTokens);
    }

    function giveAwayOneToMany(address[] memory recipients) external nonReentrant() onlyOwner {
        require(totalSupply() + recipients.length <= totalSupply(), "Not enough pieces remain.");
        for (uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], 1);
        }
    }

    function giveAwayManyToMany(address[] memory recipients, uint256[] memory amounts) external nonReentrant() onlyOwner {
        require(recipients.length == amounts.length, "Number of addresses and amounts much match");
        uint256 totalToGiveAway = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalToGiveAway += amounts[i];
        }
        require(totalSupply() + totalToGiveAway <= totalSupply(), "Not enough pieces remain.");
        
        for (uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract_metadata.json"));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }
}