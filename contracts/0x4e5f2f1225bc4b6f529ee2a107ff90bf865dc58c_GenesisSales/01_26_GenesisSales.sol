//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Art2ActGenesisNFT.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title The genesis sales contract
 * @notice Allows for users to buy genesis NFTs
 */
contract GenesisSales is AccessControl, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address private art2actTreasury;
    address private art2actPayments;
    address private art2actGenesisNFT;
    uint256 public unitPrice;
    uint256 public basis_points;
    uint256 public platform_fee;
    bool public allowlist1Active;
    bool public allowlist2Active;
    bool public publicActive;
    uint256 public maxNFTsToSell;
    uint256 public salesCounter;
    string private urlBase;
    string private initialURI;
    mapping(address => bool) public allowlist1;
    mapping(address => bool) public allowlist2;
    mapping(address => uint16) public maxPurchase;
    mapping(address => uint16) public currentPurchase;

    event GenesisNFTPurchased(
        address indexed buyer,
        uint256 salesCounter,
        string uri
    );

    event GenesisNFTRevealed(uint256 nftId, string uri);
    event GenesisAllowlist1(address user, uint16 maxPurchase);
    event GenesisAllowlist2(address user, uint16 maxPurchase);

    constructor(
        address treasury,
        address payments,
        address genesisNFT,
        uint256 price,
        string memory initialUri,
        uint256 maxNFTs,
        uint16 maxPurchasesPerUser,
        address[] memory allowlist1Users,
        address[] memory allowlist2Users
    ) {
        require(treasury != address(0), "Invalid Address");
        art2actTreasury = treasury;
        art2actPayments = payments;
        art2actGenesisNFT = genesisNFT;
        unitPrice = price;
        maxNFTsToSell = maxNFTs;
        salesCounter = 0;
        basis_points = 10000;
        platform_fee = 6000; //60%
        urlBase = "https://gateway.pinata.cloud/ipfs/";
        initialURI = initialUri;
        allowlist1Active = false;
        allowlist2Active = false;
        publicActive = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        for (uint8 i = 0; i < allowlist1Users.length; i++) {
            setAllowlist1(allowlist1Users[i], maxPurchasesPerUser);
        }

        for (uint8 i = 0; i < allowlist2Users.length; i++) {
            setAllowlist2(allowlist2Users[i], maxPurchasesPerUser);
        }
    }

    function setUrlBase(string memory url) public onlyRole(DEFAULT_ADMIN_ROLE) {
        urlBase = url;
    }

    function setInitialURI(string memory url)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        initialURI = url;
    }

    function setPayments(address treasury, address payment)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        art2actTreasury = treasury;
        art2actPayments = payment;
    }

    function setFees(uint256 _basis_points, uint256 _platform_fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        basis_points = _basis_points;
        platform_fee = _platform_fee;
    }

    function setMaxToSell(uint256 max) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxNFTsToSell = max;
    }

    function setGenesisNFTPrice(uint256 price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unitPrice = price;
    }

    function setAllowlist1(address user, uint16 maxim)
        public
        onlyRole(OPERATOR_ROLE)
    {
        maxPurchase[user] = maxim;
        if (!allowlist1[user]) {
            allowlist1[user] = true;
            currentPurchase[user] = 0;
        }
        emit GenesisAllowlist1(user, maxim);
    }

    function setAllowlist1Batch(address [] memory users, uint16 [] memory maxims)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(users.length == maxims.length && users.length > 0, "users and maxims length mismatch or empty");
        for (uint8 i = 0; i < users.length; i++) {
            setAllowlist1(users[i], maxims[i]);
        }
    }

    function setAllowlist2(address user, uint16 maxim)
        public
        onlyRole(OPERATOR_ROLE)
    {
        maxPurchase[user] = maxim;
        if (!allowlist2[user]) {
            allowlist2[user] = true;
            currentPurchase[user] = 0;
        }
        emit GenesisAllowlist2(user, maxim);
    }

    function setAllowlist2Batch(address [] memory users, uint16 [] memory maxims)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(users.length == maxims.length && users.length > 0, "users and maxims length mismatch or empty");
        for (uint8 i = 0; i < users.length; i++) {
            setAllowlist2(users[i], maxims[i]);
        }
    }

    function enableAllowlist1(bool active) public onlyRole(OPERATOR_ROLE) { 
        allowlist1Active = active;
    }

    function enableAllowlist2(bool active) public onlyRole(OPERATOR_ROLE) {
        allowlist2Active = active;
    }

    function enablePublic(bool active) public onlyRole(OPERATOR_ROLE) {
        publicActive = active;
    }


    function buyGenesisNFT(uint256 items) public payable nonReentrant {
        for (uint256 i = 0; i < items; i++) {
            require(
                unitPrice > 0 && salesCounter < maxNFTsToSell,
                "Genesis NFT not available"
            );
            require(
                allowlist1Active && allowlist1[msg.sender] || allowlist2Active && allowlist2[msg.sender] || publicActive,
                "Sales disabled or user is not in allowlists"
            );
            require(
                currentPurchase[msg.sender] < maxPurchase[msg.sender] || publicActive,
                "Maximum purchases reached"
            );
            if (!publicActive) {
                currentPurchase[msg.sender]++;
            }
            Art2ActGenesisNFT(art2actGenesisNFT).safeMint(
                msg.sender,
                initialURI
            );
            emit GenesisNFTPurchased(msg.sender, salesCounter++, initialURI);
        }
        uint256 totalPrice = SafeMath.mul(unitPrice, items);
        uint256 fees = Math.mulDiv(totalPrice, platform_fee, basis_points); //(unitPrice*items * platform_fee) / basis_points;
        uint256 amount = SafeMath.sub(totalPrice, fees); //unitPrice*items - fees
        require(
            msg.value == totalPrice,
            "Amount is not set correctly"
        );
        (bool success1, ) = art2actTreasury.call{value: fees}("");
        require(success1, "Failed to send Amount (ETH) to Treasury");
        (bool success2, ) = art2actPayments.call{value: amount}("");
        require(success2, "Failed to send Amount (ETH) to this contract");
    }

    function revealGenesisNFT(uint256 tokenId, string memory cid)
        public
        onlyRole(OPERATOR_ROLE)
    {
        string memory uri = string(abi.encodePacked(urlBase, cid));
        Art2ActGenesisNFT(art2actGenesisNFT).setTokenURI(tokenId, uri);
        emit GenesisNFTRevealed(tokenId, cid);
    }

    function revealGenesisNFTBatch(
        uint256[] memory tokensId,
        string[] memory cids
    ) public onlyRole(OPERATOR_ROLE) {
        require(tokensId.length == cids.length && tokensId.length > 0, "Tokens and CIDs length mismatch or empty");
        for (uint256 i = 0; i < tokensId.length; i++) {
            revealGenesisNFT(tokensId[i], cids[i]);
        }
    }
}