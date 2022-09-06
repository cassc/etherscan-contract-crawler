// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "../access/SharedOwnable.sol";
import "../interfaces/IERC721Optimized.sol";
import "../opensea/IERC721Factory.sol";
import "../opensea/ProxyRegistry.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Optimized is Context, SharedOwnable, IERC721, IERC721Metadata, IERC721Enumerable, IERC721Optimized {
    using Address for address;
    using Strings for uint256;

    struct AddressData {
        uint128 balance;  
        uint128 privateMintCount;
    }

    struct TokenData {
        address owner;
        uint96 owningStartTimestamp;
    }

    uint constant private MAX_TOTAL_SUPPLY = 10000;
    uint constant private MAX_TEAM_MINTS = 100;

    string private _name;
    string private _symbol;
    string private _baseURI;
    MintConfig private _privateMintConfig;
    mapping(uint64 => uint128) private _privateMintDiscountPerMintAmount;
    MintConfig private _publicMintConfig;
    mapping(uint64 => uint128) private _publicMintDiscountPerMintAmount;
    address private _erc721FactoryAddress;
    address private _proxyRegistryAddress;

    uint256 private _totalSupply;
    mapping(address => uint256) private _privateMintWhitelist;

    uint256 private _teamMintedCount;
    uint256 private _privateMintedCount;
    uint256 private _publicMintedCount;
    uint256 private _airdroppedToOwnersCount;
    uint256 private _raffledToOwnersCount;
    mapping(uint256 => uint256) private _raffleToOwnersHelper;

    mapping(address => AddressData) private _addresses;
    mapping(address => mapping(address => uint256)) private _operatorApprovals;
    mapping(uint256 => TokenData) private _tokens;
    mapping(uint256 => address) private _tokenApprovals;

    mapping(uint256 => bool) private _isTeamMintedToken;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, MintConfig memory privateMintConfig_, MintConfig memory publicMintConfig_, address erc721FactoryAddress_, address proxyRegistryAddress_) {
        require(bytes(name_).length > 0, "ERC721Optimized: name can't be empty");
        require(bytes(symbol_).length > 0, "ERC721Optimized: symbol can't be empty");
        require(bytes(baseURI_).length > 0, "ERC721Optimized: baseURI can't be empty");
        require(privateMintConfig_.maxMintAmountPerAddress <= privateMintConfig_.maxTotalMintAmount, "ERC721Optimized: maximum mint amount per address can't exceed the maximum total mint amount");
        require(privateMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(privateMintConfig_.discountPerMintAmountKeys.length == privateMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        require(publicMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(publicMintConfig_.discountPerMintAmountKeys.length == publicMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        if (erc721FactoryAddress_ != address(0))
            IERC721Factory(erc721FactoryAddress_).supportsFactoryInterface();
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());

        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _privateMintConfig = privateMintConfig_;
        for (uint256 index = 0; index < privateMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(privateMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _privateMintDiscountPerMintAmount[privateMintConfig_.discountPerMintAmountKeys[index]] = privateMintConfig_.discountPerMintAmountValues[index];
        }
        _publicMintConfig = publicMintConfig_;
        for (uint256 index = 0; index < publicMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(publicMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _publicMintDiscountPerMintAmount[publicMintConfig_.discountPerMintAmountKeys[index]] = publicMintConfig_.discountPerMintAmountValues[index];
        }
        _erc721FactoryAddress = erc721FactoryAddress_;
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    modifier onlyERC721Factory() {
        require(_erc721FactoryAddress == msg.sender, "ERC721Optimized: caller is not the erc 721 factory");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC721Enumerable).interfaceId || interfaceId == type(IERC721Optimized).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function privateMintConfig() external view returns (MintConfig memory) {
        return _privateMintConfig;
    }

    function publicMintConfig() external view returns (MintConfig memory) {
        return _publicMintConfig;
    }

    function erc721FactoryAddress() external view returns (address) {
        return _erc721FactoryAddress;
    }

    function proxyRegistryAddress() external view returns (address) {
        return _proxyRegistryAddress;
    }

    function setBaseURI(string calldata baseURI_) external onlySharedOwners {
        require(bytes(baseURI_).length > 0, "ERC721Optimized: baseURI can't be empty");
        _baseURI = baseURI_;
    }

    function setPrivateMintConfig(MintConfig calldata privateMintConfig_) external onlySharedOwners {
        require(privateMintConfig_.maxMintAmountPerAddress <= privateMintConfig_.maxTotalMintAmount, "ERC721Optimized: maximum mint amount per address can't exceed the maximum total mint amount");
        require(privateMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(privateMintConfig_.discountPerMintAmountKeys.length == privateMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        for (uint256 index = 0; index < _privateMintConfig.discountPerMintAmountKeys.length; index++)
            delete _privateMintDiscountPerMintAmount[_privateMintConfig.discountPerMintAmountKeys[index]];
        _privateMintConfig = privateMintConfig_;
        for (uint256 index = 0; index < privateMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(privateMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _privateMintDiscountPerMintAmount[privateMintConfig_.discountPerMintAmountKeys[index]] = privateMintConfig_.discountPerMintAmountValues[index];
        }
    }

    function setPublicMintConfig(MintConfig calldata publicMintConfig_) external onlySharedOwners {
        require(publicMintConfig_.pricePerMint > 0, "ERC721Optimized: the mint can't be for free");
        require(publicMintConfig_.discountPerMintAmountKeys.length == publicMintConfig_.discountPerMintAmountValues.length, "ERC721Optimized: array size mismatch");
        for (uint256 index = 0; index < _publicMintConfig.discountPerMintAmountKeys.length; index++)
            delete _publicMintDiscountPerMintAmount[_publicMintConfig.discountPerMintAmountKeys[index]];
        _publicMintConfig = publicMintConfig_;
        for (uint256 index = 0; index < publicMintConfig_.discountPerMintAmountKeys.length; index++) {
            require(publicMintConfig_.discountPerMintAmountValues[index] < 100, "ERC721Optimized: discount exceeds 100%");
            _publicMintDiscountPerMintAmount[publicMintConfig_.discountPerMintAmountKeys[index]] = publicMintConfig_.discountPerMintAmountValues[index];
        }
    }

    function setERC721FactoryAddress(address erc721FactoryAddress_) external onlySharedOwners {
        if (erc721FactoryAddress_ != address(0))
            IERC721Factory(erc721FactoryAddress_).supportsFactoryInterface();
        _erc721FactoryAddress = erc721FactoryAddress_;
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) external onlySharedOwners {
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalMinted() external view returns (uint256) {
        return _privateMintedCount + _publicMintedCount;
    }

    function isPrivateMintWhitelisted(address account) external view returns (bool) {
        return _privateMintWhitelist[account] > 0;
    }

    function updatePrivateMintWhitelisted(address[] calldata addresses, uint256[] calldata values) external onlySharedOwners {
        require(addresses.length == values.length, "ERC721Optimized: array mismatch");
        for (uint256 index = 0; index < addresses.length; index++)
            _privateMintWhitelist[addresses[index]] = values[index];
    }

    function teamMintedCount() external view returns (uint256) {
        return _teamMintedCount;
    }

    function privateMintedCount() external view returns (uint256) {
        return _privateMintedCount;
    }

    function publicMintedCount() external view returns (uint256) {
        return _publicMintedCount;
    }

    function airdroppedToOwnersCount() external view returns (uint256) {
        return _airdroppedToOwnersCount;
    }

    function raffledToOwnersCount() external view returns (uint256) {
        return _raffledToOwnersCount;
    }

    function isTeamMintedToken(uint256 tokenId) external view returns (bool) {
        require(tokenId < _totalSupply, "ERC721Optimized: Nonexistent tokenId operation");
        return _isTeamMintedToken[tokenId];
    }

    function withdraw(address payable recipient) external onlyOwner {
        (bool success, ) = recipient.call{ value: address(this).balance }("");
        require(success, "ERC721Optimized: Transfer failed.");
    }

    function addressData(address owner) external view returns (AddressData memory) {
        return _addresses[owner];
    }

    function tokenData(uint256 tokenId) external view returns (TokenData memory) {
        return _tokens[tokenId];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](_addresses[owner].balance);

        uint256 currentIndex;
        address currentOwner;
        address ownerAtIndex;
        for (uint256 tokenId = 0; tokenId < _totalSupply; tokenId++) {
            ownerAtIndex = _tokens[tokenId].owner;
            if (ownerAtIndex != address(0))
                currentOwner = ownerAtIndex;

            if (currentOwner == owner) {
                tokenIds[currentIndex++] = tokenId;
                if (currentIndex == tokenIds.length)
                    break;
            }
        }

        require(currentIndex == tokenIds.length, "ERC721Optimized: not all tokens found");
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract"));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId) {
        require(index < _addresses[owner].balance, "ERC721Optimized: Nonexistent index operation");
        
        uint256 currentIndex;
        address currentOwner;
        address ownerAtIndex;
        for (; tokenId < _totalSupply; tokenId++) {
            ownerAtIndex = _tokens[tokenId].owner;
            if (ownerAtIndex != address(0))
                currentOwner = ownerAtIndex;

            if (currentOwner == owner) {
                if (currentIndex == index)
                    return tokenId;

                currentIndex++;
            }
        }

        revert("ERC721Optimized: no token found");
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _totalSupply, "ERC721Optimized: Nonexistent index operation");
        return index;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = _addresses[owner].balance;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        owner = _tokens[tokenId].owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        address msgSender = _msgSender();
        _transfer(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(msgSender, from, to, tokenId, ""), "ERC721Optimized: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(_msgSender(), from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        address owner = _tokens[tokenId].owner;

        address msgSender = _msgSender();
        require(msgSender == owner || (_operatorApprovals[owner][msgSender] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner)) == msgSender)), "ERC721Optimized: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address operator) {
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        operator = _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) external {
        address msgSender = _msgSender();
        require(msgSender != operator, "ERC721Optimized: approve to caller");
        _operatorApprovals[msgSender][operator] = _approved ? 1 : 0;

        emit ApprovalForAll(msgSender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner)) == operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        address msgSender = _msgSender();
        _transfer(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(msgSender, from, to, tokenId, data), "ERC721Optimized: transfer to non ERC721Receiver implementer");
    }

    function transferWithData(address to, uint256 tokenId) external {
        address msgSender = _msgSender();
        uint96 tokenOwningStartTimestamp = _tokens[tokenId].owningStartTimestamp;
        _transfer(msgSender, msgSender, to, tokenId);
        _tokens[tokenId].owningStartTimestamp = tokenOwningStartTimestamp;
    }

    function privateMint(uint64 quantity) external payable {
        require(block.timestamp >= _privateMintConfig.mintStartTimestamp, "ERC721Optimized: private mint has not yet started");
        require(block.timestamp < _privateMintConfig.mintEndTimestamp, "ERC721Optimized: private mint has ended");
        address msgSender = _msgSender();

        require(_privateMintWhitelist[msgSender] > 0, "ERC721Optimized: not whitelisted for the private mint");
        require(_privateMintedCount + _publicMintedCount + quantity <= _privateMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        require(_addresses[msgSender].privateMintCount + quantity <= _privateMintConfig.maxMintAmountPerAddress, "ERC721Optimized: exceeds mint maximum");
        uint128 discount = _privateMintDiscountPerMintAmount[quantity];
        uint256 discountedPrice = ((quantity * _privateMintConfig.pricePerMint) * (100 - discount)) / 100;
        require(msg.value >= discountedPrice, "ERC721Optimized: missing funds");
        _safeMint(msgSender, msgSender, quantity);
        _addresses[msgSender].privateMintCount += quantity;
        _privateMintedCount += quantity;
    }

    function publicMint(uint64 quantity) external payable {
        require(block.timestamp >= _publicMintConfig.mintStartTimestamp, "ERC721Optimized: public mint has not yet started");
        require(block.timestamp < _publicMintConfig.mintEndTimestamp, "ERC721Optimized: public mint has ended");
        address msgSender = _msgSender();

        require(_privateMintedCount + _publicMintedCount + quantity <= _publicMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        uint128 discount = _publicMintDiscountPerMintAmount[quantity];
        uint256 discountedPrice = ((quantity * _publicMintConfig.pricePerMint) * (100 - discount)) / 100;
        require(msg.value >= discountedPrice, "ERC721Optimized: missing funds");
        _safeMint(msgSender, msgSender, quantity);
        _publicMintedCount += quantity;
    }

    function publicMint(address to, uint64 quantity) external onlyERC721Factory {
        require(block.timestamp >= _publicMintConfig.mintStartTimestamp, "ERC721Optimized: public mint has not yet started");
        require(block.timestamp < _publicMintConfig.mintEndTimestamp, "ERC721Optimized: public mint has not yet started");
        
        require(_privateMintedCount + _publicMintedCount + quantity <= _publicMintConfig.maxTotalMintAmount, "ERC721Optimized: exceeds total mint maximum");
        _safeMint(_msgSender(), to, quantity);
        _publicMintedCount += quantity;
    }

    function teamMint(address[] calldata addresses, uint128[] calldata quantities) external onlySharedOwners {
        require(quantities.length == addresses.length, "ERC721Optimized: array size mismatch");

        uint256 j;
        uint128 quantity;
        for (uint256 index = 0; index < addresses.length; index++) {
            quantity = quantities[index];
            for (j = 0; j < quantity; j++)
                _isTeamMintedToken[_totalSupply + j] = true;
            _safeMint(_msgSender(), addresses[index], quantity);
            _teamMintedCount += quantity;
        }

        require(_teamMintedCount <= MAX_TEAM_MINTS, "ERC721Optimized: exceeds maximum team mint count");
    }

    function airdropToOwners(uint256 airdropQuantity, uint256 startTokenId) external onlySharedOwners {
        uint256 _existingTotalSupply = _totalSupply;
        require(startTokenId + airdropQuantity <= _existingTotalSupply, "ERC721Optimized: not enough tokens");

        uint256 _airdroppedTokens = 0;
        for (uint256 tokenId = startTokenId; tokenId < _existingTotalSupply && _airdroppedTokens < airdropQuantity; tokenId++) {
            if (!_isTeamMintedToken[tokenId]) {
                _safeMint(_msgSender(), _tokens[tokenId].owner, 1);
                _airdroppedTokens++;
            }
        }

        require(_airdroppedTokens == airdropQuantity, "ERC721Optimized: didn't minted all tokens");
        _airdroppedToOwnersCount += _airdroppedTokens;
    }

    function resetRaffleToOwnersHelper() external onlySharedOwners {
        for (uint256 tokenId = 0; tokenId < _totalSupply; tokenId++)
            if (_raffleToOwnersHelper[tokenId] != 0)
                _raffleToOwnersHelper[tokenId] = 0;
    }

    function raffleToOwners(uint256 minimumOwningDuration, uint256 tokensToRaffle, uint256 maxIterations) external onlySharedOwners {
        address[] memory owners = new address[](tokensToRaffle);
        uint256 ownersFound = 0;
        uint256 tokensIterated = 0;
        uint256 iterations = 0;

        uint256 tokenId;
        TokenData memory token;
        while (ownersFound < tokensToRaffle && _totalSupply - tokensIterated > tokensToRaffle - ownersFound && iterations < maxIterations) {
            tokenId = _getRandomExistingTokenId(iterations++);
            if (_raffleToOwnersHelper[tokenId] == 0) {
                token = _tokens[tokenId];
                if (block.timestamp - token.owningStartTimestamp >= minimumOwningDuration)
                    owners[ownersFound++] = token.owner;
                tokensIterated++;
                _raffleToOwnersHelper[tokenId] = 1;
            }
        }

        require(ownersFound == tokensToRaffle, "ERC721Optimized: didn't found all owners");
        for (uint256 index = 0; index < ownersFound; index++)
            _safeMint(_msgSender(), owners[index], 1);

        _raffledToOwnersCount += tokensToRaffle;
    }

    function _safeMint(address operator, address to, uint128 quantity) internal {
        require(to != address(0), "ERC721Optimized: mint to the zero address");
        require(_totalSupply + quantity <= MAX_TOTAL_SUPPLY, "ERC721Optimized: mint exceeds max total supply");

        uint256 tokenId = _totalSupply;
        for (uint256 index = 0; index < quantity; index++) {
            _tokens[tokenId].owner = to;
            _tokens[tokenId].owningStartTimestamp = uint96(block.timestamp);

            emit Transfer(address(0), to, tokenId);
            require(_checkOnERC721Received(operator, address(0), to, tokenId++, ""), "ERC721Optimized: transfer to non ERC721Receiver implementer");
        }
        require(tokenId == _totalSupply + quantity, "ERC721Optimized: Reentrancy detected");

        _totalSupply = tokenId;
        _addresses[to].balance += quantity;
    }

    function _transfer(address operator, address from, address to, uint256 tokenId) private {
        require(from != address(0), "ERC721Optimized: transfer from the zero address");
        require(to != address(0), "ERC721Optimized: transfer to the zero address");
        require(tokenId < _totalSupply, "ERC721Optimized: nonexistent tokenId operation");
        require(_tokens[tokenId].owner == from, "ERC721Optimized: transfer from incorrect owner");
        require(from == operator || _tokenApprovals[tokenId] == operator || (_operatorApprovals[from][operator] > 0 || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(from)) == operator)), "ERC721Optimized: transfer caller is not owner nor approved");
        require(from != to, "ERC721Optimized: transfer to the same address");
        require(!_isTeamMintedToken[tokenId] || block.timestamp >= _publicMintConfig.mintStartTimestamp,  "ERC721Optimized: transfer of team minted token prior to public mint");

        _tokenApprovals[tokenId] = address(0);
        emit Approval(from, address(0), tokenId);

        _addresses[from].balance -= 1;
        _addresses[to].balance += 1;
        _tokens[tokenId].owner = to;
        _tokens[tokenId].owningStartTimestamp = uint96(block.timestamp);
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract())
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert("ERC721Optimized: transfer to non ERC721Receiver implementer");
                else
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else
            return true;
    }
    
    function _getRandomExistingTokenId(uint256 nonce) private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(nonce + block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number + nonce)));
        return seed - ((seed / _totalSupply) * _totalSupply);
    }
}