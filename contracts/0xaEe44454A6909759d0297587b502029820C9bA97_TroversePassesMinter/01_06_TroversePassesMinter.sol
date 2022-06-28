// contracs/TroversePassesMinter.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IMultiToken is IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function totalSupply(uint256 id) external returns (uint256);
}

interface IYieldToken is IERC20 {
    function burn(address _from, uint256 _amount) external;
}


contract TroversePassesMinter is Ownable {
    mapping(uint256 => NFT) public NFTInfo;

    struct NFT {
        bool mintsAllowed;
        bool mintsByTokenAllowed;
        bool whitelistsAllowed;
        bool whitelistsByTokenAllowed;
        uint128 mintPrice;
        uint128 whitelistPrice;
        uint256 maxSupply;
    }

    mapping(uint256 => mapping(address => uint256)) public whitelist;

    IMultiToken public multiToken;
    IYieldToken public yieldToken;
    bool public burnYieldToken;

    event MultiTokenChanged(address _multiToken);
    event YieldTokenChanged(address _yieldToken, bool _burnYieldToken);


    constructor() { }
    
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMultiToken(address _multiToken) external onlyOwner {
        require(_multiToken != address(0), "Bad MultiToken address");
        multiToken = IMultiToken(_multiToken);

        emit MultiTokenChanged(_multiToken);
    }

    function setYieldToken(address _yieldToken, bool _burnYieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Bad YieldToken address");

        yieldToken = IYieldToken(_yieldToken);
        burnYieldToken = _burnYieldToken;

        emit YieldTokenChanged(_yieldToken, _burnYieldToken);
    }

    function getMintPrice(uint256 id) external view returns (uint128) {
        return NFTInfo[id].mintPrice;
    }

    function getWhitelistPrice(uint256 id) external view returns (uint128) {
        return NFTInfo[id].whitelistPrice;
    }

    function setNFTInfos(
        uint256[] memory ids,
        bool[] memory mintsAllowed,
        bool[] memory mintsByTokenAllowed,
        bool[] memory whitelistsAllowed,
        bool[] memory whitelistsByTokenAllowed,
        uint128[] memory mintPrices,
        uint128[] memory whitelistPrices,
        uint256[] memory maxSupply
    ) external onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            NFTInfo[ids[i]] = NFT(mintsAllowed[i], mintsByTokenAllowed[i], whitelistsAllowed[i], whitelistsByTokenAllowed[i], mintPrices[i], whitelistPrices[i], maxSupply[i]);
        }
    }

    function setNFTInfo(
        uint256 id,
        bool mintsAllowed,
        bool mintsByTokenAllowed,
        bool whitelistsAllowed,
        bool whitelistsByTokenAllowed,
        uint128 mintPrice,
        uint128 whitelistPrice,
        uint256 maxSupply
    ) external onlyOwner {
        NFTInfo[id] = NFT(mintsAllowed, mintsByTokenAllowed, whitelistsAllowed, whitelistsByTokenAllowed, mintPrice, whitelistPrice, maxSupply);
    }

    function updateWhitelist(uint256 id, address[] calldata addresses, uint256 limit) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            whitelist[id][addresses[i]] = limit;
        }
    }

    function Airdrop(uint256 id, uint256 amount, address[] calldata accounts) external onlyOwner {
        NFT storage nft = NFTInfo[id];
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + (amount * accounts.length) <= nft.maxSupply, "Token max supply reached");
        
        for (uint256 i; i < accounts.length; i++) {
            multiToken.mint(accounts[i], id, amount, bytes(""));
        }
    }

    function MintForByToken(uint256 id, uint256 amount, address account, uint256 totalCost) external onlyOwner {
        NFT storage nft = NFTInfo[id];
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + amount <= nft.maxSupply, "Token max supply reached");

        if (totalCost > 0) {
            if (burnYieldToken) {
                yieldToken.burn(account, totalCost);
            } else {
                yieldToken.transferFrom(account, address(this), totalCost);
            }
        }
        
        multiToken.mint(account, id, amount, bytes(""));
    }

    function Mint(uint256 id, uint256 amount) external payable callerIsUser {
        NFT storage nft = NFTInfo[id];
        require(nft.mintsAllowed && nft.mintPrice > 0, "Mints are not allowed yet");
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + amount <= nft.maxSupply, "Token max supply reached");

        uint256 totalPrice = amount * nft.mintPrice;
        refundIfOver(totalPrice);

        multiToken.mint(_msgSender(), id, amount, bytes(""));
    }

    function MintByToken(uint256 id, uint256 amount) external callerIsUser {
        NFT storage nft = NFTInfo[id];
        require(nft.mintsByTokenAllowed && nft.mintPrice > 0, "Mints are not allowed yet");
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + amount <= nft.maxSupply, "Token max supply reached");

        uint256 totalPrice = amount * nft.mintPrice;

        if (burnYieldToken) {
            yieldToken.burn(_msgSender(), totalPrice);
        } else {
            yieldToken.transferFrom(_msgSender(), address(this), totalPrice);
        }

        multiToken.mint(_msgSender(), id, amount, bytes(""));
    }

    function Claim(uint256 id, uint256 amount) external payable callerIsUser {
        NFT storage nft = NFTInfo[id];
        require(nft.whitelistsAllowed, "Whitelists are not allowed yet");
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + amount <= nft.maxSupply, "Token max supply reached");
        require(whitelist[id][_msgSender()] >= amount, "Can't claim this much");

        if (nft.whitelistPrice > 0) {
            uint256 totalPrice = amount * nft.whitelistPrice;
            refundIfOver(totalPrice);
        }

        multiToken.mint(_msgSender(), id, amount, bytes(""));
        whitelist[id][_msgSender()] -= amount;
    }

    function ClaimByToken(uint256 id, uint256 amount) external callerIsUser {
        NFT storage nft = NFTInfo[id];
        require(nft.whitelistsByTokenAllowed, "Whitelists are not allowed yet");
        require(nft.maxSupply > 0 , "Token doesn't exist");
        require(multiToken.totalSupply(id) + amount <= nft.maxSupply, "Token max supply reached");
        require(whitelist[id][_msgSender()] >= amount, "Can't claim this much");

        if (nft.whitelistPrice > 0) {
            uint256 totalPrice = amount * nft.whitelistPrice;
            
            if (burnYieldToken) {
                yieldToken.burn(_msgSender(), totalPrice);
            } else {
                yieldToken.transferFrom(_msgSender(), address(this), totalPrice);
            }
        }

        multiToken.mint(_msgSender(), id, amount, bytes(""));
        whitelist[id][_msgSender()] -= amount;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Insufficient funds");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawAll(address to) external onlyOwner {
        require(payable(to).send(address(this).balance), "Transfer failed");
    }

    function withdrawToken(address tokenContract, address to, uint256 amount) external onlyOwner {
        IERC20(tokenContract).transfer(to, amount);
    }
}