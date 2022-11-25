// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**----------------------------------------------------------------
   __  ___     ___            __           _  __     __  _         
  /  |/  /_ __/ _ |_  _____ _/ /____ _____/ |/ /__ _/ /_(_)__  ___ 
 / /|_/ / // / __ | |/ / _ `/ __/ _ `/ __/    / _ `/ __/ / _ \/ _ \
/_/  /_/\_, /_/ |_|___/\_,_/\__/\_,_/_/ /_/|_/\_,_/\__/_/\___/_//_/
       /___/                                                       
 ----------------------------------------------------------------*/

/// @author Gen3 Studios
/// Version 1.0.0
contract MyAvatarNationPass is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public baseURI;

    // General Mint Settings
    uint256 public GUARDIAN_MAX_SUPPLY = 111;
    uint256 public CITIZEN_MAX_SUPPLY = 999;
    uint256 public guardiansMinted;
    uint256 public citizensMinted;

    // Guardian Sale Settings
    uint256 public guardianMintPrice = 1 ether;
    mapping(address => uint256) public guardianMintedPerWallet;
    uint256 public guardianMintLimitPerWallet = 2;

    // Citizen Sale Settings
    uint256 public citizenMintPrice = 0.25 ether;
    mapping(address => uint256) public citizenMintedPerWallet;
    uint256 public citizenMintLimitPerWallet = 3;

    // Stage
    uint8 public stage;

    // Off-chain whitelist
    address private signerAddress;
    address private citizenSignerAddress;

    // Events
    event GuardianMint(address indexed to, uint256 amount);
    event CitizenMint(address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initBaseURI,
        address _newOwner,
        address _signerAddress,
        address _citizenSignerAddress
    ) ERC721A(name_, symbol_) {
        setBaseURI(_initBaseURI);
        setSignerAddress(_signerAddress);
        setCitizenSignerAddress(_citizenSignerAddress);
        transferOwnership(_newOwner);
    }

    // -------------------- MINT FUNCTIONS --------------------------

    /**
     * @notice Guardian Mint
     * Price: 1 ETH
     * Whitelisted Addresses Only
     * @param signature Signature given by signer
     */
    function guardianMint(
        uint256 _mintAmount,
        bytes memory signature
    ) external payable {
        // Check if guardian sale is open
        require(stage == 1, "MyAvatarNationPass: Guardian Sale Closed!");

        // Check if user is whitelisted
        require(
            whitelistSigned(msg.sender, signature),
            "MyAvatarNationPass: Invalid Signature!"
        );

        // Check if enough ETH is sent
        require(
            msg.value == guardianMintPrice * _mintAmount,
            "MyAvatarNationPass: Insufficient ETH for Guardian Mint!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            guardiansMinted + _mintAmount <= GUARDIAN_MAX_SUPPLY,
            "MyAvatarNationPass: Max Supply for Guardian Mint Reached!"
        );

        // Check if user has not exceeded mint limit
        require(
            guardianMintedPerWallet[msg.sender] + _mintAmount <=
                guardianMintLimitPerWallet,
            "MyAvatarNationPass: Exceeded Guardian Mint Limit!"
        );

        _safeMint(msg.sender, _mintAmount);
        guardiansMinted += _mintAmount;
        guardianMintedPerWallet[msg.sender] += _mintAmount;
        emit GuardianMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Citizen Whitelist Mint
     * Price: 0.25 ETH
     * Whitelisted Addresses Only
     * @param signature Signature given by signer
     */
    function citizenWhitelistMint(
        uint256 _mintAmount,
        bytes memory signature
    ) external payable {
        // Check if citizen sale is open
        require(
            stage == 2,
            "MyAvatarNationPass: Citizen Whitelist Sale Closed!"
        );

        // Check if user is whitelisted
        require(
            whitelistSignedCitizen(msg.sender, signature),
            "MyAvatarNationPass: Invalid Signature!"
        );

        // Check if enough ETH is sent
        require(
            msg.value == citizenMintPrice * _mintAmount,
            "MyAvatarNationPass: Insufficient ETH for Citizen Mint!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            citizensMinted + _mintAmount <= CITIZEN_MAX_SUPPLY,
            "MyAvatarNationPass: Max Supply for Citizen Mint Reached!"
        );

        // Check if user has not exceeded mint limit
        require(
            citizenMintedPerWallet[msg.sender] + _mintAmount <=
                citizenMintLimitPerWallet,
            "MyAvatarNationPass: Exceeded Citizen Mint Limit!"
        );

        _safeMint(msg.sender, _mintAmount);
        citizensMinted += _mintAmount;
        citizenMintedPerWallet[msg.sender] += _mintAmount;
        emit CitizenMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Citizen Mint
     * Price: 0.25 ETH
     * @param _mintAmount Amount that is minted
     */
    function citizenMint(uint256 _mintAmount) external payable {
        // Check if citizen sale is open
        require(stage == 3, "MyAvatarNationPass: Citizen Mint Closed!");

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * citizenMintPrice,
            "MyAvatarNationPass: Insufficient ETH for Citizen Mint!"
        );

        // Check if citizen mints does not exceed CITIZEN_MAX_SUPPLY
        require(
            citizensMinted + _mintAmount <= CITIZEN_MAX_SUPPLY,
            "MyAvatarNationPass: Max Supply for Citizen Mint Reached!"
        );

        // Check if user has not exceeded mint limit
        require(
            citizenMintedPerWallet[msg.sender] + _mintAmount <=
                citizenMintLimitPerWallet,
            "MyAvatarNationPass: Exceeded Citizen Mint Limit!"
        );

        _safeMint(msg.sender, _mintAmount);
        citizensMinted += _mintAmount;
        citizenMintedPerWallet[msg.sender] += _mintAmount;
        emit CitizenMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Dev Mint
     * @param _mintAmount Amount that is minted
     */
    function devMint(uint256 _mintAmount) external onlyOwner {
        _safeMint(owner(), _mintAmount);
    }

    /**
     * @notice Airdrop
     * @param _addresses List of addresses
     * @param _mintAmounts List of mint amounts
     */
    function airdrop(
        address[] memory _addresses,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        require(
            _addresses.length == _mintAmounts.length,
            "MyAvatarNationPass: Array length incorrect!"
        );

        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _mintAmounts[i]);
        }
    }

    // -------------------- WHITELIST FUNCTION ----------------------

    /**
     * @dev Checks if the the signature is signed by a valid signer for whitelists
     * @param sender Address of minter
     * @param signature Signature generated off-chain
     */
    function whitelistSigned(
        address sender,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(sender));
        return
            signerAddress ==
            ECDSA.toEthSignedMessageHash(_hash).recover(signature);
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for citizen whitelists
     * @param sender Address of minter
     * @param signature Signature generated off-chain
     */
    function whitelistSignedCitizen(
        address sender,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(sender));
        return
            citizenSignerAddress ==
            ECDSA.toEthSignedMessageHash(_hash).recover(signature);
    }

    // ---------------------- VIEW FUNCTIONS ------------------------
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    // ------------------------- OWNER FUNCTIONS ----------------------------

    /**
     * @dev Set Private Sale Status
     */
    function setStage(uint8 _stage) public onlyOwner {
        stage = _stage;
    }

    /**
     * @dev Set Signer Address for guardian mint
     */
    function setSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    /**
     * @dev Set Signer Address for citizen mint
     */
    function setCitizenSignerAddress(address _signer) public onlyOwner {
        citizenSignerAddress = _signer;
    }

    /**
     * @dev Set Citizen Price
     */
    function setCitizenMintPrice(uint256 _price) public onlyOwner {
        citizenMintPrice = _price;
    }

    /**
     * @dev Set Citizen Mint Limit Per Wallet
     */
    function setCitizenMintLimitPerWallet(uint256 _limit) public onlyOwner {
        citizenMintLimitPerWallet = _limit;
    }

    /**
     * @dev Set Max Citizen Supply
     */
    function setCitizenMaxSupply(uint256 _maxSupply) public onlyOwner {
        CITIZEN_MAX_SUPPLY = _maxSupply;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Withdraw Function which splits the ETH to `fundRecipients`
     * @dev requires currentBalance of contract to have some amount
     * @dev withdraws with the fixed define distribution
     */
    function withdrawFund() public onlyOwner {
        //final address receives remainder to prevent ether dust
        _withdraw(owner(), address(this).balance);
    }

    /**
     * @dev private function utilized by withdrawFund
     * @param _addr Address of receiver
     * @param _amt Amount to withdraw
     */
    function _withdraw(address _addr, uint256 _amt) private {
        (bool success, ) = _addr.call{value: _amt}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Returns the starting token ID.
     * MAN - Override to start from tokenID 1
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Multicall for ownerOf
     */
    function ownersOf(
        uint256[] memory tokenIds
    ) public view returns (address[] memory owners) {
        // Need to have fixed length array for multicall
        owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owners[i] = ownerOf(tokenIds[i]);
        }
    }
}