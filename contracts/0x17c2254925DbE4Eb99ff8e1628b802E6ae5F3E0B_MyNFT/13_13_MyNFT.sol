//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdrawable {
    event Withdrawed(address sender, address payee, uint256 amount);

    uint256 private totalSharesAmount;
    uint256 private totalTokenReleased;
    address[] private payeesAddresses;
    mapping(address => uint256) private tokenReleased;
    mapping(address => uint256) private shares;

    constructor(address[] memory _payeesIn, uint256[] memory _sharesIn) {
        require(
            _payeesIn.length == _sharesIn.length,
            "TokenPaymentSplitter: payees and shares length mismatch"
        );
        require(_payeesIn.length > 0, "TokenPaymentSplitter: no payees");

        for (uint256 i = 0; i < _payeesIn.length; i++) {
            _addPayee(_payeesIn[i], _sharesIn[i]);
        }
    }

    function totalShares() external view returns (uint256) {
        return totalSharesAmount;
    }

    function hasShares(address _account) public view returns (bool) {
        return shares[_account] > 0;
    }

    function sharesOf(address _account) external view returns (uint256) {
        return shares[_account];
    }

    function payees() external view returns (address[] memory) {
        return payeesAddresses;
    }

    function _addPayee(address _account, uint256 _shares) private {
        require(
            _account != address(0),
            "TokenPaymentSplitter: account is the zero address"
        );
        require(_shares > 0, "TokenPaymentSplitter: shares are 0");
        require(
            shares[_account] == 0,
            "TokenPaymentSplitter: account already has shares"
        );
        payeesAddresses.push(_account);
        shares[_account] = _shares;
        totalSharesAmount = totalSharesAmount + _shares;
    }

    function availableAmountToWithdraw(address _account)
        public
        view
        returns (uint256)
    {
        require(
            hasShares(_account),
            "TokenPaymentSplitter: account has no shares"
        );

        uint256 tokenTotalReceived = address(this).balance + totalTokenReleased;
        uint256 payment = (tokenTotalReceived * shares[_account]) /
            totalSharesAmount -
            tokenReleased[_account];

        return payment;
    }

    function withdraw(address _account) external {
        require(
            hasShares(_account),
            "TokenPaymentSplitter: account has no shares"
        );
        require(msg.sender == _account, "Withraw can only payee");

        uint256 payment = availableAmountToWithdraw(_account);
        require(payment != 0, "TokenPaymentSplitter: account has zero payment");

        tokenReleased[_account] = tokenReleased[_account] + payment;
        totalTokenReleased = totalTokenReleased + payment;

        (bool success, ) = _account.call{value: payment}("");
        require(success, "Transfer failed.");

        emit Withdrawed(msg.sender, _account, payment);
    }
}

contract MyNFT is ERC721, Ownable, Withdrawable {
    event AddedToWhitelist(address sender);
    event RemovedFromWhitelist(address sender);

    using Counters for Counters.Counter;
    uint256 private NFTprice;

    // Private state variable
    Counters.Counter private tokenIds;
    Counters.Counter private lastSoldID;

    uint256 totalTokenCountTarget;

    string constant dummyUrl =
        "ipfs://QmPgSXnkju1wj4GhJoHAokMAY8YVrw9vxXB7ATHZMP2yz9";
    string baseURIdata;

    mapping(address => bool) private whitelist;
    uint256 private whitelistPrice;
    bool private allowBuyForWhitelist;
    bool private allowBuyForPublic;

    constructor(
        uint256 _price,
        address[] memory _payeesIn,
        uint256[] memory _sharesIn,
        uint256 _tokenAmount
    ) ERC721("MyNFT", "NFT") Withdrawable(_payeesIn, _sharesIn) {
        require(_price != 0, "NFT price is zero");
        require(_tokenAmount != 0, "Mint zero tokens");

        totalTokenCountTarget = _tokenAmount;
        NFTprice = _price;

        whitelistPrice = _price;
    }

    // Whitelist
    function isInWhitelist(address _account) public view returns (bool) {
        return whitelist[_account];
    }

    function getWhitelistPrice() external view returns (uint256) {
        return whitelistPrice;
    }

    function getPublicPrice() external view returns (uint256) {
        return NFTprice;
    }

    function getAllowBuyForWhitelist() external view returns (bool) {
        return allowBuyForWhitelist;
    }

    function getAllowBuyForPublic() external view returns (bool) {
        return allowBuyForPublic;
    }

    function isBuyAllowed(address _account) public view returns (bool) {
        return
            isInWhitelist(_account) ? allowBuyForWhitelist : allowBuyForPublic;
    }

    // Privileged methods

    function addToWhitelist(address[] calldata _accounts) external onlyOwner {
        require(_accounts.length <= 500, "Maximum allowed length is 500");

        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;

            emit AddedToWhitelist(_accounts[i]);
        }
    }

    function removeFromWhitelist(address[] calldata _accounts)
        external
        onlyOwner
    {
        require(_accounts.length <= 500, "Maximum allowed length is 500");

        for (uint256 i = 0; i < _accounts.length; i++) {
            delete whitelist[_accounts[i]];

            emit RemovedFromWhitelist(_accounts[i]);
        }
    }

    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    function setAllowBuyForWhitelist(bool allow) external onlyOwner {
        allowBuyForWhitelist = allow;
    }

    function setAllowBuyForPublic(bool allow) external onlyOwner {
        allowBuyForWhitelist = allow;
        allowBuyForPublic = allow;
    }

    // NFTs
    function _mintNFT(address _to) private returns (uint256) {
        tokenIds.increment();

        uint256 newItemId = tokenIds.current();
        _safeMint(_to, newItemId, "");

        return newItemId;
    }

    function buyNFTs(address _to, uint256 _count) external payable {
        uint256 price = priceNFT(_to) * _count;

        require(
            lastSoldID.current() + _count <= totalTokenCountTarget,
            "Not enough tokens for sale"
        );
        require(msg.value >= price, "Not enough ETH to buy tokens");
        require(isBuyAllowed(_to), "Buy is currently not allowed");

        for (uint256 i = 0; i < _count; i++) {
            lastSoldID.increment();
            _mintNFT(_to);
        }
    }

    function availableNFTs() external view returns (uint256) {
        return totalTokenCountTarget - lastSoldID.current();
    }

    function mintTargetNFTs() external view returns (uint256) {
        return totalTokenCountTarget;
    }

    function mintedNFTs() external view returns (uint256) {
        return tokenIds.current();
    }

    function priceNFT(address _account) public view returns (uint256) {
        return isInWhitelist(_account) ? whitelistPrice : NFTprice;
    }

    function revealedNFTs() public view returns (bool) {
        return bytes(baseURIdata).length > 0;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        require(bytes(baseURIdata).length == 0, "Base URI already set");

        baseURIdata = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!revealedNFTs()) return dummyUrl;

        return super.tokenURI(_tokenId);
    }
}