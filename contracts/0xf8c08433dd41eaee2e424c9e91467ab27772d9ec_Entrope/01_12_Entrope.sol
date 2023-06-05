pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Entrope is ERC721, Ownable {
    string public _base;

    // Token price
    uint256 public tokenPrice = 2e7 gwei;

    // Token supply
    uint256 public supply = 2358;

    // Minting sale state
    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }
    SaleState saleState = SaleState.CLOSED;

    // Whitelist token allowances
    mapping(address => uint256) presaleAllowance;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(uint256 _projectId) ERC721("Entrope", "*") {
        _base = string(
            abi.encodePacked(
                "http://host.entropes.xyz/project/",
                Strings.toString(_projectId)
            )
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(_base, "/token-"));
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _base = _uri;
    }

    function setPresaleAllowance(address _to, uint256 _allowance)
        public
        onlyOwner
    {
        presaleAllowance[_to] = _allowance;
    }

    function setPresaleAllowances(address[] memory _to, uint256 _allowance)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            presaleAllowance[_to[i]] = _allowance;
        }
    }

    function getPresaleAllowance(address _to) public view returns (uint256) {
        return presaleAllowance[_to];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return presaleAllowance[_account] > 0;
    }

    function isWhitelisted(address _account, uint256 _count)
        public
        view
        returns (bool)
    {
        return presaleAllowance[_account] >= _count;
    }

    /**
     * @dev Sets sale state to CLOSED (0), PRESALE (1), or OPEN (2).
     */
    function setSaleState(uint8 _state) public onlyOwner {
        saleState = SaleState(_state);
    }

    function getSaleState() public view returns (uint8) {
        return uint8(saleState);
    }

    function setPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function getPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function getTokenCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getSupply() public view returns (uint256) {
        return supply;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    /**
     * @dev Mints a token to `to`.
     */
    function awardToken(address _to) public onlyOwner returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(_to, newItemId);
        return newItemId;
    }

    /**
     * @dev Mints `_count` tokens to `_to`.
     */
    function awardTokens(uint256 _count, address _to)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory ids = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            uint256 newItemId = _tokenIds.current();
            _tokenIds.increment();
            _safeMint(_to, newItemId);
            ids[i] = newItemId;
        }
        return ids;
    }

    /**
     * @dev Mints reserved tokens to msg.sender during presale.
     */
    function buyPresaleTokens(uint256 _count) public payable {
        require(saleState == SaleState.PRESALE, "Not in presale");
        uint256 totalPrice = tokenPrice * _count;
        require(
            msg.value >= totalPrice,
            "Insufficient input balance, must be > price"
        );
        require(
            _tokenIds.current() < supply,
            "Token supply insufficent for the given count"
        );
        require(
            isWhitelisted(msg.sender, _count),
            "Insufficient reserved tokens for your address"
        );
        for (uint256 i = 0; i < _count; i++) {
            uint256 newItemId = _tokenIds.current();
            _tokenIds.increment();
            _safeMint(msg.sender, newItemId);
        }
        presaleAllowance[msg.sender] -= _count;

        // reconcile payments
        bool sent = payable(owner()).send(totalPrice);
        require(sent, "Failed to send Ether");
        if (msg.value - totalPrice > 0) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    /**
     * @dev Mints a token to msg.sender during open sale.
     */
    function buyToken() public payable {
        require(saleState != SaleState.CLOSED, "Sales are closed");
        require(
            msg.value >= tokenPrice,
            "Insufficient input balance, must be > price"
        );
        require(_tokenIds.current() < supply, "Token supply limit reached");
        if (saleState == SaleState.PRESALE) {
            require(
                isWhitelisted(msg.sender),
                "No tokens reserved for your address"
            );
        }

        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, newItemId);
        if (saleState == SaleState.PRESALE) {
            presaleAllowance[msg.sender] -= 1;
        }

        // Reconcile payments
        bool sent = payable(owner()).send(tokenPrice);
        require(sent, "Failed to send Ether");
        if (msg.value - tokenPrice > 0) {
            payable(msg.sender).transfer(msg.value - tokenPrice);
        }
    }

    fallback() external payable {
        require(msg.value > 0, "Insufficient input balance (0)");
        payable(owner()).transfer(msg.value);
    }
}