// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "./ChaosPacks.sol";
import "./external/interfaces/ISplitMain.sol";
import "./external/erc721a/extensions/ERC721ABurnable.sol";
import "./BatchShuffle.sol";
import "./Royalties/ERC2981/IERC2981Royalties.sol";

error CallerIsNotTokenOwner();
error PacksDisabledUntilSuperchargedComplete();
error SuperchargedOffsetAlreadySet();
error SuperchargeConfigurationNotReady();
error SuperchargedOffsetNotSet();
error InvalidOffset();
error BurnPackFailed();
error PackContractLocked();

/// @title Chaos Songs
/// @notice Distribute random selection of 4 songs to Chaos Pack holders
contract ChaosSongs is
    ERC721ABurnable,
    Ownable,
    BatchShuffle,
    IERC2981Royalties
{
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using Strings for uint256;

    uint256 constant SONG_COUNT = 4; /* Number of songs minted on pack open*/
    uint32 constant SUPERCHARGED_SUPPLY = 1e3; /* Number of supercharged songs*/
    uint16 constant PACK_SUPPLY = 5e3; /*Supply of packs determines number of offsets*/

    uint256 public royaltyPoints; /*Royalty percentage / 10000*/

    uint256 public superchargedOffset; /*Track offset for first 1000 NFTs separately*/

    ChaosPacks public packContract; /*External contract to use for pack NFTs*/
    bool public packContractLocked; /*Allow pack contract to be locked against further change*/

    /*Liquid splits config*/
    address payable public immutable payoutSplit; /* 0xSplits address for split */
    ISplitMain public splitMain; /* 0xSplits address for updating & distributing split */
    uint32 public distributorFee; /* 0xSplits distributorFee payable to third parties covering gas of distribution */
    mapping(address => uint32) public superchargeBalances; /*Track supercharged balance separately for liquid splits*/

    /*Contract config*/
    string public contractURI; /*contractURI contract metadata json*/
    string public baseURI; /*baseURI_ String to prepend to token IDs*/

    event PackOpened(uint256 _id, address _opener);

    /// @notice Constructor sets contract metadata configurations and split interfaces
    /// @param baseURI_ Base URI for token metadata
    /// @param _contractURI URI for marketplace contract metadata
    /// @param _splitMain Address of splits contract for sending royalties
    /// @param _distributorFee Optional fee to compensate address calling distribute, offset gas
    /// @param _royaltyPoints BP of royalties to send to song contract
    constructor(
        string memory baseURI_,
        string memory _contractURI,
        address _splitMain,
        uint256 _royaltyPoints,
        uint32 _distributorFee
    )
        ERC721A("Chaos", "\u0024SONGS")
        BatchShuffle(PACK_SUPPLY, SONG_COUNT, SUPERCHARGED_SUPPLY)
    {
        baseURI = baseURI_; /*Set token level metadata*/
        contractURI = _contractURI; /*Set marketplace metadata*/

        splitMain = ISplitMain(_splitMain); /*Establish interface to splits contract*/

        // create dummy mutable split with this contract as controller;
        // recipients & distributorFee will be updated on first payout
        address[] memory recipients = new address[](2);
        recipients[0] = address(0);
        recipients[1] = address(1);
        uint32[] memory percentAllocations = new uint32[](2);
        percentAllocations[0] = uint32(500000);
        percentAllocations[1] = uint32(500000);
        payoutSplit = payable(
            splitMain.createSplit(
                recipients,
                percentAllocations,
                0,
                address(this)
            )
        );
        distributorFee = _distributorFee; /*Set optional fee for calling distribute*/

        royaltyPoints = _royaltyPoints; /*Set royalty amount out of 10000*/
    }

    /*****************
    EXTERNAL MINTING FUNCTIONS
    *****************/
    /// @dev Burn packs and receive 4 song NFTs in exchange
    /// @param _packIds Packs owned by sender
    function batchOpenPack(uint256[] calldata _packIds) external {
        for (uint256 index = 0; index < _packIds.length; index++) {
            _openPack(_packIds[index]);
        }
    }

    /// @dev Burn a pack and receive 4 song NFTs in exchange
    /// @param _packId Pack owned by sender
    function openPack(uint256 _packId) external {
        _openPack(_packId);
    }

    /// @dev Burn a pack and receive 4 song NFTs in exchange
    /// @param _packId Pack owned by sender
    function _openPack(uint256 _packId) internal {
        if (packContract.ownerOf(_packId) != msg.sender)
            /*Only pack owner can open pack*/
            revert CallerIsNotTokenOwner();

        if (superchargedOffset == 0)
            /*Pack opening disabled until supercharged tokens are configured*/
            revert PacksDisabledUntilSuperchargedComplete();

        if (!packContract.burnPack(_packId)) revert BurnPackFailed(); /*Opening a pack burns the pack NT*/
        _mintSongs(msg.sender, _currentIndex); /*Mint 4 songs to opener*/

        emit PackOpened(_packId, msg.sender);
    }

    /*****************
    Permissioned Minting
    *****************/

    /// @dev Mint the supercharged tokens to proper destination
    /// @param _to Recipient
    /// @param _amount Number of tokens to send
    function mintSupercharged(address _to, uint256 _amount) external onlyOwner {
        _mintSupercharged(_to, _amount);
    }

    /// @dev Mint the supercharged tokens to proper destination in batches
    /// @param _tos Recipients
    /// @param _amounts Numbers of tokens to send
    function batchMintSupercharged(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (_tos.length != _amounts.length) revert LengthMismatch();
        for (uint256 index = 0; index < _tos.length; index++) {
            _mintSupercharged(_tos[index], _amounts[index]);
        }
    }

    /*****************
    RNG Config
    *****************/
    /// @notice Set the offset using on chain entropy for the reserve minted tokens
    /// @dev Should be done AFTER distribution, BEFORE pack opening
    ///     In rare case that offset is 0, fail transaction and allow owner to rerun
    function setSuperchargedOffset() external onlyOwner {
        if (superchargedOffset != 0) revert SuperchargedOffsetAlreadySet(); /*Can only be set once*/
        if (totalSupply() != SUPERCHARGED_SUPPLY)
            /*Must be done after supercharge minting is complete before pack opening*/
            revert SuperchargeConfigurationNotReady();

        uint256 _seed = uint256(blockhash(block.number - 1)); /*Use prev block hash for pseudo randomness*/

        superchargedOffset = _seed % SUPERCHARGED_SUPPLY; /*Mod seed by supply to get offset*/
        if (superchargedOffset == 0) revert InvalidOffset(); /*Fail the transaction if we get 0*/
    }

    /*****************
    Internal RNG functions
    *****************/
    /// @dev Get the token ID to use for URI of a token ID
    /// @param _tokenId Token to check
    function getSongTokenId(uint256 _tokenId) public view returns (uint256) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken(); /*Only return for minted tokens*/
        uint256 _shuffledTokenId; /*Initialize shuffled token ID*/

        /*If not supercharged use individual offsets*/
        if (_tokenId >= SUPERCHARGED_SUPPLY) {
            _shuffledTokenId = getShuffledTokenId(_tokenId);
        } else {
            /*If supercharged use the supercharged offset*/
            if (superchargedOffset == 0) revert SuperchargedOffsetNotSet(); /*Require that offset is set for this to return*/
            _shuffledTokenId =
                (superchargedOffset + _tokenId) %
                SUPERCHARGED_SUPPLY; /*Supercharged offset is same for all tokens*/
        }

        return _shuffledTokenId;
    }

    /*****************
    INTERNAL MINTING FUNCTIONS AND HELPERS
    *****************/
    function _mintSongs(address _to, uint256 _offsetIndex) internal {
        _safeMint(_to, SONG_COUNT);

        uint256 _seed = uint256(blockhash(block.number - 1)); /*Use prev block hash for pseudo randomness*/
        _setNextOffset(_offsetIndex, _seed);
    }

    /// @dev Mint the supercharged tokens to proper destination - internal utility
    /// @param _to Recipient
    /// @param _amount Number of tokens to send
    function _mintSupercharged(address _to, uint256 _amount) internal {
        if ((totalSupply() + _amount > SUPERCHARGED_SUPPLY))
            revert MaxSupplyExceeded(); /*Revert if max supply exceeded*/
        _safeMint(_to, _amount); /*Batch mint*/
    }

    /*****************
    DISTRIBUTION FUNCTIONS
    *****************/

    /// @notice distributes ETH to supercharged NFT holders
    /// @param accounts Ordered, unique list of supercharged NFT tokenholders
    /// @param distributorAddress Address to receive distributorFee
    function distributeETH(
        address[] calldata accounts,
        address distributorAddress
    ) external {
        uint256 numRecipients = accounts.length;
        uint32[] memory percentAllocations = new uint32[](numRecipients);
        for (uint256 i = 0; i < numRecipients; ) {
            percentAllocations[i] =
                (superchargeBalances[accounts[i]] * 1e6) /
                SUPERCHARGED_SUPPLY;
            unchecked {
                ++i;
            }
        }

        // atomically deposit funds into split, update recipients to reflect current supercharged NFT holders,
        // and distribute
        payoutSplit.safeTransferETH(address(this).balance);
        splitMain.updateAndDistributeETH(
            payoutSplit,
            accounts,
            percentAllocations,
            distributorFee,
            distributorAddress
        );
    }

    /// @notice distributes ERC20s to supercharged NFT holders
    /// @param accounts Ordered, unique list of supercharged NFT tokenholders
    /// @param token ERC20 token to distribute
    /// @param distributorAddress Address to receive distributorFee
    function distributeERC20(
        address[] calldata accounts,
        ERC20 token,
        address distributorAddress
    ) external {
        uint256 numRecipients = accounts.length;
        uint32[] memory percentAllocations = new uint32[](numRecipients);
        for (uint256 i = 0; i < numRecipients; ) {
            percentAllocations[i] =
                (superchargeBalances[accounts[i]] * 1e6) /
                SUPERCHARGED_SUPPLY;
            unchecked {
                ++i;
            }
        }

        // atomically deposit funds into split, update recipients to reflect current supercharged NFT holders,
        // and distribute
        token.safeTransfer(payoutSplit, token.balanceOf(address(this)));
        splitMain.updateAndDistributeERC20(
            payoutSplit,
            token,
            accounts,
            percentAllocations,
            distributorFee,
            distributorAddress
        );
    }

    /*****************
    CONFIG FUNCTIONS
    *****************/

    /// @notice Set the contract with packs to burn upon opening
    /// @dev reverts if locked
    /// @param _packContract New contract address
    function setPackContract(address _packContract) external onlyOwner {
        if (packContractLocked) revert PackContractLocked();
        packContract = ChaosPacks(_packContract);
    }

    /// @notice Lock pack contract against further changes
    function lockPackAddress() external onlyOwner {
        if (packContractLocked) revert PackContractLocked();
        packContractLocked = true;
    }

    /// @notice Set new base URI
    /// @dev only possible before supercharged offset is set
    /// @param baseURI_ String to prepend to token IDs
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @notice Set new contract URI
    /// @param _contractURI Contract metadata json
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice Set distributorFee as owner
    /// @param _distributorFee 0xSplits distributorFee payable to third parties covering gas of distribution
    function setDistributorFee(uint32 _distributorFee) external onlyOwner {
        distributorFee = _distributorFee;
    }

    /// @notice Set royalty points
    /// @param _royaltyPoints Royalty percentage / 10000
    function setRoyaltyPoints(uint256 _royaltyPoints) external onlyOwner {
        royaltyPoints = _royaltyPoints;
    }

    /*****************
    Public view interfaces
    *****************/
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        uint256 _shuffled = getSongTokenId(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _shuffled.toString(), ".json")
                )
                : "";
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        override(IERC2981Royalties)
        returns (address _receiver, uint256 _royaltyAmount)
    {
        return (address(this), (_value * royaltyPoints) / 10000);
    }

    /*****************
    Hooks
    *****************/
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (startTokenId < SUPERCHARGED_SUPPLY) {
            require(to != address(0)); /*Disallow burning of supercharged tokens*/
            if (from != address(0)) {
                superchargeBalances[from] -= uint32(quantity);
            }
            superchargeBalances[to] += uint32(quantity);
        }
    }

    receive() external payable {}
}