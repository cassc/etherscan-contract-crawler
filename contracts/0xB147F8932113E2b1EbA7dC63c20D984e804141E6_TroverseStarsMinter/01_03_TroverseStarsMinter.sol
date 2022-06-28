// contracs/TroverseStarsMinter.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IYieldToken {
    function burn(address _from, uint256 _amount) external;
}

interface INFTContract {
    function Mint(address to, uint256 quantity) external payable;
    function totalSupply() external view returns (uint256);
}


contract TroverseStarsMinter is Ownable {

    INFTContract public NFTContract;

    uint256 public constant TOTAL_NFTS = 750;
    uint256 public mintPrice;

    mapping(address => uint256) public whitelist;
    bool public isClaimActive;

    IYieldToken public yieldToken;
    
    event YieldTokenChanged(address _yieldToken);
    event PriceChanged(uint256 _price);
    event ClaimStateChanged(bool _isActive);
    event NFTContractChanged(address _NFTContract);


    constructor() { }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setYieldToken(address _yieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Bad YieldToken address");
        yieldToken = IYieldToken(_yieldToken);
    
        emit YieldTokenChanged(_yieldToken);
    }

    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;

        emit PriceChanged(_price);
    }

    function updateWhitelist(address[] calldata addresses, uint256 limit) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = limit;
        }
    }

    function setClaimState(bool _isActive) external onlyOwner {
        isClaimActive = _isActive;

        emit ClaimStateChanged(_isActive);
    }

    function Claim(uint256 quantity) external callerIsUser {
        require(isClaimActive, "Claiming is not active");
        require(whitelist[msg.sender] > 0, "Not eligible for whitelist mint");
        require(whitelist[msg.sender] >= quantity, "Can not mint this many");

        NFTContract.Mint(msg.sender, quantity);
        whitelist[msg.sender] -= quantity;
    }

    function Mint(uint256 quantity) external callerIsUser {
        require(mintPrice > 0, "Minting is not active");

        yieldToken.burn(msg.sender, quantity * mintPrice);
        NFTContract.Mint(msg.sender, quantity);
    }

    function Airdrop(address[] calldata accounts, uint256 quantity) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            NFTContract.Mint(accounts[i], quantity);
        }
    }

    function setNFTContract(address _NFTContract) external onlyOwner {
        require(_NFTContract != address(0), "Bad NFTContract address");
        NFTContract = INFTContract(_NFTContract);

        emit NFTContractChanged(_NFTContract);
    }

    function totalSupply() public view returns (uint256) {
        return NFTContract.totalSupply();
    }

}