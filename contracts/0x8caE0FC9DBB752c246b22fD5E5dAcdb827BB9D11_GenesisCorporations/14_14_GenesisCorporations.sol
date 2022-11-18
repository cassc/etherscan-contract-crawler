//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract GenesisCorporations is ERC1155SupplyUpgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;
    string public name;
    string public symbol;

    bool public isPaused;
    address public moderator;
    mapping(uint256 => string) public uris;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => uint256) public prices;

    mapping(uint256 => uint256) public mintLimitForId;
    mapping(address => mapping(uint256 => uint256)) public tokensMinted;

    event MintLimitSet(uint256 indexed id, uint256 limit);

    mapping(uint256 => bool) public usedNonce;
    address public mintingSigner;

    mapping(uint256 => uint256) public privateSalePrice;
    mapping(uint256 => bool) public publicSaleOpen;

    mapping(uint256 => uint256) public privateSaleMaxSupply;
    mapping(uint256 => uint256) public totalSaleMaxSupply;

    modifier onlyGov() {
        require(msg.sender == owner() || msg.sender == moderator, "NFT: NOT_GOVERNANCE");
        _;
    }

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC1155_init("");
        __Ownable_init();

        moderator = msg.sender;
        isPaused = true;
        name = name_;
        symbol = symbol_;
    }

    function setName(string memory name_) external onlyGov {
        name = name_;
    }

    function setSymbol(string memory symbol_) external onlyGov {
        symbol = symbol_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "NFT: WITHDRAW_FAILED");
    }

    function toggleStatus() external onlyGov {
        isPaused = !isPaused;
    }

    function setModerator(address moderator_) external onlyOwner {
        require(moderator_ != address(0), "NFT: ZERO_ADDRESS");
        moderator = moderator_;
    }

    function setMaxSupply(uint256 id, uint256 maxSupply) external onlyOwner {
        maxSupplies[id] = maxSupply;
    }

    function setSaleSupply(uint256 id, uint256 _privateSaleMaxSupply, uint256 _totalSaleMaxSupply) external onlyOwner {
        privateSaleMaxSupply[id] = _privateSaleMaxSupply;
        totalSaleMaxSupply[id] = _totalSaleMaxSupply;
    }

    function setPrice(uint256 id, uint256 _publicSalePrice, uint256 _privateSalePrice) external onlyOwner {
        prices[id] = _publicSalePrice;
        privateSalePrice[id] = _privateSalePrice;
    }

    function setURI(uint256 id, string memory uri_) external onlyGov {
        uris[id] = uri_;
    }

    function setPublicSaleOpen(uint256 id, bool _publicSaleOpen) external onlyGov {
        publicSaleOpen[id] = _publicSaleOpen;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    function currentSaleSupply(uint256 id) public view returns (uint256) {
        if (publicSaleOpen[id]) {
            return totalSaleMaxSupply[id];
        } else {
            return privateSaleMaxSupply[id];
        }
    }

    function _saleMintTo(address userAddress, uint256 id, uint256 amount) internal {
        require(totalSupply(id) + amount <= currentSaleSupply(id), "NFT: EXCEED_PRIVATE_SUPPLY");
        require(amount <= availableMints(userAddress, id), "NFT: EXCEED_MINT_LIMIT");

        tokensMinted[userAddress][id] += amount;

        _mint(userAddress, id, amount, "");
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(!isPaused, "NFT: SALE_PAUSED");
        require(publicSaleOpen[id], "NFT: NOT_PUBLIC_SALE");
        require(msg.value == prices[id] * amount, "NFT: INCORRECT_PRICE");
        _saleMintTo(msg.sender, id, amount);
    }

    function setMintLimit(uint256 id, uint256 limit) external onlyGov {
        mintLimitForId[id] = limit;
        emit MintLimitSet(id, limit);
    }

    /**
     * @dev Returns how much tokens can address mint for given token id
     * @param userAddress address for which it is checked
     * @param id token id
     * @return uint256 number of available mints, or 0 if none is available
     */
    function availableMints(address userAddress, uint256 id) public view returns(uint256) {
        int256 available = int256(mintLimitForId[id]) - int256(tokensMinted[userAddress][id]);
        if (available <= 0) {
          return 0;
        } else {
          return uint256(available);
        }
    }

    function _verifySignature(bytes memory message, bytes memory signature) private view returns (bool) {
        address signer = keccak256(message).toEthSignedMessageHash().recover(signature);
        return(signer == mintingSigner);
    }

    function setMintingSigner(address newMintingSigner) external onlyGov {
        mintingSigner = newMintingSigner;
    }

    function authorizedMint(address to, uint256 id, uint256 amount) external onlyGov {
        require(totalSupply(id) + amount <= maxSupplies[id], "NFT: EXCEED_MAX_SUPPLY");
        _mint(to, id, amount, "");
    }

    /**
     * @dev Minting list of tokenIds and it's amounts with given signature from the backend
     * @dev `mintingSigner` address must sign encoded all parameters and senders address in the following order:
     * @dev abi.encode(msg.sender, _tokenIds, _amounts, _signatureNonce)
     * @dev where `_signatureNonce` is unique value (i.e keccak256(user address,timestamp)) to ensure that
     * @dev one signature is not used multiple times
     * @param _tokenIds list of token ids to mint
     * @param _amounts amount for each token to be minted
     * @param _signatureNonce nonce which should be unique for each signature
     * @param _signature signature of all parameters by `mintingSigner` address
    */
    function mintWithSignature(
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts,
        uint256 _signatureNonce,
        bytes memory _signature
    ) external payable {
        require(!isPaused, "NFT: SALE_PAUSED");
        require(_tokenIds.length == _amounts.length, "NFT: INVALID_LENGTHS");
        require(!usedNonce[_signatureNonce], "NFT: USED_NONCE");
        require(_verifySignature(abi.encode(msg.sender, _tokenIds, _amounts, _signatureNonce), _signature), "NFT: INVALID_SIGNATURE");
        usedNonce[_signatureNonce] = true;

        uint256 sumPrices = 0;
        for(uint256 i=0; i<_tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];
            uint256 tokenPrice;
            if (publicSaleOpen[tokenId]) {
                tokenPrice = prices[tokenId];
            } else {
                tokenPrice = privateSalePrice[tokenId];
            }
            sumPrices += tokenPrice * amount;
        }
        require(msg.value == sumPrices, "NFT: INCORRECT_PRICE");

        for(uint256 i=0; i<_tokenIds.length; i++) {
            _saleMintTo(msg.sender, _tokenIds[i], _amounts[i]);
        }
    }
}