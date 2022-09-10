//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./IERC2981.sol";
import "./IERC4906.sol";
import "./IReward.sol";

contract BabyDoge3DNFT is
    IReward,
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    IERC4906,
    IERC2981
{
    struct Royalty {
        address receiver;
        uint64 share;
    }

    string public baseURI;
    Royalty private royalty;
    address public nftStaking;


    event NftStakingSet(address);
    event RoyaltyUpdated(address royaltyReceiver, uint64 royaltyShare);


    modifier onlyNftStaking() {
        require(msg.sender == nftStaking, "Only NFT Staking");
        _;
    }


    /*
     * @notice Initializer function
     * @param baseURI_ Base token URI
     * @dev Called once for proxy initialization
     */
    function initialize(
        string memory baseURI_,
        address royaltyReceiver,
        uint64 royaltyShare
    ) initializer public {
        __UUPSUpgradeable_init();
        __ERC721_init("Baby Doge 3D", "BBD3D");
        __AccessControl_init();

        require(
            royaltyReceiver != address(0)
            && royaltyShare < 9000,
                "Invalid royalty"
        );

        baseURI = baseURI_;
        royalty = Royalty({
            receiver: royaltyReceiver,
            share: royaltyShare
        });
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /*
     * @notice Returns implementation address
     * @return Implementation address
     */
    function implementationAddress() external view returns (address){
        return _getImplementation();
    }


    /*
     * @notice Sets base URI in case of data loss
     * @param newURI New Base URI
     * @dev Only DEFAULT_ADMIN_ROLE
     * @dev Emits event according to IERC4906 standard
     */
    function setBaseURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newURI;

        emit BatchMetadataUpdate(0, 10000);
    }


    /*
     * @notice Sets NFT Staking contract address
     * @param _nftStaking NFT Staking contract address
     * @dev Can be done only once
     */
    function setNftStaking(address _nftStaking) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftStaking != address(0) && nftStaking == address(0), "Already set");
        nftStaking = _nftStaking;

        emit NftStakingSet(_nftStaking);
    }


    /*
     * @notice Sets royalty receiver and share
     * @param _nftStaking NFT Staking contract address
     * @dev Can be done only once
     */
    function setRoyalty(
        address royaltyReceiver,
        uint64 royaltyShare
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            royaltyReceiver != address(0)
            && royaltyShare < 9000,
            "Invalid royalty"
        );

        royalty = Royalty({
            receiver: royaltyReceiver,
            share: royaltyShare
        });

        emit RoyaltyUpdated(royaltyReceiver, royaltyShare);
    }


    /*
     * @notice Mints array of tokens
     * @param account Account to receive tokens
     * @param tokenIds Array of token IDs to mint
     * @dev Only NFT Staking contract can call
     */
    function mintTokens(
        address account,
        uint256[] calldata tokenIds
    ) external onlyNftStaking {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(account, tokenIds[i]);
        }
    }


    /*
     * @notice Called with the sale price by marketplace to determine the amount of royalty
     * needed to be paid to a wallet for specific tokenId
     * @param _tokenId NFT asset queried for royalty information
     * @param _salePrice Sale price of the NFT asset specified by _tokenId
     * @return receiver Address of royalty receiver
     * @return royaltyAmount Amount of royalty to send
    */
    function royaltyInfo
    (
        uint256 /*_tokenId*/,
        uint256 _salePrice
    )
    external
    view
    override
    returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        Royalty memory _royalty = royalty;
        receiver = _royalty.receiver;
        royaltyAmount = _salePrice * _royalty.share / 10000;
    }


    /*
     * @notice Called to determine interface support
     * @param interfaceId - interface ID
     * @return Does contract support interface?
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == 0x49064906 || //IERC4906
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /*
     * @param newImplementation New implementation address
     * @dev This function is called before proxy upgrade and makes sure it is authorized.
     * @dev Only DEFAULT_ADMIN_ROLE can upgrade proxy
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    virtual
    override
    onlyRole(DEFAULT_ADMIN_ROLE) {}


    /*
     * @notice Returns base URI
     * @return Base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}