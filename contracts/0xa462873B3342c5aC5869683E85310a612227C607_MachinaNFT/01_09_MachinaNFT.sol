// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


// $$\      $$\                     $$\       $$\
// $$$\    $$$ |                    $$ |      \__|
// $$$$\  $$$$ | $$$$$$\   $$$$$$$\ $$$$$$$\  $$\ $$$$$$$\   $$$$$$\
// $$\$$\$$ $$ | \____$$\ $$  _____|$$  __$$\ $$ |$$  __$$\  \____$$\
// $$ \$$$  $$ | $$$$$$$ |$$ /      $$ |  $$ |$$ |$$ |  $$ | $$$$$$$ |
// $$ |\$  /$$ |$$  __$$ |$$ |      $$ |  $$ |$$ |$$ |  $$ |$$  __$$ |
// $$ | \_/ $$ |\$$$$$$$ |\$$$$$$$\ $$ |  $$ |$$ |$$ |  $$ |\$$$$$$$ |
// \__|     \__| \_______| \_______|\__|  \__|\__|\__|  \__| \_______|


/**
 * @title Machina NFT contract
 * @author @Xirynx
 * @notice 2 Phase NFT mint. 10k max supply.
 */
contract MachinaNFT is ERC721A("Machina", "MACH"), Ownable {
    //============================================//
    //                Definitions                 //
    //============================================//

    using ECDSA for bytes;

    enum Phase {
        NONE,
        WHITELIST,
        PUBLIC
    }

    //============================================//
    //                  Errors                    //
    //============================================//

    error AddressNotManager();
    error AddressNotWhitelisted();
    error CallerNotOrigin();
    error IncorrectPhase();
    error InsufficientETH();
    error InvalidAddress();
    error InvalidBytes();
    error InvalidString();
    error MaxMintAmountExceeded();
    error MaxSupplyExceeded();

    //============================================//
    //                  Events                    //
    //============================================//

    event UpdatedBaseURI(address indexed owner, string newURI);
    event StartedWhitelistPhase(
        uint256 indexed blockNumber,
        bytes32 merkleRoot,
        uint256 mintPrice
    );
    event StartedPublicPhase(uint256 indexed blockNumber, uint256 mintPrice);
    event WithdrawnFunds(address indexed to, uint256 indexed amount);

    //============================================//
    //                 Constants                  //
    //============================================//

    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MAX_PER_WALLET = 3;

    //============================================//
    //              State Variables               //
    //============================================//

    uint256 public mintPrice;
    bytes32 public merkleRoot;
    string internal baseURI;
    Phase public phase = Phase.NONE;
    mapping(address => bool) public managers;

    //============================================//
    //                 Modifiers                  //
    //============================================//

    /**
     * @notice Verifies that the caller is currently a manager
     * @dev Reverts if the caller is not a manager and not the contract owner
     */
    modifier onlyManager() {
        if (!managers[msg.sender] && msg.sender != owner())
            revert AddressNotManager();
        _;
    }

    //============================================//
    //              Admin Functions               //
    //============================================//

    /**
     * @notice Flips manager status of `wallet` between true and false
     * @dev Caller must be contract owner
     * @param wallet Address to set/unset as manager
     */
    function toggleManager(address wallet) external onlyOwner {
		if (address(0) == wallet) revert InvalidAddress();
        managers[wallet] = !managers[wallet];
    }

    /**
     * @notice Sets the base uri for token metadata.
     * @dev Requirements:
     *	Caller must be contract owner.
     *	`_newURI` must not be an empty string.
     * @param _newURI New base uri for token metadata.
     */
    function setBaseURI(string memory _newURI) external onlyOwner {
        if (bytes(_newURI).length == 0) revert InvalidString();
        baseURI = _newURI;
        emit UpdatedBaseURI(msg.sender, _newURI);
    }

    /**
     * @notice Starts the whitelist minting phase.
     * @dev Requirements:
     *	Caller must be contract owner.
     *	`_merkleRoot` must not be empty.
     *	emits { StartedWhitelistPhase }
     * @param _merkleRoot New root of merkle tree for whitelist mints.
     * @param _mintPrice New mint price in wei.
     */
    function startWhitelistPhase(
        bytes32 _merkleRoot,
        uint256 _mintPrice
    ) external onlyOwner {
        if (bytes32(0) == _merkleRoot) revert InvalidBytes();
        _setMintPrice(_mintPrice);
        _setMerkleRoot(_merkleRoot);
        phase = Phase.WHITELIST;
        emit StartedWhitelistPhase(block.number, _merkleRoot, _mintPrice);
    }

    /**
     * @notice Starts the public minting phase.
     * @dev Requirements:
     *	Caller must be contract owner.
     *	emits { StartedPublicPhase }
     * @param _mintPrice New mint price in wei.
     */
    function startPublicPhase(uint256 _mintPrice) external onlyOwner {
        _setMintPrice(_mintPrice);
        phase = Phase.PUBLIC;
        emit StartedPublicPhase(block.number, _mintPrice);
    }

    /**
     * @notice Stops sale entirely. No mints can be made by users other than contract owner.
     * @dev Requirements:
     *	Caller must be contract owner.
     */
    function stopSale() external onlyOwner {
        phase = Phase.NONE;
    }

    /**
     * @notice Withdraws entire ether balance in the contract to the wallet specified.
     * @dev Requirements:
     *	Caller must be contract owner.
     *	`to` must not be zero address.
     *	Contract balance should be greater than zero.
     *	emits { WithdrawnFunds }
     * @param to Address to send ether balance to.
     */
    function withdrawFunds(address to) public onlyOwner {
        if (address(0) == to) revert InvalidAddress();
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientETH();
        (bool callSuccess, ) = payable(to).call{value: balance}("");
        require(callSuccess, "Call failed");
        emit WithdrawnFunds(to, balance);
    }

    //============================================//
    //               Access Control               //
    //============================================//

    /**
     * @notice Verifies that an address forms part of the merkle tree with the current `merkleRoot`.
     * @param wallet Address to compute leaf node of merkle tree.
     * @param _merkleProof Bytes array proof to verify `wallet` is part of merkle tree.
     * @return bool True if `wallet` is part of the merkle tree, false otherwise.
     */
    function verifyWhitelist(
        address wallet,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    //============================================//
    //              Helper Functions              //
    //============================================//

    /**
     * @notice Sets the mint price for all mints.
     * @param _mintPrice New mint price in wei.
     */
    function _setMintPrice(uint256 _mintPrice) internal {
        mintPrice = _mintPrice;
    }

    /**
     * @notice Sets the merkle tree root used to verify whitelist mints.
     * @param _merkleRoot New merkle tree root.
     */
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }

    //============================================//
    //                Minting Logic               //
    //============================================//

    /**
     * @notice Mints `amount` tokens to `to` address.
     * @dev Requirements:
     *	Caller must be contract owner.
     *	`amount` must be less than or equal to 30. This avoids excessive first-time transfer fees.
     *	Total supply must be less than or equal to `MAX_SUPPLY` after mint.
     * @param to Address that will receive the tokens.
     * @param amount Number of tokens to send to `to`.
     */
    function adminMint(address to, uint256 amount) external onlyOwner {
        if (amount + _totalMinted() > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (amount > 30) revert MaxMintAmountExceeded();

        _mint(to, amount);
    }

    /**
     * @notice Mints `amount` tokens to caller's address.
     * @dev Requirements:
     *	Caller must be an externally owned account.
     *	`phase` must equal WHITELIST.
     *	Total minted must be less than or equal to `MAX_SUPPLY` after mint.
     *	Caller must not mint more tokens than `MAX_PER_WALLET` across all phases.
     *	Value sent in function call must exceed or equal `mintPrice` multiplied by `amount`.
     *	Caller must be whitelisted.
     * @param _merkleProof Proof showing caller's address is part of merkle tree specified by `merkleRoot`.
     * @param amount Amount of tokens to mint.
     */
    function whitelistMint(
        bytes32[] calldata _merkleProof,
        uint8 amount
    ) external payable {
        if (tx.origin != msg.sender) revert CallerNotOrigin();
        if (phase != Phase.WHITELIST) revert IncorrectPhase();
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_numberMinted(msg.sender) + amount > MAX_PER_WALLET) revert MaxMintAmountExceeded();
        if (msg.value < mintPrice * amount) revert InsufficientETH();
        if (!verifyWhitelist(msg.sender, _merkleProof)) revert AddressNotWhitelisted();

        _mint(msg.sender, amount);
    }

    /**
     * @notice Mints `amount` tokens to caller's address.
     * @dev Requirements:
     *	Caller must be an externally owned account.
     *	`phase` must equal PUBLIC.
     *	Total minted must be less than or equal to `MAX_SUPPLY` after mint.
     *	Caller must not mint more tokens than `MAX_PER_WALLET` across all phases.
     *	Value sent in function call must exceed or equal `mintPrice` multiplied by `amount`.
     * @param amount Amount of tokens to mint.
     */
    function publicMint(uint8 amount) external payable {
        if (tx.origin != msg.sender) revert CallerNotOrigin();
        if (phase != Phase.PUBLIC) revert IncorrectPhase();
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_numberMinted(msg.sender) + amount > MAX_PER_WALLET) revert MaxMintAmountExceeded();
        if (msg.value < mintPrice * amount) revert InsufficientETH();

        _mint(msg.sender, amount);
    }

    /**
     * @notice Burns `tokenA` and `tokenB` and mints 1 token to `minter` address.
     * @dev Requirements:
     *	Caller must be a manager.
     *	`tokenA` and `tokenB` must exist.
     * @param tokenA Token ID to burn.
     * @param tokenB Token ID to burn.
     * @param minter Address to send minted NFT to.
     */
    function burnMint(
        uint256 tokenA,
        uint256 tokenB,
        address minter
    ) external onlyManager {
        _burn(tokenA, false);
        _burn(tokenB, false);
        _mint(minter, 1);
    }

    //============================================//
    //              ERC721 Overrides              //
    //============================================//

    /**
     * @notice Overridden to return variable `baseURI` rather than constant string. Allows for flexibility to alter metadata in the future.
     * @return string the current value of `baseURI`.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}