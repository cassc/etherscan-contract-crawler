// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../../rooms/interface/IRoomContractMin.sol";
import "../../helpers/IDelegateOwnership.sol";

contract MultipleToken is ERC1155 {
    struct Token {
        uint256 token_id;
        address creator;
        string token_uri;
        uint256 royalty;
        bool first_sale;
    }

    Token[] public tokens;
    IRoomContractMin public roomContract;
    IDelegateOwnership public storageContract;
    mapping(uint256 => bool) _exists;

    event tokenCreated(
        uint256 token_id,
        address creator,
        string token_uri,
        uint256 amount,
        uint256 royalty
    );

    constructor(string memory _uri, address _storageContract) ERC1155(_uri) {
        storageContract = IDelegateOwnership(_storageContract);
    }

    modifier onlyOwner {
        require(storageContract.owners(msg.sender), "221");
        _;
    }

    function _mint(
        string memory token_uri,
        uint256 amount,
        uint256 royalty
    ) internal {
        require(royalty <= 100, "203");
        uint256 newTokenId = tokens.length;
        _exists[newTokenId] = true;
        _mint(msg.sender, newTokenId, amount, "");
        tokens.push(Token(newTokenId, msg.sender, token_uri, royalty, true));
        emit tokenCreated(newTokenId, msg.sender, token_uri, amount, royalty);
    }

    function mint(
        string calldata token_uri,
        uint256 amount,
        uint256 royalty
    ) external {
        _mint(token_uri, amount, royalty);
    }

    function mintAndPush(
        string calldata token_uri,
        uint256 price,
        uint256 room_id,
        uint256 royalty,
        uint128 start_time,
        uint128 end_time,
        uint256 amount_mint,
        uint256 amount_push,
        bool is_auction,
        bool is_physical
    ) external {
        require(msg.sender == tx.origin, "205");
        require(amount_mint >= amount_push, "206");
        _mint(token_uri, amount_mint, royalty);
        roomContract.proposeTokenToRoom(
            IRoomContractMin.TokenObject(
                address(this),
                tokens.length - 1,
                room_id,
                price,
                amount_push,  
                start_time,
                end_time,
                is_auction,
                is_physical,
                msg.sender
            )
        );    
    }

    function setRoomContract(address _newRoomContract) external onlyOwner {
        roomContract = IRoomContractMin(_newRoomContract);
    }

    function burn(uint256 token_id, uint256 amount) external {
        require(_exists[token_id], "200");
        _burn(msg.sender, token_id, amount);
    }

    function uri(uint256 token_id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists[token_id], "201");
        return tokens[token_id].token_uri;
    }

    function getCreator(uint256 token_id) public view returns (address) {
        require(_exists[token_id], "202");
        return tokens[token_id].creator;
    }

    function getRoyaltyInfo(uint256 token_id) external view returns (address, uint256, bool) {
        require(_exists[token_id], "203");
        return (tokens[token_id].creator, tokens[token_id].royalty, tokens[token_id].first_sale); 
    }

    function updateFirstSale(uint256 token_id) external {
        require(_exists[token_id], "204");
        require(msg.sender == address(roomContract), "205");
        tokens[token_id].first_sale = false;
    }
}