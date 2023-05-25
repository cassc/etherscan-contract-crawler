//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interface/IAccessPass.sol";


contract MojoHeads is ERC721, AccessControl, IERC2981, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private campaignCounter;

    Counters.Counter private artistTokensCounter;

    enum CampaignState {PENDING, READY, PRESALE, ONGOING, PAUSED, FINISH}

    struct Campaign {
        CampaignState state;
        address accessPassAddress;
        uint256 preSalePassId;
        uint256 vipSalePassId;
        uint256 maxPresaleTokens;
        uint256 maxOngoingTokens;
        uint256 totalSupply;
    }

    struct CampaignPrice {
        uint256 unitPricePresale;
        uint256 unitPriceVipSale;
        uint256 unitPriceStartPublicSale;
        uint256 unitPriceEndPublicSale;
        uint256 totalBlockUntilUnitPriceEnd;
        uint256 publicSaleStartBlock;
    }

    struct CampaignPriceInput {
        uint256 unitPricePresale;
        uint256 unitPriceVipSale;
        uint256 unitPriceStartPublicSale;
        uint256 unitPriceEndPublicSale;
        uint256 totalBlockUntilUnitPriceEnd;
    }

    mapping(uint256 => uint256[]) availableHashList;

    event CampaignRegisteredEvent(
        uint256 indexed campaignId
    );

    event CampaignUpdatedEvent(
        uint256 indexed campaignId
    );

    event CampaignStateChangedEvent(
        uint256 indexed campaignId,
        CampaignState state
    );

    event CampaignNewHashAddedEvent(
        uint256 indexed campaignId
    );

    event WithdrawEth(
        uint256 indexed amount,
        address indexed receiver
    );

    event WithdrawERC20(
        address indexed token,
        uint256 indexed amount,
        address indexed receiver
    );

    mapping(uint256 => Campaign) public campaignList;
    mapping(uint256 => CampaignPrice) public campaignPriceList;
    mapping(uint256 => bytes32) public tokenHashMapping;
    mapping(bytes32 => uint256) public hashTokenMapping;
    mapping(uint256 => uint256) public tokenToArtistMapping;
    mapping(uint256 => address) public tokenRoyaltyMapping;

    address public defaultRoyaltyAddress;
    uint256 public royaltyPercentage;
    uint256 public artistTokenReserve;
    uint256 public maxSupply;
    uint256 public totalSupply;
    bytes32 public constant CAMPAIGN_ADMIN_ROLE = keccak256("CAMPAIGN_ADMIN");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW");

    string private _baseURIextended = "https://artist.mojoheads.com/meta/";

    constructor(string memory name_, string memory symbol_, uint256 artistTokenReserve_, uint256 royaltyPercentage_, address defaultRoyaltyAddress_, uint256 maxSupply_) ERC721(name_, symbol_) {
        require(royaltyPercentage_ <= 10000, "royaltyPercentage_ must be lte 10000.");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CAMPAIGN_ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAW_ROLE, _msgSender());
        _setRoleAdmin(WITHDRAW_ROLE, DEFAULT_ADMIN_ROLE);
        artistTokenReserve = artistTokenReserve_;
        royaltyPercentage = royaltyPercentage_;
        defaultRoyaltyAddress = defaultRoyaltyAddress_;
        maxSupply = maxSupply_;
    }

    function register(address accessPassAddress,
        uint256 preSalePassId,
        uint256 vipSalePassId,
        CampaignPriceInput memory campaignPriceInput,
        uint256 maxPresaleTokens,
        uint256 maxOngoingTokens) public onlyRole(CAMPAIGN_ADMIN_ROLE) returns (uint256) {

        campaignCounter.increment();
        uint256 campaignId = campaignCounter.current();
        campaignList[campaignId].state = CampaignState.PENDING;
        campaignList[campaignId].accessPassAddress = accessPassAddress;
        campaignList[campaignId].preSalePassId = preSalePassId;
        campaignList[campaignId].vipSalePassId = vipSalePassId;

        campaignList[campaignId].maxPresaleTokens = maxPresaleTokens;
        campaignList[campaignId].maxOngoingTokens = maxOngoingTokens;

        campaignPriceList[campaignId].unitPricePresale = campaignPriceInput.unitPricePresale;
        campaignPriceList[campaignId].unitPriceVipSale = campaignPriceInput.unitPriceVipSale;
        campaignPriceList[campaignId].unitPriceStartPublicSale = campaignPriceInput.unitPriceStartPublicSale;
        campaignPriceList[campaignId].unitPriceEndPublicSale = campaignPriceInput.unitPriceEndPublicSale;
        campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd = campaignPriceInput.totalBlockUntilUnitPriceEnd;

        emit CampaignRegisteredEvent(
            campaignId
        );

        return campaignId;
    }

    function finishCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PAUSED || campaignList[campaignId].state == CampaignState.ONGOING, "Campaign should be started.");
        campaignList[campaignId].state = CampaignState.FINISH;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.FINISH
        );
    }

    function setCampaignReady(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PENDING, "Campaign should be pending.");
        campaignList[campaignId].state = CampaignState.READY;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.READY
        );
    }


    function startPresale(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.READY
        || campaignList[campaignId].state == CampaignState.ONGOING
            || campaignList[campaignId].state == CampaignState.PAUSED, "Campaign should be READY, PAUSED or ONGOING.");

        campaignList[campaignId].state = CampaignState.PRESALE;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.PRESALE
        );
    }

    function startCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.READY
        || campaignList[campaignId].state == CampaignState.PAUSED
            || campaignList[campaignId].state == CampaignState.PRESALE, "Campaign should be READY or PAUSED.");

        campaignList[campaignId].state = CampaignState.ONGOING;
        campaignPriceList[campaignId].publicSaleStartBlock = block.number;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.ONGOING
        );
    }


    function pauseCampaign(uint256 campaignId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.ONGOING
            || campaignList[campaignId].state == CampaignState.PRESALE, "Campaign should be ONGOING.");

        campaignList[campaignId].state = CampaignState.PAUSED;

        emit CampaignStateChangedEvent(
            campaignId,
            CampaignState.PAUSED
        );
    }

    function update(uint256 campaignId, address accessPassAddress,
        uint256 preSalePassId,
        uint256 vipSalePassId,
        CampaignPriceInput memory campaignPriceInput,
        uint256 maxPresaleTokens,
        uint256 maxOngoingTokens) public onlyRole(CAMPAIGN_ADMIN_ROLE) returns (uint256) {

        campaignList[campaignId].accessPassAddress = accessPassAddress;
        campaignList[campaignId].preSalePassId = preSalePassId;
        campaignList[campaignId].vipSalePassId = vipSalePassId;
        campaignList[campaignId].maxPresaleTokens = maxPresaleTokens;
        campaignList[campaignId].maxOngoingTokens = maxOngoingTokens;

        campaignPriceList[campaignId].unitPricePresale = campaignPriceInput.unitPricePresale;
        campaignPriceList[campaignId].unitPriceVipSale = campaignPriceInput.unitPriceVipSale;
        campaignPriceList[campaignId].unitPriceStartPublicSale = campaignPriceInput.unitPriceStartPublicSale;
        campaignPriceList[campaignId].unitPriceEndPublicSale = campaignPriceInput.unitPriceEndPublicSale;
        campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd = campaignPriceInput.totalBlockUntilUnitPriceEnd;

        emit CampaignUpdatedEvent(
            campaignId
        );

        return campaignId;
    }

    function mapTokenToArtistBatch(uint256 campaignId, uint256 [] calldata tokenIdList, uint256 [] calldata artistTokenList) public onlyRole (CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PENDING, "Cannot add hash to Started campaign");
        require(tokenIdList.length == artistTokenList.length, "tokenIdList and artistTokenList must be in same length");
        campaignList[campaignId].totalSupply += tokenIdList.length;
        for (uint i = 0; i < tokenIdList.length; i++) {
            tokenToArtistMapping[tokenIdList[i]] = artistTokenList[i];
            availableHashList[campaignId].push(tokenIdList[i]);
        }
    }

    function mint(uint256 campaignId, uint256 amount, address receiver) public payable {
        if (campaignList[campaignId].state == CampaignState.PRESALE) {
            require(amount <= campaignList[campaignId].maxPresaleTokens, "Cannot mint more than allowed in presale.");
        } else {
            require(amount <= campaignList[campaignId].maxOngoingTokens, "Cannot mint more than allowed.");
        }

        uint256 totalCost = 0;

        for (uint i; i < amount; i++) {
            uint256 price = _checkCampaignStateForMinting(campaignId);
            totalCost = totalCost + price;
            _randomMint(campaignId, receiver);
        }

        require(msg.value >= totalCost, "Insufficient funds.");

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function getOngoingPrice(uint256 campaignId) public view returns (uint256) {
        require(campaignList[campaignId].state == CampaignState.ONGOING, "Campaign is not started yet.");
        uint256 blockPasted = block.number - campaignPriceList[campaignId].publicSaleStartBlock;

        if (blockPasted > campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd) {
            blockPasted = campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd;
        }
        if (campaignPriceList[campaignId].unitPriceEndPublicSale > campaignPriceList[campaignId].unitPriceStartPublicSale) {
            return campaignPriceList[campaignId].unitPriceStartPublicSale + (campaignPriceList[campaignId].unitPriceEndPublicSale - campaignPriceList[campaignId].unitPriceStartPublicSale) / campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd * blockPasted;
        } else {
            return campaignPriceList[campaignId].unitPriceStartPublicSale - (campaignPriceList[campaignId].unitPriceStartPublicSale - campaignPriceList[campaignId].unitPriceEndPublicSale) / campaignPriceList[campaignId].totalBlockUntilUnitPriceEnd * blockPasted;
        }
    }
    
    function _checkCampaignStateForMinting(uint256 campaignId) internal returns (uint256) {
        if (campaignList[campaignId].state == CampaignState.PRESALE) {
            IAccessPass accessPass = IAccessPass(campaignList[campaignId].accessPassAddress);
            if (accessPass.balanceOf(msg.sender, campaignList[campaignId].vipSalePassId) > 0) {
                accessPass.burn(msg.sender, campaignList[campaignId].vipSalePassId, 1);
                return campaignPriceList[campaignId].unitPriceVipSale;
            } else if (accessPass.balanceOf(msg.sender, campaignList[campaignId].preSalePassId) > 0) {
                accessPass.burn(msg.sender, campaignList[campaignId].preSalePassId, 1);
                return campaignPriceList[campaignId].unitPricePresale;
            } else {
                revert("No Access token.");
            }

        } else {
            return getOngoingPrice(campaignId);
        }
    }

    function adminMint(uint256 campaignId, uint256 amount, address receiver) public payable onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.READY, "Must be in ready state.");
        require(amount <= campaignList[campaignId].maxPresaleTokens, "Cannot mint more than allowed in presale.");

        uint256 totalCost = 0;

        for (uint i; i < amount; i++) {
            uint256 price = _checkCampaignStateForAdminMinting(campaignId);
            totalCost = totalCost + price;
            _randomMint(campaignId, receiver);
        }

        require(msg.value >= totalCost, "Insufficient funds.");

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function _checkCampaignStateForAdminMinting(uint256 campaignId) internal returns (uint256) {
        IAccessPass accessPass = IAccessPass(campaignList[campaignId].accessPassAddress);
        if (accessPass.balanceOf(msg.sender, campaignList[campaignId].vipSalePassId) > 0) {
            accessPass.burn(msg.sender, campaignList[campaignId].vipSalePassId, 1);
            return campaignPriceList[campaignId].unitPriceVipSale;
        } else if (accessPass.balanceOf(msg.sender, campaignList[campaignId].preSalePassId) > 0) {
            accessPass.burn(msg.sender, campaignList[campaignId].preSalePassId, 1);
            return campaignPriceList[campaignId].unitPricePresale;
        } else {
            revert("No Access token.");
        }
    }

    function preMintWithTokenId(uint256 campaignId, address receiver, uint256 tokenId, uint256 artistTokenId) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state == CampaignState.PENDING, "Campaign is not PENDING.");
        tokenToArtistMapping[tokenId] = artistTokenId;
        _mintToken(tokenId, receiver);
    }

    function preMint(uint256 campaignId, address receiver) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state != CampaignState.PENDING, "Campaign is not ready yet.");
        _randomMint(campaignId, receiver);
    }

    function preMintBatch(uint256 campaignId, address[] memory receiverList) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(campaignList[campaignId].state != CampaignState.PENDING, "Campaign is not ready yet.");
        require(receiverList.length <= availableHashList[campaignId].length, "Campaign does not have enough hashes.");
        for (uint i = 0; i < receiverList.length; i++) {
            _randomMint(campaignId, receiverList[i]);
        }
    }

    function _randomMint(uint256 campaignId, address receiver) private {
        require(availableHashList[campaignId].length > 0, "All NFTs are sold.");
        uint256 random;
        if (availableHashList[campaignId].length > 1) {
            random = uint256(keccak256(abi.encodePacked(availableHashList[campaignId].length, blockhash(block.number), block.difficulty))) % availableHashList[campaignId].length;
        } else {
            random = 0;
        }

        uint256 tokenId = availableHashList[campaignId][random];
        availableHashList[campaignId][random] = availableHashList[campaignId][availableHashList[campaignId].length - 1];
        availableHashList[campaignId].pop();

        _mintToken(tokenId, receiver);
    }

    function _mintToken(uint256 tokenId, address receiver) private {
        totalSupply += 1;
        require(totalSupply <= maxSupply, "Cannot mint more than maxSupply.");
        _mint(receiver, tokenId);
    }

    function mintArtistToken(address to) public onlyRole(CAMPAIGN_ADMIN_ROLE) {
        artistTokensCounter.increment();
        uint256 tokenId = artistTokensCounter.current();
        require(tokenId <= artistTokenReserve, "Artist token id reserves finished.");
        _mint(to, tokenId);
        tokenRoyaltyMapping[tokenId] = defaultRoyaltyAddress;
    }

    function withdrawERC20(address token, uint256 amount, address payable receiver) external onlyRole(WITHDRAW_ROLE) {
        IERC20(token).transfer(receiver, amount);
        emit WithdrawERC20(token, amount, receiver);
    }

    function withdrawEth(uint256 amount, address payable receiver) external onlyRole(WITHDRAW_ROLE) {
        receiver.transfer(amount);
        emit WithdrawEth(amount, receiver);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
        || interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC2981).interfaceId
        || interfaceId == type(ERC721URIStorage).interfaceId;
    }

    function campaignCount() public view returns (uint256) {
        return campaignCounter.current();
    }

    function getCampaign(uint256 id) public view returns (Campaign memory) {
        return campaignList[id];
    }

    function getCampaignPrice(uint256 id) public view returns (CampaignPrice memory) {
        return campaignPriceList[id];
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        uint256 artistTokenId = tokenToArtistMapping[tokenId];
        address royaltyAddress = tokenRoyaltyMapping[artistTokenId];
        uint256 royaltyAmount = salePrice * royaltyPercentage / 10000;
        if (royaltyAddress == address(0)) {
            return (defaultRoyaltyAddress, royaltyAmount);
        }

        return (royaltyAddress, royaltyAmount);
    }

    function setTokenRoyaltyAddress(uint256 tokenId, address royaltyAddress) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        require(_exists(tokenId), "Token must be existing to set royalty info.");
        tokenRoyaltyMapping[tokenId] = royaltyAddress;
    }

    function getCampaignHash(uint256 campaignId, uint256 hashIndex) external view returns (bytes32) {
        return tokenHashMapping[availableHashList[campaignId][hashIndex]];
    }

    function getCampaignAvailableHashCount(uint256 campaignId) external view returns (uint256) {
        return availableHashList[campaignId].length;
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        royaltyPercentage = _royaltyPercentage;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(CAMPAIGN_ADMIN_ROLE) {
        _baseURIextended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"URI query for nonexistent token");
        return string(abi.encodePacked(_baseURIextended, Strings.toString(tokenId)));
    }
}