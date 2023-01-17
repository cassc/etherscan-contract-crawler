// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IERC1155 } from "openzeppelin/interfaces/IERC1155.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";
import { ERC721AUpgradeable } from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";
import { ERC2981Upgradeable } from "openzeppelin-contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import { IERC721Receiver } from "openzeppelin/token/ERC721/IERC721Receiver.sol";

// developed by @rev3studios
// authored by @hexzerodev

library JiraFusionV1Storage {
    struct Layout {
        // signer
        address _signer;

        // contracts + addresses
        address _tokensReceiver;
        IERC721 _jiraGen2;
        IERC20 _jiraToken;

        // operator filterer
        bool _operatorFilteringEnabled;

        // public
        bool _publicOpen;

        // limits
        uint256 _maxPublicMint;

        // counters
        uint256 _publicMintCounter;
        uint256 _normalMintCounter;
        uint256 _rareMintCounter;
        uint256 _legendaryMintCounter;
        mapping(uint256 => bool) _isLegendaryUsed;

        // nonce
        mapping(address => uint256) _userRerollNonceMap;
        mapping(uint256 => bool) _fusionIDsMap;

        // tokenURI
        string _baseURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('JiraFusionImplV1.storage');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract JiraFusionImplementationV1 is ERC721AUpgradeable, OwnableUpgradeable, ERC2981Upgradeable, OperatorFilterer {

    using JiraFusionV1Storage for JiraFusionV1Storage.Layout;

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrMaxNormalMints();
    error ErrMaxRareMints();
    error ErrMaxLegendaryMints();
    error ErrExceedsMaxPublicMint();
    error ErrInvalidSignature();
    error ErrLegendaryAlreadyUsed();
    error ErrFusionIDTaken();
    error ErrPublicNotOpen();
    error ErrNotTokenOwner();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event LogBurnAndMint(address indexed msgSender, uint256 tokenID1, uint256 tokenID2, uint256 jiraAmount, uint256 fusionID, bool isWL, uint256 mintedToken);
    event LogBurnAndMintRare(address indexed msgSender, uint256 tokenID, uint256 jiraAmount, uint256 fusionID, bool retainGen2Artwork, uint256 mintedToken);
    event LogClaim(address indexed msgSender, uint256 tokenID, uint256 fusionID, uint256 mintedToken);
    event LogReroll(address indexed msgSender, uint256 tokenID1, uint256 tokenID2, uint256 jiraAmount);
    event LogRerollRare(address indexed msgSender, uint256 tokenID, uint256 jiraAmount);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    // supply
    uint256 private constant TOTAL_SUPPLY = 999;

    uint256 private constant RESERVED_TEAM = 160;
    uint256 private constant RESERVED_LEGENDARIES = 11;
    uint256 private constant RESERVED_RARES = 52;

    uint256 private constant TOTAL_RESERVED = RESERVED_TEAM + RESERVED_LEGENDARIES + RESERVED_RARES;
    uint256 private constant MAX_NORMAL_MINTS = TOTAL_SUPPLY - TOTAL_RESERVED;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    function initialize(address jiraGen2_, address jiraToken_, address tokensReceiver_, address teamWallet_, address signer_) public initializer initializerERC721A {
        __ERC721A_init("Jira Fusion", "JIRAFUSION");
        __Ownable_init();
        __ERC2981_init();

        // initial states
        JiraFusionV1Storage.layout()._maxPublicMint = 366;
        JiraFusionV1Storage.layout()._jiraGen2 = IERC721(jiraGen2_);
        JiraFusionV1Storage.layout()._jiraToken = IERC20(jiraToken_);
        JiraFusionV1Storage.layout()._tokensReceiver = tokensReceiver_;
        JiraFusionV1Storage.layout()._signer = signer_;

        // team mint
        _mint(teamWallet_, RESERVED_TEAM);

        // operator filterer
        _registerForOperatorFiltering();
        JiraFusionV1Storage.layout()._operatorFilteringEnabled = true;

        // erc2981 royalty - 5%
        _setDefaultRoyalty(teamWallet_, 500);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function burnAndMint(uint256 tokenID1_, uint256 tokenID2_, uint256 jiraAmount_, uint256 fusionID_, bool isWL_, bytes calldata signature_) external {
        // check supply
        uint256 __normalMintCounter = JiraFusionV1Storage.layout()._normalMintCounter;
        if (__normalMintCounter >= MAX_NORMAL_MINTS) revert ErrMaxNormalMints();

        // check public open
        if (!isWL_ && !JiraFusionV1Storage.layout()._publicOpen) revert ErrPublicNotOpen();

        // check public mint supply
        uint256 __publicMintCounter = JiraFusionV1Storage.layout()._publicMintCounter;
        if (!isWL_ && JiraFusionV1Storage.layout()._publicMintCounter >= JiraFusionV1Storage.layout()._maxPublicMint) {
            revert ErrExceedsMaxPublicMint();
        }

        // check fusionID not taken
        if (JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_]) {
            revert ErrFusionIDTaken();
        }

        // check signature
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            tokenID1_,
            tokenID2_,
            jiraAmount_,
            fusionID_,
            isWL_
        ));
        if (ECDSA.recover(hash, signature_) != JiraFusionV1Storage.layout()._signer) revert ErrInvalidSignature();

        // burn tokens
        JiraFusionV1Storage.layout()._jiraGen2.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, tokenID1_);
        JiraFusionV1Storage.layout()._jiraGen2.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, tokenID2_);

        // payment
        JiraFusionV1Storage.layout()._jiraToken.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, jiraAmount_);

        // update state
        if (!isWL_) {
            JiraFusionV1Storage.layout()._publicMintCounter = __publicMintCounter + 1;
        }
        JiraFusionV1Storage.layout()._normalMintCounter = __normalMintCounter + 1;
        JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_] = true;

        // mint
        _mint(msg.sender, 1);

        // emit
        emit LogBurnAndMint(msg.sender, tokenID1_, tokenID2_, jiraAmount_, fusionID_, isWL_, _nextTokenId() - 1);
    }

    function burnAndMintRare(uint256 tokenID_, uint256 jiraAmount_, uint256 fusionID_, bool retainGen2Artwork_, bytes calldata signature_) external {
        // check supply
        uint256 __rareMintCounter = JiraFusionV1Storage.layout()._rareMintCounter;
        if (__rareMintCounter >= RESERVED_RARES) revert ErrMaxRareMints();

        // check fusionID not taken
        if (JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_]) {
            revert ErrFusionIDTaken();
        }

        // check signature
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            tokenID_,
            jiraAmount_,
            fusionID_,
            retainGen2Artwork_
        ));
        if (ECDSA.recover(hash, signature_) != JiraFusionV1Storage.layout()._signer) revert ErrInvalidSignature();

        // burn token
        JiraFusionV1Storage.layout()._jiraGen2.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, tokenID_);

        // payment
        JiraFusionV1Storage.layout()._jiraToken.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, jiraAmount_);

        // update state
        JiraFusionV1Storage.layout()._rareMintCounter = __rareMintCounter + 1;
        JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_] = true;

        // mint
        _mint(msg.sender, 1);

        // emit
        emit LogBurnAndMintRare(msg.sender, tokenID_, jiraAmount_, fusionID_, retainGen2Artwork_, _nextTokenId() - 1);
    }

    function claim(uint256 tokenID_, uint256 fusionID_, bytes calldata signature_) external {
        // check supply
        uint256 __legendaryMintCounter = JiraFusionV1Storage.layout()._legendaryMintCounter;
        if(__legendaryMintCounter >= RESERVED_LEGENDARIES) revert ErrMaxLegendaryMints();

        // check if legendary used
        if (JiraFusionV1Storage.layout()._isLegendaryUsed[tokenID_]) revert ErrLegendaryAlreadyUsed();

        // check fusionID not taken
        if (JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_]) {
            revert ErrFusionIDTaken();
        }

        // check signature
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            tokenID_,
            fusionID_
        ));
        if (ECDSA.recover(hash, signature_) != JiraFusionV1Storage.layout()._signer) revert ErrInvalidSignature();

        // check owner
        if (JiraFusionV1Storage.layout()._jiraGen2.ownerOf(tokenID_) != msg.sender) revert ErrNotTokenOwner();

        // update state
        JiraFusionV1Storage.layout()._isLegendaryUsed[tokenID_] = true;
        JiraFusionV1Storage.layout()._legendaryMintCounter = __legendaryMintCounter + 1;
        JiraFusionV1Storage.layout()._fusionIDsMap[fusionID_] = true;

        // mint
        _mint(_msgSender(), 1);

        // emit
        emit LogClaim(msg.sender, tokenID_, fusionID_, _nextTokenId() - 1);
    }

    function reroll(uint256 tokenID1_, uint256 tokenID2_, uint256 jiraAmount_, bytes calldata signature_) external {

        // check signature
        uint256 rerollNonce = JiraFusionV1Storage.layout()._userRerollNonceMap[msg.sender];
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            tokenID1_,
            tokenID2_,
            rerollNonce,
            jiraAmount_
        ));
        if (ECDSA.recover(hash, signature_) != JiraFusionV1Storage.layout()._signer) revert ErrInvalidSignature();

        // transfer ERC20 token
        JiraFusionV1Storage.layout()._jiraToken.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, jiraAmount_);

        // update reroll nonce
        JiraFusionV1Storage.layout()._userRerollNonceMap[msg.sender] = rerollNonce + 1;

        // emit
        emit LogReroll(msg.sender, tokenID1_, tokenID2_, jiraAmount_);
    }

    function rerollRare(uint256 tokenID_, uint256 jiraAmount_, bytes calldata signature_) external {

        // check signature
        uint256 rerollNonce = JiraFusionV1Storage.layout()._userRerollNonceMap[msg.sender];
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            tokenID_,
            rerollNonce,
            jiraAmount_
        ));
        if (ECDSA.recover(hash, signature_) != JiraFusionV1Storage.layout()._signer) revert ErrInvalidSignature();

        // transfer ERC20 token
        JiraFusionV1Storage.layout()._jiraToken.transferFrom(msg.sender, JiraFusionV1Storage.layout()._tokensReceiver, jiraAmount_);

        // update reroll nonce
        JiraFusionV1Storage.layout()._userRerollNonceMap[msg.sender] = rerollNonce + 1;

        // emit
        emit LogRerollRare(msg.sender, tokenID_, jiraAmount_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    // addresses
    function setSigner(address signer_) external onlyOwner {
        JiraFusionV1Storage.layout()._signer = signer_;
    }

    function setTokensReceiver(address receiver_) external onlyOwner {
        JiraFusionV1Storage.layout()._tokensReceiver = receiver_;
    }

    function setJiraGen2(address address_) external onlyOwner {
        JiraFusionV1Storage.layout()._jiraGen2 = IERC721(address_);
    }

    function setJiraToken(address address_) external onlyOwner {
        JiraFusionV1Storage.layout()._jiraToken = IERC20(address_);
    }

    // public
    function setPublicOpen(bool publicOpen_) external onlyOwner {
        JiraFusionV1Storage.layout()._publicOpen = publicOpen_;
    }

    function setMaxPulicMint(uint256 maxPublicMint_) external onlyOwner {
        JiraFusionV1Storage.layout()._maxPublicMint = maxPublicMint_;
    }

    // tokenURI
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        JiraFusionV1Storage.layout()._baseURI = baseURI_;
    }

    // operator filterer
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        JiraFusionV1Storage.layout()._operatorFilteringEnabled = value;
    }

    // erc2981
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721                                   */
    /* -------------------------------------------------------------------------- */
    /*
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721a                                  */
    /* -------------------------------------------------------------------------- */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return JiraFusionV1Storage.layout()._baseURI;
    }

    /* -------------------------------------------------------------------------- */
    /*                              erc165 overrides                              */
    /* -------------------------------------------------------------------------- */
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override (ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                         operator filterer overrides                        */
    /* -------------------------------------------------------------------------- */
    function setApprovalForAll(address operator, bool approved) 
        public override(ERC721AUpgradeable) 
        onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public payable override (ERC721AUpgradeable)
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public payable override (ERC721AUpgradeable)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable override (ERC721AUpgradeable) 
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return JiraFusionV1Storage.layout()._operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function operatorFilteringEnabled() external view returns(bool) {
        return JiraFusionV1Storage.layout()._operatorFilteringEnabled;
    }

    function maxPublicMint() external view returns(uint256) {
        return JiraFusionV1Storage.layout()._maxPublicMint;
    }

    function publicOpen() external view returns(bool) {
        return JiraFusionV1Storage.layout()._publicOpen;
    }

    function publicMintCounter() external view returns(uint256) {
        return JiraFusionV1Storage.layout()._publicMintCounter;
    }

    function normalMintCounter() external view returns(uint256) {
        return JiraFusionV1Storage.layout()._normalMintCounter;
    }

    function rareMintCounter() external view returns(uint256) {
        return JiraFusionV1Storage.layout()._rareMintCounter;
    }

    function legendaryMintCounter() external view returns(uint256) {
        return JiraFusionV1Storage.layout()._legendaryMintCounter;
    }

    function isLegendaryUsed(uint256 tokenID) external view returns(bool) {
        return JiraFusionV1Storage.layout()._isLegendaryUsed[tokenID];
    }

    function userRerollNonceMap(address user) external view returns(uint256) {
        return JiraFusionV1Storage.layout()._userRerollNonceMap[user];
    }

    function fusionIDsMap(uint256 tokenID) external view returns(bool) {
        return JiraFusionV1Storage.layout()._fusionIDsMap[tokenID];
    }

    function baseURI() external view returns(string memory) {
        return JiraFusionV1Storage.layout()._baseURI;
    }
}