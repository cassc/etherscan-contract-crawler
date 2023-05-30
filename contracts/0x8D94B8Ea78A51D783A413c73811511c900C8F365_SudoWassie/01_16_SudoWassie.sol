// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721i.sol";

contract SudoWassie is ERC721i, ReentrancyGuard {
    using Strings for uint256;
    using Address for address payable;
    using Counters for Counters.Counter;

    /// @dev Some sales-related events
    event Purchase(
        address indexed newOwner,
        uint256 amount,
        uint256 lastTokenId
    );
    event Withdraw(address indexed receiver, uint256 amount);
    event PriceUpdate(uint256 newPrice);

    /// @dev Track number of tokens sold
    Counters.Counter internal _lastPurchasedTokenId;

    /// @dev ERC721 Base Token URI
    string internal _baseTokenURI;

    string public uriSuffix = ".json";

    // Individual NFT Sale Price in ETH
    uint256 public _pricePer;

    /// @dev The Deployer of this contract is also the Owner and the Pre-Mint Receiver.
    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        uint256 maxSupply
    ) ERC721i(name, symbol, _msgSender(), maxSupply) {
        _baseTokenURI = baseUri;

        // Since we pre-mint to "owner", allow this contract to transfer on behalf of "owner" for sales.
        _setApprovalForAll(_msgSender(), address(this), true);
    }

    /// @dev Let's Pre-Mint a Gazillion NFTs!!  (wait, 2^^256-1 equals what again?)
    function preMint() external onlyOwner {
        _preMint();
    }

    /**
     * @dev Purchases from the Pre-Mint Receiver are a simple matter of transferring the token.
     * For this reason, we can provide a very simple "batch" transfer mechanism in order to
     * save even more gas for our users.
     */
    function purchase(uint256 amount)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 amountTransferred)
    {
        uint256 index = _lastPurchasedTokenId.current();
        if (index + amount > _maxSupply) {
            amount = _maxSupply - index;
        }

        uint256 cost;
        if (_pricePer > 0) {
            cost = _pricePer * amount;
            require(msg.value >= cost, "Insufficient payment");
        }

        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            _lastPurchasedTokenId.increment();
            tokenIds[i] = _lastPurchasedTokenId.current();
        }
        amountTransferred = _batchTransfer(owner(), _msgSender(), tokenIds);

        emit Purchase(_msgSender(), amount, _lastPurchasedTokenId.current());

        // Refund overspend
        if (msg.value > cost) {
            payable(_msgSender()).sendValue(msg.value - cost);
        }
    }

    /// @dev Set the price for sales to maintain a purchase price of $1 USD
    function setPrice(uint256 newPrice) external onlyOwner {
        _pricePer = newPrice;
        emit PriceUpdate(newPrice);
    }

    /// @dev Withdraw ETH from Sales
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        address payable receiver = payable(owner());
        receiver.sendValue(amount);
        emit Withdraw(receiver, amount);
    }

    /// @dev Provide a Base URI for Token Metadata (override defined in ERC721.sol)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    //
    // Batch Transfers
    //

    function batchTransfer(address to, uint256[] memory tokenIds)
        external
        virtual
        returns (uint256 amountTransferred)
    {
        amountTransferred = _batchTransfer(_msgSender(), to, tokenIds);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external virtual returns (uint256 amountTransferred) {
        amountTransferred = _batchTransfer(from, to, tokenIds);
    }

    function _batchTransfer(
        address from,
        address to,
        uint256[] memory tokenIds
    ) internal virtual returns (uint256 amountTransferred) {
        uint256 count = tokenIds.length;

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokenIds[i];

            // Skip invalid tokens; no need to cancel the whole tx for 1 failure
            // These are the exact same "require" checks performed in ERC721.sol for standard transfers.
            if (
                (ownerOf(tokenId) != from) ||
                (!_isApprovedOrOwner(from, tokenId)) ||
                (to == address(0))
            ) {
                continue;
            }

            _beforeTokenTransfer(from, to, tokenId);

            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            amountTransferred += 1;
            _owners[tokenId] = to;

            emit Transfer(from, to, tokenId);

            _afterTokenTransfer(from, to, tokenId);
        }

        // We can save a bit of gas here by updating these state-vars atthe end
        _balances[from] -= amountTransferred;
        _balances[to] += amountTransferred;
    }

    //
    // Pre Mint
    //

    /**
     * @dev Change preMintReceiver.
     */
    function setPreMintReceiver(address newPreMintReceiver) public onlyOwner {
        require(
            newPreMintReceiver != address(0),
            "ERC721i: new preMintReceiver cannot be the null address"
        );
        _preMintReceiver = newPreMintReceiver;
    }

    /**
     * @dev Getter function for preMintReceiver.
     */
    function getPreMintReceiver() public view returns (address) {
        return _preMintReceiver;
    }
}