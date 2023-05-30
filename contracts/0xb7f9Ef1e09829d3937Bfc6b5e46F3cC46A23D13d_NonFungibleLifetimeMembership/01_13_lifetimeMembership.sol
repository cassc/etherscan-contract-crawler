// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface FoundingMemberInteraction {
    function ownerOf(uint256 id) external view returns (address);
}

contract NonFungibleLifetimeMembership is ERC1155, Ownable, Pausable, ERC1155Supply {
    uint16 public SUPPLY = 1000;
    uint8 public RESERVED_SUPPLY = 20;
    uint8 public MAX_MINT_PER_TX = 3;

    uint8 FOUNDING_MEMBERS_CLAIMABLE = 2;
    uint8 TOKEN_INDEX = 0;

    uint16 public claimedTokensCount = 0;
    uint16 public supplyLeft = SUPPLY;

    bool public saleActive;
    bool public claimActive;

    address public foundingMembershipContractAddress;

    uint256 private _price = 0.5 ether;

    event Mint(address indexed _address, uint8 amount, uint16 supplyLeft);
    event Claim(address _address, uint8 membershipId, uint8 amount, uint8 membershipClaimCount, uint16 totalClaimed);

    // Founding Membership ID -> Amount claimed
    mapping (uint8 => uint8) claimedTokens;

    modifier isMintable(uint256 amount) {
        require(saleActive, "Sale is not active");
        require(amount > 0, "Amount must be positive integer");
        require(amount <= MAX_MINT_PER_TX, "Can't mint that many tokens at once");
        require(supplyLeft - amount >= 0, "Can't mint over supply limit");

        _;
    }

    modifier isClaimable(uint8 amount, uint8 memberId) {
        require(claimActive, "Claiming is not active");
        require(amount > 0,"Amount must be positive integer");
        require(claimedTokens[memberId] + amount <= FOUNDING_MEMBERS_CLAIMABLE, "Can only claim 2 tokens per membership");
        require(FoundingMemberInteraction(foundingMembershipContractAddress).ownerOf(memberId) == msg.sender, "Only the owner of this membership can claim its tokens");

        _;
    }

    constructor(address _address, bool _saleAndClaimActive) ERC1155("https://nonfungible.tools/api/metadata/lifetime") {
        foundingMembershipContractAddress = _address;
        saleActive = _saleAndClaimActive;
        claimActive = _saleAndClaimActive;

        _mint(msg.sender, TOKEN_INDEX, RESERVED_SUPPLY, "");

        supplyLeft -= RESERVED_SUPPLY;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function setClaimStatus(bool _claimActive) public onlyOwner {
        claimActive = _claimActive;
    }


    function hasLifetimeToken(address account) public view returns (bool) {
        return balanceOf(account, TOKEN_INDEX) > 0;
    }

    function checkClaimedForMembership(uint8 memberId) public view returns (uint8) {
        return claimedTokens[memberId];
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function claimToken(address account, uint8 memberId, uint8 amount) public whenNotPaused isClaimable(amount, memberId) {
        _mint(account, TOKEN_INDEX, amount, "");

        claimedTokens[memberId] += amount;
        claimedTokensCount += amount;

        emit Claim(account, memberId, amount, claimedTokens[memberId], claimedTokensCount);
    }

    function mint(address account, uint8 amount)
        public
        payable
        whenNotPaused
        isMintable(amount)
    {
        require(msg.value >= amount * _price, "Wrong amount sent");
        _mint(account, TOKEN_INDEX, amount, "");

        supplyLeft -= amount;

        emit Mint(account, amount, supplyLeft);
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
 
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}