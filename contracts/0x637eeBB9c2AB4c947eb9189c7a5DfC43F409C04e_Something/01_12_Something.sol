//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Something is ERC721A, Ownable, ReentrancyGuard {
    struct PeriodInfo {
        uint256 limitPerWallet;
        uint256 supply;
        uint256 curSupply;
        uint256 price;
        bool    sign;
    }

    struct Period {
        PeriodInfo info;
        mapping(address => uint256) mintList;
    }

    uint256 public MAX_SUPPLY = 10000;

    Period[] private periods;

    string public baseURI;

    // 0 -- None period
    // 1 -- Whitelist mint period
    // 2 ~ 10 -- Public sale mint period
    uint256 public periodState = 0;

    constructor(string memory uri) ERC721A("Something", "STH") {
        baseURI = uri;
        // whitelist period
        _addPeriod(2, 1000, 1e16, true);
        // public sale period
        for (int i = 0; i < 9; i++) {
            _addPeriod(1000, 1000, 2e16, false);
        }
    }

    function _addPeriod(uint256 limitPerWallet, uint256 supply, uint256 price, bool sign) internal {
        uint256 idx = periods.length;
        periods.push();

        periods[idx].info.limitPerWallet = limitPerWallet;
        periods[idx].info.supply = supply;
        periods[idx].info.curSupply = 0;
        periods[idx].info.price = price;
        periods[idx].info.sign = sign;
    }

    function _getPeriod(uint256 state) internal view returns (Period storage) {
        require(state > 0, "period state error");
        return periods[state - 1];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function periodInfo(uint256 state) external view returns (PeriodInfo memory) {
        return _getPeriod(state).info;
    }

    function periodMints(uint256 state, address owner) external view returns (uint256) {
        Period storage period = _getPeriod(state);
        return period.mintList[owner];
    }

    function remainMints(address owner) external view returns (uint256) {
        Period storage period = _getPeriod(periodState);

        uint256 walletRemain = period.info.limitPerWallet - period.mintList[owner];
        uint256 periodRemain = period.info.supply - period.info.curSupply;
        uint256 totalRemain = MAX_SUPPLY - totalSupply();

        uint256 remain = walletRemain < periodRemain ? walletRemain : periodRemain;

        return remain < totalRemain ? remain : totalRemain;
    }

    function mint(uint256 quantity, bytes calldata sign) external payable nonReentrant {
        require(msg.sender == tx.origin, "not allowed");

        Period storage period = _getPeriod(periodState);
        require((totalSupply() + quantity <= MAX_SUPPLY), "total supply limit");

        require((period.info.curSupply + quantity <= period.info.supply), "period supply limit");
        require((period.mintList[msg.sender] + quantity <= period.info.limitPerWallet) && (quantity > 0), "quantity limit");

        period.mintList[msg.sender] += quantity;

        period.info.curSupply += quantity;

        uint256 price = period.info.price * quantity;

        if (period.info.sign) {
            bytes32 hashBytes =  keccak256(abi.encodePacked(name(), periodState, msg.sender));
            bytes32 message = ECDSA.toEthSignedMessageHash(hashBytes);
            address signer = ECDSA.recover(message, sign);
            require(signer == owner(), "illegal signature");
        }

        require(msg.value >= price, "need more ETH");

        _safeMint(msg.sender, quantity);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

 	function devMint(address to, uint256 quantity) public onlyOwner nonReentrant {
	    require(totalSupply() + quantity <= MAX_SUPPLY, "supply limit");
        _safeMint(to, quantity);
    }

    function setURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setPeriodState(uint256 newPeriodState) external onlyOwner {
        periodState = newPeriodState;
    }

    function setPeriodLimitPerWallet(uint256 state, uint256 newLimitPerWallet) external onlyOwner {
        _getPeriod(state).info.limitPerWallet = newLimitPerWallet;
    }
    
    function setPeriodSupply(uint256 state, uint256 newSupply) external onlyOwner {
        _getPeriod(state).info.supply = newSupply;
    }   

    function setPeriodPrice(uint256 state, uint256 newPrice) external onlyOwner {
        _getPeriod(state).info.price = newPrice;
    }  

    function setPeriodSign(uint256 state, bool newSign) external onlyOwner {
        _getPeriod(state).info.sign = newSign;
    }  

    function setPeriod(uint256 state, uint256 newLimitPerWallet, uint256 newSupply, uint256 newPrice, bool newSign) external onlyOwner {
        Period storage period = _getPeriod(state);
        period.info.limitPerWallet = newLimitPerWallet;
        period.info.supply = newSupply;
        period.info.price = newPrice;
        period.info.sign = newSign;
    }

    function addPeriod(uint256 limitPerWallet, uint256 supply, uint256 price, bool sign) external onlyOwner {
        _addPeriod(limitPerWallet, supply, price, sign);
    }
}