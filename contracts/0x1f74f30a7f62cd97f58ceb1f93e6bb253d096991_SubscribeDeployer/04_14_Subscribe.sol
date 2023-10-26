// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribe } from "../interfaces/ISubscribe.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IDeployer } from "../interfaces/IDeployer.sol";

import { CyberNFT721 } from "../base/CyberNFT721.sol";
import { LibString } from "../libraries/LibString.sol";

/**
 * @title Subscribe NFT
 * @author CyberConnect
 * @notice This contract defines Subscribe NFT in CyberConnect Protocol.
 */
contract Subscribe is CyberNFT721, ISubscribe {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address public immutable ENGINE;
    address internal _account;
    mapping(address => uint256) public ownedToken;
    mapping(uint256 => uint256) public expiries;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        address engine = IDeployer(msg.sender).params();
        require(engine != address(0), "ZERO_ADDRESS");

        ENGINE = engine;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISubscribe
    function mint(
        address to,
        uint256 durationDay
    ) external override returns (uint256) {
        require(msg.sender == ENGINE, "ONLY_ENGINE");
        require(durationDay >= 1, "MIN_DURATION_ONE_DAY");

        uint256 mintedId = super._mint(to);
        ownedToken[to] = mintedId;
        expiries[mintedId] = block.timestamp + durationDay * 1 days;

        return mintedId;
    }

    /// @inheritdoc ISubscribe
    function initialize(
        address account,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        _account = account;
        super._initialize(name, symbol);
    }

    /// @inheritdoc ISubscribe
    function extend(
        address account,
        uint256 durationDay
    ) external override returns (uint256) {
        require(msg.sender == ENGINE, "ONLY_ENGINE");
        require(durationDay >= 1, "MIN_DURATION_ONE_DAY");

        uint256 curTime = block.timestamp;
        uint256 tokenId = ownedToken[account];

        // not expired
        if (curTime < expiries[tokenId]) {
            expiries[tokenId] += durationDay * 1 days;
        } else {
            expiries[tokenId] = curTime + durationDay * 1 days;
        }

        return tokenId;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Disallows the transfer of the essence nft.
     */
    function transferFrom(address, address, uint256) public pure override {
        revert("TRANSFER_NOT_ALLOWED");
    }

    /// ERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint256 expiryTs = expiries[tokenId];
        if (expiryTs != 0) {
            require(block.timestamp < expiryTs, "EXPIRED");
        }

        return super.ownerOf(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /// ERC721
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory uri = ICyberEngine(ENGINE).getSubscriptionTokenURI(
            _account
        );
        return string(abi.encodePacked(uri, LibString.toString(tokenId)));
    }
}