//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721M.sol";
import "./IERC165.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//     ███╗   ███╗██╗██████╗  █████╗ ████████╗ █████╗ ███████╗██╗  ██╗██╗     //
//     ████╗ ████║██║██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║  ██║██║     //
//     ██╔████╔██║██║██████╔╝███████║   ██║   ███████║███████╗███████║██║     //
//     ██║╚██╔╝██║██║██╔══██╗██╔══██║   ██║   ██╔══██║╚════██║██╔══██║██║     //
//     ██║ ╚═╝ ██║██║██║  ██║██║  ██║   ██║   ██║  ██║███████║██║  ██║██║     //
//     ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* ==================================================================
 * 🔥 Miratashi.sol
 *
 * 👨🏽‍💻 Author: funcTh4natos
 *
 * 🎉 Special thanks goes to: VinzMIRATASHI
 * ==================================================================
 */

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

/// @custom:security-contact [email protected]
contract Miratashi is ERC721M, Ownable, ERC2981, ReentrancyGuard {
    // =============================================================
    // |                          Structs                          |
    // =============================================================

    // A structure for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    // =============================================================
    // |                         Constants                         |
    // =============================================================

    // Founder address
    address public constant FOUNDER_ADDRESS =
        0x5F3278c06135c69ce171914793584c04f4AD5054;

    // Team treasury address
    address public constant TEAM_TREASURY_ADDRESS =
        0x9F4da584027518dD170956e07B22769B1Eb30050;

    // The quantity for total mint
    uint256 public constant MINT_CAPACITY = 10000;

    // Owner will be minting this amount to the treasury which happens after
    // OG and whitelist sale. Once totalSupply() is over this amount,
    // no more can get minted by {mintTeamTreasury}
    uint256 public constant TEAM_TREASURY_SUPPLY = 1000;

    // Public mint is unlikely to be enabled as it will get botted, but if
    // is needed this will make it a tiny bit harder to bot the entire remaining.
    uint256 public constant MAX_PUBLIC_MINT_TXN_SIZE = 5;

    // =============================================================
    // |                         Storage                           |
    // =============================================================

    // This smart contract has three phases.
    // [0 = None, 10 = Sold Out]
    // [1 = Public, 2 = OG and 3 = Whitelist]
    uint8 public phase = 0;

    string public tokenBaseURI;
    string public baseURIExtension;

    // Check team treasury minted
    bool public isTeamTreasuryMinted = false;

    // Delay revealed active variable
    bool public isRevealed = false;

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators
    address public filterRegistrant;

    // Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Miratashi: The caller is another contract"
        );
        _;
    }

    // =============================================================
    // |                   Dutch Auction Storage                   |
    // =============================================================

    // Continue until Whitelist phase
    uint256 public auctionStartingTime;

    // Auction capacity
    uint256 public auctionCapacity;

    // Starting price (wei)
    uint256 public auctionStartingPrice;

    // Ending price (wei)
    uint256 public auctionEndingPrice;

    // Final auction price (wei)
    uint256 public auctionFinalPrice;

    // Auction price decrement (wei)
    uint256 public auctionPriceDecrement;

    // Decrement frequency (second)
    uint256 public auctionDecrementFrequency;

    // Auction minted count
    uint256 public auctionMinted;

    // =============================================================
    // |                      OG Phase Storage                     |
    // =============================================================

    // OG phase price (wei)
    uint256 public ogPhasePrice;

    // Starting OG phase time (seconds). Ending og phase time in 2 hours (7200 seconds)
    uint256 public ogPhaseStartingTime;
    uint256 public ogPhaseDuration;

    // OG phase wallet addresses
    mapping(address => bool) public walletOGPhase;

    // OG phase wallet mint capacity
    mapping(address => uint8) public walletOGPhaseCapacity;

    // OG phase wallet mint count
    mapping(address => uint8) public walletOGPhaseMinted;

    // OG minted count
    uint256 public ogPhaseMinted;

    // =============================================================
    // |                     Whitelist Storage                     |
    // =============================================================

    bytes32 public merkleRootWhitelist;

    // The capacity for whitelist mint
    uint256 public whitelistCapacity;

    // Whitelist price (wei)
    uint256 public whitelistPrice;

    // Starting whitelist time (seconds). Ending whitelist time in 2 hours (7200 seconds)
    uint256 public whitelistStartingTime;
    uint256 public whitelistDuration;
    uint256 public whitelistDurationGuarantee;

    // Whitelist wallet addresses
    mapping(address => uint8) public walletWhitelistMinted;

    // Whitelist minted count
    uint256 public whitelistMinted;

    // =============================================================
    // |                        Constructor                        |
    // =============================================================

    constructor() ERC721M("Miratashi", "MIRA") {
        _setDefaultRoyalty(TEAM_TREASURY_ADDRESS, 500); // Creator earnings 5%
    }

    // =============================================================
    // |                          IERC165                          |
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721M, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC721M.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // =============================================================
    // |                          IERC2981                         |
    // =============================================================

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // =============================================================
    // |                  Operator Filter Registry                 |
    // =============================================================
    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        // Expiration time represented in hours. multiply by 60 * 60, or 3600.
        if (_getExtraDataAt(tokenId) * 3600 > block.timestamp)
            revert TokenTransferLocked();
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address _registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = _registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address _newRegistrant) external onlyOwner {
        filterRegistrant = _newRegistrant;
    }

    // =============================================================
    // |                    Dutch Auction Method                   |
    // =============================================================

    /**
     * @notice Allows the people to auction a NFT.
     */
    function mintDutchAuction(uint8 _quantity) external payable callerIsUser {
        // Check if Public phase (1 = Public)
        require(phase == 1, "Miratashi: You are not in Public phase.");

        // Check capacity
        require(
            auctionMinted + _quantity <= auctionCapacity,
            "Miratashi: Over max public phase supply."
        );

        // Max supply
        require(
            _quantity <= remainingSupply(),
            "Miratashi: Over max total supply. (0 remaining)"
        );

        // Require public phase started
        require(
            block.timestamp >= auctionStartingTime,
            "Miratashi: Public phase has not begun yet."
        );

        // Require max per transaction
        require(
            _quantity <= MAX_PUBLIC_MINT_TXN_SIZE,
            "Miratashi: Over max per transaction."
        );

        // Get current price
        uint256 _currentPrice = auctionCurrentPrice();

        /// Require enough ETH
        require(
            msg.value >= _quantity * _currentPrice,
            "Miratashi: Not enough ETH."
        );

        // This calculates the final price
        if (
            auctionMinted + _quantity == auctionCapacity ||
            totalSupply() + _quantity == MINT_CAPACITY
        ) {
            auctionFinalPrice = _currentPrice;
        }

        // Saving wallet mint price data
        userToTokenBatchPriceData[msg.sender].push(
            TokenBatchPriceData(uint128(msg.value), _quantity)
        );

        auctionMinted = auctionMinted + _quantity;

        _mint(msg.sender, _quantity);
    }

    // =============================================================
    // |                  OG Phase Mint Method                     |
    // =============================================================

    /**
     * @notice Allows the OG people to mint a NFT.
     */
    function mintOG(uint8 _quantity) external payable callerIsUser {
        // Check if OG phase (2 = OG)
        require(phase == 2, "Miratashi: You are not in OG phase.");

        // Check if wallet was in OG
        require(walletOGPhase[msg.sender], "Miratashi: You are not OG.");

        // Require max capacity per transaction
        require(
            _quantity <= walletOGPhaseCapacity[msg.sender],
            "Miratashi: Over max mint capacity per transaction."
        );

        // Max address OG phase capacity
        require(
            walletOGPhaseMinted[msg.sender] + _quantity <=
                walletOGPhaseCapacity[msg.sender],
            "Miratashi: Max mint limit reached."
        );

        // Require OG Phase started
        require(
            block.timestamp >= ogPhaseStartingTime,
            "Miratashi: OG phase has not begun yet."
        );

        // Require OG Phase not ended
        require(
            block.timestamp <= (ogPhaseStartingTime + ogPhaseDuration),
            "Miratashi: OG phase was ended."
        );

        // Require enough ETH
        require(
            msg.value >= _quantity * ogPhasePrice,
            "Miratashi: Not enough ETH."
        );

        // Increase wallet addesss minted count
        walletOGPhaseMinted[msg.sender] += _quantity;

        // Increase OG Phase minted count
        ogPhaseMinted = _quantity;

        _mint(msg.sender, _quantity);
    }

    // =============================================================
    // |                   Whitelist Mint Method                   |
    // =============================================================

    /**
     * @notice Allows the whitelisted people to mint a NFT.
     */
    function mintWhitelist(
        bytes32[] calldata merkleProof
    ) external payable callerIsUser {
        // Check if Whitelist phase (3 = Whitelist)
        require(phase == 3, "Miratashi: You are not in Whitelist phase.");

        // Check if wallet was in whitelist
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRootWhitelist,
                toBytes32(msg.sender)
            ) == true,
            "Miratashi: Invalid merkle proof. (You are not Whitelist)"
        );

        // Max supply
        require(
            whitelistMinted + 1 <= whitelistCapacity,
            "Miratashi: Whitelist phase mint supply limit."
        );

        // Mint only once during the guarantee
        if (
            walletWhitelistMinted[msg.sender] > 0 &&
            block.timestamp <=
            (whitelistStartingTime + whitelistDurationGuarantee)
        ) {
            revert(
                "Miratashi: You can mint only once during the guarantee time."
            );
        }

        // Max mint 3 times
        require(
            walletWhitelistMinted[msg.sender] < 3,
            "Miratashi: Max mint limit reached."
        );

        // Require whitelist started
        require(
            block.timestamp >= whitelistStartingTime,
            "Miratashi: Whitelist phase has not begun yet."
        );

        // Require whitelist not ended
        require(
            block.timestamp <= (whitelistStartingTime + whitelistDuration),
            "Miratashi: Whitelist phase was ended."
        );

        // Require enough ETH
        require(msg.value >= whitelistPrice, "Miratashi: Not enough ETH.");

        // Increase wallet addesss minted count
        walletWhitelistMinted[msg.sender]++;

        // Increase whitelist minted count
        whitelistMinted++;

        _mint(msg.sender, 1);
    }

    // =============================================================
    // |                   External Mint Method                    |
    // =============================================================

    /**
     * @notice Allows the owner to mint from treasury supply.
     */
    function mintTeamTreasury() external onlyOwner {
        // Once time mint only
        require(
            isTeamTreasuryMinted == false,
            "Miratashi: Team treasury minted."
        );

        // Remaining supply should more than mint amount
        require(
            remainingSupply() >= TEAM_TREASURY_SUPPLY,
            "Miratashi: Team treasury mint supply limit."
        );

        isTeamTreasuryMinted = true;

        _mint(TEAM_TREASURY_ADDRESS, TEAM_TREASURY_SUPPLY);
    }

    // =============================================================
    // |                       Token Metadata                      |
    // =============================================================

    /**
     * @notice Allows the owner to set the base token URI.
     */
    function setBaseURI(
        string memory _baseURI,
        string memory _extension
    ) external onlyOwner {
        tokenBaseURI = _baseURI;
        baseURIExtension = _extension;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    tokenBaseURI,
                    Strings.toString(_tokenId),
                    baseURIExtension
                )
            );
    }

    // =============================================================
    // |                         Miscellaneous                     |
    // =============================================================

    /**
     * @notice Allows the owner to withdraw a total amount of ETH to a specified address.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = FOUNDER_ADDRESS.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    /**
     * @notice Allows the owner to set phase.
     */
    function setPhase(uint8 _numOfPhase) external onlyOwner {
        phase = _numOfPhase;
    }

    /**
     * @notice Remaining supply.
     */
    function remainingSupply() public view returns (uint256) {
        return MINT_CAPACITY - totalSupply();
    }

    /**
     * @notice Allows the owner to setup auction phase.
     */
    function setupAuction(
        uint256 _increaseCapacity,
        uint256 _price,
        uint256 _decrement,
        uint256 _frequency,
        uint256 _startTime
    ) external onlyOwner {
        require(
            (TEAM_TREASURY_SUPPLY +
                auctionCapacity +
                totalSupply() +
                _increaseCapacity) <= MINT_CAPACITY,
            "Miratashi: Over max total supply."
        );

        auctionCapacity = auctionCapacity + _increaseCapacity;
        auctionStartingPrice = _price;
        auctionPriceDecrement = _decrement;
        auctionDecrementFrequency = _frequency;
        auctionStartingTime = _startTime;
        auctionFinalPrice = 0; // Reset final price
    }

    /**
     * @notice Current price for auction phase.
     */
    function auctionCurrentPrice() public view returns (uint256) {
        // Check is auction started and phase already setup
        if (
            auctionStartingTime == 0 ||
            block.timestamp < auctionStartingTime ||
            auctionFinalPrice > 0
        ) {
            return auctionFinalPrice;
        }

        // Seconds since we started
        uint256 timeSinceStart = block.timestamp - auctionStartingTime;

        // How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart /
            auctionDecrementFrequency;

        // How much ETH to remove
        uint256 totalDecrement = decrementsSinceStart * auctionPriceDecrement;

        // If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= auctionStartingPrice - auctionEndingPrice) {
            return auctionEndingPrice;
        }

        // If not, return the starting price minus the decrement.
        return auctionStartingPrice - totalDecrement;
    }

    /**
     * @notice Allows the owner to add specified wallet address of OG to this smart contract.
     */
    function addToOG(
        address[] calldata _toAddAddresses,
        uint8[] calldata _listOfMintCapacity
    ) external onlyOwner {
        for (uint256 i = 0; i < _toAddAddresses.length; i++) {
            walletOGPhase[_toAddAddresses[i]] = true;
            walletOGPhaseCapacity[_toAddAddresses[i]] = _listOfMintCapacity[i];
        }
    }

    /**
     * @notice Allows the owner to remove specified wallet address of OG from this smart contract.
     */
    function removeFromOG(
        address[] calldata _toRemoveAddresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _toRemoveAddresses.length; i++) {
            delete walletOGPhase[_toRemoveAddresses[i]];
            delete walletOGPhaseCapacity[_toRemoveAddresses[i]];
        }
    }

    /**
     * @notice Allows the owner to setup OG phase.
     */
    function setupOGPhase(
        uint256 _newPrice,
        uint256 _startTime,
        uint256 _duration
    ) external onlyOwner {
        ogPhasePrice = _newPrice;
        ogPhaseStartingTime = _startTime;
        ogPhaseDuration = _duration;
    }

    /**
     * @notice Allows the owner to setup whitelist phase.
     */
    function setupWhitelist(
        bytes32 _merkleRoot,
        uint256 _newPrice,
        uint256 _capacity,
        uint256 _startTime,
        uint256 _duration,
        uint256 _durationGuarantee
    ) external onlyOwner {
        require(
            (TEAM_TREASURY_SUPPLY +
                auctionCapacity +
                totalSupply() +
                _capacity) <= MINT_CAPACITY,
            "Miratashi: Over max total supply."
        );

        merkleRootWhitelist = _merkleRoot;
        whitelistPrice = _newPrice;
        whitelistCapacity = _capacity;
        whitelistStartingTime = _startTime;
        whitelistDuration = _duration;
        whitelistDurationGuarantee = _durationGuarantee;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function userToTokenBatch(
        address _user
    ) public view returns (TokenBatchPriceData[] memory) {
        return userToTokenBatchPriceData[_user];
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    // Operator filter registry errors
    error OperatorNotAllowed();
    error TokenTransferLocked();
}