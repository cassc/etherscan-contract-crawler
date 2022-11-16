// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface CandiesNFT {
    function mint(address _to) external;
    function remaining() external view returns (uint256);
    function unwrap(uint _tokenId, address _to) external;
}

contract CandyShop is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    IERC1363 public immutable token;
    CandiesNFT public candies;
    uint private priceETH; 
    uint private priceREG; 
    uint public availableETH;
    uint public availableREG;
    address beneficiary;   
    mapping(address => uint) private minted;
    mapping(address => bool) public gifts;
    uint public maxMints = 1;

    event SaleInETH(address wallet, uint256 amount);
    event SaleInREG(address wallet, uint256 amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        candies = CandiesNFT(0x832DE117D8fA309B55F9C187475a17B87b9dFc85);
        token = IERC1363(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5);
        priceETH = 4321 * 10 ** 14; 
        priceREG = 69 * (10 ** 18); 
        availableETH = 5;
        availableREG = 0;
        beneficiary = msg.sender; 
    }

// Mint

    function mintWithEth(address _to) public payable whenNotPaused {
        require(minted[_to] < maxMints, "Already minted.");
        require(candies.remaining() > 0, "None Remaining");
        require(msg.value >= priceETH, 'Insufficient payment');
        availableETH--;
        Address.sendValue(payable(beneficiary), msg.value);
        minted[_to]++;
        candies.mint(_to);
        emit SaleInETH(_to,priceETH);
    }

    function claimGift(address _to) public whenNotPaused {
        require(gifts[_to], "Not on the gift list.");
        gifts[_to] = false;
        minted[_to]++;
        candies.mint(_to);
        emit SaleInETH(_to,priceETH);
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external whenNotPaused returns (bytes4) {
        require(msg.sender == address(token), "not correct sender");
        require(priceREG > 0, "item price not set");
        require(minted[from] < maxMints, "Already minted");
        token.transfer(beneficiary, priceREG);              // move REG token to recipient
        if (value > priceREG) {
            token.transfer(from, value - priceREG);         // return overpayment
        }
        availableREG--;
        minted[operator]++;
        candies.mint(operator);
        emit SaleInREG(operator,priceREG);
        return IERC1363Receiver.onTransferReceived.selector; // Return magic value
    }

// Unwrap

    function unwrap(uint _tokenId, address _to) public whenNotPaused {
        candies.unwrap(_tokenId, _to);
    }

// View

    function hasGift(address _to) public view returns (bool) {
        return (gifts[_to]);
    }

    function numSold() public view returns (uint) {
        return (230 - candies.remaining());
    }

    function getPriceETH() public view returns (uint) {
        return priceETH;
    }

    function getPriceREG() public view returns (uint) {
        return priceREG;
    }

    function getPrices() public view returns (uint, uint) {
        return (priceETH,priceREG);
    }

    function getAvailibility() public view returns (uint, uint) {
        return (availableETH, availableREG);
    }

    function balanceREG() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function balanceETH() public view returns (uint) {
        return address(this).balance;
    }

    function numMinted(address _addr) public view returns (uint) {
        return minted[_addr];
    }

// Admin

    function gift(address _wallet) public onlyRole(MINTER_ROLE) {
        gifts[_wallet] = true;
    }

    function withdrawReg() public onlyRole(MINTER_ROLE) {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

    function setCandiesAddress(address addr)public onlyRole(MINTER_ROLE) {
        candies = CandiesNFT(addr);
    }

    function setPriceInETH(uint _val)public onlyRole(MINTER_ROLE) {
        priceETH = _val;
    }

    function setPriceInREG(uint _val)public onlyRole(MINTER_ROLE) {
        priceREG = _val;
    }

    function setAvailableETH(uint _val)public onlyRole(MINTER_ROLE) {
        availableETH = _val;
    }

    function setAvailableREG(uint _val)public onlyRole(MINTER_ROLE) {
        availableREG = _val;
    }

    function setBeneficiary(address _addr)public onlyRole(MINTER_ROLE) {
        beneficiary = _addr;
    }

    function withdraw(address _addr)public onlyRole(MINTER_ROLE) {
        Address.sendValue(payable(_addr), address(this).balance);
    }

    function increaseMintedCount(address _addr, uint _count) public onlyRole(MINTER_ROLE) {
        minted[_addr] += _count;
    }

    function setMaxMints(uint _maxCount) public onlyRole(MINTER_ROLE) {
        maxMints = _maxCount;
    }

// Internal

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}