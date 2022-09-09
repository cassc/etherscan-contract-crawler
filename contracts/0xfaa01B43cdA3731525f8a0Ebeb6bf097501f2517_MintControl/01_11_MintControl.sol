//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAvatar.sol";

contract MintControl is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct MintControlConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 amount;
        uint256 userCanMint;
    }

    mapping(uint256 => mapping(address => uint256)) public userHaveMint;
    mapping(uint256 => uint256) public haveMinted;

    IAvatar public avatar;

    MintControlConfig[3] public mintControl;

    uint256 public platformHoldForGenesis;
    bool public platformHaveClaimForGenesis;
    uint256 public platformHoldForPublic;
    bool public platformHaveClaimForPublic;

    uint256 public genesisTokenIdCounter;
    uint256 public publicTokenIdCounter;

    address public whitelistAdmin;
    
    bool public whitelistOpen;
    bool public mintOpen;
    uint256 public mvtAmount;
    uint256 public whitelistPrice;
    uint256 public pubPrice;
    address public mToken;

    modifier checkMintPeriod(uint256 mp) {
        require(mp >= 0 && mp <= 2, "Mint period not allowed");
        _;
    }

    function initialize(uint256 _genesisHold, uint256 _publicHold) public initializer {
        __Ownable_init();
        platformHoldForGenesis = _genesisHold;
        platformHaveClaimForGenesis = false;
        platformHoldForPublic = _publicHold;
        platformHaveClaimForPublic = false;
        genesisTokenIdCounter = 0;
        publicTokenIdCounter = 1000;
    }

    function setAvatarAddress(IAvatar addr) external onlyOwner {
        avatar = addr;
    }

    function setMintOpen() external onlyOwner {
        mintOpen = true;
    }

    function setMToken(address addr) external onlyOwner {
        mToken = addr;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        pubPrice = price;
    }

    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    function openWhiteList(address addr,uint256 price, uint256 _mvtAmount) external onlyOwner {
        whitelistAdmin = addr;
        whitelistPrice = price;
        mvtAmount = _mvtAmount;
        whitelistOpen = true;
    }

    function closeWhiteList() external onlyOwner {
        whitelistOpen = false;
    }

    function setWhitelistAdmin(address addr) external onlyOwner {
        whitelistAdmin = addr;
    }

    function isAuthorized(address account, uint256 mintPeriod, bytes calldata signature) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(account, mintPeriod, block.chainid, address(this)));
        return whitelistAdmin == hash.recover(signature);
    }

    function setMintControl(uint256 mintPeriod, MintControlConfig calldata m) checkMintPeriod(mintPeriod) external onlyOwner {
        mintControl[mintPeriod] = m;
    }

    function mintWhitelist(uint256 amount, bytes calldata signature)  external payable nonReentrant {
        require((haveMinted[1]+haveMinted[2])<(mintControl[2].amount+mintControl[1].amount), "No more minting");
        if (signature.length == 0) {
            haveMinted[1] += amount;
            require(msg.value == pubPrice * amount, "Public Mint: value not enough");
        }else{
            require(whitelistOpen, "White list is not open");
            require(msg.value == whitelistPrice * amount, "Whitelist Mint: value not enough");
            require(isAuthorized(msg.sender, 2, signature), "Mint: not in whitelist");
            IERC20Upgradeable(mToken).safeTransfer(msg.sender,amount* mvtAmount);
            haveMinted[2] += amount;
        }
        avatar.batchMint(msg.sender, publicTokenIdCounter, amount);
        publicTokenIdCounter += amount;
    }

    function mint(uint256 mp, uint256 amount, bytes calldata signature) checkMintPeriod(mp) external payable nonReentrant {
        require(mintOpen, "Mint is not open");
        MintControlConfig memory m = mintControl[mp];
        require(block.timestamp >= m.startTime && m.startTime > 0, "Mint: mint is over");

        require(msg.value == m.price * amount, "Mint: value not enough");

        userHaveMint[mp][msg.sender] += amount;
        require(userHaveMint[mp][msg.sender] <= m.userCanMint, "Mint: Limit is used up");

        haveMinted[mp] += amount;
        if (mp == 1 && block.timestamp > mintControl[2].endTime) {
            require(haveMinted[mp] <= (mintControl[2].amount - haveMinted[2] + m.amount), "Mint: amount > limit");
        } else {
            require(haveMinted[mp] <= m.amount, "Mint: amount > limit");
        }

        if (mp == 2) {
            require(block.timestamp < m.endTime, "Mint: whitelist has over");
            require(isAuthorized(msg.sender, mp, signature), "Mint: not in whitelist");
        }

        if (mp == 0) {
            avatar.batchMint(msg.sender, genesisTokenIdCounter, amount);
            genesisTokenIdCounter += amount;
        } else {
            avatar.batchMint(msg.sender, publicTokenIdCounter, amount);
            publicTokenIdCounter += amount;
        }
    }

    function platformMintForGenesis(address to) external onlyOwner {
        require(!platformHaveClaimForGenesis, "platformMint: have mint");

        platformHaveClaimForGenesis = true;
        avatar.batchMint(to, genesisTokenIdCounter, platformHoldForGenesis);
        genesisTokenIdCounter += platformHoldForGenesis;
    }

    function platformMintForPublic(address to) external onlyOwner {
        require(!platformHaveClaimForPublic, "platformMint: have mint");

        platformHaveClaimForPublic = true;
        avatar.batchMint(to, publicTokenIdCounter, platformHoldForPublic);
        publicTokenIdCounter += platformHoldForPublic;
    }

    function withdraw(address addr1, address addr2, address addr3) external onlyOwner {
        uint256 b = address(this).balance;

        uint256 v1 = b * 5 / 100;
        uint256 v2 = b * 10 / 100;
        uint256 v3 = b - v1 - v2;

        payable(addr1).transfer(v1);
        payable(addr2).transfer(v2);
        payable(addr3).transfer(v3);
    }

    function transferBack(
        IERC20Upgradeable erc20Token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (address(erc20Token) == address(0)) {
            _safeTransferETH(to, amount);
        } else {
            erc20Token.safeTransfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 2300, value: value}("");
        require(success, "transfer eth failed");
    }
}