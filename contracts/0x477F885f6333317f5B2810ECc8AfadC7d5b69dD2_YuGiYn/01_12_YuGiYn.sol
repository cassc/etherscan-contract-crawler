// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title ¥u-Gi-¥n 遊戯苑 NFT
 *
 * Feature overview:
 *     * Configurable sale stages with independent prices, allow lists, and mint limits
 *     * Sale stages transition based on block timestamp
 *     * User-callable minting by sending ETH
 *     * Owner-callable mass minting
 *     * Funds can be `withdraw()`n by the configurable treasury account
 *     * Base URI / contract URI is rewritable
 *     * `exists()` is public
 *     * Minting can be `pause()`d
 */
contract YuGiYn is
    Ownable,
    ReentrancyGuard,
    Pausable,
    ERC721A,
    ERC2981
{
    string public baseURI =
        "http://localhost:3000/metadata/";

    string internal _contractURI =
        "http://localhost:3000/contract-metadata";

    struct SaleStage {
        uint256 startTime;
        uint256 priceWei;
        uint256 maxPerAddress;
        bool mintable;
        bool useList;
        bytes32 merkleRoot;
        mapping(address => uint256) claimed;
    }

    SaleStage[] public stages;

    uint256 public constant MAX_SUPPLY = 8888;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address payable private _treasury;

    event TreasuryChanged(
        address indexed previousTreasury,
        address indexed newTreasury
    );

    constructor() ERC721A("YuGiYn", "YGY") {
        // 7.5% royalties to the deployer
        _setDefaultRoyalty(msg.sender, 750);
        
        // Deployer is also the treasury
        _treasury = payable(msg.sender);

        // Stage 0: Pre-sale stage (unmintable)
        stages.push();
        stages[0].startTime = 1656601200; // 2022-07-01 00:00:00 +0900
        stages[0].priceWei = 0;
        stages[0].maxPerAddress = 0;
        stages[0].mintable = false;
        stages[0].useList = false;

        // Stage 1: Whitelist sale
        stages.push();
        stages[1].startTime = 1657119600; // 2022-07-07 00:00:00 +0900
        stages[1].priceWei = 0.01 ether;
        stages[1].maxPerAddress = 2;
        stages[1].mintable = true;
        stages[1].useList = true;

        // Stage 2: Public sale
        stages.push();
        stages[2].startTime = 1659279600; // 2022-08-01 00:00:00 +0900
        stages[2].priceWei = 0.07 ether;
        stages[2].maxPerAddress = 2;
        stages[2].mintable = true;
        stages[2].useList = false;

        // Stage 3: Post-sale stage (unmintable)
        stages.push();
        stages[3].startTime = 1661958000; // 2022-09-01 00:00:00 +0900
        stages[3].priceWei = 0;
        stages[3].maxPerAddress = 0;
        stages[3].mintable = false;
        stages[3].useList = false;

        // Initial mint to deployer
        _mintERC2309(owner(), 1);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Contract-level metadata
    /// @dev Customizing the metadata for your smart contract
    /// @return A URL for the storefront-level metadata for your contract.
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**************************************************************************
     * Minting
     **************************************************************************/

    /**
     * @notice Owner-only manual minting in a sepcific quantity to a specific address
     * @param to Address to mint to
     * @param quantity Number of tokens to mint
     */
    function mint(address to, uint256 quantity) public onlyOwner whenNotPaused {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Over max supply");
        _safeMint(to, quantity);
    }

    /**
     * @notice Owner-only mass minting to specific addresses
     * @param addresses Array of addresses to mint to
     * @param quantity Each address gets this amount of tokens
     */
    function giveoutMint(address[] memory addresses, uint256 quantity) public nonReentrant onlyOwner whenNotPaused {
        require(_totalMinted() + (addresses.length * quantity) <= MAX_SUPPLY, "Over max supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity);
        }
    }

    /**
     * @return The current sale stage number, starting with 0
     */
    function stageNumber() public view returns (uint256) {
        require(stages.length > 0, "No sale stages set");
        for (uint256 num = stages.length - 1; num > 0; num--) {
            if (block.timestamp >= stages[num].startTime) {
                return num;
            }
        }
        return 0;
    }

    /**
     * @return Total number of sale stages
     */
    function totalStages() external view returns (uint256) {
        return stages.length;
    }

    /**
     * @notice Check the number of tokens a user has already claimed during a sale stage.
     * @param stageNum The stage number to check
     * @param addr The address of the user
     */
    function claimed(
        uint256 stageNum,
        address addr
    ) external view returns (uint256) {
        require(stageNum < stages.length, "Invalid stage number");
        SaleStage storage stage = stages[stageNum];
        return stage.claimed[addr];
    }

    /**
     * @notice Check the remaining number of tokens a user is allowed to mint during a sale stage.
     * @param stageNum The stage number to check
     * @param addr The address of the user
     * @param merkleProof MerkleTree proof for the user's address.
     *                    Required for allow-list sale stages.
     *                    Provide an empty array for non-allow-list sale stages.
     * @return The user's allowance
     */
    function allowance(
        uint256 stageNum,
        address addr,
        bytes32[] calldata merkleProof
    ) public view returns (uint256) {
        require(stageNum < stages.length, "Invalid stage number");
        SaleStage storage stage = stages[stageNum];
        require(stage.mintable, "Not mintable during this stage");

        if (stage.useList) {
            bytes32 leaf = keccak256(abi.encodePacked(addr));
            require(MerkleProof.verify(merkleProof, stage.merkleRoot, leaf), "Address is not in allow list");
        }

        if (stage.claimed[addr] >= stage.maxPerAddress) {
            return 0;
        } else {
            return stage.maxPerAddress - stage.claimed[addr];
        }
    }

    /**
     * @notice Minting, to be called by the user, according to the current sale stage
     * @param quantity The number of tokens to mint. Must be within user's allowance
     * @param merkleProof MerkleTree proof for the user's address.
     *                    Required for allow-list sale stages.
     *                    Provide an empty array for non-allow-list sale stages.
     */
    function saleStageMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        onlyEOA
        whenNotPaused
    {
        uint256 stageNum = stageNumber();
        SaleStage storage stage = stages[stageNum];

        require(stage.mintable, "Not mintable during this stage");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Over max supply");

        if (! stage.useList) {
            require(stage.priceWei > 0, "Price not set for public sale");
        }

        require(allowance(stageNum, msg.sender, merkleProof) >= quantity, "Requested quantity is over allowance for account");

        uint256 totalPriceWei = quantity * stage.priceWei;
        require(msg.value == totalPriceWei, "Wrong amount of ETH sent.");

        stage.claimed[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    /**************************************************************************
     * Administrative setters
     **************************************************************************/
    /**
     * @notice Set the baseURI for tokenURI()
     * @param _newBaseURI The URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set the URI for storefront-level metadata
     * @param _newContractURI The URI
     */
    function setContractURI(string calldata _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @notice Clear sale stage settings, including allow-lists and claimed counts
     */
    function clearSaleStages() external onlyOwner {
        delete stages;
    }

    /**
     * @notice Set up sale stages.
     *         Overwrites existing stages and adds new ones,
     *         but does not delete anything.
     * @param startTimeVals Start timestamps of each stage
     * @param priceWeiVals Token prices for each stage
     * @param maxPerAddressVals Per-address mint limits for each stage
     * @param mintableVals Flags for whether stages are mintable
     * @param useListVals Flags for whether stages should use allow-lists
     */
    function setSaleStages(
        uint256[] calldata startTimeVals,
        uint256[] calldata priceWeiVals,
        uint256[] calldata maxPerAddressVals,
        bool[] calldata mintableVals,
        bool[] calldata useListVals
    ) external onlyOwner {
        require(
            startTimeVals.length == priceWeiVals.length &&
            startTimeVals.length == maxPerAddressVals.length &&
            startTimeVals.length == mintableVals.length &&
            startTimeVals.length == useListVals.length,
            'Mismatched parameter lengths'
        );

        for (uint256 i = 1; i < startTimeVals.length; i++) {
            require(startTimeVals[i] > startTimeVals[i-1], 'Start time must be greater than previous');
        }

        for (uint256 i = 0; i < startTimeVals.length; i++) {
            if (i >= stages.length) {
                stages.push();
            }

            SaleStage storage stage = stages[i];
            stage.startTime = startTimeVals[i];
            stage.priceWei = priceWeiVals[i];
            stage.maxPerAddress = maxPerAddressVals[i];
            stage.mintable = mintableVals[i];
            stage.useList = useListVals[i];
        }
    }

    /**
     * @notice Set allow list addresses for a stage
     * @param stageNum The stage number
     * @param merkleRoot MerkleTree root for the allow list
     */
    function setAllowList(
        uint256 stageNum,
        bytes32 merkleRoot
    ) external onlyOwner {
        require(stageNum < stages.length, "Invalid stage number");
        SaleStage storage stage = stages[stageNum];
        require(stage.useList, "Stage does not use allow list");
        stage.merkleRoot = merkleRoot;
    }

    /**
     * @notice Alter claimed count for a stage and address
     * @param stageNum The stage number
     * @param addr The address of the user
     * @param quantity The new claimed count
     */
    function setClaimed(
        uint256 stageNum,
        address addr,
        uint256 quantity
    ) external onlyOwner {
        require(stageNum < stages.length, "Invalid stage number");
        SaleStage storage stage = stages[stageNum];
        stage.claimed[addr] = quantity;
    }

    function setTreasury(address payable newTreasury) public onlyOwner {
        require(newTreasury != address(0), "Cannot set treasury to the zero address");
        address oldTreasury = _treasury;
        _treasury = newTreasury;
        emit TreasuryChanged(oldTreasury, newTreasury);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev See https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#dont-use-transfer-or-send
     */
    function withdraw() public {
        require(msg.sender == _treasury, "Caller is not the treasury");
        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**************************************************************************
     * Utilities
     **************************************************************************/

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev Need to explicitly override this function because it is inherited
            from both ERC721A and ERC2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ERC2981 ||
        ERC721A.supportsInterface(interfaceId) ||
        super.supportsInterface(interfaceId);
    }
}