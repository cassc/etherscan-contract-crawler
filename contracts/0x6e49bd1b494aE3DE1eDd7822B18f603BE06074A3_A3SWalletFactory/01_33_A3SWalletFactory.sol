//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

import "./IA3SWalletFactory.sol";
import "./IMerkleWhitelist.sol";
import "../libraries/A3SWalletHelper.sol";

contract A3SWalletFactory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    IA3SWalletFactory
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Token ID counter
    CountersUpgradeable.Counter public tokenIdCounter;

    // Commom meta path prefix
    string public baseMetaURI;

    // Whitelist contract's address
    address public whilelistAddress;

    // Token for fees
    address public fiatToken;

    // Number of fiat tokens to mint a wallet
    uint256 public fiatTokenFee;

    // Number of ether to mint a wallet
    uint256 public etherFee;

    // Mapping from token ID to wallet address
    mapping(uint256 => address) private _wallets;

    // Mapping from  wallet address to token ID
    mapping(address => uint256) private _walletsId;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize() public initializer {
        __ERC721_init("A3SProtocol", "A3S");
        __Ownable_init();
    }

    receive() external payable {}

    /**
     * @dev See {IA3SWalletFactory-mintWallet}.
     */
    function mintWallet(
        address to,
        bytes32 salt,
        bool useFiatToken,
        bytes32[] calldata proof
    ) external payable virtual override returns (address) {
        IMerkleWhitelist(whilelistAddress).claimWhitelist(
            address(msg.sender),
            proof
        );

        if (useFiatToken) {
            require(fiatToken != address(0), "A3S: FiatToken not set");
            IERC20Upgradeable(fiatToken).transferFrom(
                msg.sender,
                address(this),
                fiatTokenFee
            );
        } else {
            require(msg.value >= etherFee, "A3S: Not enough ether");
        }

        tokenIdCounter.increment();
        uint256 newTokenId = tokenIdCounter.current();

        address newWallet = A3SWalletHelper.deployWallet(salt);

        _mint(to, newTokenId);

        _wallets[newTokenId] = newWallet;
        _walletsId[newWallet] = newTokenId;

        emit MintWallet(to, salt, newWallet, newTokenId);

        return newWallet;
    }

    /**
     * @dev See {IA3SWalletFactory-mintWallet}.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external {
        require(tokenIds.length <= balanceOf(from), "Not enough tokens");

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // uint256 tokenId = tokens[i];
            transferFrom(from, to, tokenIds[i]);
        }
    }

    /**
     * @dev Update the base `uri` of common meta path's prefix
     */
    function updateBaseMetaURI(string calldata uri) external onlyOwner {
        baseMetaURI = uri;
    }

    /**
     * @dev Update the base `uri` of common meta path's prefix
     */
    function updateWhilelistAddress(address whitelistContract)
        external
        onlyOwner
    {
        whilelistAddress = whitelistContract;
    }

    /**
     * @dev Update fiat token for fees to `token` and the `amount` of fiat tokens to mint a wallet
     */
    function updateFee(
        address token,
        uint256 tokenAmount,
        uint256 ehterAmount
    ) external onlyOwner {
        fiatToken = token;
        fiatTokenFee = tokenAmount;
        etherFee = ehterAmount;
    }

    /**
     * @dev Withdraw `amount` of ether to the _owner
     */
    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Not enough ether");
        payable(address(owner())).transfer(amount);
    }

    /**
     * @dev Withdraw `amount` of fiat token to the _owner
     */
    function withdrawToken(uint256 amount) public onlyOwner {
        require(
            amount <= IERC20Upgradeable(fiatToken).balanceOf(address(this)),
            "Not enough token"
        );
        IERC20Upgradeable(fiatToken).transfer(owner(), amount);
    }

    /**
     * @dev See {IA3SWalletFactory-walletOf}.
     */
    function walletOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address wallet)
    {
        wallet = _wallets[tokenId];
        require(wallet != address(0), "A3S: Nonexistent token");
    }

    /**
     * @dev See {IA3SWalletFactory-walletIdOf}.
     */
    function walletIdOf(address wallet)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        tokenId = _walletsId[wallet];
        require(tokenId != 0, "A3S: Nonexistent wallet");
    }

    /**
     * @dev See {IA3SWalletFactory-walletOwnerOf}.
     */
    function walletOwnerOf(address wallet)
        public
        view
        virtual
        override
        returns (address owner)
    {
        owner = ownerOf(walletIdOf(wallet));
        require(owner != address(0), "A3S: Nonexistent wallet");
    }

    function walletListOwnerOf(address owner)
        public
        view
        returns (address[] memory)
    {
        address[] memory results = new address[](balanceOf(owner));
        uint256 id = 1;
        uint256 count = 0;
        for (; id <= tokenIdCounter.current(); id++) {
            if (ownerOf(id) == owner) {
                results[count] = walletOf(id);
                count++;
            }
        }

        return results;
    }

    /**
     * @dev See {IA3SWalletFactory-predictWalletAddress}.
     */
    function predictWalletAddress(bytes32 salt)
        external
        view
        returns (address)
    {
        return A3SWalletHelper.walletAddress(salt);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseMetaURI;
    }
}