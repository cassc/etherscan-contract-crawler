// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC2771Context, Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {FxBaseRootTunnel} from "./tunnel/FxBaseRootTunnel.sol";
import {IAcorneCommon} from "./interfaces/IAcorneCommon.sol";
import {IAcorneRenderer} from "./interfaces/IAcorneRenderer.sol";
import {NativeMetaTransaction} from "./common/NativeMetaTransaction.sol";

/**
 * @title Acorne
 * @custom:website www.acorne.io
 * @author @ThePlagueNFT
 * @notice Acorne E2E NFT. L2 Polygon based state sync protocol
 */
contract Acorne is
    DefaultOperatorFilterer,
    FxBaseRootTunnel,
    IAcorneCommon,
    ERC2981,
    ERC2771Context,
    NativeMetaTransaction,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    /// @dev Sync actions
    bytes32 public constant MINTED = keccak256("MINTED");
    bytes32 public constant COMMISSION_CLAIM = keccak256("COMMISSION_CLAIM");

    /// @dev The FRG WL merkle root
    bytes32 public frgMerkleRoot;

    /// @dev The ETH WL merkle root
    bytes32 public ethMerkleRoot;

    /// @dev Treasury
    address public treasury =
        payable(0xB39AF34781a55404803b1d087c113Dc787E229eF);

    /// @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 701;

    /// @notice ETH mint price
    uint256 public price = 0.11 ether;

    /// @notice Mint live timestamp
    uint256 public liveAt = 1673100000;

    /// @notice Mint expires timestamp
    uint256 public expiresAt = 1673791200;

    /// @notice Public mint is open
    bool public isPublicOpen = false;

    /// @notice $FRG token address
    address public frgTokenAddress;

    /// @notice An address mapping mints
    mapping(address => bool) public addressToMinted;

    /// @notice A mapping from token id to commission structure
    mapping(uint256 => Commission) public commissions;

    /// @notice The rendering library contract
    IAcorneRenderer public renderer;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _acorneRenderer,
        address _frgTokenAddress,
        address _trustedForwarder
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        ERC2771Context(_trustedForwarder)
        ERC721A("Acorne", "ACORNE")
    {
        _mintERC2309(treasury, 1); // Placeholder mint
        _setDefaultRoyalty(treasury, 1000);
        renderer = IAcorneRenderer(_acorneRenderer);
        frgTokenAddress = _frgTokenAddress;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier canMintWhitelist(
        uint256 _amount,
        bytes32 _merkleRoot,
        bytes32[] calldata _proof
    ) {
        require(isLive(), "Mint is not active.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        require(!addressToMinted[_msgSenderERC721A()], "Already minted.");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        require(
            MerkleProof.verify(_proof, _merkleRoot, leaf),
            "Invalid proof."
        );
        _;
    }

    modifier canMintPublic(uint256 _amount) {
        require(isPublicOpen, "Public mint is not active.");
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        _;
    }

    modifier isCorrectPrice(uint256 _amount, uint256 _price) {
        require(msg.value >= _amount * _price, "Not enough funds.");
        _;
    }

    /**************************************************************************
     * Minting
     *************************************************************************/

    /**
     * @dev Public mint function
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _amount
    ) external payable isCorrectPrice(_amount, price) canMintPublic(_amount) {
        _mintSync(_msgSenderERC721A(), _amount);
    }

    /**
     * @dev Whitelist mint function
     * @param _proof The generated merkel proof
     */
    function whitelistMint(
        bytes32[] calldata _proof
    )
        external
        payable
        isCorrectPrice(1, price)
        canMintWhitelist(1, ethMerkleRoot, _proof)
    {
        _mintSync(_msgSenderERC721A(), 1);
    }

    /**
     * @dev Public FRG mint function that works based of whitelist and the ERC20 FRG token
     * @param _proof The generated merkel proof
     */
    function mintWithFRG(
        uint256 _frgAmount,
        bytes32[] calldata _proof
    ) external payable canMintWhitelist(1, frgMerkleRoot, _proof) {
        address owner = _msgSenderERC721A();
        IERC20(frgTokenAddress).transferFrom(owner, address(this), _frgAmount);
        _mintSync(owner, 1);
    }

    function claim(uint256 tokenId) external payable nonReentrant {
        address owner = ownerOf(tokenId);
        require(
            _msgSenderERC721A() == owner,
            "Operation restricted to token owner."
        );

        // Process commissions
        Commission storage instance = commissions[tokenId];
        uint256 commissionAmount = instance.value;
        require(commissionAmount > 0, "No commissions to claim.");

        // Process transfer
        (bool success, ) = payable(owner).call{value: commissionAmount}("");
        require(success, "Unable to claim rewards.");

        // Reset commission claim
        commissions[tokenId] = Commission({
            value: 0,
            lastClaimedAt: block.timestamp,
            lastClaimedAddress: owner
        });

        emit Claim(tokenId, owner, commissionAmount);
    }

    /**
     * @dev Internal helper function for minting and syncing to L2
     * @param _address The mint address
     * @param _amount The amount mint
     */
    function _mintSync(address _address, uint256 _amount) internal {
        uint256 tokenId = _nextTokenId();
        addressToMinted[_address] = true;
        _mint(_address, _amount);
        // Initialize commission claims
        for (uint256 i = 0; i < _amount; i++) {
            commissions[tokenId + i] = Commission({
                value: 0,
                lastClaimedAt: block.timestamp,
                lastClaimedAddress: _address
            });
            // Send message to child chain via portal
            _sendMessageToChild(
                abi.encode(MINTED, abi.encode(_address, tokenId))
            );
        }
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt && block.timestamp < expiresAt;
    }

    /**
     * @notice Returns the current commission details for a token id
     * @param _tokenId The address
     */
    function getCommission(
        uint256 _tokenId
    ) external view returns (Commission memory) {
        return commissions[_tokenId];
    }

    /**
     * @notice Returns all commission details for a batch of token ids
     * @param _tokenIds The array of addresses
     */
    function getCommissions(
        uint256[] memory _tokenIds
    ) external view returns (Commission[] memory) {
        Commission[] memory allCommissions = new Commission[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            allCommissions[i] = commissions[_tokenIds[i]];
        }
        return allCommissions;
    }

    /**
     * @notice Returns current mint state for a particular address
     * @param _address The address
     */
    function getMintState(
        address _address
    ) external view returns (MintState memory) {
        return
            MintState({
                isPublicOpen: isPublicOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                frgMerkleRoot: frgMerkleRoot,
                ethMerkleRoot: ethMerkleRoot,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                price: price,
                hasMinted: addressToMinted[_address]
            });
    }

    /**
     * @notice The token uri for a given tokenId, pulls in commission data
     * @param _tokenId the token id of NFT
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return renderer.tokenURI(_tokenId, commissions[_tokenId].value);
    }

    /**
     * @notice Deposit ERC20 tokens into contract
     * @param _tokenContract The token contract to transfer
     * @param _amount The amount of token to transfer
     */
    function depositERC20(
        address _tokenContract,
        uint256 _amount
    ) external payable {
        IERC20(_tokenContract).transferFrom(
            _msgSenderERC721A(),
            address(this),
            _amount
        );
        emit DepositERC20(
            _tokenContract,
            _msgSenderERC721A(),
            address(this),
            _amount
        );
    }

    /// @notice Deposit ETH funds into contract
    function deposit() external payable {
        emit Deposit(_msgSenderERC721A(), address(this), msg.value);
    }

    /**************************************************************************
     * Admin
     *************************************************************************/

    /**
     * @notice Sets the commission value for a particular token
     * @dev EMERGENCY fallback - renounce ownership to remove this control
     * @param _tokenId The token id
     * @param _amount The amount to set
     */
    function setCommissionValue(
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        commissions[_tokenId] = Commission({
            value: _amount,
            lastClaimedAt: block.timestamp,
            lastClaimedAddress: _msgSenderERC721A()
        });
        emit CommissionManuallySet(_msgSenderERC721A(), _tokenId, _amount);
    }

    /**
     * @notice Sets whether the public mint is open
     * @param _isPublicOpen true/false value of whether the public mint is open
     */
    function setIsPublicOpen(bool _isPublicOpen) external onlyOwner {
        isPublicOpen = _isPublicOpen;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets eth price
     * @param _price The price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the ETH merkle root for the mint
     * @param _ethMerkleRoot The merkle root to set
     */
    function setETHMerkleRoot(bytes32 _ethMerkleRoot) external onlyOwner {
        ethMerkleRoot = _ethMerkleRoot;
    }

    /**
     * @notice Sets the FRG merkle root for the mint
     * @param _frgMerkleRoot The merkle root to set
     */
    function setFRGMerkleRoot(bytes32 _frgMerkleRoot) external onlyOwner {
        frgMerkleRoot = _frgMerkleRoot;
    }

    /**
     * @notice Sets the FRG token address
     * @param _frgTokenAddress The FRG token address
     */
    function setFRGTokenAddress(address _frgTokenAddress) external onlyOwner {
        frgTokenAddress = _frgTokenAddress;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Changes the contract defined royalty
     * @param _receiver - The receiver of royalties
     * @param _feeNumerator - The numerator that represents a percent out of 10,000
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice Sets the rendering library contract
     * @dev only owner call this function
     * @param _renderingAddress The new contract address
     */
    function setRenderingAddress(address _renderingAddress) external onlyOwner {
        renderer = IAcorneRenderer(_renderingAddress);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
        emit Withdraw(address(this), treasury, balance);
    }

    /*
     * @notice Withdraws a generic ERC20 token from contract
     * @param _to The address to withdraw FRG to
     */
    function withdrawERC20(
        address _tokenContract,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenContract).transfer(_to, _amount);
    }

    /*
     * @notice Withdraws FRG from contract to a specific address
     * @param _to The address to withdraw FRG to
     */
    function withdrawFRG(address _to) public onlyOwner {
        uint256 balance = IERC20(frgTokenAddress).balanceOf(address(this));
        withdrawERC20(frgTokenAddress, _to, balance);
    }

    /**
     * @dev Admin mint function
     * @param _to The address to mint to
     * @param _amount The amount to mint
     */
    function adminMint(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "Max mint reached.");
        _mintSync(_to, _amount);
    }

    /**************************************************************************
     * L2 State Sync
     *************************************************************************/

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(
        address _fxChildTunnel
    ) public override onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * Adds commission value for a particular token id
     * @param _tokenId - The token id of the nft
     * @param _value - The value to add onto the commission in ETH
     */
    function _processCommissionClaim(
        uint256 _tokenId,
        uint256 _value
    ) internal {
        require(_value > 0, "Invalid value provided");
        commissions[_tokenId].value += _value;
        emit CommissionAdded(_tokenId, _value);
    }

    /**
     * Handles a message
     * @param _message - the message in bytes
     */
    function _handleMessage(bytes memory _message) internal {
        (bytes32 action, bytes memory data) = abi.decode(
            _message,
            (bytes32, bytes)
        );
        if (action == COMMISSION_CLAIM) {
            (uint256 tokenId, uint256 value) = abi.decode(
                data,
                (uint256, uint256)
            );
            _processCommissionClaim(tokenId, value);
        } else {
            revert("INVALID_ACTION_TYPE");
        }
    }

    /// @dev TEST
    //    function _processMessageFromChildTest(
    //        bytes memory message
    //    ) external onlyOwner {
    //        _handleMessage(message);
    //    }

    function _processMessageFromChild(bytes memory message) internal override {
        _handleMessage(message);
    }

    /**************************************************************************
     * Royalties
     *************************************************************************/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**************************************************************************
     * Meta Transaction Integration
     *************************************************************************/

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}