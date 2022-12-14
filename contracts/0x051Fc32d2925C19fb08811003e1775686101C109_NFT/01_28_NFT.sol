// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IStorageContract.sol";

contract NFT is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuard, ERC2981Upgradeable, DefaultOperatorFiltererUpgradeable {

    using SafeERC20 for IERC20;
     
    struct Parameters {
        address storageContract;    // Address of the storage contract
        address payingToken;    // Address of ERC20 paying token or ETH address (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        uint256 mintPrice;  // Mint price
        uint256 whitelistMintPrice; // Mint price for whitelisted users
        string contractURI; // Contract URI (for OpenSea)
        string erc721name;  // The name of the collection 
        string erc721shortName; // The symbol of the collection
        bool transferable;  //  Flag if the tokens transferable or not
        uint256 maxTotalSupply; // The max amount of tokens to be minted
        address feeReceiver;    // The receiver of the royalties
        uint96 feeNumerator;    // Fee numerator
        uint256 collectionExpire;   // The period of time in which collection is expired (for the BE)
        address creator;    // Creator address
    }
    
    address public payingToken; // Current token accepted as a mint payment
    address public storageContract; // Storage contract address
    uint256 public mintPrice;   // Mint price
    uint256 public whitelistMintPrice;   // Mint price for whitelisted users
    bool public transferable;   // Flag if the tokens transferable or not
    uint256 public totalSupply; // The current totalSupply
    uint256 public maxTotalSupply;  // The max amount of tokens to be minted
    uint96 public totalRoyalty; // Royalty fraction for platform + Royalty fraction for creator
    address public creator; // Creator address
    uint256 public collectionExpire;    // The period of time in which collection is expired (for the BE)

    string public contractURI;  // Contract URI (for OpenSea)

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;  

    mapping(uint256 => string) public metadataUri;  // token ID -> metadata link
    mapping(uint256 => uint256) public creationTs;  // token ID -> creation Ts

    event PayingTokenChanged(
        address oldToken, 
        address newToken,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 oldWLPrice, 
        uint256 newWLPrice
    );

    modifier onlyCreator() {
        require(_msgSender() == creator, "not creator");
        _;
    }

    /** 
     * @dev called by factory when instance deployed
     * @param _params Collection parameters
     */
    function initialize(
        Parameters memory _params
    ) external initializer {
        __ERC721_init(_params.erc721name, _params.erc721shortName);
        __Ownable_init();
        __ERC2981_init();
        __DefaultOperatorFilterer_init();
        require(_params.payingToken != address(0), "incorrect paying token address");
        require(_params.storageContract != address(0), "incorrect storage contract address");
        require(_params.feeReceiver != address(0), "incorrect fee receiver address");
        require(_params.creator != address(0), "incorrect creator address");
        payingToken = _params.payingToken;
        mintPrice = _params.mintPrice;
        whitelistMintPrice = _params.whitelistMintPrice;
        contractURI = _params.contractURI;
        storageContract = _params.storageContract;
        transferable = _params.transferable;
        maxTotalSupply = _params.maxTotalSupply;
        _setDefaultRoyalty(_params.feeReceiver, _params.feeNumerator);
        totalRoyalty = _params.feeNumerator;
        creator = _params.creator;
        collectionExpire = _params.collectionExpire;
    }

    /** 
     * @notice Mints new NFT
     * @dev Requires a signature from the trusted address
     * @param reciever Address that gets ERC721 token
     * @param tokenId ID of a ERC721 token to mint
     * @param tokenUri Metadata URI of the ERC721 token
     * @param whitelisted A flag if the user whitelisted or not
     * @param signature Signature of the trusted address
     */
    function mint(
        address reciever,
        uint256 tokenId,
        string calldata tokenUri,
        bool whitelisted,
        bytes calldata signature,
        uint256 _expectedMintPrice,
        address _expectedPayingToken
    ) external payable nonReentrant {
        require(
            _verifySignature(reciever, tokenId, tokenUri, whitelisted, signature),
            "Invalid signature"
        );

        require(totalSupply + 1 <= maxTotalSupply, "limit exceeded");

        _mint(reciever, tokenId);
        totalSupply++;
        metadataUri[tokenId] = tokenUri;
        creationTs[tokenId] = block.timestamp;

        uint256 amount;
        address payingToken_ = payingToken;

        uint256 fee;
        uint8 feeBPs = IFactory(IStorageContract(storageContract).factory())
            .platformCommission();
        uint256 price = whitelisted ? whitelistMintPrice : mintPrice;
        require(_expectedMintPrice == price, "price changed");
        require(_expectedPayingToken == payingToken_, "token changed");

        address platformAddress = IFactory(IStorageContract(storageContract).factory()).platformAddress();
        if (payingToken_ == ETH) {
            require(msg.value == price, "Not enough ether sent");
            amount = msg.value;
            if (feeBPs == 0) {
                (bool success, ) = payable(creator).call{value: amount}("");
                require(success, "Low-level call failed");
            } else {
                fee = (amount * uint256(feeBPs)) / _feeDenominator();
                (bool success1, ) = payable(platformAddress).call{value: fee}("");
                (bool success2, ) = payable(creator).call{value: amount - fee}("");
                require(success1 && success2, "Low-level call failed");

            }
        } else {
            amount = price;
            if (feeBPs == 0) {
                IERC20(payingToken_).safeTransferFrom(msg.sender, creator, amount);
            } else {
                fee = (amount * uint256(feeBPs)) / _feeDenominator();
                IERC20(payingToken_).safeTransferFrom(msg.sender, platformAddress, fee);
                IERC20(payingToken_).safeTransferFrom(msg.sender, creator, amount - fee);
            }
        }
    }

    /** 
     * @notice Sets paying token
     * @param _payingToken New token address
     */
    function setPayingToken(
        address _payingToken, 
        uint256 _mintPrice, 
        uint256 _whitelistMintPrice
    ) external onlyCreator {
        require(_payingToken != address(0), "incorrect paying token address");
        address oldToken = payingToken;
        uint256 oldPrice = mintPrice;
        uint256 oldWLPrice = whitelistMintPrice;
        payingToken = _payingToken;
        mintPrice = _mintPrice;
        whitelistMintPrice = _whitelistMintPrice;
        emit PayingTokenChanged(
            oldToken, 
            _payingToken, 
            oldPrice, 
            _mintPrice,
            oldWLPrice,
            _whitelistMintPrice
        );
    }

    /** 
     * @notice Returns if specified interface is supported or no
     * @param interfaceId Interface ID
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return ERC2981Upgradeable.supportsInterface(interfaceId) || ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns metadata link for specified ID
     * @param _tokenId Token ID
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return metadataUri[_tokenId];
    }

    /**
     * @notice owner() function overriding for OpenSea
     */
    function owner() public view override returns (address) {
        return IFactory(IStorageContract(storageContract).factory()).platformAddress();
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     * Overridden with onlyAllowedOperatorApproval modifier to follow OpenSea royalties requirements.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     * Overridden with onlyAllowedOperatorApproval modifier to follow OpenSea royalties requirements.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     * Overridden with onlyAllowedOperator modifier to follow OpenSea royalties requirements.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     * Overridden with onlyAllowedOperator modifier to follow OpenSea royalties requirements.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     * Overridden with onlyAllowedOperator modifier to follow OpenSea royalties requirements.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Transfers the token via ERC721's _transfer() function
     * if the collection is transferrable
     * @param from Inherited from ERC721's _transfer() function
     * @param to Inherited from ERC721's _transfer() function
     * @param tokenId Inherited from ERC721's _transfer() function
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override { 
        require(transferable, "token is not transferable");
        super._transfer(from, to, tokenId);
    }

    /**
     * @dev Verifies if the signature belongs to the current signer address
     * @param receiver The token receiver
     * @param tokenId The token ID
     * @param tokenUri The token URI
     * @param whitelisted If the receiver is whitelisted or no
     * @param signature The signature to check
     */
    function _verifySignature(
        address receiver,
        uint256 tokenId,
        string memory tokenUri,
        bool whitelisted,
        bytes memory signature
    ) internal view returns (bool) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        receiver, 
                        tokenId,
                        tokenUri,
                        whitelisted,
                        block.chainid
                    )
                ), signature
            ) == IFactory(IStorageContract(storageContract).factory()).signerAddress();
    }

}