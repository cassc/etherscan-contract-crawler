// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 * @title OrangeadNFT
 * @dev Orangead contract implementing an NFT token.
 */
contract OrangeadNFT is ERC721A, Ownable {
    /// Maximum amount of tokens that can be minted + 1 NFT to initiate OpenSea collection.
    uint256 public maxSupply = 223;

    /// Initial part of the URI for the metadata
    string private baseURI = "";
    /// The URI for when the NFTs have not yet been revealed
    string private unrevealedURI =
        "https://oa-nft-unrevealed-q3wbqijt1a.s3.ca-central-1.amazonaws.com/json/";

    /// Minting price during Sale
    uint256 private mintPrice = 2 ether;

    /// Timestamp of when the Sale has been opened
    uint256 internal launchTime = 0;
    /// Timestamp of when the NFTs has been revealed
    uint256 internal revealTime = 0;

    /// Dictates whether sale is paused or not
    bool private paused = false;

    /// Confirm message to call the burnTokens
    string private confirmMessage = "OK TO BURN";

    /// Current state of sale
    enum State {
        NoSale,
        Sale
    }

    /// Restricted to NoSale state only
    modifier NoSaleOnly() {
        require(
            saleState() == State.NoSale,
            "Sale state has already been activated"
        );
        _;
    }

    /**
     * @dev Deploy the contract, then mint the first one for OpenSea initialization.
     */
    constructor() ERC721A("OrangeadNFT", "OA") {
        _mint(msg.sender, 1);
    }

    /**
     * @dev Handles unexpected transactions / function calls sent to the contract
     */
    /// For empty calldata (and any value)
    /// e.g: all calls made via send() or transfer()
    receive() external payable {}

    /// When no other function matches (not even the receive() function)
    fallback() external payable {
        revert("No matching function");
    }

    /**
     * @dev We don't want to renounceOwnership(), therefore revert()
     */
    function renounceOwnership() public view override onlyOwner {
        revert("This smart contract is still under Orangead's control");
    }

    /**
     * @dev @return The current state of sale
     */
    function saleState() public view returns (State) {
        if (launchTime == 0) {
            return State.NoSale;
        } else {
            return State.Sale;
        }
    }

    /**
     * @dev @return The current minting price
     */
    function _mintPrice() public view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev @return The unrevealed URI of the collection
     */
    function _unrevealedURI() public view virtual returns (string memory) {
        return unrevealedURI;
    }

    /**
     * @dev @return The revealed URI of the collection
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets the unrevealed baseURI for the metadata in case needed for IPFS
     * @param _newUnrevealedURI New URI for the unrevealed metadata
     */
    function setUnrevealedURI(string memory _newUnrevealedURI) public onlyOwner {
        unrevealedURI = _newUnrevealedURI;
    }

    /**
     * @dev Sets the current baseURI for the metadata in case needed for IPFS
     * @param _newBaseURI New base URI for the metadata
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Set the new total supply of the contract, only at NoSale state
     * @param _newMaxSupply New total supply of the contract
     */
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner NoSaleOnly {
        maxSupply = _newMaxSupply;
    }

    /**
     * @dev Set new minting price, only at NoSale state
     * @param _newMintPrice New minting price
     */
    function setMintPrice(uint256 _newMintPrice) public onlyOwner NoSaleOnly {
        mintPrice = _newMintPrice;
    }

    /**
     * @dev Set sale state to Sale
     */
    function setToSale() public onlyOwner NoSaleOnly {
        launchTime = block.timestamp;
    }

    /**
     * @dev Let user mint a desired amount of tokens
     * @param _quantity Amount of tokens to mint
     */
    function mint(uint256 _quantity) public payable {
        require(!paused, "Sale is paused");

        State saleState_ = saleState();
        require(saleState_ != State.NoSale, "Sale is not open yet");

        require(
            totalSupply() + _quantity <= maxSupply,
            "Not enough NFTs left to mint. Please wait for the upcoming public sale"
        );
        require(
            msg.value >= _mintPrice() * _quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );
        require(
            msg.value == _mintPrice() * _quantity,
            "Ether sent must be exact as the minting price for this amount of NFTs"
        );

        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev @return The URI for a given _tokenId
     * @param _tokenId The ID of the desired NFT
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentURI;
        revealTime == 0 ? currentURI = _unrevealedURI() : currentURI = _baseURI();

        return
            bytes(currentURI).length > 0
                ? string(abi.encodePacked(currentURI, _toString(_tokenId), ".json"))
                : "";
    }

    /**
     * @dev Burn the rest of tokens that have not yet been sold
     * @param _message Message to confirm the burn
     */
    function burnTokens(string memory _message) public onlyOwner {
        require(
            keccak256(abi.encodePacked(confirmMessage)) ==
                keccak256(abi.encodePacked(_message)),
            "Confirmation message is incorrect"
        );
        maxSupply = totalSupply();
    }

    /**
     * @dev Retrieve all funds received from minting
     */
    function withdraw() public onlyOwner {
        uint256 balance = contractBalance();
        require(balance > 0, "No funds to withdraw, balance is 0");

        _withdraw(payable(msg.sender), balance);
    }

    /**
     * @dev @return The current balance of the contract
     */
    function contractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Send a desired amount of funds to a wallet
     * @param _account The address of the desired wallet
     * @param _amount The amount of funds to send
     */
    function _withdraw(address payable _account, uint256 _amount) internal {
        (bool sent, ) = _account.call{value: _amount}("");
        require(sent, "Failed to send ether");
    }

    /**
     * @dev @return Whether sale is paused or not
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Toggle pause state of sale
     */
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Set the NFTs collection to be revealed
     */
    function reveal() public onlyOwner {
        require(revealTime == 0, "Collection has already been revealed");
        revealTime = block.timestamp;
    }
}