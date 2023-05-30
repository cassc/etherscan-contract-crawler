// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Paw
 * Paw - a contract for non-fungible PAW THE HYPER LYNX.
 */
contract Paw is ERC721Tradable {
    using SafeMath for uint256;

    uint256 private _pawSupply = 10296;
    uint256 private _price = 20000000000000000;
    // O: inactive, 1: limitted, 2: public
    uint8 private _saleState = 0;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _whitelistBalances;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PAW THE HYPER LYNX", "PTHL", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmSa554zsuZKdxLWThLUM92t7AJbGuxd23nvY2d2tnbKcj/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmUvGTgJYyKhreGKJb1xi8zpYZmrgR88FC4wivPz6JfMfo";
    }

    function changePrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function changePawSupply(uint256 pawSupply) public onlyOwner {
        _pawSupply = pawSupply;
    }

    function getSaleState() public view returns (uint8) {
        return _saleState;
    }

    function changeSaleState(uint8 state) public onlyOwner {
        _saleState = state;
    }

    function buyPaw(uint256 amount) public payable {
        require(_saleState == 2, "It's not public sales");
        require(amount <= 20, "You can not buy more than 20 Paws");
        require(totalSupply().add(amount) <= _pawSupply, "Purchase would exceed max supply of Paws");
        require(msg.value >= (_price * amount), "Insufficient funds to purchase");
        address payable receiver = payable(owner());
        receiver.transfer(msg.value);
        for (uint256 j = 0; j < amount; j++) {
            safeMint(msg.sender);
        }
    }

    function whitelistBuyPaw(uint256 amount) public payable {
        require(_saleState == 1, "It's not private sales");
        uint256 _balance = whitelistBalanceOf(msg.sender);
        require(_balance < 2, "This account has more than 2 NFTs");
        require(_balance.add(amount) <= 2, "this account buy more than 2 NFTs");
        require(totalSupply().add(amount) <= _pawSupply, "Purchase would exceed max supply of Paws");
        require(msg.value >= (_price * amount), "Insufficient funds to purchase");
        require(whitelistHas(msg.sender), "This account is not available");
        address payable receiver = payable(owner());
        receiver.transfer(msg.value);
        _whitelistBalances[msg.sender] += amount;
        for (uint256 j = 0; j < amount; j++) {
            safeMint(msg.sender);
        }
    }

    function mintToOwner(uint256 amount) public onlyOwner {
        require(totalSupply().add(amount) <= _pawSupply, "Mint would exceed max supply of Paws");
        for (uint256 i = 0; i < amount; i++) {
            mintTo(msg.sender);
        }
    }

    function transferNFTs(address[] memory targetAccounts, uint16 startTokenId) public onlyOwner {
        require(startTokenId == totalSupply().add(1), "Wrong token id");
        require(targetAccounts.length > 0, "No one to transfer");
        for (uint256 k = 0; k < targetAccounts.length; k++) {
            safeMint(targetAccounts[k]);
        }
    }

    function addAccountsToWhitelist(address[] memory accounts) public onlyOwner {
        require(accounts.length > 0, "There are not accounts to add");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }

    function removeAccountsFromWhitelist(address[] memory accounts) public onlyOwner {
        require(accounts.length > 0, "There are not accounts to delete");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (whitelistHas(accounts[i])) {
                delete _whitelist[accounts[i]];
            }
        }
    }

    function whitelistHas(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function whitelistBalanceOf(address account) public view returns (uint256) {
        return _whitelistBalances[account];
    }
}