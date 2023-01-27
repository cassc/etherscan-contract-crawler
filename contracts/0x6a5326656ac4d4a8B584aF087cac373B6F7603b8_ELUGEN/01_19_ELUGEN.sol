// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

// ▄▄▄▄▄▄▄ ▄▄▄     ▄▄   ▄▄ ▄▄▄     ▄▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ 
//█       █   █   █  █ █  █   █   █       █  █  █ █      ██       █
//█    ▄▄▄█   █   █  █ █  █   █   █   ▄   █   █▄█ █  ▄    █  ▄▄▄▄▄█
//█   █▄▄▄█   █   █  █▄█  █   █   █  █▄█  █       █ █ █   █ █▄▄▄▄▄ 
//█    ▄▄▄█   █▄▄▄█       █   █▄▄▄█       █  ▄    █ █▄█   █▄▄▄▄▄  █
//█   █▄▄▄█       █       █       █   ▄   █ █ █   █       █▄▄▄▄▄█ █
//█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█▄▄█ █▄▄█▄█  █▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█

// ERC721 Smart Contract for the Lands of Elulands. Audited by ProtoStarter.io.

// First 5 person to send a screenshot of this smart contract code will get a T3 Pickaxe!
// #create-a-ticket on discord with your screenshot https://discord.gg/elulands

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ELUGEN is
    Initializable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721BurnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant WL_MAX_SUPPLY = 999;
    uint256 public constant WL_MAX_MINT_PER_WALLET = 1;

    function initialize(bytes32 _merkleRoot, uint256 _whitelistStartAt) public initializer {
        require(_merkleRoot != bytes32(0), "zero bytes32");
        require(_whitelistStartAt > 0, "zero number");

        __ERC721_init("Elulands Genesis Avatar", "ELUGEN");
        __ERC721Enumerable_init();
        __ERC721Pausable_init();
        __ERC721Burnable_init();

        __Ownable_init();

        crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

        merkleRoot = _merkleRoot;
        price = 0.01 ether;

        wlStartAt = _whitelistStartAt;
        wlDuration = 12 hours;

        _unrevealDuration = 3 days;
    }

    // contract uri used to display collection in the opensea
    string private _contractURI;
    // base uri used to display nft metadata
    string private _baseURIVal;
    // generated from list whitelist users
    bytes32 public merkleRoot;
    // mint price by eth
    uint256 public price;
    // whitelist settings
    uint256 public wlStartAt;
    uint256 public wlDuration;
    // used to unreveal nft in few days
    uint256 private _unrevealDuration;
    mapping(uint256 => uint256) private _revealAt;
    // total minted nft
    uint256 public totalMinted;
    mapping (address => uint256) public nftsMintedPerWallet;

    // crossmint.com address
    address public crossmintAddress;

    /**
     * @notice Set CrossMint Address
     *
     * @dev External function to change crossmint address. Only owner can call this function.
     * @param _crossmintAddress New crossmint address
     */
    function setCrossmintAddress(address _crossmintAddress) external onlyOwner {
        require(_crossmintAddress != address(0), "zero address");

        crossmintAddress = _crossmintAddress;
    }

    /**
     * @notice Set Merkle Root
     *
     * @dev External function to change merkle root. Only owner can call this function.
     * @param _merkleRoot New merkle root.
     */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot != bytes32(0), "zero bytes32");

        merkleRoot = _merkleRoot;
    }

    /**
     * @notice View Contract URI
     *
     * @dev External funciton to view contract URI.
     */

    function contractURI() external view returns(string memory) {
        return _contractURI;
    }

    /**
     * @notice Set Contract URI
     *
     * @dev Update contract uri for contract. Only owner can call this function.
     * @param _newContractURI New contract uri.
     */

    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Internal function to view base URI. This will be used internally by NFT library.
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseURIVal;
    }

    /**
     * @notice View Base URI
     *
     * @dev External funciton to view base URI.
     */

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Set Base URI
     *
     * @dev Update base uri for contract. Only admin can call this function.
     * @param _newBaseURI New base uri (must contains "/" at the end)
     */

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURIVal = _newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_revealAt[tokenId] > block.timestamp) {
            return "https://bafybeielszxwdorvmaon7soxcm2oba2d4kj2nni372ex76fp6jnv4haaae.ipfs.nftstorage.link/1.json";
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    /**
     * @notice Set Whitelist Start
     *
     * @dev Update whitelist start at for contract. Only owner can call this function.
     * @param _newWlStartAt New value.
     */
    function setWlStartAt(uint256 _newWlStartAt) external onlyOwner {
        require(_newWlStartAt > 0, "zero number");

        wlStartAt = _newWlStartAt;
    }

    /**
     * @notice Set Whitelist duration
     *
     * @dev Update whitelist duration for contract. Only owner can call this function.
     * @param _newWlDuration New value.
     */
    function setWlDuration(uint256 _newWlDuration) external onlyOwner {
        require(_newWlDuration > 0, "zero number");

        wlDuration = _newWlDuration;
    }

    /**
     * @notice Set Price
     *
     * @dev Update price for contract. Only owner can call this function.
     * @param _newPrice New price.
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "zero number");

        price = _newPrice;
    }

    /**
     * @notice Mint & purchase by native token
     *
     * @dev Mint new token. Only whitelist address can call this function.
     */

    function mint(uint256 _amount, uint256 _index, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(totalMinted + _amount <= MAX_SUPPLY, "MAX_SUPPLY");
        require(wlStartAt < block.timestamp, "NOT_OPEN");

        if (wlStartAt + wlDuration > block.timestamp) {
            // only allow whitelist to mint
            bytes32 node = keccak256(abi.encodePacked(_index, _msgSender()));
            require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node), "INVALID_PROOF");

            require(totalMinted + _amount <= WL_MAX_SUPPLY, "WL_MAX_SUPPLY");
            require(nftsMintedPerWallet[_msgSender()] + _amount <= WL_MAX_MINT_PER_WALLET, "WL_MAX_MINT_PER_WALLET");
        } else {
            // check fee
            require(price * _amount == msg.value, "INSUFFICIENT_BALANCE");
        }

        _multipleMint(_msgSender(), _amount);

        if (msg.value > 0) {
            payable(owner()).transfer(msg.value);
        }
    }

    /**
     * @notice Crossmint
     *
     * @dev External function to allow crossmint.com can mint NFTs
     * @param _to The recepient address
     * @param _amount Total amount to mint
     */
    function crossmint(address _to, uint256 _amount) external payable nonReentrant {
        require(_msgSender() == crossmintAddress, "ONLY_CROSSMINT");
        require(totalMinted + _amount <= MAX_SUPPLY, "MAX_SUPPLY");
        require(wlStartAt + wlDuration < block.timestamp, "NOT_OPEN");
        require(price * _amount == msg.value, "INSUFFICIENT_BALANCE");

        _multipleMint(_to, _amount);

        if (msg.value > 0) {
            payable(owner()).transfer(msg.value);
        }
    }

    /**
     * @notice Multiple Mint NFTs
     *
     * @dev Internal function to mint multiple NFT
     * @param _recepient The recepient address
     * @param _quantity Total quantity to mint
     */
    function _multipleMint(address _recepient, uint256 _quantity) internal {
        require(_recepient != address(0), "ZERO_ADDRESS");
        require(_quantity > 0, "ZERO_NUMBER");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 _tokenId = totalMinted + i + 1;
            _safeMint(_recepient, _tokenId);

            _revealAt[_tokenId] = block.timestamp + _unrevealDuration;
        }

        totalMinted = totalMinted + _quantity;
        nftsMintedPerWallet[_recepient] = nftsMintedPerWallet[_recepient] + _quantity;
    }

    /**
     * @notice Pause Contract
     *
     * @dev Only owner can call this function.
     */

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Un-pause Contract
     *
     * @dev Only owner can call this function.
     */

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * ===============================================================
     * OVERRIDE METHOD
     * ===============================================================
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}