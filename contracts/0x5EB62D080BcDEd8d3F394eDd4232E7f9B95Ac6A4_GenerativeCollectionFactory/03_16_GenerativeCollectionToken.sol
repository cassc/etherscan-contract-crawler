// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721, Strings} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IRandomizer} from "../../Randomizer/IRandomizer.sol";

contract GenerativeCollectionToken is ERC721, ERC2981, ReentrancyGuard {
    string private _token_uri;
    address private _owner;
    uint256 private _price = 0;
    uint96 private _fee;
    uint256 private _limit;
    uint256 private _limit_per_wallet;
    uint256 private _start_time = 0;
    address private _platform_address;
    address[] private _access_tokens;
    address[] private _profit_split_addresses;
    uint256[] private _profit_split_amount;
    uint256 private _total;
    uint256 private _free_mint;
    address private _randomizer_address;
    uint256 private total_supply;

    mapping(uint256 => uint256) _id_to_metadata__id;
    mapping(address => uint256) private _minted_amount_by_user;

    constructor(
        string[3] memory metadata_,
        address owner_,
        uint96 fee_,
        uint256[5] memory uints,
        address platform_address_,
        address[] memory access_tokens_,
        address[] memory profit_split_addresses_,
        uint256[] memory profit_split_amount_,
        address randomizer_address_
    ) ERC721(metadata_[0], metadata_[1]) {
        _token_uri = metadata_[2];
        _owner = owner_;
        _price = uints[0];
        _fee = fee_;
        _limit = uints[1];
        _limit_per_wallet = uints[2];
        _start_time = uints[3];
        _free_mint = uints[4];
        _platform_address = platform_address_;
        _access_tokens = access_tokens_;
        _profit_split_addresses = profit_split_addresses_;
        _profit_split_amount = profit_split_amount_;
        _randomizer_address = randomizer_address_;
        for (uint256 i = 0; i < profit_split_amount_.length; i++) {
            _total += profit_split_amount_[i];
        }
        require(fee_ <= 1000 && _total <= 975);
    }

    function mint(uint256 quantity_) external payable nonReentrant {
        require(_limit >= total_supply + quantity_);
        require(_minted_amount_by_user[msg.sender] + quantity_ <= _limit_per_wallet);
        bool has_access_token = false;
        if (total_supply + quantity_ <= _free_mint) {
            for (uint256 i = 0; i < _access_tokens.length; i++) {
                if (IERC721(_access_tokens[i]).balanceOf(msg.sender) > 0) {
                    has_access_token = true;
                    break;
                }
            }
        }
        if (total_supply + quantity_ > _free_mint || !has_access_token) {
            require(_start_time < block.timestamp);
            require(msg.value >= _price * quantity_);
        }
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 tokenId = IRandomizer(_randomizer_address)
                .requestRandomWords();
            _mint(msg.sender, tokenId);
            _id_to_metadata__id[tokenId] = total_supply + i + 1;
            _setTokenRoyalty(tokenId, msg.sender, _fee);
        }
        _minted_amount_by_user[msg.sender] += quantity_;
        if (_free_mint > total_supply + quantity_ && has_access_token) {
            uint256 profit_spit = (msg.value * _total) / 1000;
            uint256 owner_fee = ((msg.value * 975) / 1000) - profit_spit;
            payable(_owner).transfer(owner_fee);
            payable(_platform_address).transfer(
                msg.value - profit_spit - owner_fee
            );

            for (uint256 i = 0; i < _profit_split_amount.length; i++) {
                payable(_profit_split_addresses[i]).transfer(
                    (msg.value * _profit_split_amount[i]) / 1000
                );
            }
        }
        total_supply += quantity_;
    }

    function concatenate(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, "", b));
    }

    function tokenURI(uint256 token_id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(token_id));
        return
            concatenate(
                _token_uri,
                concatenate(
                    Strings.toString(_id_to_metadata__id[token_id]),
                    ".json"
                )
            );
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setAccessTokens(address[] memory access_tokens_) public {
        require(owner() == msg.sender);
        _access_tokens = access_tokens_;
    }

    function getAccessTokens() public view returns (address[] memory) {
        return _access_tokens;
    }

    function setProfitShare(
        address[] memory profit_split_addresses_,
        uint256[] memory profit_split_amount_
    ) public {
        require(owner() == msg.sender);
        uint256 check_total = 0;
        for (uint256 i = 0; i < profit_split_amount_.length; i++) {
            check_total += profit_split_amount_[i];
        }
        require(check_total <= 975);
        _profit_split_addresses = profit_split_addresses_;
        _profit_split_amount = profit_split_amount_;
    }

    function getProfitShare()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (_profit_split_addresses, _profit_split_amount);
    }

    function setFreeMint(uint96 fee_) public {
        require(msg.sender == owner());
        require(_free_mint <= _limit);
        _fee = fee_;
    }

    function getFreeMint() public view returns (uint256) {
        return _free_mint;
    }

}