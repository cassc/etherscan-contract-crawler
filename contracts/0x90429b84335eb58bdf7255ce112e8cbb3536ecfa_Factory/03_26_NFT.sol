// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IStorageContract.sol";

contract NFT is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuard, ERC2981Upgradeable {

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
     * @dev initialize is called by factory when deployed
     * @param _params Collection parameters
     */
    function initialize(
        Parameters memory _params
    ) external initializer {
        __ERC721_init(_params.erc721name, _params.erc721shortName);
        __Ownable_init();
        __ERC2981_init();
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
     * @notice needs a signature from trusted address in order to mint
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
     * @notice sets paying token
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