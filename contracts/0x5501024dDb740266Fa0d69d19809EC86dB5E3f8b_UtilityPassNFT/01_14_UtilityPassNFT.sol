// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GenesisContractAbi {
    function isSoldOut() external view returns (bool) {}
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract UtilityPassNFT is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Address for address payable;
    using Strings for uint256;

    // Keep in sync with number in GenesisNft
    uint256 public constant PRICE = 0.045 ether;

    string public baseTokenURI =
        "ipfs://QmTfpzSejJcKtzz4gePUWnZkBLjSQ6eCapgdnAm3g72hXD/";
    address public genesisAddress;
    GenesisContractAbi private genesisContract;
    uint256 public tokenCount = 0;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    uint256 private royaltyDivisor = 20;

    uint256 public giveawaySupply = 50;
    uint256 public supply = 9595;
    uint256 public mintableSupply = supply - giveawaySupply;

    address public withdrawDest1 = 0x2102AE12dED4A8cc8321e656Ca213d3Eaf6151C4;
    address public withdrawDest2 = 0x218B622bbe4404c01f972F243952E3a1D2132Dec;

    constructor(
        address _genesisAddress,
        address _openSeaProxyRegistryAddress,
        uint256 _supply,
        uint256 _giveawaySupply
    ) ERC721("Psychedelics Anonymous Component #1", "PA") {
        genesisAddress = _genesisAddress;
        genesisContract = GenesisContractAbi(_genesisAddress);
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        supply = _supply;
        giveawaySupply = _giveawaySupply;
        mintableSupply = _supply - _giveawaySupply;
    }

    // Override so the openzeppelin tokenURI() method will use this method to
    // create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    ///
    /// Mint
    //

    // Private mint function, does not check for payment
    function _mintPrivate(address _to, uint256 _amount) private {
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, ++tokenCount);
        }
    }

    function mintGenesisSoldOut(uint256 _amount)
        public
        payable
        onlyExternal
        nonReentrant
    {
        require(genesisContract.isSoldOut(), "Genesis not sold out");
        // Assumes giveaways will be done after minting
        require(tokenCount + _amount <= mintableSupply, "Not enough supply");
        require(msg.value == PRICE * _amount, "Ether sent is not correct");
        require(_amount > 0, "Must mint at least 1 NFT");
        require(_amount < 3, "Minting limits exceeded");

        _mintPrivate(msg.sender, _amount);
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        require(
            msg.sender == genesisAddress,
            "Only genesis NFT contract can mint"
        );
        require(_amount < 3, "Minting limits exceeded");

        // Assumes giveaways will be done after minting
        if (tokenCount + _amount > mintableSupply) {
            // Don't throw, just return so genesis minting will succeed
            return false;
        }

        _mintPrivate(_to, _amount);
        return true;
    }

    ///
    /// Setters
    ///
    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function setGenesisAddress(address _genesisAddress) public onlyOwner {
        genesisAddress = _genesisAddress;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setOpenSeaProxyRegistryAddress(
        address _openSeaProxyRegistryAddress
    ) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function setRoyaltyDivisor(uint256 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setWithdrawDests(address _dest1, address _dest2) public onlyOwner {
        withdrawDest1 = _dest1;
        withdrawDest2 = _dest2;
    }

    ///
    /// Modifiers
    ///
    modifier onlyExternal() {
        require(msg.sender == tx.origin, "Contracts not allowed to mint");

        _;
    }

    ///
    /// Giveaway
    ///
    function giveaway(address _to, uint256 _amount) external onlyOwner {
        require(tokenCount + _amount <= supply, "Not enough supply");
        require(_amount < giveawaySupply, "Giving away too many NFTs");
        require(_amount > 0, "Amount must be greater than zero");

        _mintPrivate(_to, _amount);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    ///
    /// Withdrawal
    ///
    function withdraw() public onlyOwner {
        require(address(this).balance != 0, "Balance is zero");

        payable(withdrawDest1).sendValue(address(this).balance / 20);
        payable(withdrawDest2).sendValue(address(this).balance);
    }

    ///
    /// Misc
    ///

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), salePrice / royaltyDivisor);
    }
}