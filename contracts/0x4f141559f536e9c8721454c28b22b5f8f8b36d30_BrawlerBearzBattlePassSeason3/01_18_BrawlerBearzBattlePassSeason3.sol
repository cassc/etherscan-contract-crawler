// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import "./tunnel/FxBaseRootTunnel.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**
 * @title BrawlerBearzBattlePassSeason3
 * @author @scottybmitch
 * @dev Battle pass public mint and L2 sync on mint, non-transferable, or sellable
 */
contract BrawlerBearzBattlePassSeason3 is
    FxBaseRootTunnel,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable
{
    using Strings for uint256;

    /// @dev Sync actions
    bytes32 public constant MINTED = keccak256("MINTED");
    bytes32 public constant REWARDS_CLAIM = keccak256("REWARDS_CLAIM");

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeibcjnairw3alc65whtvcy7vosjion5csp5zctn7e4gehbqb77kbye/";

    /// @notice Pro battle pass tier
    uint256 constant PRO_PASS = 1;

    /// @notice Pro pass mint price
    uint256 public proPrice = 0.03 ether;

    // @dev Treasury
    address public treasury =
        payable(0x39bfA2b4319581bc885A2d4b9F0C90C2e1c24B87);

    /*
     * @notice All mints live ~ July 12th, 12PM EST
     * @dev Mints go live date
     */
    uint256 public liveAt = 1689177600;

    /*
     * @notice All mints expired ~ July 29th, 12PM EST
     * @dev Mints expire at
     */
    uint256 public expiresAt = 1690646400;

    /// @dev Thrown on approval
    error CannotApproveAll();

    /// @dev Thrown on transfer
    error Nontransferable();

    modifier mintIsActive() {
        require(
            block.timestamp > liveAt && block.timestamp < expiresAt,
            "Minting is not active."
        );
        _;
    }

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _vendorContractAddress
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        ERC721A("Brawler Bearz Battle Pass: S3", "BBBPS3")
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Pro pass mints
     * @param _amount The amount of passes to mint
     **/
    function proPassMint(uint256 _amount) external payable mintIsActive {
        require(msg.value >= _amount * proPrice, "Not enough funds.");
        address to = _msgSender();

        // Mint passes
        _mint(to, _amount);

        // Mint a synthesizer per mint
        uint256[] memory itemIds = new uint256[](_amount);

        for (uint256 i; i < _amount; i++) {
            itemIds[i] = 211; // Synthesizer item id
        }

        vendorContract.dropItems(to, itemIds);

        // Sync w/ child
        _sendMessageToChild(
            abi.encode(
                MINTED,
                abi.encode(to, _nextTokenId(), PRO_PASS, _amount)
            )
        );
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(PRO_PASS)));
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt && block.timestamp < expiresAt;
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets pro price
     * @param _proPrice A base uri
     */
    function setProPrice(uint256 _proPrice) external onlyOwner {
        proPrice = _proPrice;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(uint256 _liveAt, uint256 _expiresAt)
        external
        onlyOwner
    {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(address _fxChildTunnel)
        public
        override
        onlyOwner
    {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        external
        onlyOwner
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }

    /// @dev Prevent approvals of token
    function setApprovalForAll(address, bool) public virtual override {
        revert CannotApproveAll();
    }

    /// @dev Prevent token transfer unless burning
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        if (to != address(0) && from != address(0)) {
            revert Nontransferable();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _processRewardsClaim(bytes memory data) internal {
        (address to, uint256[] memory itemIds) = abi.decode(
            data,
            (address, uint256[])
        );
        vendorContract.dropItems(to, itemIds);
    }

    /// @dev TEST
    function _processMessageFromChildTest(bytes memory message)
        external
        onlyOwner
    {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == REWARDS_CLAIM) {
            _processRewardsClaim(syncData);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }

    function _processMessageFromChild(bytes memory message) internal override {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == REWARDS_CLAIM) {
            _processRewardsClaim(syncData);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }
}