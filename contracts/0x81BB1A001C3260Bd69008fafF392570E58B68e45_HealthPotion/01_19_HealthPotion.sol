// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721.sol";
import "Pausable.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";
import "Strings.sol"; 

import "Authorized.sol";
import "Policy.sol";

// Ownable inherited via Authorized
contract HealthPotion is ERC721, Pausable, ERC721Burnable, Authorized, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    mapping (uint256 => Policy.Cover) policyTerms;
    IERC20 public usdcContract;
    string private _baseURIextended;

    event Minted(address indexed owner, uint256 tokenId);
    event Revoked(address indexed owner, uint256 tokenId);

    constructor(address _usdcAddress) ERC721("Health Potion", "HP") {
        usdcContract = IERC20(_usdcAddress);
    }

    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 _policyDays, Policy.PolicyType _policyType) 
        public 
        onlyAuthorized 
        nonReentrant 
    {
        require(balanceOf(to) == 0, "Can only mint one token per wallet");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        policyTerms[tokenId].startTimestamp = block.timestamp;
        policyTerms[tokenId].lengthDays = _policyDays;
        policyTerms[tokenId].paymentType = _policyType;
    }

    function burn(uint256 tokenId) 
        public 
        override 
        onlyOwner 
    {
        _burn(tokenId);
    }

    function isValid(uint256 tokenId) 
        external 
        view 
        returns (bool) 
    {
        return _ownerOf(tokenId) != address(0);
    }

    function hasValid(address owner) 
        external 
        view 
        returns (bool) 
    {
        return balanceOf(owner) > 0;
    }

    function isActive(uint256 tokenId) 
        public 
        view 
        returns (bool) 
    {
        Policy.Cover memory policy = policyTerms[tokenId];
        return(policy.startTimestamp <= block.timestamp && block.timestamp < policy.startTimestamp + policy.lengthDays * 1 days);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        if (from != address(0) && to != address(0)){    // Can only transfer between wallets when the policy is expired
            require(isActive(tokenId) == false, "Not allowed to transfer token whilst policy is active");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) 
        internal
        override
        virtual 
    {
        if (from == address(0)) {
            emit Minted(to, firstTokenId);
        } else if (to == address(0)) {
            emit Revoked(from, firstTokenId);
        }
    }

    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        usdcContract.transfer(_to, _amount);
    }

    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}