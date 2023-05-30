// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BlankBase is ERC721, Ownable {
    /// @dev Addresses that can approve restricted mints
    address internal freeMintApprover = 0xb681cFf9A2Ed00756A7144afd9378455751b0A8e;
    address internal blankApprover = 0x074631a146ABF0103453507094084f29982F7e0e;
    address internal reserveApprover = 0x3a192C386db33C3d65c1a34dBE562860A61BEA4b;

    /// @dev Infos of the Gen2 contract
    address internal gen2Contract;

    /// @notice Mint configuration
    uint256 public constant MINT_PRICE = 0.29 ether;
    uint256 public constant GENESIS_SUPPLY = 400;
    uint256 public constant DEV_SUPPLY = 4;
    uint256 public constant FREE_SUPPLY = 25;
    uint256 public constant GEN2_SUPPLY = 3200; // 12800 divided by 4;

    /// @notice Mint start timestamp
    uint256 public mintStartTimestamp = 1653987600; // May 31st 2022, 10AM BST
    uint256 public whitelistMintDuration = 12 hours;

    /// @notice Mint counters for subgroups with dedicated supply
    uint256 public devMints;
    uint256 public freeMints;
    uint256 public gen2Mints;

    /// @dev Modifier to ensure the message signer is the one expected
    modifier isMintApproved(address approver, bytes calldata signature) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender))
            )
        );
        require(
            ECDSA.recover(hash, signature) == approver,
            "You have not been approved for this mint"
        );
        _;
    }

    /// @dev Modifier to ensure the caller hasn't already minted
    modifier canStillMint() {
        require(!hasMinted(msg.sender), "You can only mint once"); // YOMO: You Only Mint Once
        _;
    }

    /// @dev Modifier to ensure the max supply won't be exceeded by a genesis mint transaction
    modifier hasTokenSupply(uint256 supply) {
        require(_currentIndex < supply, "Mint supply reached");
        _;
    }

    /// @dev Modifier to ensure the max supply won't be exceeded by a genesis mint transaction
    modifier hasSubgroupSupply(uint256 supply, uint256 current) {
        require(current < supply, "Mint supply reached for this category");
        _;
    }

    /// @dev Modifier that checks that the mint has started and that devs have already minted token 0
    modifier mintHasStarted() {
        require(
            block.timestamp >= mintStartTimestamp && _currentIndex > 0,
            "Mint has not started"
        );
        _;
    }

    /// @dev Modifier that checks that the reserve list can mint
    modifier reserveHasStarted() {
        require(
            block.timestamp >= mintStartTimestamp + whitelistMintDuration && _currentIndex > 0,
            "Reserve Mint has not started"
        );
        _;
    }


    /// @dev Modifier to ensure the right amount has been sent (no more, no less)
    modifier hasTheRightAmount() {
        require(msg.value == MINT_PRICE, "You must send the right amount");
        _;
    }

    /// @dev Modifier to ensure the call was made by the Gen2 contract
    modifier onlyGen2Contract() {
        require(msg.sender == gen2Contract, "Caller must be Blank Gen 2");
        _;
    }

    /// @dev Contract constructor. Initializes the base URI that serves Metadata
    constructor() ERC721("Blank.", "BLNK") {
        _baseURI = "https://api.blankstudio.art/metadata/";
    }

    /// @notice Update the base URI that serves the Metadata
    function setBaseURI(string calldata uri) public onlyOwner {
        _baseURI = uri;
    }

    /// @notice Change the Freemint Approver
    function setFreeMintApprover(address approver) public onlyOwner {
        require(approver != freeMintApprover, "Nothing to change");
        freeMintApprover = approver;
    }

    /// @notice Change the BlankList Approver
    function setBlankApprover(address approver) public onlyOwner {
        require(approver != blankApprover, "Nothing to change");
        blankApprover = approver;
    }

    /// @notice Change the Reserve Approver
    function setReserveApprover(address approver) public onlyOwner {
        require(approver != reserveApprover, "Nothing to change");
        reserveApprover = approver;
    }

    /// @notice Updates the mint start timestamp
    function setMintStartTimestamp(uint256 timestamp) public onlyOwner {
        mintStartTimestamp = timestamp;
    }

    /// @notice Sets the address of the Gen2 contract
    function setGen2(address gen2) public onlyOwner
    {
        require(gen2Contract == address(0), "Gen2 was already initialized");
        gen2Contract = gen2;
    }

    /// @notice
    function withdraw()
    public
    onlyOwner
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "I'm Broke!");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Get Blanked!");
    }
}