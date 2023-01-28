// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BBBBBBBGG&@@@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P!:          :[email protected]@@@&P7^.        .^?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&J.            :#@@@#7.                  :Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&!              [email protected]@@B:                        !&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@P               [email protected]@@~                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@J               [email protected]@&.                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@G               [email protected]@@.                                [email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@Y                                  #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               [email protected]@@&##########&&&&&&&&&&&#############@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&               [email protected]@@@@@@@@@@@@@#B######&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.               &@@@@@@@@@@@@@B~         .:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@B               [email protected]@@@@@@@@@@@@@@&!            .7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@Y               [email protected]@@@@@@@@@@@@@@@B.             ^#@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@G               [email protected]@@@@@@@@@@@@@@@@:              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@?              [email protected]@@@@@@@@@@@@@@@@.              ^@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@5:            [email protected]@@@@@@@@@@@@@@B               [email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^.         :[email protected]@@@@@@@@@@@@@:               #@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#######BB&@@@@@@@@@@@@@7               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@.                                 ^@@@:               [email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@Y                                 [email protected]@#               ^@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@!                               [email protected]@@:              [email protected]@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@Y                             [email protected]@@^              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&~                         !&@@&.             :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&?.                   .J&@@@?             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y~.           :!5&@@@#7          .^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGGB#&@@@@@@@@BPGGGGGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./common/SignedMessageHandler.sol";
import "./interfaces/IStoryverseCharacterPass.sol";

contract ETHSaleCharacterPass is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    SignedMessageHandler
{
    struct Sale {
        uint256 id;
        uint256 starttime; // to start immediately, set starttime = 0
        uint256 endtime;
        bool active;
        bytes32 merkleRoot; // Merkle root of the entrylist Merkle tree, 0x00 for non-merkle sale
        uint256 maxQuantity;
        uint256 price; // in Wei, where 10^18 Wei = 1 ETH
        uint256 maxNFTs;
        uint256 mintedNFTs;
        bool onlySignatureMint;
    }

    struct AdminSaleMint {
        address token;
        address recipient;
        uint256 quantity;
    }

    struct MintTokenRequest {
        address to;
        address token;
        uint256 quantity;
        uint256 nonce;
    }

    address public characterPass;

    Sale[] public sales;
    mapping(uint256 => mapping(address => uint256)) public minted; // sale ID => account => quantity

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINT_SIGNER = keccak256("MINT_SIGNER");
    bytes32 public constant MINT_HEADER = keccak256("ETHSaleCharacterPass.mint");

    /// @notice Emitted when a new sale is added to the contract
    /// @param who Admin that created the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleAdded(address who, uint256 saleId);

    /// @notice Emitted when the current sale is updated
    /// @param who Admin that updated the sale
    /// @param saleId Sale ID, will be the current sale
    event SaleUpdated(address who, uint256 saleId);

    /// @notice Emitted when new tokens are sold and minted
    /// @param who Purchaser (payer) for the tokens
    /// @param tokenAddress Token address
    /// @param to Owner of the newly minted tokens
    /// @param quantity Quantity of tokens minted
    /// @param amount Amount paid in Wei
    event Minted(address who, address tokenAddress, address to, uint256 quantity, uint256 amount);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Initializer
    /// @param _characterPass Character Pass NFT contract
    /// @param _adminAccount Account to give admin role to
    function initialize(address _characterPass, address _adminAccount) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        characterPass = _characterPass;

        _grantRole(DEFAULT_ADMIN_ROLE, _adminAccount);
        _grantRole(MINTER_ROLE, _adminAccount);
    }

    /// @notice Get the current sale
    /// @return Current sale
    function currentSale() public view returns (Sale memory) {
        require(sales.length > 0, "no current sale");
        return sales[sales.length - 1];
    }

    /// @notice Get the current sale ID
    /// @return Current sale ID
    function currentSaleId() public view returns (uint256) {
        require(sales.length > 0, "no current sale");
        return sales.length - 1;
    }

    /// @notice Adds a new sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of NFTs per account that can be sold
    /// @param _price Price of each NFT
    /// @param _maxNFTs Maximum number of NFTs that can be minted in this sale
    /// @param _onlySignatureMint If true, disable mintTo() and entryListMintTo()
    function addSale(
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _maxNFTs,
        bool _onlySignatureMint
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = sales.length;

        Sale memory sale = Sale({
            id: saleId,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            maxNFTs: _maxNFTs,
            mintedNFTs: 0,
            onlySignatureMint: _onlySignatureMint
        });

        sales.push(sale);

        emit SaleAdded(msg.sender, saleId);
    }

    /// @notice Updates the current sale
    /// @param _starttime Start time of the sale
    /// @param _endtime End time of the sale
    /// @param _active Whether the sale is active
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    /// @param _maxQuantity Maximum number of NFTs per account that can be sold
    /// @param _price Price of each NFT
    /// @param _maxNFTs Maximum number of NFTs that can be minted in this sale
    /// @param _onlySignatureMint If true, disable mintTo() and entryListMintTo()
    function updateSale(
        uint256 _starttime,
        uint256 _endtime,
        bool _active,
        bytes32 _merkleRoot,
        uint256 _maxQuantity,
        uint256 _price,
        uint256 _maxNFTs,
        bool _onlySignatureMint
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Sale memory sale = currentSale();

        Sale memory updatedSale = Sale({
            id: sale.id,
            starttime: _starttime,
            endtime: _endtime,
            active: _active,
            merkleRoot: _merkleRoot,
            maxQuantity: _maxQuantity,
            price: _price,
            maxNFTs: _maxNFTs,
            mintedNFTs: sale.mintedNFTs,
            onlySignatureMint: _onlySignatureMint
        });

        sales[sale.id] = updatedSale;

        emit SaleUpdated(msg.sender, sale.id);
    }

    /// @notice Updates the start time of the current sale
    /// @param _starttime Start time of the sale
    function updateSaleStarttime(uint256 _starttime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].starttime = _starttime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the end time of the current sale
    /// @param _endtime End time of the sale
    function updateSaleEndtime(uint256 _endtime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].endtime = _endtime;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the active status of the current sale
    /// @param _active Whether the sale is active
    function updateSaleActive(bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].active = _active;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the merkle root of the current sale
    /// @param _merkleRoot Merkle root of the entry list Merkle tree, 0x00 for non-merkle sale
    function updateSaleMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].merkleRoot = _merkleRoot;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the max quantity of the current sale
    /// @param _maxQuantity Maximum number of NFTs per account that can be sold
    function updateSaleMaxQuantity(uint256 _maxQuantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].maxQuantity = _maxQuantity;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the price of each NFT for the current sale
    /// @param _price Price of each NFT
    function updateSalePrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();
        sales[saleId].price = _price;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the  of the current sale
    /// @param _maxNFTs Maximum number of NFTs that can be minted in this sale
    function updateSaleMaxNFTs(uint256 _maxNFTs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 saleId = currentSaleId();

        sales[saleId].maxNFTs = _maxNFTs;
        emit SaleUpdated(msg.sender, saleId);
    }

    /// @notice Updates the active status of the current sale
    /// @param _onlySignatureMint If true, disable mintTo() and entryListMintTo()
    function updateSaleOnlySignatureMint(bool _onlySignatureMint)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 saleId = currentSaleId();
        sales[saleId].onlySignatureMint = _onlySignatureMint;
        emit SaleUpdated(msg.sender, saleId);
    }

    function _mintTo(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) private {
        require(_quantity > 0, "quantity must be greater than 0");
        IStoryverseCharacterPass(characterPass).mint(_tokenAddress, _to, _quantity);
        emit Minted(msg.sender, _tokenAddress, _to, _quantity, msg.value);
    }

    /// @notice Mints new passes in exchange for ETH
    /// @param _tokenAddress Token address
    /// @param _to Address to mint the Character Pass to
    /// @param _quantity Quantity of Character Passes to mint
    function mintTo(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) external payable nonReentrant {
        Sale memory sale = currentSale();

        // only proceed if no merkle root is set
        require(sale.merkleRoot == bytes32(0), "merkle sale requires valid proof");

        require(!sale.onlySignatureMint, "only signature mint allowed");

        _checkMint(sale, _quantity, sale.maxQuantity);

        sales[sale.id].mintedNFTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(_tokenAddress, _to, _quantity);
    }

    /// @notice Mints new tokens in exchange for ETH based on the sale's entry list
    /// @param _proof Merkle proof to validate the caller is on the sale's entry list
    /// @param _maxQuantity Max quantity that the caller can mint
    /// @param _tokenAddress Token address
    /// @param _to Address to mint the Character Pass to
    /// @param _quantity Quantity of Character Passes to mint
    function entryListMintTo(
        bytes32[] calldata _proof,
        uint256 _maxQuantity,
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) external payable nonReentrant {
        Sale memory sale = currentSale();

        // validate merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxQuantity));
        require(MerkleProofUpgradeable.verify(_proof, sale.merkleRoot, leaf), "invalid proof");

        require(!sale.onlySignatureMint, "only signature mint allowed");

        _checkMint(sale, _quantity, _maxQuantity);

        sales[sale.id].mintedNFTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(_tokenAddress, _to, _quantity);
    }

    /// @notice Get message that a signer need to sign to mint a token
    /// @param request Request to mint a token
    /// @return Message
    function getRequestMessage(MintTokenRequest calldata request) public view returns (bytes32) {
        return keccak256(abi.encode(MINT_HEADER, address(this), request));
    }

    /// @notice Check a Character Pass mint request
    /// @param sale Current sale
    /// @param quantity Quantity to mint
    /// @param maxQuantity Outside-of-sale max quantity to mint
    function _checkMint(
        Sale memory sale,
        uint256 quantity,
        uint256 maxQuantity
    ) private view {
        // check sale validity
        require(sale.active, "sale is inactive");
        require(block.timestamp >= sale.starttime, "sale has not started");
        require(block.timestamp < sale.endtime, "sale has ended");

        // validate payment and authorized quantity
        require(msg.value == sale.price * quantity, "incorrect payment for quantity and price");
        require(
            minted[sale.id][msg.sender] + quantity <=
                MathUpgradeable.max(sale.maxQuantity, maxQuantity),
            "exceeds allowed quantity"
        );

        // check sale supply
        require(sale.mintedNFTs + quantity <= sale.maxNFTs, "insufficient supply");
    }

    /// @notice Check the signature and mark it as used
    /// @param request Request to mint a token
    /// @param signature Signature authorizing creation of the NFT
    function _checkAndConsumeSignature(MintTokenRequest calldata request, bytes calldata signature)
        private
    {
        address signer = _consumeSigner(getRequestMessage(request), signature);
        require(hasRole(MINT_SIGNER, signer), "invalid signature");
        require(request.to == msg.sender, "msg.sender, request.to mismatch");
    }

    /// @notice Mint a Character Pass using a valid signature
    /// @param request Request to mint a token
    /// @param signature Signature authorizing creation of the NFT
    function signatureMint(MintTokenRequest calldata request, bytes calldata signature)
        external
        payable
        nonReentrant
    {
        _checkAndConsumeSignature(request, signature);
        {
            Sale memory sale = currentSale();

            // only proceed if no merkle root is set
            require(sale.merkleRoot == bytes32(0), "merkle sale requires valid proof");

            _checkMint(sale, request.quantity, sale.maxQuantity);

            sales[sale.id].mintedNFTs += request.quantity;
            minted[sale.id][msg.sender] += request.quantity;

            _mintTo(request.token, msg.sender, request.quantity);
        }
    }

    /// @notice Mint a Character Pass using a valid signature and an entry list
    /// @param request Request to mint a token
    /// @param signature Signature authorizing creation of the NFT
    function signatureEntryListMint(
        MintTokenRequest calldata request,
        bytes calldata signature,
        bytes32[] calldata _proof,
        uint256 _maxQuantity
    ) external payable nonReentrant {
        _checkAndConsumeSignature(request, signature);
        {
            Sale memory sale = currentSale();

            // validate merkle proof
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxQuantity));
            require(MerkleProofUpgradeable.verify(_proof, sale.merkleRoot, leaf), "invalid proof");

            _checkMint(sale, request.quantity, _maxQuantity);

            sales[sale.id].mintedNFTs += request.quantity;
            minted[sale.id][msg.sender] += request.quantity;

            _mintTo(request.token, msg.sender, request.quantity);
        }
    }

    function _adminSaleMintTo(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) private {
        Sale memory sale = currentSale();

        // check sale supply
        require(sale.mintedNFTs + _quantity <= sale.maxNFTs, "insufficient supply");

        sales[sale.id].mintedNFTs += _quantity;
        minted[sale.id][msg.sender] += _quantity;

        _mintTo(_tokenAddress, _to, _quantity);
    }

    /// @notice Administrative mint function within the constraints of the current sale, skipping some checks
    /// @param _tokenAddress Token address
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminSaleMintTo(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) external onlyRole(MINTER_ROLE) {
        _adminSaleMintTo(_tokenAddress, _to, _quantity);
    }

    /// @notice Administrative mint function for tuple of recipient and quantity
    /// @param mints Consist of the owner of the newly minted token and quantity of tokens to mint
    function adminSaleMultiMintTo(AdminSaleMint[] calldata mints) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < mints.length; i++) {
            AdminSaleMint memory mint = mints[i];
            _adminSaleMintTo(mint.token, mint.recipient, mint.quantity);
        }
    }

    /// @notice Administrative mint function
    /// @param _tokenAddress Token address
    /// @param _to Owner of the newly minted token
    /// @param _quantity Quantity of tokens to mint
    function adminMintTo(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // add a sale (clobbering any current sale) to ensure token ranges
        // are respected and recorded
        addSale(
            block.timestamp,
            block.timestamp,
            false,
            bytes32(0),
            0,
            2**256 - 1,
            _quantity,
            false
        );

        // record the sale as fully minted
        sales[sales.length - 1].mintedNFTs = _quantity;

        _mintTo(_tokenAddress, _to, _quantity);
    }

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_amount <= address(this).balance, "not enough funds");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
    }
}