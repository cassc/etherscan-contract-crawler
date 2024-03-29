// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './IMutant.sol';
import './IMutantMetadata.sol';
import './MutantPunk.sol';

contract Mutant is ERC721Enumerable, Ownable, IMutant, IMutantMetadata {
    using Strings for uint256;

    uint256 public constant MPL_GIFT = 0;
    uint256 public constant MPL_PUBLIC = 3_608;
    uint256 public constant MPL_MAX = MPL_GIFT + MPL_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.08 ether;

    bool public isActiveClaiming = false;
    bool public isActive = false;
    bool public isAllowListActive = false;
    string public proof;

    uint256 public allowListMaxMint = 1;

    /// @dev We will use these to be able to calculate remaining correctly.
    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;
    mapping(address => uint256) private _claimed;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    MutantPunk private immutable mutantPunk;

    constructor(string memory name, string memory symbol, address punkAddress) ERC721(name, symbol) {
        mutantPunk = MutantPunk(punkAddress);
    }

    function addToAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            /**
            * @dev We don't want to reset _allowListClaimed count
            * if we try to add someone more than once.
            */
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    /**
    * @dev We want to be able to distinguish tokens bought during isAllowListActive
    * and tokens bought outside of isAllowListActive
    */
    function allowListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return _allowListClaimed[owner];
    }

    function allowedForClaim(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return mutantPunk.balanceOf(owner) - _claimed[owner];
    }

    function claim(uint256 numberOfTokens) external override {
        require(isActiveClaiming, 'Contract is not active');
        require(totalSupply() < MPL_MAX, 'All tokens have been minted');
        require(numberOfTokens + _claimed[msg.sender] <= mutantPunk.balanceOf(msg.sender), 'Purchase would exceed number of Mutant Punks City');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
            * @dev Since they can get here while exceeding the MPL_MAX,
            * we have to make sure to not mint any additional tokens.
            */
            if (totalPublicSupply < MPL_PUBLIC) {
                /**
                * @dev Public token numbering starts after MPL_GIFT.
                * And we don't want our tokens to start at 0 but at 1.
                */
                uint256 tokenId = MPL_GIFT + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _claimed[msg.sender] += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(!isAllowListActive, 'Only allowing from Allow List');
        require(totalSupply() < MPL_MAX, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        /**
        * @dev The last person to purchase might pay too much.
        * This way however they can't get sniped.
        * If this happens, we'll refund the Eth for the unavailable tokens.
        */
        require(totalPublicSupply < MPL_PUBLIC, 'Purchase would exceed MPL_PUBLIC');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
            * @dev Since they can get here while exceeding the MPL_MAX,
            * we have to make sure to not mint any additional tokens.
            */
            if (totalPublicSupply < MPL_PUBLIC) {
                /**
                * @dev Public token numbering starts after MPL_GIFT.
                * And we don't want our tokens to start at 0 but at 1.
                */
                uint256 tokenId = MPL_GIFT + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isAllowListActive, 'Allow List is not active');
        require(_allowList[msg.sender], 'You are not on the Allow List');
        require(totalSupply() < MPL_MAX, 'All tokens have been minted');
        require(numberOfTokens <= allowListMaxMint, 'Cannot purchase this many tokens');
        require(totalPublicSupply + numberOfTokens <= MPL_PUBLIC, 'Purchase would exceed MPL_PUBLIC');
        require(_allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint, 'Purchase exceeds max allowed');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
            * @dev Public token numbering starts after MPL_GIFT.
            * We don't want our tokens to start at 0 but at 1.
            */
            uint256 tokenId = MPL_GIFT + totalPublicSupply + 1;

            totalPublicSupply += 1;
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < MPL_MAX, 'All tokens have been minted');
//        require(totalGiftSupply + to.length <= MPL_GIFT, 'Not enough tokens left to gift');

        for(uint256 i = 0; i < to.length; i++) {
            /// @dev We don't want our tokens to start at 0 but at 1.
            uint256 tokenId = totalGiftSupply + 1;

            totalGiftSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setClaimingIsActive(bool _isActiveClaiming) external override onlyOwner {
        isActiveClaiming = _isActiveClaiming;
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsAllowListActive(bool _isAllowListActive) external override onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
        allowListMaxMint = maxMint;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        /// @dev Convert string to bytes so we can check if it's empty or not.
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        _tokenBaseURI;
    }
}