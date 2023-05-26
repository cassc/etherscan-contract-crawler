// SPDX-License-Identifier: MIT
// author: @props
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./base64.sol";
import "./ICollectible.sol";

import "hardhat/console.sol";

contract Collectible is
    ICollectible,
    AccessControl,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private generalCounter;

    mapping(uint256 => RedemptionWindow) public redemptionWindows;

    address public receivingWallet;

    struct Token {
        string name;
        string description;
        string image;
        string animation_url;
        string url;
    }

    mapping(uint256 => Token) public tokens;
    mapping(uint256 => uint256) public tokenTypes;

    struct FusionConfig {
        uint256 tokenIDRequired;
        uint256 numTokensRequired;
    }

    mapping(uint256 => FusionConfig) public fusionConfigs;

    struct MembershipTier {
        string name;
    }

    mapping(uint256 => MembershipTier) public membershipTiers;

    struct RedemptionWindow {
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 maxRedeemPerTxn;
    }

    struct SaleConfig {
        bool isSaleOpen;
        bool isPresaleOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 maxMintsPerTxn;
        uint256 mintPrice;
        uint256 maxSupply;
        bool requireSignature;
        address signerAddress;
        uint256 tokenType;
    }

    SaleConfig public saleConfiguration;

    string public _contractURI;

    bool public isFusionOpen;

    MintPassFactory public mintPassFactory;

    event Fused(address indexed account, string tokens);
    event Redeemed(address indexed account, string tokens);
    event Minted(address indexed account, string tokens);

    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");

    /**
     * @notice Constructor to create Collectible
     *
     * @param _symbol the token symbol
     * @param _mpIndexes the mintpass indexes to accommodate
     * @param _redemptionWindowsOpen the mintpass redemption window open unix timestamp by index
     * @param _redemptionWindowsClose the mintpass redemption window close unix timestamp by index
     * @param _maxRedeemPerTxn the max mint per redemption by index
     * @param _contractMetaDataURI the respective contract meta data URI
     * @param _mintPassToken contract address of MintPass token to be burned
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256[] memory _mpIndexes,
        uint256[] memory _redemptionWindowsOpen,
        uint256[] memory _redemptionWindowsClose,
        uint256[] memory _maxRedeemPerTxn,
        string memory _contractMetaDataURI,
        address _mintPassToken
    ) ERC721(_name, _symbol) {
        _contractURI = _contractMetaDataURI;
        mintPassFactory = MintPassFactory(_mintPassToken);
        generalCounter.increment();

        for (uint256 i = 0; i < _mpIndexes.length; i++) {
            uint256 passID = _mpIndexes[i];
            redemptionWindows[passID].windowOpens = _redemptionWindowsOpen[i];
            redemptionWindows[passID].windowCloses = _redemptionWindowsClose[i];
            redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn[i];
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Update token metadata
     */
    function updateTokenMetadata(
        uint256 tokenId,
        string memory name,
        string memory description,
        string memory image,
        string memory animation_url,
        string memory url
    ) external onlyRole(CONTRACT_ADMIN_ROLE) {
        Token storage token = tokens[tokenId];
        token.name = name;
        token.description = description;
        token.image = image;
        token.animation_url = animation_url;
        token.url = url;
    }

    /**
     * @notice Update membership tier
     */
    function updateMembershipTier(uint256 tokenTypeID, string memory name)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        MembershipTier storage tier = membershipTiers[tokenTypeID];
        tier.name = name;
    }

    /**
     * @notice Set the mintpass contract address
     *
     * @param _mintPassToken the respective Mint Pass contract address
     */
    function setMintPassToken(address _mintPassToken)
        external
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        mintPassFactory = MintPassFactory(_mintPassToken);
    }

    /**
     * @notice Pause redeems until unpause is called
     */
    function pause() external override onlyRole(CONTRACT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause redeems until pause is called
     */
    function unpause() external override onlyRole(CONTRACT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Configure time to enable redeem functionality
     *
     * @param _windowOpen UNIX timestamp for redeem start
     */
    function setRedeemStart(uint256 passID, uint256 _windowOpen)
        external
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        redemptionWindows[passID].windowOpens = _windowOpen;
    }

    /**
     * @notice Configure time to enable redeem functionality
     *
     * @param _windowClose UNIX timestamp for redeem close
     */
    function setRedeemClose(uint256 passID, uint256 _windowClose)
        external
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        redemptionWindows[passID].windowCloses = _windowClose;
    }

    /**
     * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
     *
     * @param _maxRedeemPerTxn number of passes that can be redeemed
     */
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn)
        external
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn;
    }

    /**
     * @notice Check if redemption window is open
     *
     * @param passID the pass index to check
     */
    function isRedemptionOpen(uint256 passID)
        public
        view
        override
        returns (bool)
    {
        if (paused()) {
            return false;
        }
        return
            block.timestamp > redemptionWindows[passID].windowOpens &&
            block.timestamp < redemptionWindows[passID].windowCloses;
    }

    /*
     * @dev fusion
     */

    function toggleFusion(bool _on) external onlyRole(CONTRACT_ADMIN_ROLE) {
        isFusionOpen = _on;
    }

    function addFusion(
        uint256 _tokenIndex,
        uint256 _fusionTokenID,
        uint256 _fusionQuantity
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        FusionConfig storage fusionConfig = fusionConfigs[_tokenIndex];
        fusionConfig.tokenIDRequired = _fusionTokenID;
        fusionConfig.numTokensRequired = _fusionQuantity;
    }

    function fusion(
        uint256 _tokenIndex, //fusing into
        uint256[] calldata _inputTokenIDs //required token IDs passed in
    ) external nonReentrant {
        require(isFusionOpen, "Fusion is not open");
        require(isUniqueArray(_inputTokenIDs), "Duplicate Array Value");

        FusionConfig storage fusionConfig = fusionConfigs[_tokenIndex];
        require(_inputTokenIDs.length >= fusionConfig.numTokensRequired, "21");
        require(
            _inputTokenIDs.length % fusionConfig.numTokensRequired == 0,
            "Wrong multiple of required token quantity sent"
        );
        //check for ownership
        Collectible contract721 = Collectible(this);
        for (uint256 i = 0; i < _inputTokenIDs.length; i++) {
            require(
                contract721.ownerOf(_inputTokenIDs[i]) == msg.sender,
                "Sender does not own this token"
            );
            require(
                tokenTypes[_inputTokenIDs[i]] == fusionConfig.tokenIDRequired,
                "Wrong token type"
            );
        }

        uint256 numToIssue = _inputTokenIDs.length.div(
            fusionConfig.numTokensRequired
        );

        for (uint256 i = 0; i < _inputTokenIDs.length; i++) {
            _burn(_inputTokenIDs[i]);
        }

        string memory tokensMinted = "";

        for (uint256 i = 0; i < numToIssue; i++) {
            tokenTypes[generalCounter.current()] = _tokenIndex;
            tokensMinted = string(
                abi.encodePacked(
                    tokensMinted,
                    generalCounter.current().toString(),
                    ","
                )
            );
            _safeMint(msg.sender, generalCounter.current());
            generalCounter.increment();
        }

        emit Fused(msg.sender, tokensMinted);
    }

    /**
     * @notice Redeem specified amount of MintPass tokens
     *
     * @param mpIndexes the tokenIDs of MintPasses to redeem
     * @param amounts the amount of MintPasses to redeem
     */
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts)
        external
        override
    {
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        require(isUniqueArray(mpIndexes), "Duplicate Array Value");
        //check to make sure all are valid then re-loop for redemption
        for (uint256 i = 0; i < mpIndexes.length; i++) {
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(
                amounts[i] <= redemptionWindows[mpIndexes[i]].maxRedeemPerTxn,
                "Redeem: max redeem per transaction reached"
            );
            require(
                mintPassFactory.balanceOf(msg.sender, mpIndexes[i]) >=
                    amounts[i],
                "Redeem: insufficient amount of Mint Passes"
            );
            require(
                block.timestamp > redemptionWindows[mpIndexes[i]].windowOpens,
                "Redeem: redeption window not open for this Mint Pass"
            );
            require(
                block.timestamp < redemptionWindows[mpIndexes[i]].windowCloses,
                "Redeem: redeption window is closed for this Mint Pass"
            );
        }

        string memory tokensMinted = "";

        for (uint256 i = 0; i < mpIndexes.length; i++) {
            mintPassFactory.burnFromRedeem(
                msg.sender,
                mpIndexes[i],
                amounts[i]
            );

            for (uint256 j = 0; j < amounts[i]; j++) {
                tokenTypes[generalCounter.current()] = mpIndexes[i];
                _safeMint(msg.sender, generalCounter.current());
                tokensMinted = string(
                    abi.encodePacked(
                        tokensMinted,
                        generalCounter.current().toString(),
                        ","
                    )
                );
                generalCounter.increment();
            }
        }

        emit Redeemed(msg.sender, tokensMinted);
    }

    function toggleSaleOn(bool isOn) external onlyRole(CONTRACT_ADMIN_ROLE) {
        saleConfiguration.isSaleOpen = isOn;
    }

    function getTokenType(uint256 tokenId) public view returns (uint256) {
        return tokenTypes[tokenId];
    }

    function editSale(
        bool isSaleOpen,
        uint256 windowOpens,
        uint256 windowCloses,
        uint256 maxMintsPerTxn,
        uint256 mintPrice,
        uint256 maxSupply,
        bool requireSignature,
        address signerAddress,
        uint256 tokenType
    ) external onlyRole(CONTRACT_ADMIN_ROLE) {
        saleConfiguration.isSaleOpen = isSaleOpen;
        saleConfiguration.windowOpens = windowOpens;
        saleConfiguration.windowCloses = windowCloses;
        saleConfiguration.maxMintsPerTxn = maxMintsPerTxn;
        saleConfiguration.mintPrice = mintPrice;
        saleConfiguration.maxSupply = maxSupply;
        saleConfiguration.requireSignature = requireSignature;
        saleConfiguration.signerAddress = signerAddress;
        saleConfiguration.tokenType = tokenType;
    }

    function togglePresale(bool isPresaleOpen)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        saleConfiguration.isPresaleOpen = isPresaleOpen;
    }


    function purchase(
        uint256 quantity,
        uint256 tokenType,
        bytes memory signature
    ) external payable {
        require(!paused(), "Mint: minting is paused");
        require(quantity > 0, "Sale: Must send quantity");
        require(saleConfiguration.isSaleOpen, "Sale: Not started");
        require(
            tokenType == saleConfiguration.tokenType,
            "Sale: Token type not on sale"
        );
        if (saleConfiguration.requireSignature) {
            require(
                ECDSA.recover(
                    keccak256(abi.encodePacked(msg.sender, quantity, tokenType))
                        .toEthSignedMessageHash(),
                    signature
                ) == saleConfiguration.signerAddress,
                "Invalid Signature"
            );
        }

        require(
            quantity <= saleConfiguration.maxMintsPerTxn,
            "Sale: Max quantity per transaction exceeded"
        );
        require(
            block.timestamp >= saleConfiguration.windowOpens,
            "Sale: redeption window not open for this Mint Pass"
        );
        require(
            block.timestamp <= saleConfiguration.windowCloses,
            "Sale: redeption window is closed for this Mint Pass"
        );
        require(
            msg.value >= quantity.mul(saleConfiguration.mintPrice),
            "Sale: Ether value incorrect"
        );
        require(
            totalSupply() + quantity <= saleConfiguration.maxSupply,
            "Purchase would exceed max supply"
        );

        string memory tokensMinted = "";

        payable(receivingWallet).transfer(msg.value);

        for (uint256 i = 0; i < quantity; i++) {
            tokenTypes[generalCounter.current()] = tokenType;
            _safeMint(msg.sender, generalCounter.current());
            tokensMinted = string(
                abi.encodePacked(
                    tokensMinted,
                    generalCounter.current().toString(),
                    ","
                )
            );
            generalCounter.increment();
        }

        emit Minted(msg.sender, tokensMinted);
    }

     function airdrop(address __to, uint256 __quantity, uint256 __tokenType) external onlyRole(CONTRACT_ADMIN_ROLE){
       
        for (uint256 i = 0; i < __quantity; i++) {
            tokenTypes[generalCounter.current()] = __tokenType;
           _safeMint(__to, generalCounter.current());
           generalCounter.increment();
        }
       
    }


    function setReceivingWallet(address __receivingWallet) external onlyRole(CONTRACT_ADMIN_ROLE){
        receivingWallet = __receivingWallet;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawEther(address payable _to, uint256 _amount) public onlyRole(CONTRACT_ADMIN_ROLE)
    {
        _to.transfer(_amount);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        Token storage token = tokens[tokenTypes[tokenId]];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        token.name,
                        " - #",
                        Strings.toString(tokenId),
                        '", "description": "',
                        token.description,
                        '", "image": "',
                        token.image,
                        '", "animation_url": "',
                        token.animation_url,
                        '", "external_url": "',
                        token.url,
                        '", "attributes": [{"trait_type": "Membership Tier","value": "',
                        membershipTiers[tokenTypes[tokenId]].name,
                        '"}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setContractURI(string memory uri)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isUniqueArray(uint256[] calldata _array)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                if (_array[i] == _array[j] && i != j) return false;
            }
        }
        return true;
    }
}

interface MintPassFactory {
    function burnFromRedeem(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}