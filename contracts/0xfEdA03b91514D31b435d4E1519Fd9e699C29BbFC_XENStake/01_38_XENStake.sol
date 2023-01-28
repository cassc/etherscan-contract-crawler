// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@faircrypto/xen-crypto/contracts/XENCrypto.sol";
import "@faircrypto/xen-crypto/contracts/interfaces/IBurnableToken.sol";
import "@faircrypto/magic-numbers/contracts/MagicNumbers.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./libs/ERC2771Context.sol";
import "./interfaces/IERC2771.sol";
import "./libs/StakeInfo.sol";
import "./libs/StakeMetadata.sol";
import "./libs/Array.sol";
import "./interfaces/IXENStake.sol";
import "./interfaces/IXENStakeProxying.sol";

/*

        \\      //   |||||||||||   |\      ||       A CRYPTOCURRENCY FOR THE MASSES
         \\    //    ||            |\\     ||
          \\  //     ||            ||\\    ||       PRINCIPLES OF XEN:
           \\//      ||            || \\   ||       - No pre-mint; starts with zero supply
            XX       ||||||||      ||  \\  ||       - No admin keys
           //\\      ||            ||   \\ ||       - Immutable contract
          //  \\     ||            ||    \\||
         //    \\    ||            ||     \\|
        //      \\   |||||||||||   ||      \|       Copyright (C) FairCrypto Foundation 2022-23


    XENFT XEN Stake props:
    - amount, term, maturityTs, APY, rarityScore
 */

contract XENStake is
    DefaultOperatorFilterer, // required to support OpenSea royalties
    IXENStake,
    IXENStakeProxying,
    IBurnableToken,
    ERC2771Context, // required to support meta transactions
    IERC2981, // required to support NFT royalties
    ERC721("XEN Stake", "XENS")
{
    using Strings for uint256;
    using StakeInfo for uint256;
    using MagicNumbers for uint256;
    using Array for uint256[];

    // PUBLIC CONSTANTS

    // XENFT common business logic
    uint256 public constant SECONDS_IN_DAY = 24 * 3_600;
    uint256 public constant BLACKOUT_TERM = 7 * SECONDS_IN_DAY;

    string public constant AUTHORS = "@MrJackLevin @lbelyaev faircrypto.org";

    uint256 public constant ROYALTY_BP = 500;

    // PUBLIC MUTABLE STATE

    // increasing counter for NFT tokenIds, also used as salt for proxies' spinning
    uint256 public tokenIdCounter = 1;

    // tokenId => stakeInfo
    mapping(uint256 => uint256) public stakeInfo;

    // PUBLIC IMMUTABLE STATE

    // pointer to XEN Crypto contract
    XENCrypto public immutable xenCrypto;

    // PRIVATE STATE

    // original contract marking to distinguish from proxy copies
    address private immutable _original;
    // original deployer address to be used for setting trusted forwarder
    address private immutable _deployer;
    // address to be used for royalties' tracking
    address private immutable _royaltyReceiver;

    // mapping Address => tokenId[]
    mapping(address => uint256[]) private _ownedTokens;

    constructor(address xenCrypto_, address forwarder_, address royaltyReceiver_) ERC2771Context(forwarder_) {
        require(xenCrypto_ != address(0), "bad address");
        _original = address(this);
        _deployer = msg.sender;
        _royaltyReceiver = royaltyReceiver_ == address(0) ? msg.sender : royaltyReceiver_;
        xenCrypto = XENCrypto(xenCrypto_);
    }

    // INTERFACES & STANDARDS
    // IERC165 IMPLEMENTATION

    /**
        @dev confirms support for IERC-165, IERC-721, IERC2981, IERC2771 and IBurnRedeemable interfaces
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IBurnRedeemable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC2771).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ERC2771 IMPLEMENTATION

    /**
        @dev use ERC2771Context implementation of _msgSender()
     */
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    /**
        @dev use ERC2771Context implementation of _msgData()
     */
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    // OWNABLE IMPLEMENTATION

    /**
        @dev public getter to check for deployer / owner (Opensea, etc.)
     */
    function owner() external view returns (address) {
        return _deployer;
    }

    // ERC-721 METADATA IMPLEMENTATION
    /**
        @dev compliance with ERC-721 standard (NFT); returns NFT metadata, including SVG-encoded image
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 info = stakeInfo[tokenId];

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "XEN Stake #',
            tokenId.toString(),
            '",',
            '"description": "XENFT: XEN Crypto Proof Of Stake",',
            '"image": "',
            "data:image/svg+xml;base64,",
            Base64.encode(StakeMetadata.svgData(tokenId, info, address(xenCrypto))),
            '",',
            '"attributes": ',
            StakeMetadata.attributes(info),
            "}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    // IMPLEMENTATION OF XENStakeProxying INTERFACE
    // FUNCTIONS IN PROXY COPY CONTRACTS (VMU), CALLING ORIGINAL XEN CRYPTO CONTRACT
    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.stake(amount, term)
     */
    function callStake(uint256 amount, uint256 term) external {
        require(msg.sender == _original, "XEN Proxy: unauthorized");
        bytes memory callData = abi.encodeWithSignature("stake(uint256,uint256)", amount, term);
        (bool success, ) = address(xenCrypto).call(callData);
        require(success, "stake call failed");
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.withdraw()
     */
    function callWithdraw() external {
        require(msg.sender == _original, "XEN Proxy: unauthorized");
        bytes memory callData = abi.encodeWithSignature("withdraw()");
        (bool success, ) = address(xenCrypto).call(callData);
        require(success, "withdraw call failed");
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.transfer(to, amount)
     */
    function callTransfer(address to) external {
        require(msg.sender == _original, "XEN Proxy: unauthorized");
        uint256 balance = xenCrypto.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", to, balance);
        (bool success, ) = address(xenCrypto).call(callData);
        require(success, "transfer call failed");
    }

    /**
        @dev function callable only in proxy contracts from the original one => destroys the proxy contract
     */
    function powerDown() external {
        require(msg.sender == _original, "XEN Proxy: unauthorized");
        selfdestruct(payable(address(0)));
    }

    // OVERRIDING OF ERC-721 IMPLEMENTATION
    // ENFORCEMENT OF TRANSFER BLACKOUT PERIOD

    /**
        @dev overrides OZ ERC-721 before transfer hook to check if there's no blackout period
     */
    function _beforeTokenTransfer(address from, address, uint256 tokenId) internal virtual override {
        if (from != address(0)) {
            uint256 maturityTs = StakeInfo.getMaturityTs(stakeInfo[tokenId]);
            uint256 delta = maturityTs > block.timestamp ? maturityTs - block.timestamp : block.timestamp - maturityTs;
            require(delta > BLACKOUT_TERM, "XENFT: transfer prohibited in blackout period");
        }
    }

    /**
        @dev overrides OZ ERC-721 after transfer hook to allow token enumeration for owner
     */
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _ownedTokens[from].removeItem(tokenId);
        _ownedTokens[to].addItem(tokenId);
    }

    // IBurnableToken IMPLEMENTATION

    /**
        @dev burns XENTorrent XENFT which can be used by connected contracts services
     */
    function burn(address user, uint256 tokenId) public {
        require(
            IERC165(_msgSender()).supportsInterface(type(IBurnRedeemable).interfaceId),
            "XENFT burn: not a supported contract"
        );
        require(user != address(0), "XENFT burn: illegal owner address");
        require(tokenId > 0, "XENFT burn: illegal tokenId");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "XENFT burn: not an approved operator");
        require(ownerOf(tokenId) == user, "XENFT burn: user is not tokenId owner");
        _ownedTokens[user].removeItem(tokenId);
        _burn(tokenId);
        IBurnRedeemable(_msgSender()).onTokenBurned(user, tokenId);
    }

    // OVERRIDING ERC-721 IMPLEMENTATION TO ALLOW OPENSEA ROYALTIES ENFORCEMENT PROTOCOL

    /**
        @dev implements `setApprovalForAll` with additional approved Operator checking
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
        @dev implements `approve` with additional approved Operator checking
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
        @dev implements `transferFrom` with additional approved Operator checking
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
        @dev implements `safeTransferFrom` with additional approved Operator checking
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
        @dev implements `safeTransferFrom` with additional approved Operator checking
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // SUPPORT FOR ERC2771 META-TRANSACTIONS

    /**
        @dev Implements setting a `Trusted Forwarder` for meta-txs. Settable only once
     */
    function addForwarder(address trustedForwarder) external {
        require(msg.sender == _deployer, "XENFT: not an deployer");
        require(_trustedForwarder == address(0), "XENFT: Forwarder is already set");
        _trustedForwarder = trustedForwarder;
    }

    // SUPPORT FOR ERC2981 ROYALTY INFO

    /**
        @dev Implements getting Royalty Info by supported operators. ROYALTY_BP is expressed in basis points
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * ROYALTY_BP) / 10_000;
    }

    // XEN TORRENT PRIVATE / INTERNAL HELPERS

    /**
        @dev internal torrent interface. calculates rarityBits and rarityScore
     */
    function _calcRarity(uint256 tokenId) private view returns (uint256 rarityScore, uint256 rarityBits) {
        bool isPrime = tokenId.isPrime();
        bool isFib = tokenId.isFib();
        bool blockIsPrime = block.number.isPrime();
        bool blockIsFib = block.number.isFib();
        rarityScore += (isPrime ? 500 : 0);
        rarityScore += (blockIsPrime ? 1_000 : 0);
        rarityScore += (isFib ? 5_000 : 0);
        rarityScore += (blockIsFib ? 10_000 : 0);
        rarityBits = StakeInfo.encodeRarityBits(isPrime, isFib, blockIsPrime, blockIsFib);
    }

    /**
        @dev internal torrent interface. composes StakeInfo
     */
    function _stakeInfo(
        address proxy,
        uint256 tokenId,
        uint256 amount,
        uint256 term
    ) private view returns (uint256 info) {
        (, uint256 maturityTs, , uint256 apy) = xenCrypto.userStakes(proxy);
        (uint256 rarityScore, uint256 rarityBits) = _calcRarity(tokenId);
        info = StakeInfo.encodeStakeInfo(term, maturityTs, amount / 10 ** 18, apy, rarityScore, rarityBits);
    }

    /**
        @dev internal helper. Creates bytecode for minimal proxy contract
     */
    function _bytecode() private view returns (bytes memory) {
        return
            bytes.concat(
                bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
                bytes20(address(this)),
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
    }

    /**
        @dev internal torrent interface. initiates Stake Operation
     */
    function _createStake(uint256 amount, uint256 term, uint256 tokenId) private {
        bytes memory bytecode = _bytecode();
        bytes memory callData = abi.encodeWithSignature("callStake(uint256,uint256)", amount, term);
        address proxy;
        bool succeeded;
        bytes32 salt = keccak256(abi.encodePacked(tokenId));
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(proxy != address(0), "XENFT: Error creating VSU");
        require(xenCrypto.transferFrom(_msgSender(), proxy, amount), "XENFT: Error transferring XEN to VSU");
        assembly {
            succeeded := call(gas(), proxy, 0, add(callData, 0x20), mload(callData), 0, 0)
        }
        require(succeeded, "XENFT: Error while staking");

        stakeInfo[tokenId] = _stakeInfo(proxy, tokenId, amount, term);
    }

    /**
        @dev internal torrent interface. initiates Stake Operation
     */
    function _endStake(uint256 tokenId) private {
        bytes memory bytecode = _bytecode();
        bytes memory callData = abi.encodeWithSignature("callWithdraw()");
        bytes memory callData1 = abi.encodeWithSignature("callTransfer(address)", _msgSender());
        bytes memory callData2 = abi.encodeWithSignature("powerDown()");
        bytes32 salt = keccak256(abi.encodePacked(tokenId));
        bytes32 hash = keccak256(abi.encodePacked(hex"ff", address(this), salt, keccak256(bytecode)));
        address proxy = address(uint160(uint256(hash)));

        bool succeeded;
        assembly {
            succeeded := call(gas(), proxy, 0, add(callData, 0x20), mload(callData), 0, 0)
        }
        require(succeeded, "XENFT: Error while withdrawing");
        assembly {
            succeeded := call(gas(), proxy, 0, add(callData1, 0x20), mload(callData1), 0, 0)
        }
        require(succeeded, "XENFT: Error while transferring");
        assembly {
            succeeded := call(gas(), proxy, 0, add(callData2, 0x20), mload(callData2), 0, 0)
        }
        require(succeeded, "XENFT: Error while powering down");

        delete stakeInfo[tokenId];
    }

    // PUBLIC GETTERS

    /**
        @dev public getter for tokens owned by address
     */
    function ownedTokens() external view returns (uint256[] memory) {
        return _ownedTokens[_msgSender()];
    }

    // PUBLIC TRANSACTIONAL INTERFACE

    /**
        @dev    public XEN Stake interface
                initiates XEN Crypto Stake
     */
    function createStake(uint256 amount, uint256 term) public returns (uint256 tokenId) {
        require(amount > 0, "XENFT: Illegal amount");
        require(term > 0, "XENFT: Illegal term");

        _createStake(amount, term, tokenIdCounter);
        _ownedTokens[_msgSender()].addItem(tokenIdCounter);
        _safeMint(_msgSender(), tokenIdCounter);
        tokenId = tokenIdCounter;
        tokenIdCounter++;
        emit CreateStake(_msgSender(), tokenId, amount, term);
    }

    /**
        @dev    public XEN Stake interface
                ends XEN Crypto Stake, withdraws principal and reward amounts
     */
    function endStake(uint256 tokenId) public {
        require(tokenId > 0, "XENFT: Illegal tokenId");
        require(ownerOf(tokenId) == _msgSender(), "XENFT: Incorrect owner");
        uint256 maturityTs = StakeInfo.getMaturityTs(stakeInfo[tokenId]);
        require(block.timestamp > maturityTs, "XENFT: Maturity not reached");

        _endStake(tokenId);
        _ownedTokens[_msgSender()].removeItem(tokenId);
        _burn(tokenId);
        emit EndStake(_msgSender(), tokenId);
    }
}