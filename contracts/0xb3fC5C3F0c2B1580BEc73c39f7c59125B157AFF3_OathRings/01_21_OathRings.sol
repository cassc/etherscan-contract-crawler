// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'hardhat/console.sol';
import { IOathRingsDescriptor } from './interfaces/IOathRingsDescriptor.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';

contract OathRings is IERC2981, Ownable, ERC721Enumerable {
    error InvalidAddress();
    event PaymentReceived(address from, uint256 amount);
    event EthWithdrawn(address to, uint256 amount);
    event TokensWithdrawn(address token, address to, uint256 amount);

    using Strings for uint256;
    using Counters for Counters.Counter;
    mapping(address => bool) private isMinter;

    uint256 private constant COUNT_OFFSET = 1;
    Counters.Counter private totalCount;
    Counters.Counter private councilCount;
    Counters.Counter private guildCount;

    address private royaltyPayout;
    bool private isOpenSeaProxyActive = true;

    // seller fee basis points 1000 == 10%
    uint16 public sellerFeeBasisPoints = 1000;
    uint256 public totalOathRings;
    uint256 public councilQuantity;
    uint256 public guildQuantity;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;
    IOathRingsDescriptor public oathRingsDescriptor;

    // IPFS content hash of contract-level metadata
    string private contractURIHash = 'ipfs://bafkreigbu5fdkic4bmmvwahr7q7m2dgbc5r2jfdwlkpvjyxp6zq7svqx54';

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev
     * @param openSeaProxyRegistry_ address for OpenSea proxy.
     * @param oathRingsDescriptor_ address for nft descriptor.
     * @param councilQuantity_	total number of council tokens
     * @param guildQuantity_	total number of guild Token
     */
    constructor(
        address openSeaProxyRegistry_,
        address oathRingsDescriptor_,
        uint256 councilQuantity_,
        uint256 guildQuantity_
    ) ERC721('funDAOmental Oath Rings', 'OATHRINGS') {
        proxyRegistry = IProxyRegistry(openSeaProxyRegistry_);
        oathRingsDescriptor = IOathRingsDescriptor(oathRingsDescriptor_);

        // set total max supply
        totalOathRings = councilQuantity_ + guildQuantity_;
        // define quantity
        councilQuantity = councilQuantity_;
        guildQuantity = guildQuantity_;

        // setup counter
        councilCount._value = COUNT_OFFSET; // start with id 1
        guildCount._value = councilQuantity + COUNT_OFFSET; // start with councilQuantity offset
        royaltyPayout = address(this);
        isMinter[_msgSender()] = true;
    }

    modifier onlyMinter() {
        require(isMinter[_msgSender()] == true, 'caller is not the minter');
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    /**
     * @dev mintCouncilOathRings
     * @notice mint council token
     * @param quantity_ quantity per mint
     */
    function mintCouncilOathRings(uint256 quantity_) public onlyMinter {
        require(councilCount.current() + quantity_ - COUNT_OFFSET <= councilQuantity, 'quantity exceeds max supply');
        for (uint256 i; i < quantity_; i++) {
            _safeMint(msg.sender, councilCount.current());
            councilCount.increment();
            totalCount.increment();
        }
    }

    /**
     * @dev mintGuildOathRings
     * @notice mint guild token
     * @param quantity_ quantity per mint
     */
    function mintGuildOathRings(uint256 quantity_) public onlyMinter {
        require(
            guildCount.current() - councilQuantity + quantity_ - 2 * COUNT_OFFSET <= guildQuantity,
            'quantity exceeds max supply'
        );

        for (uint256 i; i < quantity_; i++) {
            _safeMint(msg.sender, guildCount.current());
            guildCount.increment();
            totalCount.increment();
        }
    }

    /**
     * @dev mintToCouncilOathRings
     * @notice mint council to token
     * @param to_ address to mint
     * @param quantity_ quantity per mint
     */
    function mintToCouncilOathRings(address to_, uint256 quantity_) public onlyMinter {
        require(councilCount.current() + quantity_ - COUNT_OFFSET <= councilQuantity, 'quantity exceeds max supply');
        for (uint256 i; i < quantity_; i++) {
            _safeMint(to_, councilCount.current());
            councilCount.increment();
            totalCount.increment();
        }
    }

    /**
     * @dev mintToGuildOathRings
     * @notice mint guild to token
     * @param to_ address to mint
     * @param quantity_ quantity per mint
     */
    function mintToGuildOathRings(address to_, uint256 quantity_) public onlyMinter {
        require(
            guildCount.current() - councilQuantity + quantity_ - 2 * COUNT_OFFSET <= guildQuantity,
            'quantity exceeds max supply'
        );
        for (uint256 i; i < quantity_; i++) {
            _safeMint(to_, guildCount.current());
            guildCount.increment();
            totalCount.increment();
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ==============

    /**
     * @dev contractURI
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return contractURIHash;
    }

    /**
     * @dev getTotalOathRings
     * @notice get total oath rings
     */
    function getTotalOathRings() public view returns (uint256) {
        return totalCount.current();
    }

    /**
     * @dev getTotalCouncilOathRings
     * @notice get number of council oath rings
     */
    function getTotalCouncilOathRings() public view returns (uint256) {
        return councilCount.current() - COUNT_OFFSET;
    }

    /**
     * @dev getTotalGuildOathRings
     * @notice get number of guild oath rings
     */
    function getTotalGuildOathRings() public view returns (uint256) {
        return guildCount.current() - councilQuantity - COUNT_OFFSET;
    }

    /**
     * @dev tokenURI.
     * @notice See {IERC721Metadata-tokenURI}.
     * @param tokenId token id
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'non-existent tokenId');
        return oathRingsDescriptor.genericDataURI(tokenId.toString(), hasCouncilRole(tokenId));
    }

    /**
     * @dev isCouncilRole.
     * @notice get token Role council=True, guild=False.
     * @param tokenId token id
     */
    function hasCouncilRole(uint256 tokenId) public view returns (bool) {
        return tokenId <= councilQuantity ? true : false;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    /**
     * @notice add minter address.
     * @dev Only callable by the owner.
     */
    function addMinter(address _minter) external onlyOwner {
        if (_minter == address(0)) revert InvalidAddress();
        isMinter[_minter] = true;
    }

    /**
     * @notice remove minter address.
     * @dev Only callable by the owner.
     */
    function removeMinter(address _minter) external onlyOwner {
        if (_minter == address(0)) revert InvalidAddress();
        delete isMinter[_minter];
    }

    /**
     * @notice Set the oathRingsDescriptor.
     * @dev Only callable by the owner.
     */
    function setOathRingsDescriptor(address oathRingsDescriptor_) external onlyOwner {
        require(oathRingsDescriptor_ != address(0), 'INVALID_ADDRESS');
        oathRingsDescriptor = IOathRingsDescriptor(oathRingsDescriptor_);
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURI(string memory _contractURIHash) external onlyOwner {
        contractURIHash = _contractURIHash;
    }

    /**
     * @notice
     *  function to disable gasless listings for security in case
     *  opensea ever shuts down or is compromised
     * @dev Only callable by the owner.
     */
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) external onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    /**
     * @notice
     * set default selling fees will be interpreted if nothing
     * is specified
     * @dev Only callable by the owner.
     */
    function setSellerFeeBasisPoints(uint16 _sellerFeeBasisPoints) external onlyOwner {
        require(_sellerFeeBasisPoints <= 2500, 'Max royalty check failed! > 20%');
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
    }

    /**
     * @notice
     * set default royalty payout address if nothing
     * is specified
     * @dev Only callable by the owner.
     */
    function setRoyaltyPayout(address _royaltyPayout) external onlyOwner {
        require(_royaltyPayout != address(0), 'Zero Address not allowed');
        royaltyPayout = _royaltyPayout;
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        virtual
        override(IERC721, ERC721)
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        if (isOpenSeaProxyActive && proxyRegistry.proxies(_owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), 'non-existent tokenId');
        return (royaltyPayout, SafeMath.div(SafeMath.mul(salePrice, sellerFeeBasisPoints), 10000));
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function withdraw(address to_) public onlyOwner {
        if (to_ == address(0)) revert InvalidAddress();
        uint256 _balance = address(this).balance;
        require(_balance > 0, 'Contract balance is zero');
        payable(to_).transfer(_balance);
        emit EthWithdrawn(to_, _balance);
    }

    function withdrawTokens(IERC20 token, address to_) public onlyOwner {
        if (to_ == address(0)) revert InvalidAddress();
        uint256 _tokenBalance = token.balanceOf(address(this));
        require(_tokenBalance > 0, 'Contract Token balance is zero');
        token.transfer(to_, _tokenBalance);
        emit TokensWithdrawn(address(token), to_, _tokenBalance);
    }
}