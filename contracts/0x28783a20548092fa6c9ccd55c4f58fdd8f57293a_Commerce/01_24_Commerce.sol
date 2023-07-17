// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Abstract1155Factory.sol";
import "./Utils.sol";
import "hardhat/console.sol";

contract Commerce is Abstract1155Factory, ReentrancyGuard {
    using SafeMath for uint256;
    address public receivingWallet;
    uint256 bonusAlbumsGiven = 0;
    uint256 maxBonusAlbumsGiven = 100;
    mapping(uint256 => Token) public tokens;
    event Purchased(uint256[] index, address indexed account, uint256[] amount);
    event Fused(uint256[] index, address indexed account, uint256[] amount);
    struct Token {
        string ipfsMetadataHash;
        string extraDataUri;
        mapping(address => uint256) claimedTokens;
        mapping(uint256 => address) redeemableContracts;
        uint256 numRedeemableContracts;
        mapping(uint256 => Whitelist) whitelistData;
        mapping(uint256 => CurrencyConfig) availableCurrencies;
        uint256 numCurrencies;
        uint256 numTokenWhitelists;
        MintingConfig mintingConfig;
        WhiteListConfig whiteListConfig;
        bool isTokenPack;
    }
    struct MintingConfig {
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        uint256 numMinted;
        uint256 fusionTokenID;
        uint256 fusionQuantity;
        bool fusionOpen;
    }
    struct WhiteListConfig {
        bool maxQuantityMappedByWhitelistHoldings;
        bool requireAllWhiteLists;
        bool hasMerkleRoot;
        bytes32 merkleRoot;
    }

    struct CurrencyConfig {
        address tokenAddress;
        string tokenName;
        string abiURI;
        uint256 requiredAmount;
        bool enabled;
    }

    struct Whitelist {
        string tokenType;
        address tokenAddress;
        uint256 mustOwnQuantity;
        uint256 tokenId;
        bool active;
    }

    string public _contractURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _admins,
        string memory _contract_URI,
        address _receivingWallet
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
        receivingWallet = _receivingWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < _admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
        _contractURI = _contract_URI;
    }

    function getOpenSaleTokens() public view returns (string memory) {
        string memory open = "";
        uint256 numTokens = 0;
        while (!Utils.compareStrings(tokens[numTokens].ipfsMetadataHash, "")) {
            if (isSaleOpen(numTokens)) {
                open = string(
                    abi.encodePacked(open, Strings.toString(numTokens), ",")
                );
            }
            numTokens++;
        }
        return open;
    }

    function editToken(
        uint256 _tokenIndex,
        string memory _ipfsMetadataHash,
        string memory _extraDataUri,
        uint256 _windowOpens,
        uint256 _windowCloses,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _maxPerWallet,
        bool _maxQuantityMappedByWhitelistHoldings,
        bool _requireAllWhiteLists,
        address[] memory _redeemableContracts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        token.mintingConfig.windowOpens = _windowOpens;
        token.mintingConfig.windowCloses = _windowCloses;
        token.mintingConfig.mintPrice = _mintPrice;
        token.mintingConfig.maxSupply = _maxSupply;
        token.mintingConfig.maxMintPerTxn = _maxMintPerTxn;
        token.mintingConfig.maxPerWallet = _maxPerWallet;
        token.ipfsMetadataHash = _ipfsMetadataHash;
        token.extraDataUri = _extraDataUri;

        for (uint256 i = 0; i < _redeemableContracts.length; i++) {
            token.redeemableContracts[i] = _redeemableContracts[i];
        }
        token.numRedeemableContracts = _redeemableContracts.length;
        token
            .whiteListConfig
            .maxQuantityMappedByWhitelistHoldings = _maxQuantityMappedByWhitelistHoldings;
        token.whiteListConfig.requireAllWhiteLists = _requireAllWhiteLists;
    }

     function addCurrency(
        uint256 _tokenIndex,
        address _tokenAddress,
        string calldata _tokenName,
        string calldata _tokenABIURI,
        uint256 _requiredAmount,
        bool enabled
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        editCurrency(_tokenIndex, token.numCurrencies, _tokenAddress,_tokenName, _tokenABIURI, _requiredAmount, enabled);
        token.numCurrencies++;
    }

    function editCurrency(
        uint256 _tokenIndex,
        uint256 _currencyIndex,
        address _tokenAddress,
        string calldata _tokenName,
        string calldata _tokenABIURI,
        uint256 _requiredAmount,
        bool enabled
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        CurrencyConfig storage currency = token.availableCurrencies[_currencyIndex];
        currency.tokenAddress = _tokenAddress;
        currency.tokenName = _tokenName;
        currency.abiURI = _tokenABIURI;
        currency.requiredAmount = _requiredAmount;
        currency.enabled = enabled;
    }


    function addWhiteList(
        uint256 _tokenIndex,
        string memory _tokenType,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _mustOwnQuantity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Whitelist storage whitelist = tokens[_tokenIndex].whitelistData[
            tokens[_tokenIndex].numTokenWhitelists
        ];
        whitelist.tokenType = _tokenType;
        whitelist.tokenId = _tokenId;
        whitelist.active = true;
        whitelist.tokenAddress = _tokenAddress;
        whitelist.mustOwnQuantity = _mustOwnQuantity;
        tokens[_tokenIndex].numTokenWhitelists =
            tokens[_tokenIndex].numTokenWhitelists +
            1;
    }

    function disableWhiteList(
        uint256 _tokenIndex,
        uint256 _whiteListIndexToRemove
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex]
            .whitelistData[_whiteListIndexToRemove]
            .active = false;
    }

    function editTokenWhiteListMerkleRoot(
        uint256 _tokenIndex,
        bytes32 _merkleRoot,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex].whiteListConfig.merkleRoot = _merkleRoot;
        tokens[_tokenIndex].whiteListConfig.hasMerkleRoot = enabled;
    }

    function editReceivingWallet(address _receivingWallet) external onlyOwner {
        receivingWallet = _receivingWallet;
    }

    function burnFromRedeem(
        address account,
        uint256 tokenIndex,
        uint256 amount
    ) external {
        Token storage token = tokens[tokenIndex];
        bool hasValidRedemptionContract = false;
        if (token.numRedeemableContracts > 0) {
            for (uint256 i = 0; i < token.numRedeemableContracts; i++) {
                if (token.redeemableContracts[i] == msg.sender) {
                    hasValidRedemptionContract = true;
                }
            }
        }
        require(hasValidRedemptionContract, "1");
        _burn(account, tokenIndex, amount);
    }



    function purchase(
        uint256[] calldata _quantities,
        uint256[] calldata _tokenIndexes,
        uint256[] calldata _merkleAmounts,
        bytes32[][] calldata _merkleProofs
    ) external payable nonReentrant {
        require(
            arrayIsUnique(_tokenIndexes),
            "Redeem: cannot contain duplicate indexes"
        );
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIndexes.length; i++) {
            require(isSaleOpen(_tokenIndexes[i]), "5");
            require(
                tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(
                    _quantities[i]
                ) <= _merkleAmounts[i],
                "8"
            );
            require(
                tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(
                    _quantities[i]
                ) <= tokens[_tokenIndexes[i]].mintingConfig.maxPerWallet,
                "9"
            );
            require(
                _quantities[i] <=
                    tokens[_tokenIndexes[i]].mintingConfig.maxMintPerTxn,
                "10"
            );
            require(
                getTokenSupply(_tokenIndexes[i]) + _quantities[i] <=
                    tokens[_tokenIndexes[i]].mintingConfig.maxSupply,
                "11"
            );
            totalPrice = totalPrice.add(
                _quantities[i].mul(
                    tokens[_tokenIndexes[i]].mintingConfig.mintPrice
                )
            );
        }
        require(!paused() && msg.value >= totalPrice, "3");

        uint256[] memory idsToMint;
        uint256[] memory quantitiesToMint;

        idsToMint = new uint256[](_tokenIndexes.length);
        quantitiesToMint = new uint256[](_quantities.length);

        for (uint256 i = 0; i < _tokenIndexes.length; i++) {

            idsToMint[i] = _tokenIndexes[i];

            if (_tokenIndexes[i] == 1) {
                uint256 r = pR();
                if (
                    r <= 2 &&
                    bonusAlbumsGiven < maxBonusAlbumsGiven
                    
                ) {
                    idsToMint[i] = 0;
                    bonusAlbumsGiven++;
                }
            }

            quantitiesToMint[i] = _quantities[i];
            tokens[_tokenIndexes[i]].claimedTokens[msg.sender] = tokens[
                _tokenIndexes[i]
            ].claimedTokens[msg.sender].add(_quantities[i]);
        }

        payable(receivingWallet).transfer(msg.value);
        _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
        emit Purchased(idsToMint, msg.sender, quantitiesToMint);
        
    }

    function pR() public view returns (uint256) {
        uint256 r = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) /
            5000000000000000000000000000000000000000000000000000000000000000000000000000;
        return r;
    }

     

     function purchaseWithAlt(
        uint256[] calldata _quantities,
        uint256[] calldata _tokenIndexes,
        uint256[] calldata _merkleAmounts,
        bytes32[][] calldata _merkleProofs,
        uint256 _currencyIndex
    ) external payable nonReentrant {
        require(
            arrayIsUnique(_tokenIndexes),
            "purchaseWithAlt: cannot contain duplicate indexes"
        );
        require(!paused(), "Sale: paused");
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIndexes.length; i++) {
            
            require(isSaleOpen(_tokenIndexes[i]), "5");
            require(
                tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(
                    _quantities[i]
                ) <= _merkleAmounts[i],
                "8"
            );
            require(
                tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(
                    _quantities[i]
                ) <= tokens[_tokenIndexes[i]].mintingConfig.maxPerWallet,
                "9"
            );
            require(
                _quantities[i] <=
                    tokens[_tokenIndexes[i]].mintingConfig.maxMintPerTxn,
                "10"
            );
            require(
                getTokenSupply(_tokenIndexes[i]) + _quantities[i] <=
                    tokens[_tokenIndexes[i]].mintingConfig.maxSupply,
                "11"
            );

            require(tokens[_tokenIndexes[i]].availableCurrencies[_currencyIndex].enabled, string(abi.encodePacked(tokens[_tokenIndexes[0]].availableCurrencies[_currencyIndex].tokenName, " not enabled")));
        

            totalPrice = totalPrice.add(
                _quantities[i].mul(
                    tokens[_tokenIndexes[i]].availableCurrencies[_currencyIndex].requiredAmount
                )
            );
        }
        require(IERC20(tokens[_tokenIndexes[0]].availableCurrencies[_currencyIndex].tokenAddress).balanceOf(msg.sender) >= totalPrice, "3a");

        
        uint256[] memory idsToMint;
        uint256[] memory quantitiesToMint;

        idsToMint = new uint256[](_tokenIndexes.length);
        quantitiesToMint = new uint256[](_quantities.length);

        for (uint256 i = 0; i < _tokenIndexes.length; i++) {
            
            idsToMint[i] = _tokenIndexes[i];

            if (_tokenIndexes[i] == 1) {
                uint256 r = pR();
                if (
                    r <= 2 &&
                    bonusAlbumsGiven < maxBonusAlbumsGiven && _quantities[i] <= ((tokens[_tokenIndexes[i]].mintingConfig.maxSupply + maxBonusAlbumsGiven) -  totalSupply(_tokenIndexes[i]))
                    
                ) {
                    idsToMint[i] = 0;
                    bonusAlbumsGiven = bonusAlbumsGiven + _quantities[i];
                }
            }

            quantitiesToMint[i] = _quantities[i];
            tokens[_tokenIndexes[i]].claimedTokens[msg.sender] = tokens[
                _tokenIndexes[i]
            ].claimedTokens[msg.sender].add(_quantities[i]);
        }

        IERC20(tokens[_tokenIndexes[0]].availableCurrencies[_currencyIndex].tokenAddress).transferFrom(msg.sender, receivingWallet, totalPrice);
        _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
        emit Purchased(idsToMint, msg.sender, quantitiesToMint);
        
    }

    function numAltCurrencies(uint256 tokenIndex) public view returns (uint256) {
       return tokens[tokenIndex].numCurrencies;
    }

    function getTokenCurrencyByIndex(uint256 tokenIndex, uint256 currencyIndex) public view returns (CurrencyConfig memory) {
       return tokens[tokenIndex].availableCurrencies[currencyIndex];
    }

    function arrayIsUnique(uint256[] memory items)
        internal
        pure
        returns (bool)
    {
        // iterate over array to determine whether or not there are any duplicate items in it
        // we do this instead of using a set because it saves gas
        for (uint256 i = 0; i < items.length; i++) {
            for (uint256 k = i + 1; k < items.length; k++) {
                if (items[i] == items[k]) {
                    return false;
                }
            }
        }

        return true;
    }

    function mintBatch(
        address to,
        uint256[] calldata qty,
        uint256[] calldata _tokens
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintBatch(to, _tokens, qty, "");
    }

   
 function getQualifiedAllocation(address sender, 
        uint256 tokenIndex,
        uint256 quantity,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool returnAllocationOnly) public view returns (uint256) {
           return quantity;
        }
   

    function getExternalTokenBalance(
        address sender,
        Whitelist memory balanceRequest
    ) public view returns (uint256) {
        if (Utils.compareStrings(balanceRequest.tokenType, "ERC721")) {
            WhitelistContract721 _contract = WhitelistContract721(
                balanceRequest.tokenAddress
            );
            return _contract.balanceOf(sender);
        } else if (Utils.compareStrings(balanceRequest.tokenType, "ERC1155")) {
            WhitelistContract1155 _contract = WhitelistContract1155(
                balanceRequest.tokenAddress
            );
            return _contract.balanceOf(sender, balanceRequest.tokenId);
        }
    }

    function isSaleOpen(uint256 tokenIndex) public view returns (bool) {
        Token storage token = tokens[tokenIndex];
        if (paused()) {
            return false;
        }
        if (
            block.timestamp > token.mintingConfig.windowOpens &&
            block.timestamp < token.mintingConfig.windowCloses
        ) {
            return token.mintingConfig.saleIsOpen;
        }
        return false;
    }

    function toggleSale(uint256 mpIndex, bool on)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokens[mpIndex].mintingConfig.saleIsOpen = on;
    }



    function uri(uint256 _id) public view override returns (string memory) {
        require(getTokenSupply(_id) > 0, "16");
        if (Utils.compareStrings(tokens[_id].ipfsMetadataHash, "")) {
            return
                string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
        } else {
            return string(abi.encodePacked(tokens[_id].ipfsMetadataHash));
        }
    }

    function getTokenSupply(uint256 tokenIndex) public view returns (uint256) {
        Token storage token = tokens[tokenIndex];
        return
            token.isTokenPack
                ? token.mintingConfig.numMinted
                : totalSupply(tokenIndex);
    }
}

contract WhitelistContract1155 {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256)
    {}
}

contract WhitelistContract721 {
    function balanceOf(address account) external view returns (uint256) {}
}