// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GenerativeCollectionToken is ERC721 {
    string _token_uri;
    address _owner;
    uint256 _price = 0;
    uint256 _royalty;
    uint256 _limit;
    uint256 _limit_per_wallet;
    uint256 _start_time = 0;
    address _platform_address;

    uint256 _quantity = 1;
    mapping(address => uint256) private _minted_amount_by_user;
    mapping(uint256 => address) private _creator;

    constructor(string memory name_, string memory symbol_, string memory token_uri_, address owner_, uint256 price_, uint256 royalty_, uint256 limit_, uint256 limit_per_wallet_, uint256 start_time_, address platform_address_) ERC721(name_, symbol_) {
        _token_uri = token_uri_;
        _owner = owner_;
        _price = price_;
        _royalty = royalty_;
        _limit = limit_;
        _limit_per_wallet = limit_per_wallet_;
        _start_time = start_time_;
        _platform_address = platform_address_;
    }

    function mint(uint256 quantity_) external payable  {
        require(_start_time < block.timestamp, "Not started yet");
        require(_limit >= _quantity + quantity_, "Limit exceeded");
        require(_minted_amount_by_user[msg.sender] + quantity_ <= _limit_per_wallet, "Limit per wallet exceeded");
        require(msg.value >= _price * quantity_, "Not enough funds send");
        for (uint256 i = 0; i < quantity_; i++) {
            _mint(msg.sender, _quantity);
            _quantity += 1;
        }
        _minted_amount_by_user[msg.sender] += quantity_;
        payable(_owner).transfer((msg.value * 975) / 1000);
        payable(_platform_address).transfer((msg.value * 25) / 1000);
    }

    function concatenate(string memory a, string memory b) private pure returns (string memory) {
        return string(abi.encodePacked(a, "", b));
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "Token does not exists");
        return concatenate(_token_uri, concatenate(Strings.toString(token_id), ".json"));
    }

    function getRoyalty(uint256 token_id) public view returns (uint256) {
        require(_exists(token_id), "Token does not exists");
        return _royalty;
    }

    function getCreator(uint256 token_id) public view returns (address) {
        require(_exists(token_id), "Token does not exists");
        return _creator[token_id];
    }
}