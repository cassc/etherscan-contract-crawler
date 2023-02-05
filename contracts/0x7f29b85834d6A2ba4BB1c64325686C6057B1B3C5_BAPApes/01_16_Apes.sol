// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Bulls and Apes Project - APES
/// @author BAP Dev Team
/// @notice ERC721 for BAP ecosystem
contract BAPApes is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;

    /// @notice Max supply of Apes to be minted
    uint256 public constant MAX_SUPPLY = 10000;
    /// @notice Max minting limit during sale
    uint256 public mintLimit = 2;
    /// @notice Supply reserved for public sale
    /// @dev Return amount remaining
    uint256 public publicSupply = 3500;
    /// @notice Supply reserved for Portal Pass Exchange
    /// @dev Return amount remaining
    uint256 public reservedSupply = 5000;
    /// @notice Supply reserved for treasury and team
    /// @dev Return amount remaining

    uint256 public treasurySupply = 1500;

    /// @notice Prices for public sale
    uint256[] public tierPrices = [
        0.22 ether,
        0.27 ether,
        0.3 ether,
        0.33 ether,
        0.33 ether,
        0.37 ether
    ];

    /// @notice ERC1155 Portal Pass
    IERC1155 public portalPass;

    /// @notice Signer address for encrypted signatures
    address public secret;
    /// @notice Address of BAP treasury
    address public treasury;
    /// @notice Dead wallet to send exchanged Portal Passes
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @notice Original minting price for each Ape
    mapping(uint256 => uint256) public mintingPrice;
    /// @notice Original minting date for each Ape
    mapping(uint256 => uint256) public mintingDate;

    /// @notice Refund flag for each Ape
    mapping(uint256 => bool) public notRefundable;

    /// @notice Authorization flag for orchestrators
    mapping(address => bool) public isOrchestrator;

    /// @notice Amount minted per wallet and per tier
    mapping(address => mapping(uint256 => uint256)) public walletMinted;

    event Purchased(address operator, address user, uint256 amount);
    event PassExchanged(address operator, address user, uint256 amount);
    event Airdrop(address operator, address user, uint256 amount);
    event TraitsChanged(address user, uint256 tokenId, uint256 newTokenId);
    event Refunded(address user, uint256 tokenId);
    event MintLimitChanged(uint256 limit, address operator);

    /// @notice Deploys the contract
    /// @param portalAddress Address of portal passes
    /// @param secretAddress Signer address
    /// @dev Create ERC721 token: BAP APES - BAPAPES
    constructor(address portalAddress, address secretAddress)
        ERC721("BAP APES", "BAPAPES")
    {
        portalPass = IERC1155(portalAddress);
        secret = secretAddress;
    }

    /// @notice Check if caller is an orchestrator
    /// @dev Revert transaction is msg.sender is not Authorized
    modifier onlyOrchestrator() {
        require(isOrchestrator[msg.sender], "Operator not allowed");
        _;
    }

    /// @notice Check if the wallet is valid
    /// @dev Revert transaction if zero address
    modifier noZeroAddress(address _address) {
        require(_address != address(0), "Cannot send to zero address");
        _;
    }

    /// @notice Purchase an Ape from public supply
    /// @param to Address to send the token
    /// @param amount Amount of tokens to be minted
    /// @param tier Current tier
    function purchase(
        address to,
        uint256 amount,
        uint256 tier,
        bytes memory signature
    ) external payable {
        require(tier <= 5, "Purchase: Sale closed");
        require(amount <= publicSupply, "Purchase: Supply is over");
        require(
            amount + walletMinted[to][tier] <= mintLimit,
            "Purchase: Exceed mint limit"
        );
        require(
            amount * tierPrices[tier] == msg.value,
            "Purchase: Incorrect ETH amount"
        );

        require(
            _verifyHashSignature(
                keccak256(abi.encode(amount, tier, to)),
                signature
            ),
            "Purchase: Signature is invalid"
        );

        walletMinted[to][tier] += amount;
        publicSupply -= amount;

        mint(to, amount, tierPrices[tier]);

        emit Purchased(msg.sender, to, amount);
    }

    /// @notice Airdrop an Ape from treasury supply
    /// @param to Address to send the token
    /// @param amount Amount of tokens to be minted
    function airdrop(address to, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        require(amount <= treasurySupply, "Airdrop: Supply is over");

        treasurySupply -= amount;

        mint(to, amount, 0);

        emit Airdrop(msg.sender, to, amount);
    }

    /// @notice Exchange Portal Passes for Apes
    /// @param to Address to send the token
    /// @param amount Amount of passes to be exchanged
    function exchangePass(address to, uint256 amount) external {
        require(amount <= reservedSupply, "Pass Exchange: Supply is over");

        portalPass.safeTransferFrom(
            msg.sender,
            DEAD_ADDRESS,
            1,
            amount,
            "0x00"
        );

        reservedSupply -= amount;

        mint(to, amount, tierPrices[0]);

        emit PassExchanged(msg.sender, to, amount);
    }

    /// @notice Confirm traits changes from Trait Constructor
    /// @param tokenId Ape the be modified
    /// @dev Can only be called by authorized orchestrators
    function confirmChange(uint256 tokenId) external onlyOrchestrator {
        address owner = ownerOf(tokenId);

        _burn(tokenId);

        uint256 newId = tokenId + 10000;
        _safeMint(owner, newId);

        emit TraitsChanged(owner, tokenId, newId);
    }

    /// @notice Internal function to mint Apes, set initial price and timestamp
    /// @param to Address to send the tokens
    /// @param amount Amount of tokens to be minted
    /// @param price Price payed for each token
    function mint(
        address to,
        uint256 amount,
        uint256 price
    ) internal {
        uint256 currentSupply = totalSupply();

        require(amount + currentSupply <= MAX_SUPPLY, "Mint: Supply limit");

        for (uint256 i = 1; i <= amount; i++) {
            uint256 id = currentSupply + i;
            mintingPrice[id] = price;
            mintingDate[id] = block.timestamp;
            _safeMint(to, id);
        }
    }

    /// @notice 6-Month ETH back function
    /// @param depositAddress Address to refund the funds
    /// @param tokenId Ape ID to be refunded
    /// @dev Can only be called by authorized orchestrators during refund period
    function refund(address depositAddress, uint256 tokenId)
        external
        onlyOrchestrator
        noZeroAddress(depositAddress)
    {
        uint256 balance = mintingPrice[tokenId];
        require(balance > 0, "Refund: Original Minting Price is zero");
        require(
            !notRefundable[tokenId],
            "Refund: The token is not available for refund"
        );
        require(
            ownerOf(tokenId) == depositAddress,
            "Refund: Address is not the token owner"
        );

        _transfer(depositAddress, treasury, tokenId);

        (bool success, ) = depositAddress.call{value: balance}("");

        require(success, "Refund: ETH transafer failed");

        emit Refunded(depositAddress, tokenId);
    }

    /// @notice Change the mint limit for public sale
    /// @param newLimit new minting limit
    /// @dev Can only be called by the contract owner
    function setMintLimit(uint256 newLimit) external onlyOwner {
        mintLimit = newLimit;

        emit MintLimitChanged(newLimit, msg.sender);
    }

    /// @notice Change the Base URI
    /// @param newURI new URI to be set
    /// @dev Can only be called by the contract owner
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice Change the signer address
    /// @param secretAddress new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address secretAddress)
        external
        onlyOwner
        noZeroAddress(secretAddress)
    {
        secret = secretAddress;
    }

    /// @notice Change the treasury address
    /// @param treasuryAddress new treasury address
    /// @dev Can only be called by the contract owner
    function setTreasury(address treasuryAddress)
        external
        onlyOwner
        noZeroAddress(treasuryAddress)
    {
        treasury = treasuryAddress;
    }

    /// @notice Change the portal pass address
    /// @param portalAddress new portal pass contract
    /// @dev Can only be called by the contract owner
    function setPortalPass(address portalAddress)
        external
        onlyOwner
        noZeroAddress(portalAddress)
    {
        portalPass = IERC1155(portalAddress);
    }

    /// @notice Add new authorized orchestrators
    /// @param operator Orchestrator address
    /// @param status set authorization true or false
    /// @dev Can only be called by the contract owner
    function setOrchestrator(address operator, bool status)
        external
        onlyOwner
        noZeroAddress(operator)
    {
        isOrchestrator[operator] = status;
    }

    /// @notice Send ETH to specific address
    /// @param to Address to send the funds
    /// @param amount ETH amount to be sent
    /// @dev Can only be called by the contract owner
    function withdrawETH(address to, uint256 amount)
        public
        nonReentrant
        onlyOwner
        noZeroAddress(to)
    {
        require(amount <= address(this).balance, "Insufficient funds");

        (bool success, ) = to.call{value: amount}("");

        require(success, "withdrawETH: ETH transafer failed");
    }

    /// @notice Return Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Inherit from ERC721, return token URI, revert is tokenId doesn't exist
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /// @notice Inherit from ERC721, added check of transfer period for refund
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        _checkTransferPeriod(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Inherit from ERC721, added check of transfer period for refund
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        _checkTransferPeriod(tokenId);
        super.safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Checks transfer after allow period to invalidate refund
    function _checkTransferPeriod(uint256 tokenId) internal {
        if (
            block.timestamp > mintingDate[tokenId] + 3 hours &&
            !notRefundable[tokenId]
        ) {
            notRefundable[tokenId] = true;
        }
    }

    /// @notice Inherit from ERC721, checks if a token exists
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Verify that message is signed by secret wallet
    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}