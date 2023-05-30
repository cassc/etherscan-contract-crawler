//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface WackyWhitelist {
    function isAddressWhitelisted(
        address _address
    ) view external returns(bool);
}

contract WackyWassiesNFT is ERC721, Ownable, Pausable, ReentrancyGuard, ERC2981, ERC721Enumerable {
    using Strings for uint256;
    using SafeMath for uint256;

    address public wackyWhitelist;

    bool public revealed = false;
    string public baseURI;
    string public notRevealedURI;

    bool public publicSaleActive = false;
    bool public preSaleActive = false;
    bool public claimActive = false;

    address payable public royalties;
    address payable public DEV_WALLET;
    address payable public CREATOR_WALLET;

    uint256 public immutable MAX_SUPPLY;

    uint256 public MAX_CLAIM_SUPPLY = 37;
    uint256 public CLAIMED_SUPPLY = 0;
    uint256 public MAX_PER_WALLET = 5;

    uint256 public PRE_SALE_PRICE;
    uint256 public PUBLIC_SALE_PRICE;

    mapping(address => bool) public isClaimable;

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint256 _mrangad, 
        address _wackyWhitelist
    ) ERC721(_name, _symbol) {
        require(address(_wackyWhitelist) != address(0),"NFT: Invalid Whitelist Addresss");
        MAX_SUPPLY = _mrangad;
        wackyWhitelist = _wackyWhitelist;

        CREATOR_WALLET = payable(address(0x5f790a1bB3bafEEefd6094A251ed3dBb0E1FA56a));
        DEV_WALLET = payable(address(0x6d45359B49df24eE5fd9247f4Bb307AE9315398E));
        PRE_SALE_PRICE = 20_000_000_000_000_000;
        PUBLIC_SALE_PRICE = 30_000_000_000_000_000;
    }

    function addToClaim(address[] memory _address) external onlyOwner whenNotPaused {
        for (uint256 index = 0; index < _address.length; index++) {
            isClaimable[_address[index]] = true;
        }
    }

    function airDrop(address[] calldata _address, uint256[] calldata _amount) external onlyOwner whenNotPaused {
        require(_address.length == _amount.length, "Input lengths do not match");
        uint mintIndex = totalSupply().add(1);        

        uint length = _address.length;
        for (uint index = 0; index < length; index++) {
            mintIndex = totalSupply();
            require(mintIndex.add(_amount[index]) <= MAX_SUPPLY - MAX_CLAIM_SUPPLY,"NFT: Airdrop would exceed Total Supply");

            for (uint count = 1; count <= _amount[index]; count++) {
                _safeMint(_address[index], mintIndex.add(count));
            }
        }
    }

    function claim() external whenNotPaused nonReentrant {
        require(claimActive, "NFT: Claim is NOT Active");
        require(isClaimable[msg.sender], "NFT: Sender is NOT Allowed to claim");
        require(CLAIMED_SUPPLY.add(1) <= MAX_CLAIM_SUPPLY, "NFT: Mint exceeds Claim Limit");
        isClaimable[msg.sender] = false;
        CLAIMED_SUPPLY = CLAIMED_SUPPLY.add(1);
        uint256 mintIndex = totalSupply().add(1);
        
        _safeMint(msg.sender, mintIndex);
    }

    function preSaleMint(uint256 _amount) external payable whenNotPaused nonReentrant {
        require(preSaleActive, "NFT: Pre-sale is NOT active");
        require(
            WackyWhitelist(wackyWhitelist).isAddressWhitelisted(msg.sender), 
            "NFT: Sender is NOT whitelisted"
        );
        require(balanceOf(msg.sender).add(_amount) <= MAX_PER_WALLET, "NFT: You can't mint so many tokens");
        require(totalSupply().add(_amount) <= MAX_SUPPLY - MAX_CLAIM_SUPPLY, "NFT: Mint would exceed PreSale Limit");
        mint(_amount, true);
    }

    function publicSaleMint(uint _amount) external payable whenNotPaused nonReentrant {
        require(publicSaleActive, "NFT: Public-sale is NOT active");
        require(balanceOf(msg.sender).add(_amount) <= MAX_PER_WALLET, "NFT: You can't mint so many tokens");
        require(totalSupply().add(_amount) <= MAX_SUPPLY - MAX_CLAIM_SUPPLY,"NFT: Mint would exceed total supply");
        mint(_amount, false);
    }

    function mint(uint256 _amount, bool _isPreSale) internal {
        if (_isPreSale) {
            require(PRE_SALE_PRICE.mul(_amount) <= msg.value, "NFT: Native Asset value sent for PRE SALE mint is In-correct.");
        } else {
            require(PUBLIC_SALE_PRICE.mul(_amount) <= msg.value, "NFT: Native Asset value sent for PUBLIC mint is In-correct.");
        }
        uint256 mintIndex = totalSupply().add(1);
        for(uint256 count = 0; count < _amount; count++) {
            _safeMint(msg.sender, mintIndex.add(count));
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() public onlyOwner whenPaused {
        _unpause();
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
    }

    function setMaxClaimSupply(uint256 _maxClaimSupply) external onlyOwner {
        MAX_CLAIM_SUPPLY = _maxClaimSupply;
    }

    function setpreSalePrice(uint256 _preSalePrice) external onlyOwner {
        PRE_SALE_PRICE = _preSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        PUBLIC_SALE_PRICE = _publicSalePrice;
    }

    function togglePublicSale()external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePreSale() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function toggleClaim() external onlyOwner {
        claimActive = !claimActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == false) {
            return notRevealedURI;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount,uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, amount, batchSize);
    }

    function withdraw() external onlyOwner {
        uint256 balance     = address(this).balance;
        uint256 ownerAmount = balance.mul(850).div(1000);

        CREATOR_WALLET.transfer(ownerAmount);
        DEV_WALLET.transfer(balance.sub(ownerAmount));
    }

    function setDevWallet(address _devWallet) external {
        require(msg.sender == DEV_WALLET, "Sender not developer");
        DEV_WALLET = payable(_devWallet);
    }

    function setCreatorWallet(address _creatorWallet) external {
        require(msg.sender == CREATOR_WALLET, "Sender not Creator");
        CREATOR_WALLET = payable(_creatorWallet);
    }

    function setWackyWhitelist(address _wackyWhitelist) external {
        require(address(_wackyWhitelist) != address(0),"NFT: Invalid Whitelist Addresss");
        wackyWhitelist = _wackyWhitelist;
    }

    function setRoyalty(address payable _receiver, uint96 _feeNumerator) external onlyOwner {
        royalties = _receiver;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function checkWhitelist(address _check) external view returns(bool) {
        return WackyWhitelist(wackyWhitelist).isAddressWhitelisted(_check);
    }
}