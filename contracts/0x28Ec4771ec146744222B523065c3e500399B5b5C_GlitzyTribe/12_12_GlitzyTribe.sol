// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GlitzyTribe Mint Contract
contract GlitzyTribe is ERC721, Ownable {
    using Strings for uint256;

    using ECDSA for bytes32;

    string public baseURI;

    // Stages
    // 1: OG Group
    // 2: OG/WL Group
    // 3: Public Sale
    // Others: Closed

    // General Mint Settings
    uint256 public _mintOffset = 1; // Token ID offset
    uint256 public tokenIndex = 0;
    uint8 public stage;

    // WL Settings
    enum WhitelistType {
        OG,
        Whitelist
    }
    address private signerAddress;

    // OG Mint Settings
    uint256 public ogMintPrice = 0.08 ether; // OG Sale Mint Price
    mapping(address => uint256) public ogMintCount;

    // Whitelist Mint Settings
    uint256 public whitelistMintPrice = 0.1 ether; // Private Sale Mint Price
    mapping(address => uint256) public whitelistMintCount;

    // Public Sale Mint Settings
    uint256 public nonBonusMaxSupply = 1500;
    uint256 public publicMintPrice = 0.12 ether;

    // Bonus Mint Settings
    mapping(address => uint256) public bonusMintCount;
    uint256 public bonusMaxSupply = 300;
    uint256 public _bonusOffset = 1501;
    uint256 public bonusMintIndex = 0;
    uint256 public bonusMintsRequirement = 5; // How many mints to get 1 bonus mint

    // Treasury
    address public treasury;

    // Events
    event PublicMint(address indexed to, uint256 amount);
    event DevMint(uint256 count);

    // Modifiers

    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "GlitzyTribe: must use EOA");
        _;
    }

    constructor(
        address _owner,
        address _signerAddress,
        string memory _baseURI
    ) ERC721("GlitzyTribe", "GT") {
        setBaseURI(_baseURI);
        setTreasury(_owner);
        setSignerAddress(_signerAddress);

        transferOwnership(_owner);
    }

    // -------------------- MINT FUNCTIONS --------------------------
    /**
     * @notice OG List Mint
     * @param _mintAmount Amount that is minted
     */
    function ogMint(uint256 _mintAmount, bytes memory signature)
        external
        payable
        onlyEOA
    {
        // Check if ogMint is open
        require(stage == 1, "GlitzyTribe: OG Mint is not open");
        // Check if user is whitelisted
        require(
            whitelistSigned(WhitelistType.OG, msg.sender, signature),
            "GlitzyTribe: Invalid Signature!"
        );

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * ogMintPrice,
            "GlitzyTribe: Insufficient ETH!"
        );

        // Check if mints does not exceed nonBonusMaxSupply
        require(
            tokenIndex + _mintAmount <= nonBonusMaxSupply,
            "GlitzyTribe: Max Supply for Normal Mint Reached!"
        );

        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenIndex + _mintOffset);
            tokenIndex++;
        }

        ogMintCount[msg.sender] += _mintAmount;
        bonusMintCount[msg.sender] += _mintAmount;

        uint256 bonusMints = bonusMintsAvailable(msg.sender);

        if (bonusMints > 0) {
            bonusMint(bonusMints);
        }
    }

    /**
     * @notice Whitelist Mint

     * @param _mintAmount Amount that is minted
     */
    function whitelistMint(uint256 _mintAmount, bytes memory signature)
        external
        payable
        onlyEOA
    {
        // Check if user is whitelisted
        require(
            whitelistSigned(WhitelistType.Whitelist, msg.sender, signature),
            "GlitzyTribe: Invalid Signature!"
        );

        // Check if whitelist sale is open
        require(stage == 2, "GlitzyTribe: Whitelist Mint is not open");

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * whitelistMintPrice,
            "GlitzyTribe: Insufficient ETH!"
        );

        // Check if mints does not exceed nonBonusMaxSupply
        require(
            tokenIndex + _mintAmount <= nonBonusMaxSupply,
            "GlitzyTribe: Max Supply for Normal Mint Reached!"
        );

        whitelistMintCount[msg.sender] += _mintAmount;

        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenIndex + _mintOffset);
            tokenIndex++;
        }

        bonusMintCount[msg.sender] += _mintAmount;

        uint256 bonusMints = bonusMintsAvailable(msg.sender);

        if (bonusMints > 0) {
            bonusMint(bonusMints);
        }
    }

    /**
     * @notice Public Mint
     * @param _mintAmount Amount that is minted
     */
    function publicMint(uint256 _mintAmount) external payable onlyEOA {
        // Check if public sale is open
        require(stage == 3, "GlitzyTribe: Public Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * publicMintPrice,
            "GlitzyTribe: Insufficient ETH!"
        );

        // Check if mints does not exceed nonBonusMaxSupply
        require(
            tokenIndex + _mintAmount <= nonBonusMaxSupply,
            "GlitzyTribe: Max Supply for Normal Mint Reached!"
        );

        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenIndex + _mintOffset);
            tokenIndex++;
        }
        bonusMintCount[msg.sender] += _mintAmount;

        uint256 bonusMints = bonusMintsAvailable(msg.sender);

        if (bonusMints > 0) {
            bonusMint(bonusMints);
        }
    }

    /**
     * @notice Available Bonus Mint
     */
    function bonusMintsAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return bonusMintCount[userAddress] / bonusMintsRequirement;
    }

    /**
     * @notice Bonus Mint
     */
    function bonusMint(uint256 _mintAmount) internal {
        // Check if mints does not exceed bonus max supply
        require(
            bonusMintIndex + _mintAmount <= bonusMaxSupply,
            "GlitzyTribe: Bonus max supply reached!"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, bonusMintIndex + _bonusOffset);
            bonusMintIndex++;
        }

        bonusMintCount[msg.sender] -= bonusMintsRequirement * _mintAmount;
    }

    /**
     * @notice Dev Mint
     * @param _mintAmount Amount that is minted
     */
    function devMintNormal(uint256 _mintAmount) external onlyOwner {
        require(
            tokenIndex + _mintAmount <= nonBonusMaxSupply,
            "GlitzyTribe: Max Supply of Normal Mint Reached!"
        );
        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenIndex + _mintOffset);
            tokenIndex++;
        }
    }

    /**
     * @notice Dev Mint Bonus
     * @param _mintAmount Amount that is minted
     */
    function devMintBonus(uint256 _mintAmount) external onlyOwner {
        require(
            bonusMintIndex + _mintAmount <= bonusMaxSupply,
            "GlitzyTribe: Bonus max supply reached!"
        );
        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(msg.sender, bonusMintIndex + _bonusOffset);
            bonusMintIndex++;
        }
    }

    /**
     * @notice Airdrop
     * @param _addresses List of addresses
     */
    function airdrop(address[] memory _addresses) external onlyOwner {
        require(
            tokenIndex + _addresses.length <= nonBonusMaxSupply,
            "GlitzyTribe: Max Supply of Normal Mint Reached!"
        );

        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], tokenIndex + _mintOffset);
            tokenIndex++;
        }
    }

    // -------------------- WHITELIST FUNCTION ----------------------

    /**
     * @dev Checks if the the signature is signed by a valid signer for whitelist
     * @param whitelistType Type of whitelist
     * @param sender Address of minter
     * @param signature Signature generated off-chain
     */
    function whitelistSigned(
        WhitelistType whitelistType,
        address sender,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(whitelistType, sender));
        return
            signerAddress ==
            ECDSA.toEthSignedMessageHash(_hash).recover(signature);
    }

    // ---------------------- VIEW FUNCTIONS ------------------------
    function totalSupply() public view returns (uint256) {
        return tokenIndex + bonusMintIndex;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    // ------------------------- OWNER FUNCTIONS ----------------------------

    /**
     * @dev Set stage of minting
     */
    function setStage(uint8 _newStage) public onlyOwner {
        stage = _newStage;
    }

    /**
     * @dev Set signer address for WL minting
     */
    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    /**
     * @dev Set Bonus Mint Requirement
     */
    function setBonusMintRequirement(uint256 _newRequirement) public onlyOwner {
        bonusMintsRequirement = _newRequirement;
    }

    /**
     * @dev Set mint offset
     */
    function setMintOffset(uint256 _offset) public onlyOwner {
        _mintOffset = _offset;
    }

    /**
     * @dev Set bonus offset
     */
    function setBonusOffset(uint256 _offset) public onlyOwner {
        _bonusOffset = _offset;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Withdraw all ETH from this account to the owner
     */
    function withdrawFund() external onlyOwner {
        (bool success, ) = payable(treasury).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    /**
     * @notice Sets the treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Sets the NonBonusMaxSupply
     */
    function setNonBonusMaxSupply(uint256 _nonBonusMaxSupply) public onlyOwner {
        nonBonusMaxSupply = _nonBonusMaxSupply;
    }

    /**
     * @notice Sets the BonusMaxSupply
     */
    function setBonusMaxSupply(uint256 _bonusMaxSupply) public onlyOwner {
        bonusMaxSupply = _bonusMaxSupply;
    }
}