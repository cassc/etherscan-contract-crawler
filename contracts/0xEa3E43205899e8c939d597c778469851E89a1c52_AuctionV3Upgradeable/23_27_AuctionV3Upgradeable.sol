/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./AuctionV3Base.sol";

/// @title Upgradeable 2 Phase mint for the squirrel degens NFT project (V3)
contract AuctionV3Upgradeable is AuctionV3Base {
    using MathUpgradeable for uint;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;

    using StringsUpgradeable for uint256;

    event PrivateMintStarted(uint256 _price, uint256 _supply, uint256 _tokensPerWallet);
    event PublicMintStarted(uint256 _price, uint256 _supply, uint256 _tokensPerWallet);
    event Revealed(string _uri, uint256 _seed);


    /*
    * The total supply minted
    */
    function totalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }

    /*
    * Returns a boolean indicating whether the sender wallet is whitelisted
    */
    function whitelistedWallet(address wallet) public view onlyOwner returns (bool) {
        return _whitelistMap[wallet];
    }

    /*
    * Returns the amount of tickets bought by the given wallet in the private auction of the V2 contract
    */
    function privateAuctionTicketsOf(address wallet) public view onlyOwner returns (uint256) {
        return privateAuctionTicketMap[wallet];
    }

    /*
    * Starts the whitelist mint with a specific price and supply. This method may not be called once the mint has been started.
    */
    function startPrivateMint(uint256 price_, uint256 supply_, uint256 tokensPerWallet_) public onlyOwner {
        require(!privateMintStarted, "Private mint has already been started");
        require(tokensPerWallet_ > 0, "Requires at least 1 token per wallet");
        privateMintPrice = price_;
        privateMintSupply = supply_;
        privateMintStarted = true;
        privateMintTokensPerWallet = tokensPerWallet_;
        emit PrivateMintStarted(price_, supply_, tokensPerWallet_);
    }

    /*
    * Returns true if the private mint has been started and not yet stopped. false otherwise
    */
    function privateMintActive() public view returns (bool) {
        return privateMintStarted && !privateMintStopped && _privateMintTokenCounter.current() < privateMintSupply;
    }

    /*
    * Mint tokens to wallet the private mint is active
    * Only whitelisted addresses may use this method
    */
    function privateMint(uint256 count_) public payable {
        _privateMint(_msgSender(), count_);
    }

    /*
    * Mint tokens to wallet the private mint is active
    * Only whitelisted addresses may use this method
    */
    function _privateMint(address wallet_, uint256 count_) private {
        // Basic check
        require(privateMintActive(), "Private mint is not active");

        // Count check
        require(count_ > 0, "At least 1 token has to be minted");

        // Whitelist check
        require(_whitelistMap[wallet_], "Wallet is not whitelisted");

        // Value check
        require(msg.value > 0, "Value has to be greater than 0");
        require(msg.value % privateMintPrice == 0, "Value has to be a multiple of the price");

        uint256 tokensToMint = msg.value / privateMintPrice;
        require(tokensToMint == count_, "Given count does not match provided value");

        uint256 currentTokens = privateMintMap[wallet_];

        // Token amount check
        require(tokensToMint + currentTokens <= privateMintTokensPerWallet, "Total token count is higher than the max allowed tokens per wallet for the private mint");
        require(_privateMintTokenCounter.current() + tokensToMint <= privateMintSupply, "There are not enough tokens left in the private mint");

        privateMintMap[wallet_] += tokensToMint;

        for (uint256 i = 0; i < tokensToMint; ++i) {
            _safeMint(wallet_, _tokenCounter.current() + 1);
            _tokenCounter.increment();
            _privateMintTokenCounter.increment();
        }
    }

    /*
    * Returns the amount of tokens minted in the private mint
    */
    function privateMintTokenCount() public view returns (uint256) {
        return _privateMintTokenCounter.current();
    }

    /*
    * Returns the amount of tokens minted by the sender wallet in the private mint
    */
    function privateMintTokens() public view returns (uint256) {
        return privateMintMap[_msgSender()];
    }

    /*
    * Returns the amount of tokens minted by the given wallet in the private mint
    */
    function privateMintTokensOf(address wallet) public view onlyOwner returns (uint256) {
        return privateMintMap[wallet];
    }

    /*
    * Stops the private mint and caps the private mint supply if necessary. May only be called if the private mint is active.
    */
    function stopPrivateMint() public onlyOwner {
        require(privateMintStarted, "Private mint has not been started");
        privateMintStopped = true;
        privateMintSupply = _privateMintTokenCounter.current();
    }

    /*
    * Starts the public mint with a specific price and supply. This method may not be called once the mint has been started.
    */
    function startPublicMint(uint256 price_, uint256 supply_, uint256 tokensPerWallet_) public onlyOwner {
        require(!publicMintActive(), "Public mint has already been started");
        require(privateMintStarted, "Public mint must start after private mint");
        require(!privateMintActive(), "Private mint is still active");
        require(privateMintStopped, "Private mint has to be cleaned up using the stopPrivateMint() function before starting the public mint");
        require(tokensPerWallet_ > 0, "Requires at least 1 token per wallet");

        publicMintStarted = true;
        publicMintPrice = price_;
        publicMintSupply = supply_;
        publicMintTokensPerWallet = tokensPerWallet_;
        emit PublicMintStarted(price_, supply_, tokensPerWallet_);
    }

    /*
    * Returns true if the public mint has been started and not yet stopped. false otherwise
    */
    function publicMintActive() public view returns (bool) {
        return publicMintStarted && !publicMintStopped && _publicMintTokenCounter.current() < publicMintSupply;
    }

    /*
    * Mint tokens while the public mint is active
    */
    function publicMint(uint256 count_) public payable {
        _publicMint(_msgSender(), count_);
    }

    /*
    * Mint tokens to wallet while the public mint is active
    */
    function _publicMint(address wallet_, uint256 count_) private {
        // Basic check
        require(publicMintActive(), "Public mint is not active");

        // Count check
        require(count_ > 0, "At least 1 token has to be minted");

        // Value check
        require(msg.value > 0, "Value has to be greater than 0");
        require(msg.value % publicMintPrice == 0, "Value has to be a multiple of the price");

        uint256 tokensToMint = msg.value / publicMintPrice;
        require(tokensToMint == count_, "Given count does not match provided value");

        uint256 currentTokens = publicMintMap[wallet_];

        // Token amount check
        require(tokensToMint + currentTokens <= publicMintTokensPerWallet, "Total token count is higher than the max allowed tokens per wallet for the public mint");
        require(_publicMintTokenCounter.current() + tokensToMint <= publicMintSupply, "There are not enough tokens left in the public mint");

        publicMintMap[wallet_] += tokensToMint;

        for (uint256 i = 0; i < tokensToMint; ++i) {
            _safeMint(wallet_, _tokenCounter.current() + 1);
            _tokenCounter.increment();
            _publicMintTokenCounter.increment();
        }
    }

    /*
    * Returns the amount of tokens minted in the public mint
    */
    function publicMintTokenCount() public view returns (uint256) {
        return _publicMintTokenCounter.current();
    }

    /*
    * Returns the amount of tokens minted by the sender wallet in the public mint
    */
    function publicMintTokens() public view returns (uint256) {
        return publicMintMap[_msgSender()];
    }

    /*
   * Returns the amount of tokens minted by the given wallet in the public mint
   */
    function publicMintTokensOf(address wallet) public view onlyOwner returns (uint256) {
        return publicMintMap[wallet];
    }

    /*
    * Stops the public mint
    */
    function stopPublicMint() public onlyOwner {
        require(publicMintStarted, "Public mint has not been started");
        publicMintStopped = true;
        publicMintSupply = _publicMintTokenCounter.current();
    }

    /*
    * Mint a token for a different wallet, used by crossmint
    */
    function crossmint(address wallet_, uint256 count_) public payable onlyCrossmint {
        if (privateMintActive()) {
            _privateMint(wallet_, count_);
        } else if (publicMintActive()) {
            _publicMint(wallet_, count_);
        } else {
            revert("No mint active");
        }
    }

    /*
    * Returns the total of tokens minted by the sender wallet
    */
    function mintedTokenCount() public view returns (uint256) {
        return privateMintTokens() + publicMintTokens();
    }

    /*
    * Returns the total of tokens minted by the given wallet
    */
    function mintedTokenCountOf(address wallet) public view onlyOwner returns (uint256) {
        return privateMintTokensOf(wallet) + publicMintTokensOf(wallet);
    }

    /*
    * Mint a specific amount of tokens. The tokens will be minted on the owners wallet.
    * Can be used to activate the collection on a marketplace, like OpenSeas.
    */
    function preMint(uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; ++i) {
            _mint(owner(), _tokenCounter.current() + 1);
            _tokenCounter.increment();
        }
        preMintCount = _tokenCounter.current();
    }

    /*
    * Requests randomness from the oracle
    */
    function requestReveal(string memory realURI_) public onlyOwner {
        require(!revealed, "Metadata has already been revealed");

        __realURI = realURI_;
        revealVrfRequestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    /*
    * Will be called by ChainLink with an array containing 1 random word (our seed)
    */
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        require(!revealed, "Metadata has already been revealed");
        seed = randomWords[0];
        revealed = true;
        emit Revealed(__realURI, seed);
    }

    /*
    * Withdraw all the ETH stored inside the contract to the owner wallet
    */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "The contract contains no ETH to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }

    /*
    * Transfer the LINK of this contract to the owner wallet
    */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK);
        uint256 balance = link.balanceOf(address(this));
        require(balance > 0, "The contract contains no LINK to withdraw");
        require(link.transfer(_msgSender(), balance), "Unable to withdraw LINK");
    }

    /*
    * Returns a boolean indicating if the token is currently staked
    */
    function tokens() public view returns (uint256[] memory) {
        uint256[] memory possibleOwnedTokens = new uint256[](totalSupply());
        uint256 index = 0;
        for (uint256 i = 1; i <= totalSupply(); ++i) {
            if (ownerOf(i) == _msgSender()) {
                possibleOwnedTokens[index++] = i;
            }
        }
        // Copy token ids to correct sized array
        uint256[] memory ownedTokens = new uint256[](index);
        for (uint256 i = 0; i < index; ++i) {
            ownedTokens[i] = possibleOwnedTokens[i];
        }
        return ownedTokens;
    }

    /*
    * Returns a boolean indicating if the token is currently staked
    */
    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256[] memory possibleOwnedTokens = new uint256[](totalSupply());
        uint256 index = 0;
        for (uint256 i = 1; i <= totalSupply(); ++i) {
            if (ownerOf(i) == wallet) {
                possibleOwnedTokens[index++] = i;
            }
        }
        // Copy token ids to correct sized array
        uint256[] memory ownedTokens = new uint256[](index);
        for (uint256 i = 0; i < index; ++i) {
            ownedTokens[i] = possibleOwnedTokens[i];
        }
        return ownedTokens;
    }

    /*
       Return the metadata URI of the given token
    */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory){
        if (!revealed) return __baseURI;
        uint256 offset = seed % totalSupply();
        uint256 metaId = ((tokenId + offset) % totalSupply()) + 1;
        return string.concat(__realURI, '/', metaId.toString(), '.json');
    }

}