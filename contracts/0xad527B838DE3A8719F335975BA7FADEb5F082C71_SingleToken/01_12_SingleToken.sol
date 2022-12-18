// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../rooms/interface/IRoomContractMin.sol";
import "../../helpers/IDelegateOwnership.sol";

contract SingleToken is ERC721 {
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

    event tokenCreated(uint256 token_id, address creator, string token_uri, uint256 royalty);

    constructor(address _storageContract) ERC721("Artrooms.App Single NFT", "ARM") {
        storageContract = IDelegateOwnership(_storageContract);
    }

    modifier onlyOwner {
        require(storageContract.owners(msg.sender), "121");
        _;
    }


    function _mint(
        string memory token_uri,
        uint256 royalty
    ) internal {
        require(royalty <= 100, "103");
        uint256 newTokenId = tokens.length;
        _safeMint(msg.sender, newTokenId);
        tokens.push(Token(newTokenId, msg.sender, token_uri, royalty, true));
        emit tokenCreated(newTokenId, msg.sender, token_uri, royalty);
    }

    function mint(
        string calldata token_uri,
        uint256 royalty  
    ) external {
        _mint(token_uri, royalty);
    }

    function mintAndPush(
        string calldata token_uri,
        uint256 price,
        uint256 room_id,
        uint256 royalty,
        uint128 start_time,
        uint128 end_time,
        bool is_auction,
        bool is_physical
    ) external {
        require(msg.sender == tx.origin, "105");
        _mint(token_uri, royalty);
        roomContract.proposeTokenToRoom(
            IRoomContractMin.TokenObject(
                address(this),
                tokens.length - 1,
                room_id,
                price,
                0,
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

    function burn(uint256 token_id) external onlyOwner {
        require(_exists(token_id), "100");
        _burn(token_id);
    }

    function tokenURI(uint256 token_id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(token_id), "101");
        return tokens[token_id].token_uri;
    }

    function getCreator(uint256 token_id) external view returns (address) {
        require(_exists(token_id), "102");
        return tokens[token_id].creator;
    }

    function getRoyaltyInfo(uint256 token_id) external view returns (address, uint256, bool) {
        require(_exists(token_id), "103");
        return (tokens[token_id].creator, tokens[token_id].royalty, tokens[token_id].first_sale); 
    }

    function updateFirstSale(uint256 token_id) external {
        require(_exists(token_id), "104");
        require(msg.sender == address(roomContract), "105");
        tokens[token_id].first_sale = false;
    }
}