// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./utils/Strings.sol";

/**
 * @title Forge Token Protocol
 * @notice Mint NFTs with burnable conditions
 */

contract ForgeToken is ERC1155PresetMinterPauser {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // === V1 State Vars START ===

    Counters.Counter private _tokenIdTracker;

    IERC20 public zut;

    uint256 public ethFee;
    uint256 public zutFee;

    address payable public feeRecipient;

    string private _contractURI;
    string private _baseURI;
    mapping(uint256 => string) public ipfsHashes;
    mapping(uint256 => address) tokenCreators;

    // Storing conditions for burn
    mapping(uint256 => address) public tokenMinBalances;
    mapping(uint256 => uint256) public minBalances;
    mapping(uint256 => uint256) public expirations;

    // === V1 State Vars END ===

    constructor(
        IERC20 _zut,
        address payable _feeRecipient,
        uint256 _ethFee,
        uint256 _zutFee
    ) ERC1155PresetMinterPauser("") {
        _baseURI = "ipfs://";
        zut = _zut;
        feeRecipient = _feeRecipient;
        ethFee = _ethFee;
        zutFee = _zutFee;
    }

    /**
     * @dev only admin role modifier
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC1155PresetMinterPauser: must have admin role to mint"
        );
        _;
    }

    /**
     *** GETTERS ****
     */

    /**
     * @dev concatenate base uri and ipfs hash of token
     */
    function uri(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return Strings.strConcat(_baseURI, ipfsHashes[tokenId]);
    }

    /**
     * @dev tracks current token Id
     */
    function currentTokenId() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev contract metadata for marketplace usage
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Determine if a token can be burned, 
        checking token balances and expiration time
     */
    function canBurn(uint256 tokenId, address user)
        public
        view
        virtual
        returns (bool burnable)
    {
        if (balanceOf(user, tokenId) == 0 || tokenCreators[tokenId] == user)
            return false;

        // Condition 1: Min Balance of ERC20
        if (tokenMinBalances[tokenId] != address(0)) {
            if (
                IERC20(tokenMinBalances[tokenId]).balanceOf(user) <
                minBalances[tokenId]
            ) return true;
        }

        // Condition 2: Expiration time
        if (
            expirations[tokenId] > 0 && block.timestamp > expirations[tokenId]
        ) {
            return true;
        }
    }

    /**
     * @dev easier way to get all details for token burn conditions
     */
    function getConditions(uint256 tokenId)
        public
        view
        returns (
            address token,
            uint256 minAmount,
            uint256 expires
        )
    {
        token = tokenMinBalances[tokenId];
        minAmount = minBalances[tokenId];
        expires = expirations[tokenId];
    }

    /**
     *** SETTERS ****
     */

    function increaseTokenId() internal {
        _tokenIdTracker.increment();
    }

    /**
     * @notice Create NFT Collecions paying with ETH
     */
    function buyWithETH(
        uint256 amountTokens,
        address tokenAddress,
        uint256 minBalance,
        uint256 expiration,
        string memory ipfsHash
    ) external payable virtual {
        uint256 amountFee = ethFee.mul(amountTokens);

        require(msg.value >= amountFee, "Not enough ETH sent");

        if (expiration > 0)
            require(expiration > block.timestamp, "Time in the past");

        if (minBalance > 0)
            require(tokenAddress != address(0), "Invalid Address");

        uint256 tokenId = _tokenIdTracker.current();

        // Add token properties and conditions
        ipfsHashes[tokenId] = ipfsHash;
        tokenMinBalances[tokenId] = tokenAddress;
        minBalances[tokenId] = minBalance;
        expirations[tokenId] = expiration;

        // store token creator
        tokenCreators[tokenId] = msg.sender;

        // Mint token to user
        _mint(_msgSender(), tokenId, amountTokens, "");

        increaseTokenId();

        // send ETH to fee recipient
        feeRecipient.transfer(amountFee);

        // Refund
        if (msg.value > amountFee) {
            _msgSender().transfer(msg.value.sub(amountFee));
        }
    }

    /**
     * @notice Create NFT Collecions paying with ZUT
     */
    function buyWithZUT(
        uint256 amountTokens,
        address tokenAddress,
        uint256 minBalance,
        uint256 expiration,
        string memory ipfsHash
    ) external virtual {
        if (expiration > 0)
            require(expiration > block.timestamp, "Time in the past");

        if (minBalance > 0)
            require(tokenAddress != address(0), "Invalid Address");

        uint256 amountFee = zutFee.mul(amountTokens);

        // Collect fees in ZUT token
        zut.safeTransferFrom(_msgSender(), feeRecipient, zutFee);

        uint256 tokenId = _tokenIdTracker.current();

        // Add token properties and conditions
        ipfsHashes[tokenId] = ipfsHash;
        tokenMinBalances[tokenId] = tokenAddress;
        minBalances[tokenId] = minBalance;
        expirations[tokenId] = expiration;

        // store token creator
        tokenCreators[tokenId] = msg.sender;

        // Mint token to user
        _mint(_msgSender(), tokenId, amountTokens, "");

        increaseTokenId();
    }

    /**
     * @notice Burn a NFT token if certain conditions are met
     */
    function burnToken(uint256 tokenId, address user) public {
        require(canBurn(tokenId, user), "Can't burn token yet");
        require(
            hasRole(keccak256("BURNER_ROLE"), _msgSender()),
            "Must have burner role"
        );

        _burn(user, tokenId, 1);
    }

    /**
     * @notice Burn NFT tokens in a batch transaction
     */
    function burnTokenBatch(uint256[] memory tokenIds, address[] memory users)
        public
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burnToken(tokenIds[i], users[i]);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // when its not minting or burning
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    balanceOf(to, ids[i]) == 0 && amounts[i] == 1,
                    "User can own only 1 token per id"
                );
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     *** ADMIN ****
     */

    function setContractURI(string memory ipfsUrl) external onlyAdmin {
        _contractURI = ipfsUrl;
    }

    function setBaseURI(string memory baseURI) external onlyAdmin {
        _baseURI = baseURI;
    }

    function setETHFee(uint256 _ethFee) external onlyAdmin {
        ethFee = _ethFee;
    }

    function setZUTFee(uint256 _zutFee) external onlyAdmin {
        zutFee = _zutFee;
    }

    function setFeeRecipient(address payable _feeRecipient) external onlyAdmin {
        feeRecipient = _feeRecipient;
    }
}