// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##(((((((((((((((#%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#(((((((((((((((((((((((((((((((((((((((%@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&((((((((((((((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@#(((((((((((((((((((((((((((((((((((((((((((((((((((%@@@@@@@@@@@@@
@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((#@@@@@@@@@@@
@@@@@@@@@@#(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%@@@@@@@@@
@@@@@@@@%(((((((((############################################((((((((((@@@@@@@@
@@@@@@@(((((((((&@@&,,,,,,,,,,,,,,,,,,,&@*,,,,,,,,,,,,,,,,,,/@@@(((((((((&@@@@@@
@@@@@@((((((((((&@@&,,,,,,,,,,,,,,,,,,,&@,,,,,,,,,,,,,,,,,,,/@@@((((((((((%@@@@@
@@@@@#((((((((((@@@&,,,,,,,,,,,,,,,,,,,&@,,,,,,,,,,,,,,,,,,,/@@@(((((((((((&@@@@
@@@@%(((((((((((@@@&,,,,,,,,,,,,,,,,,,,&@,,,,,,,,,,,,,,,,,,,/@@@((((((((((((@@@@
@@@@((((((((((((@@@@@@@@@@@@@@%,,,,,,,,@@,,,,,,,,,@@@@@@@@@@@@@@((((((((((((%@@@
@@@%((((((((((((((#########@@@%,,,,,,,,@@,,,,,,,,,@@@%########(((((((((((((((@@@
@@@#((((((((((((%@@&,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,(@@@(((((((((((((&@@
@@@#((((((((((((@@@%,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,(@@@(((((((((((((&@@
@@@%((((((((((((@@@%,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,(@@@(((((((((((((@@@
@@@&((((((((((((@@@%,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,(@@@((((((((((((#@@@
@@@@#(((((((((((@@@@@@@@@@@@@@#,,,,,,,,@@,,,,,,,,,@@@@@@@@@@@@@@((((((((((((%@@@
@@@@&((((((((((((((((((((((@@@#,,,,,,,,@@,,,,,,,,,@@@#(((((((((((((((((((((#@@@@
@@@@@%(((((((((((((((((((((@@@#,,,,,,,,@@,,,,,,,,,@@@#(((((((((((((((((((((@@@@@
@@@@@@%((((((((((((((((((((@@@#,,,,,,,,@@,,,,,,,,,@@@#((((((((((((((((((((@@@@@@
@@@@@@@&(((((((((((((((((((@@@#,,,,,,,,@@,,,,,,,,,@@@#(((((((((((((((((((@@@@@@@
@@@@@@@@@((((((((((((((((((@@@#,,,,,,,,@@,,,,,,,,,@@@#(((((((((((((((((%@@@@@@@@
@@@@@@@@@@&((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@#(((((((((((((((#@@@@@@@@@@
@@@@@@@@@@@@&(((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#(((((((((((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%((((((((((((((((((((((((((#&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%########%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**
 * @title ForeverFrogsEgg
 * @author @ScottMitchell18
 *
 */
contract ForeverFrogsEgg is ERC721AQueryable, Ownable {
    using PRBMathUD60x18 for uint256;
    using Strings for uint256;

    uint256 private constant ONE_PERCENT = 10000000000000000; // 1% (18 decimals)

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeih5mvtt4oyeosywjvqqzgxsdvgt6ignymo2mrxmxvh53dpcdn77sq/";

    // @dev The merkle root proof
    bytes32 public merkleRoot;

    // @dev Dev
    address public dev = payable(0x9FB980CB57E9d7BE6f3c626E9cD792562464aF8A);

    // @dev Treasury
    address public treasury =
        payable(0x9FB980CB57E9d7BE6f3c626E9cD792562464aF8A);

    /*
     * @notice Mint Price
     * @dev Public mint price
     */
    uint256 public price = 0.02 ether;

    /*
     * @notice Mint Live ~ August 15th, 12:15PM EST
     * @dev Public mint go live date
     */
    uint256 public liveAt = 1660580100;

    // @dev The max amount of mints per wallet (n-1)
    uint256 public maxPerWallet = 5;

    // @dev The premints flag
    bool public premintsActive = true;

    /*
     * @notice Total Supply
     * @dev The total supply of the collection (n-1)
     */
    uint256 public maxSupply = 1501;

    // @dev An address mapping for max mint per wallet
    mapping(address => uint256) public addressToMinted;

    constructor() ERC721A("Forever Frogs: The Egg", "FFEGG") {
        _mintERC2309(dev, 1); // Placeholder mint
    }

    /**
     * @notice Whitelist mint
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
    {
        require(msg.value >= _amount * price, "1");
        require(canMint(_msgSender(), _amount), "2");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "3");
        addressToMinted[_msgSender()] += _amount;
        if (_amount > 3) {
            _mint(_msgSender(), _amount + 1); // Extra free mint
        } else {
            _mint(_msgSender(), _amount);
        }
    }

    /**
     * @notice Public mint (requires whitelist being closed)
     * @dev Checks for price, whether sender can mint, mints, and adds mint count for user
     */
    function mint(uint256 _amount) external payable {
        require(!premintsActive, "0");
        require(msg.value >= _amount * price, "1");
        require(canMint(_msgSender(), _amount), "2");
        addressToMinted[_msgSender()] += _amount;
        if (_amount > 3) {
            _mint(_msgSender(), _amount + 1); // Extra free mint
        } else {
            _mint(_msgSender(), _amount);
        }
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt;
    }

    /**
     * @dev Check if wallet can mint
     * @param _address mint address lookup
     */
    function canMint(address _address, uint256 _amount)
        public
        view
        returns (bool)
    {
        return
            block.timestamp > liveAt &&
            totalSupply() + _amount < maxSupply &&
            addressToMinted[_address] + _amount < maxPerWallet;
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Airdrop eggs
     * @param _addresses An array of user addresses to airdrop eggs
     */
    function airdrop(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    /**
     * @notice Sets the Whitelist merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice A toggle switch for public sale
     * @param _maxSupply The max nft collection size
     */
    function triggerPublicSale(uint256 _maxSupply) external onlyOwner {
        delete merkleRoot;
        premintsActive = false;
        price = 0.035 ether;
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the premints active state
     * @param _premintsActive The bool of premint status
     */
    function setPremintsActive(bool _premintsActive) external onlyOwner {
        premintsActive = _premintsActive;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the go live timestamp
     * @param _liveAt A base uri
     */
    function setLiveAt(uint256 _liveAt) external onlyOwner {
        liveAt = _liveAt;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection (Keep mind its +1 n)
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets withdraw wallets
 
     * @param _dev Dev wallet
     * @param _treasury Team wallet
     */
    function setWithdrawWallets(address _dev, address _treasury)
        external
        onlyOwner
    {
        dev = payable(_dev);
        treasury = payable(_treasury);
    }

    // @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = treasury.call{value: amount.mul(ONE_PERCENT * 80)}("");
        (bool s2, ) = dev.call{value: amount.mul(ONE_PERCENT * 20)}("");
        if (s1 && s2) return;
        // fallback to owner
        (bool s4, ) = payable(_msgSender()).call{value: amount}("");
        require(s4, "Payment failed");
    }
}