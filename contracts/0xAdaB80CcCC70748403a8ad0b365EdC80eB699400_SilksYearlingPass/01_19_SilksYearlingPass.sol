// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./CollaborationPricing.sol";
import "./WhitelistPricing.sol";
import "./ERC721Redeemable.sol";

contract SilksYearlingPass is ERC721Redeemable, CollaborationPricing, WhitelistPricing {
    
    struct UsedTokens {
        mapping(uint256 => bool) tokens;
    }
    
    using Counters for Counters.Counter;
    Counters.Counter private passIds;
    
    address private avatarsAddress;
    
    mapping(address => UsedTokens) private usedTokens;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _maxSupply,
        address _avatarsAddress,
        address _payeeAddress,
        uint256[] memory _publicSaleInfo // price - 0, maxPerTx - 1, maxPerWallet - 2
    ) ERC721Redeemable (
        _name,
        _symbol,
        _payeeAddress,
        _maxSupply
    ) {
        baseUri = _baseUri;
        require(Address.isContract(_avatarsAddress), "NOT_CONTRACT_ADDRESS");
        avatarsAddress = _avatarsAddress;
        collaborations[address(0)] = Collaboration(
            _publicSaleInfo[0], true, _publicSaleInfo[1], _publicSaleInfo[2], true
        );
    }
    
    function publicPurchase()
    public
    payable
    whenNotPaused
    {
        (uint256 price, bool paused, uint256 maxPerTx, uint256 maxPerWallet, bool valid) = getCollaboration(address(0));
        require(valid && !paused, "PUBLIC_MINT_PAUSED");
        checkPurchaseConditions(msg.sender, price, maxPerTx, maxPerWallet);
        _mintPasses(msg.sender, (msg.value / price));
    }
    
    function whitelistGatedPurchase(
        uint _id,
        bytes32[] calldata merkleProof
    )
    public
    payable
    whenNotPaused
    {
        (uint256 price, bool paused, uint256 maxPerTx, uint256 maxPerWallet, bool valid) = getWhitelist(_id);
        require(valid && !paused, "NOT_VALID_OR_PAUSED");
        require(isWhitelisted(_id, msg.sender, merkleProof), "NOT_WHITELISTED");
        checkPurchaseConditions(msg.sender, price, maxPerTx, maxPerWallet);
        _mintPasses(msg.sender, msg.value / price);
    }
    
    function airDrop(
        address _to,
        uint256 _amount
    )
    public
    onlyOwner
    whenNotPaused
    {
        _mintPasses(_to, _amount);
    }
    
    function genesisAvatarGatedOwnerMint(
        address _to,
        uint256[] calldata _tokenIds
    )
    external
    payable
    onlyOwner
    {
        (uint256 price, bool paused, uint256 maxPerTx, uint256 maxPerWallet, bool valid) = getCollaboration(avatarsAddress);
        require(valid && !paused, "NOT_VALID_OR_PAUSED");
        checkPurchaseConditions(_to, price, maxPerTx, maxPerWallet);
        _checkAndMintPasses(avatarsAddress, _to, _tokenIds);
    }
    
    function genesisAvatarsGatedPurchase(
        uint256[] calldata _tokenIds
    )
    public
    payable
    whenNotPaused
    {
        tokenGatedPurchase(avatarsAddress, _tokenIds);
    }
    
    function tokenGatedPurchase(
        address _contractAddress,
        uint256[] calldata _tokenIds
    )
    public
    payable
    whenNotPaused
    {
        (uint256 price, bool paused, uint256 maxPerTx, uint256 maxPerWallet, bool valid) = getCollaboration(_contractAddress);
        require(valid && !paused, "NOT_VALID_OR_PAUSED");
        checkPurchaseConditions(msg.sender, price, maxPerTx, maxPerWallet);
        // Verify that the total eth sent is enough to purchase the yearling mint passes for each token
        require(_tokenIds.length == (msg.value / price), "INV_PAYMENT");
        
        _checkAndMintPasses(_contractAddress, msg.sender, _tokenIds);
    }
    
    function comboWhitelistTokenGatedPurchase(
        uint256 _id,
        bytes32[] calldata merkleProof,
        address _contractAddress,
        uint256[] calldata _tokenIds
    )
    public
    payable
    whenNotPaused
    {
        (uint256 price, bool paused, uint256 maxPerTx, uint256 maxPerWallet, bool valid) = getWhitelist(_id);
        require(valid && !paused, "NOT_VALID_OR_PAUSED");
        require(isWhitelisted(_id, msg.sender, merkleProof), "NOT_WHITELISTED");
        checkPurchaseConditions(msg.sender, price, maxPerTx, maxPerWallet);
        // Verify that the total eth sent is enough to purchase the yearling mint passes for each token
        require(_tokenIds.length == (msg.value / price), "INV_PAYMENT");
        _checkAndMintPasses(_contractAddress, msg.sender, _tokenIds);
    }
    
    function _checkAndMintPasses(
        address _contractAddress,
        address _to,
        uint256[] calldata _tokenIds
    )
    internal
    {
        ERC721 erc721Contract = ERC721(_contractAddress);
        // Verify token ownership and if already redeemed
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(erc721Contract.ownerOf(_tokenIds[i]) == _to, "NOT_OWNER");
            require(!checkIfTokenUsed(_contractAddress, _tokenIds[i]), "USED_TOKEN");
            usedTokens[_contractAddress].tokens[_tokenIds[i]] = true;
        }
        
        _mintPasses(_to, _tokenIds.length);
    }
    
    function checkPurchaseConditions(
        address _to,
        uint256 price,
        uint256 maxPerTx,
        uint256 maxPerWallet
    )
    internal
    {
        // Make sure the the exact amount needed to mint and the number to mint * price is
        // equal to the amount of eth sent.
        require(
            msg.value % price == 0 &&
            ((msg.value / price) * price == msg.value),
            "INV_ETH_TOTAL"
        );
        require(maxPerTx == 0 || (msg.value / price) <= maxPerTx, "PER_TX_ERROR");
        require(
            maxPerWallet == 0 ||
            (balanceOf(_to) + (msg.value / price)) <= maxPerWallet,
            "PER_WALLET_ERROR"
        );
    }
    
    function _mintPasses(
        address _to,
        uint256 _amount
    )
    internal
    {
        require((totalSupply() + _amount) <= maxSupply, "MAX_SUPPLY_ERROR");
        for (uint256 i = 0; i < _amount; i++) {
            passIds.increment();
            uint256 newYearlingPassId = passIds.current();
            _mint(_to, newYearlingPassId);
        }
    }
    
    function checkIfTokenUsed(
        address _contractAddress,
        uint256 _tokenId
    )
    public
    view
    returns (bool)
    {
        return usedTokens[_contractAddress].tokens[_tokenId];
    }
    
    function checkIfTokenUsedBatch(
        address _contractAddress,
        uint256[] calldata _tokenIds
    )
    public
    view
    returns (bool[] memory)
    {
        bool[] memory checks = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            checks[i] = usedTokens[_contractAddress].tokens[_tokenIds[i]];
        }
        return checks;
    }
}